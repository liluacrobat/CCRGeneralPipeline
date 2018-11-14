#!/bin/sh
#SBATCH --partition=general-compute
#SBATCH --time=48:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --mem=23000
# Memory per node specification is in MB. It is optional.
# The default limit is 3000MB per core.
#SBATCH --job-name="JOB_NAME"
#SBATCH --output=JOB_LOG.log
#SBATCH --mail-user=username@buffalo.edu
#SBATCH --mail-type=ALL

set -e
# set +x
TOTAL_START=`date +%s`

echo '--------------------'
echo 'loading modules ...'
module load python/anaconda
module load R/3.1.2
module load qiime/1.9.0
source activate /util/academic/qiime/1.9.0.dev
U_PATH=/util/academic/qiime/1.9.0.dev/usearch/bin/64bit/

echo '--------------------'
echo 'preprocessing...'
START=`date +%s`
python Tools/select_fastq.py
multiple_join_paired_ends.py -i Selected_fastq/ -o Joined/ -p Doc/parameter.txt
python Tools/qf_prepare.py
multiple_split_libraries_fastq.py -i Quality_filtered/ -o Quality_filtered/ --sampleid_indicator . -p Doc/parameter.txt
python Tools/uparse_prepare.py
END=`date +%s`
ELAPSED=$(( $END - $START ))
echo "preprocessing takes $ELAPSED s"

echo '--------------------'
echo 'UPARSE picking...'
START=`date +%s`
cd UPARSE_OTU
$U_PATH/usearch80 -derep_fulllength reads.fa -fastaout derep.fa -sizeout
$U_PATH/usearch80 -sortbysize derep.fa -fastaout sorted.fa -minsize 2
$U_PATH/usearch80 -cluster_otus sorted.fa -otus otus1.fa -relabel OTU_ -sizeout -uparseout results.txt
$U_PATH/usearch80 -uchime_ref otus1.fa -db ../Database/gold/gold.fa -strand plus -nonchimeras otus.fa
$U_PATH/usearch80 -usearch_global reads.fa -db otus.fa -strand plus -id 0.97 -uc map.uc
python ../Tools/uparse_python_scripts/uc2otutab.py map.uc > otu_table.txt
biom convert -i otu_table.txt -o otu_table_wo_tax.biom --table-type="OTU table" --to-json
assign_taxonomy.py -i otus.fa -r ../Database/gg/97_otus.fasta -t ../Database/gg/97_otu_taxonomy.txt -m blast
biom add-metadata -i otu_table_wo_tax.biom -o otu_table_w_tax.biom --observation-metadata-fp blast_assigned_taxonomy/otus_tax_assignments.txt --observation-header OTUID,taxonomy --sc-separated taxonomy
cd ..
END=`date +%s`
ELAPSED=$(( $END - $START ))
echo "UPARSE picking takes $ELAPSED s"

TOTAL_END=`date +%s`
TOTAL_ELAPSED=$(( $TOTAL_END - $TOTAL_START ))
echo "total takes $TOTAL_ELAPSED s"
