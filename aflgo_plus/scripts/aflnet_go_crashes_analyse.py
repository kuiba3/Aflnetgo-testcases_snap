import subprocess
import time
import os,re

aflpath = '/home/zz/testcases_snap/aflnet_go_v41/'
aflnetreplay = aflpath + 'aflnet-replay'

report = []
crashes_ids = []

#filename = 'id:000000,423012,sig:11,src:000000+000240,op:splice,rep:32'
in_dir = '/home/zz/testcases_snap/jg_live555/live555_aflnet0/testProgs/out-live555_test/replayable-crashes/'
out_dir = '/home/zz/testcases_snap/jg_live555/live555_aflnet0/testProgs/out-live555_test/'
out_name = 'report'
test = '/home/zz/testcases_snap/live555/live555_asan/testProgs/testOnDemandRTSPServer'

def write_time(report_txt, filename):
    temp = re.split(',', filename)
    try:
        num  = int(temp[1])
        num /= 1000
        s = int(num % 60)
        num/= 60
        m = int(num % 60)
        h = int(num / 60)
        report_txt.write(str(h) + 'h' + str(m) + 'm' + str(s) + 's\n')
    except:
        pass

def replay_one(filename):
    report_txt = open(out_dir + out_name + '/crashes_report.txt', 'a+')
    incase = in_dir + filename

    p1 = subprocess.Popen(test +' 8554', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')
    time.sleep(2)
    p2 = subprocess.Popen(aflnetreplay +' ' + incase + ' RTSP 8554 ' + '2>&1', shell=True, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2)

    if not p1.poll():
        p3 = subprocess.Popen('ps -ef|grep ' + str(p1.pid), shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')
        out,err=p3.communicate()
        ids = re.split('\n', out)
        for pi in ids:
            cl = re.split(r' +', pi)
            if len(cl)> 3 and int(cl[2]) == p1.pid:
                os.kill(int(cl[1]), 9)

    out,err = p1.communicate()
    #print(err)
    lines = re.split('\n', err)
    
    is_asan = False
    for l in lines:
        if 'SUMMARY:' in l:
            is_asan =True
            if l not in report:
                report.append(l)
                crashes_ids.append(filename)
                write_time(report_txt, filename)
                report_txt.write(l + '\n')
                report_txt.write(filename + '\n'*2)
                os.system('cp ' + incase + ' ' + out_dir + out_name + '/' + filename)
            break
            
    if not is_asan:
        ll = lines[len(lines)-3] + '\n' + lines[len(lines)-2]
        if ll not in report:
            report.append(ll)
            crashes_ids.append(filename)
            write_time(report_txt, filename)
            report_txt.write(ll + '\n')
            report_txt.write(filename + '\n'*2)
            os.system('cp ' + incase + ' ' + out_dir + out_name + '/' + filename)

    report_txt.close()




def main():
    if out_name not in os.listdir(out_dir):
        os.mkdir(out_dir + out_name)
    else:
        for name in os.listdir(out_dir + out_name):
            os.remove(out_dir + out_name + '/' + name)
    print('start replay .......................')
    files = os.listdir(in_dir)
    files.sort()
    for fname in files:
        print(fname)
        replay_one(fname)
    print('end replay *************************\n')
    for i in range(len(report)):
        print(report[i])
        print(crashes_ids[i])
    
main()














