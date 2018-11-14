#convert HOMD seq and tax file into Greengenes compatible format
#python homd_convert.py HOMD_16S_rRNA_RefSeq_V13.2.fasta homd_taxonomy_table.txt
from itertools import islice
import sys

tax_id_TO_tax = {}
with open(sys.argv[2]) as f:
        f.readline() # empty first line
        f.readline() # header line
        for line in f:
                if line.strip() != '':
                        content = line.strip().split('\t')
                        tax_id_TO_tax[content[0]] = 'k__%s; p__%s; c__%s; o__%s; f__%s; g__%s; s__%s' % \
                                (content[1], content[2], content[3], content[4], content[5], content[6], content[7])

seq_cnt = 0
with open(sys.argv[1]) as f, \
         open('homd.fa', 'w') as f_fa, \
         open('homd.tax', 'w') as f_tax:
        while True:
                next_n = list(islice(f, 2))
                if not next_n:
                        break
                if '\n' in next_n:
                        sys.stderr.write('empty line\n')

                # get tax id
                tax_id = next_n[0].strip().split('|')[2].strip()[4:]
                
                f_fa.write('>%d\n' % seq_cnt)
                f_fa.write(next_n[1])

                f_tax.write('%d\t%s\n' % (seq_cnt, tax_id_TO_tax[tax_id]))

                seq_cnt += 1

