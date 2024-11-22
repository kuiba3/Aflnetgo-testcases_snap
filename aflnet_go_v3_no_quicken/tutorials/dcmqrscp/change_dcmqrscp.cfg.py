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
for l in lines:
	l = re.sub('<put \$WORK value here>', workdir, l)
	print(l)
	f2.write(l)
f2.close()
#os.remove('dcmqrscp.cfg')
os.rename('dcmqrscp1.cfg', 'dcmqrscp.cfg')
