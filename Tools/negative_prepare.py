import shutil
import re
import sys
import os
import shlex, subprocess

home_path = os.path.dirname(os.path.realpath(__file__))  + '/../'
all_path = home_path + '/All_fastq/'
negative_path = home_path + '/Negative/'
merge_path = negative_path + '/merge/'
quality_path = negative_path + '/quality/'
blast_path = negative_path + '/blast/'

files = os.listdir(all_path)
for f in files:
    if re.match(r'(.*Negative).*_(R[12])_.*.fastq.gz', f):
        sys.stdout.write('copy %s...\n' % f)
        shutil.copyfile(all_path + f, merge_path + f)
cmd_1 = 'multiple_join_paired_ends.py -i %s -o %s -p Doc/parameter.txt' % (merge_path, merge_path)
print cmd_1
subprocess.check_call(shlex.split(cmd_1))

dirs = [x for x in os.listdir(merge_path) if os.path.isdir(os.path.join(merge_path, x))]
for d in dirs:
    shutil.copyfile(os.path.join(merge_path, d, 'fastqjoin.join.fastq'),
                    os.path.join(quality_path, d+'.fq'))
cmd_2 = 'multiple_split_libraries_fastq.py -i %s -o %s --sampleid_indicator _ -p Doc/parameter.txt' % (quality_path, quality_path)
print cmd_2
subprocess.check_call(shlex.split(cmd_2))

cmd_3 = 'split_sequence_file_on_sample_ids.py -i %s -o %s' % (quality_path + '/seqs.fna', blast_path)
print cmd_3
subprocess.check_call(shlex.split(cmd_3))


