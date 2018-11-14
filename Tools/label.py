import sys
import re

label_dict = {}
with open(sys.argv[2]) as f:
	for line in f:
		content = line.strip().split('\t')
		label_dict[content[0]] = content[1]

with open(sys.argv[1]) as fi, open(sys.argv[3],'w') as fo:
	for line in fi:
		if re.match('# BLASTN', line.strip()):
			fo.write('*'*30 + '\n')
		elif re.match('^[^#].+', line.strip()):
			fo.write(label_dict[line.strip().split('\t')[1]] + '\n')