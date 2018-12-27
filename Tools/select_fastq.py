import sys
import re
import os
import shutil

home_path = os.path.dirname(os.path.realpath(__file__))  + '/../'

ids = []
id_file = home_path + 'Doc/selected_id.txt'
with open(id_file) as f:
    for line in f:
        if line.strip == '':
            sys.stderr.write('Warning: empty line found!\n')
        else:
            ids.append(line.strip())

print('%d samples to be selected...\n' % (len(ids)))

all_fq_path = home_path + '/All_fastq/'
selected_fq_path = home_path + '/Selected_fastq/'
cp_cnt = 0
files = os.listdir(all_fq_path)
# intersection: selected
# in seletec_id.txt but not in All_fastq: sequence fail
# in All_fastq but not in selected_id.txt: condition selection fail
for f in files:
    for i in ids:
        if re.match(r'(%s).+(R[12]).+fastq.gz' % i, f):
            sys.stdout.write('copy %s...\n' % f)
            shutil.copyfile(all_fq_path + f, 
                            selected_fq_path + f)
            cp_cnt += 1
print('%d file copied.' % cp_cnt)


if cp_cnt%2 != 0:
    sys.stderr.write('ERROR: miss files...\n')
    sys.exit(1)
