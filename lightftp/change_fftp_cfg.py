import re,os,sys
f1 = open('fftp.conf')
lines = f1.readlines()
f1.close()
f2 = open('fftp.conf1', 'w+')
#
if len(sys.argv) > 1:
	workdir = sys.argv[1]
	print(workdir)
print(lines)

if len(sys.argv)>2:
	port = "port=" + str(sys.argv[2])
else:
	port = "port=2200"

for l in lines:
	l = re.sub("port=2200", port , l)
	
	l = re.sub('/home/ubuntu/fftplog', "./fftplog", l)
	l = re.sub('/home/ubuntu/ftpshare', "./ftpshare", l)
	
	l = re.sub('/home/ubuntu', workdir, l)
	print(l, end='')
	f2.write(l)
f2.close()
#os.remove('dcmqrscp.cfg')
os.rename('fftp.conf1', 'fftp.conf')
