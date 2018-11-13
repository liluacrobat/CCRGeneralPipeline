import re
import os
from itertools import islice

home_path = os.path.dirname(os.path.realpath(__file__)) + '/../'
qf_path = home_path + '/Quality_filtered/'
uparse_path = home_path + '/UPARSE_OTU/'

with open(qf_path + 'seqs.fna') as fi, \
     open(uparse_path + 'reads.fa', 'w') as fo:
    while True:
        next_n = list(islice(fi, 2))
        if not next_n:
            break
        m = re.match(r'^>((.+?)_.+?) .*', next_n[0].strip())
        fo.write('>%s;barcodelabel=%s\n' % (m.group(1), m.group(2)))
        fo.write(next_n[1])

