# python3

from random import randint
import re,os




filename = "BitVector.cpp"

def instrument(filename):

	f1 = open(filename, 'r' )

	f2 = open(filename+'_1', 'w')
	f2.writelines('#include "stdio.h"\n')
	
	f_result = open('BBtargets.txt','a+')

	line = f1.readline()

	num = 2
	kuohao_flag = 0     ##### 表示左括号比右括号数多的个数，用于记录还有几个括号没有闭合
	xunhuang_flag = 0   ##### 这个标记表示正在循环或结构内，其中的语句都不插桩
	while_flag = 0      ##### while_flag表示匹配到了可能是循环或结构的词，用来提示下面几行是否匹配循环

	path = re.sub(r'/', '_', filename)
	while line:
		#print(line.strip('\n'))
		for_line = 0
		if re.search('for|while|do|switch|struct|class', line):
			while_flag += 1
			#print('for ', num)
		if re.search('for', line):
			for_line = 1
	
		if re.search('{', line):
			kuohao_flag += 1
			if while_flag > 0 and xunhuang_flag == 0:
				xunhuang_flag = kuohao_flag
				#print('xunhuang ', num)

		if re.search('}', line):
			kuohao_flag -= 1
			if xunhuang_flag == kuohao_flag + 1:
				xunhuang_flag = 0
				f2.writelines(line)
				#print(num, xunhuang_flag)
				line = f1.readline()
				num += 1
				continue
		outfile = path + ':' + str(num)
		#print(outfile)
		fp_name = 'fp' + str(num)
		num_name = 'num'+ str(num)
		text = ' FILE *'+ fp_name +' = fopen("'+ outfile +'", "a+"); if('+fp_name+'){fprintf('+fp_name+',"1"); fclose('+fp_name+');}'

		if re.search(';', line) and not for_line:
			if not re.search('{', line) and while_flag > 0 :
				while_flag -= 1
			if randint(1,1000) < 3 and not xunhuang_flag and kuohao_flag>0:
				line = line.strip('\n') + text + '\n';
				outfile_out = re.sub(r'_', '/', outfile)
				f_result.writelines(outfile_out + '\n')
		f2.writelines(line)
		#print(num, xunhuang_flag)
		line = f1.readline()
		num += 1

	f1.close()
	f2.close()
	f_result.close()


def main():
	try:
		files = os.listdir()
	except:
		pass
	#print(type(files))
	file = files.pop()
	while True:
		print(file)
		if re.search(r'\.c$|\.cc$|\.cpp$', file):
			print(file, "  ready")
			instrument(file)
			os.system('rm ' + file)
			os.system('mv ' + file + '_1 ' + file)
		
		if(os.path.isdir(file)):
			newfiles = os.listdir(file)
			for f in newfiles:
				files.append(file + '/' + f)			
		if(len(files) == 0):
			break
		file = files.pop()
	
	
main()



