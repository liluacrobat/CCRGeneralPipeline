import re
import os

# build slurm
home_path = os.path.dirname(os.path.realpath(__file__))  + '/../'
config_file = home_path + 'config.txt'
template_file = home_path + 'Tools/job_template.sh'
para_file = home_path + 'Doc/parameter.txt'
slurm_file = home_path + 'OTU_picking.sh'

replace_pair = {}
cp_flag = False
with open(config_file) as fc, \
     open(para_file, 'w') as pa:
    for line in fc:
        if line.strip() == '#####  QIIME parameter #####':
            cp_flag = True
        elif not cp_flag and not line.strip().startswith('#') and line.strip():
            content = line.strip().split('=')
            replace_pair[content[0].strip()] = \
                    content[1].strip()

        if cp_flag and not (re.match(r'^###', line.strip())):
           pa.write(line) 

def func(m):
    return replace_pair[m.group(1).strip('_')]

with open(template_file) as ft, \
     open(slurm_file, 'w') as fs:
    for line in ft:
        p = re.compile('(__.+?__)')
        s = p.search(line.strip())
        if s:
            fs.write(p.sub(func, line.strip()) + '\n')
        else:
            fs.write(line)
