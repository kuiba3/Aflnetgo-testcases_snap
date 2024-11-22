#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/shm.h>
#include "config.h"
#include "alloc-inl.h"
#include "aflnet.h"

#define server_wait_usecs 10000

u64* (*extract_response_codes)(unsigned char* buf, unsigned int buf_size, unsigned int* state_count_ref) = NULL;

/* Expected arguments:
1. Path to the test case (e.g., crash-triggering input)
2. Application protocol (e.g., RTSP, FTP)
3. Server's network port
Optional:
4. First response timeout (ms), default 1
5. Follow-up responses timeout (us), default 1000
*/

char* trace_bits;

u64* extract_state_codes(u64* state_sequence, unsigned int* state_count) {
    if (state_sequence == NULL && *state_count == 0) {
        (*state_count) = 1;
        state_sequence = (u64*)ck_realloc(state_sequence, (*state_count) * sizeof(u64));
        state_sequence[0] = 0;
    }
    (*state_count)++;
    state_sequence = (u64*)ck_realloc(state_sequence, (*state_count) * sizeof(u64));

    // 获取运行到目标代码的标记地址
#ifdef WORD_SIZE_64
    u64* state_code = (u64*)(trace_bits + MAP_SIZE + 16);
#else
    u64* state_code = (u64*)(trace_bits + MAP_SIZE + 8);
#endif
    state_sequence[(*state_count) - 1] = *state_code;
    return state_sequence;
}


