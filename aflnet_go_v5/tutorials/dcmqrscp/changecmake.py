import re,os,sys
f = open('CMakeLists.txt')
lines = f.readlines()
f.close()
f = open('CMakeLists1.txt', 'w+')
#
if len(sys.argv) > 1:
	path = sys.argv[1]
for l in lines:
	l = re.sub('afl-clang-fast', path + '/afl-clang-fast', l)
	f.write(l)
f.close()

os.rename('CMakeLists1.txt', 'CMakeLists.txt')
