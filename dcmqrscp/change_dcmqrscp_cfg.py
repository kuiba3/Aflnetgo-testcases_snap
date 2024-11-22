import re,os,sys
f1 = open('dcmqrscp.cfg')
lines = f1.readlines()
f1.close()
f2 = open('dcmqrscp1.cfg', 'w+')
#
if len(sys.argv) > 1:
	workdir = sys.argv[1]
	print(workdir)
print(lines)

if len(sys.argv)>2:
	port = "NetworkTCPPort = " + str(sys.argv[2])
else:
	port = "NetworkTCPPort = 5158"

for l in lines:
	l = re.sub("NetworkTCPPort = 5158", port , l)
	l = re.sub('<put \$WORK value here>', workdir, l)
	print(l, end='')
	f2.write(l)
f2.close()
#os.remove('dcmqrscp.cfg')
os.rename('dcmqrscp1.cfg', 'dcmqrscp.cfg')