int main(int argc, char* argv[])
{
  FILE *fp;
  int portno, n;
  struct sockaddr_in serv_addr;
  char* buf = NULL, *response_buf = NULL;
  int response_buf_size = 0;
  unsigned int size, i, state_count, packet_count = 0;
  unsigned int *state_sequence;
  unsigned long long* state_enum_sequence = NULL;
  unsigned int state_enum_count = 0;
  unsigned int socket_timeout = 1000;
  unsigned int poll_timeout = 1;
  pid_t pid;
  char* path = NULL;
  char** args = NULL;

  int shm_id = shmget(IPC_PRIVATE, MAP_SIZE + 24, IPC_CREAT | IPC_EXCL | 0600);
  trace_bits = shmat(shm_id, NULL, 0);

  if (argc < 6) {
    PFATAL("Usage: ./aflnet-replay packet_file protocol port [-pt first_resp_timeout(us) -ft follow-up_resp_timeout(ms)] -x exec_path [args]");
  }

  fp = fopen(argv[1],"rb");

  if (!strcmp(argv[2], "RTSP")) extract_response_codes = &extract_response_codes_rtsp;
  else if (!strcmp(argv[2], "FTP")) extract_response_codes = &extract_response_codes_ftp;
  else if (!strcmp(argv[2], "DNS")) extract_response_codes = &extract_response_codes_dns;
  else if (!strcmp(argv[2], "DTLS12")) extract_response_codes = &extract_response_codes_dtls12;
  else if (!strcmp(argv[2], "DICOM")) extract_response_codes = &extract_response_codes_dicom;
  else if (!strcmp(argv[2], "SMTP")) extract_response_codes = &extract_response_codes_smtp;
  else if (!strcmp(argv[2], "SSH")) extract_response_codes = &extract_response_codes_ssh;
  else if (!strcmp(argv[2], "TLS")) extract_response_codes = &extract_response_codes_tls;
  else if (!strcmp(argv[2], "SIP")) extract_response_codes = &extract_response_codes_sip;
  else if (!strcmp(argv[2], "HTTP")) extract_response_codes = &extract_response_codes_http;
  else if (!strcmp(argv[2], "IPP")) extract_response_codes = &extract_response_codes_ipp;
  else {fprintf(stderr, "[AFLNet-replay] Protocol %s has not been supported yet!\n", argv[2]); exit(1);}

  portno = atoi(argv[3]);

  if (!strcmp(argv[4], "-x")) {
      args = realloc(args, (argc - 4) * sizeof(char*));
      for (int i = 5; i < argc; i++) {
          args[i - 5] = argv[i];
      }
      args[argc - 5] = NULL;
  
  }

  if (argc > 6) {
      if (!strcmp(argv[4], "-pt")) {
          poll_timeout = atoi(argv[5]);
          if (argc > 6 && !strcmp(argv[6], "-ft")) {
              socket_timeout = atoi(argv[7]);
              if (argc > 8 && !strcmp(argv[8], "-x")) {
                  args = realloc(args, (argc - 8) * sizeof(char*));
                  for (int i = 9; i < argc; i++) {
                      args[i - 9] = argv[i];
                  }
                  args[argc - 9] = NULL;

              }
            
          }

      }

  }


  pid = fork();
  if (pid < 0) perror("fork error");
  else if (pid == 0) {
      
      char* shm_str = alloc_printf("%d", shm_id);
      int ret = setenv("__AFL_SHM_ID", shm_str, 1);
      if (ret) fprintf(stderr, "setenv __AFL_SHM_ID error\n");
      execv(args[0], args);
      return 0;
  }



  //Wait for the server to initialize
  usleep(server_wait_usecs);

  sleep(2);

  if (response_buf) {
    ck_free(response_buf);
    response_buf = NULL;
    response_buf_size = 0;
  }

  int sockfd;
  if ((!strcmp(argv[2], "DTLS12")) || (!strcmp(argv[2], "DNS")) || (!strcmp(argv[2], "SIP"))) {
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  } else {
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
  }

  if (sockfd < 0) {
    PFATAL("Cannot create a socket");
  }

  //Set timeout for socket data sending/receiving -- otherwise it causes a big delay
  //if the server is still alive after processing all the requests
  struct timeval timeout;

  timeout.tv_sec = 0;
  timeout.tv_usec = socket_timeout;

  setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, (char *)&timeout, sizeof(timeout));

  memset(&serv_addr, '0', sizeof(serv_addr));

  serv_addr.sin_family = AF_INET;
  serv_addr.sin_port = htons(portno);
  serv_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

  if(connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
    //If it cannot connect to the server under test
    //try it again as the server initial startup time is varied
    for (n=0; n < 1000; n++) {
      if (connect(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) == 0) break;
      usleep(1000);
    }
    if (n== 1000) {
      close(sockfd);
      return 1;
    }
  }

  //Send requests one by one
  //And save all the server responses
  int send_num = 0;
  while(!feof(fp)) {
    if (buf) {ck_free(buf); buf = NULL;}
    if (fread(&size, sizeof(unsigned int), 1, fp) > 0) {
      packet_count++;
    	fprintf(stderr,"\nSize of the current packet %d is  %d\n", packet_count, size);

      buf = (char *)ck_alloc(size);
      fread(buf, size, 1, fp);

      if (net_recv(sockfd, timeout, poll_timeout, &response_buf, &response_buf_size)) break;
      n = net_send(sockfd, timeout, buf,size);
      if (n != size) break;
      send_num++;

      if (net_recv(sockfd, timeout, poll_timeout, &response_buf, &response_buf_size)) break;
      state_enum_sequence = extract_state_codes(state_enum_sequence, &state_enum_count);
    }
  }

  fclose(fp);
  close(sockfd);

  shmctl(shm_id, IPC_RMID, NULL);

  //Extract response codes
  state_sequence = (*extract_response_codes)(response_buf, response_buf_size, &state_count);

  fprintf(stderr,"\n--------------------------------");
  fprintf(stderr,"\nResponses from server:");

  for (i = 0; i < state_count; i++) {
    fprintf(stderr,"%d-",state_sequence[i]);
  }

  fprintf(stderr,"\n++++++++++++++++++++++++++++++++\nResponses in details:\n");
  for (i=0; i < response_buf_size; i++) {
    fprintf(stderr,"%c",response_buf[i]);
  }
  fprintf(stderr,"\n--------------------------------");

  fprintf(stderr, "\n------------state_enum_sequence--------------------\n");
  for (i = 0; i < state_enum_count; i++) {
      fprintf(stderr, "%llu-", state_enum_sequence[i]);
  }
  fprintf(stderr, "\nsend_num : % d\n", send_num);

  //Free memory
  ck_free(state_sequence);
  if (buf) ck_free(buf);
  ck_free(response_buf);

  return 0;
}

