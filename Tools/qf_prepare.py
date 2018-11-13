import shutil
import re
import sys
import os

home_path = os.path.dirname(os.path.realpath(__file__))  + '/../'

ids = []
id_file = home_path + 'Doc/selected_id.txt'
with open(id_file) as f:
    for line in f:
        if line.strip == '':
            sys.stderr.write('Warning: empty line found!\n')
        else:
            ids.append(line.strip())

join_path = home_path + '/Joined/'
qf_path = home_path + '/Quality_filtered/'
files = os.listdir(join_path)
for f in files:
    for i in ids:
        m = re.match(r'(%s).+(R[12]).+' % i, f)
        if m:
            sys.stdout.write('copy %s...\n' % f)
            shutil.copyfile(join_path + f + '/fastqjoin.join.fastq',
                            qf_path + '/' + m.group(1) + '.fq')

