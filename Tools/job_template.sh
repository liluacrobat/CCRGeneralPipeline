#!/bin/sh
#SBATCH --partition=__PARTITION__
#SBATCH --time=__TIME__
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=12
#SBATCH --constraint=CPU-E5645
#SBATCH --job-name="OTU_picking"
#SBATCH --output=OTU_picking.log

set -e
# set +x
TOTAL_START=`date +%s`

echo '--------------------'
echo 'loading modules ...'
module load python/anaconda
module load R/3.1.2
module load qiime/1.9.0
source activate /util/academic/qiime/1.9.0.dev

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
usearch80 -derep_fulllength reads.fa -fastaout derep.fa -sizeout
usearch80 -sortbysize derep.fa -fastaout sorted.fa -minsize 2
usearch80 -cluster_otus sorted.fa -otus otus1.fa -relabel OTU_ -sizeout -uparseout results.txt
usearch80 -uchime_ref otus1.fa -db ../Database/__GOLD_REF__ -strand plus -nonchimeras otus.fa
usearch80 -usearch_global reads.fa -db otus.fa -strand plus -id 0.97 -uc map.uc
python ../Tools/uparse_python_scripts/uc2otutab.py map.uc > otu_table.txt
biom convert -i otu_table.txt -o otu_table_wo_tax.biom --table-type="OTU table" --to-json
assign_taxonomy.py -i otus.fa -r ../Database/__DB_FA__ -t ../Database/__DB_TAX__ -m blast
biom add-metadata -i otu_table_wo_tax.biom -o otu_table_w_tax.biom --observation-metadata-fp blast_assigned_taxonomy/otus_tax_assignments.txt --observation-header OTUID,taxonomy --sc-separated taxonomy
cd ..
END=`date +%s`
ELAPSED=$(( $END - $START ))
echo "UPARSE picking takes $ELAPSED s"

echo '--------------------'
echo 'table filtering...'
START=`date +%s`
cp UPARSE_OTU/otu_table_w_tax.biom UPARSE_tables
cp UPARSE_OTU/otus.fa UPARSE_tables
cd UPARSE_tables
parallel_align_seqs_pynast.py -i otus.fa -o pynast_aligned_seqs -O 12
filter_samples_from_otu_table.py -i otu_table_w_tax.biom -o otu_table_sample_filtered.biom -n __SAMPLE_ABUNDANCE__
filter_otus_from_otu_table.py -i otu_table_sample_filtered.biom -o otu_table_sample_otu_filtered.biom --min_count_fraction=__OTU_ABUNDANCE__ -e pynast_aligned_seqs/otus_failures.fasta
cp otu_table_sample_otu_filtered.biom final_table.biom
biom convert -i final_table.biom -o final_table.txt --to-tsv --header-key taxonomy
summarize_taxa.py -i final_table.biom -L 2,3,4,5,6,7 -o sum_taxa -a
cd ..
END=`date +%s`
ELAPSED=$(( $END - $START ))
echo "table filtering takes $ELAPSED s"

echo '--------------------'
echo 'negative sample checking'
START=`date +%s`
module load ncbi/blast-2.2.29
python Tools/negative_prepare.py
cp Database/gg/* Negative/blast/
cd Negative/blast/
makeblastdb -in 97_otus.fasta -out gg -dbtype 'nucl' -input_type fasta -logfile gg.log
for f in *Negative*; do 
    blastn -query $f -task blastn -db gg -num_threads 12 -perc_identity 90 -evalue 1e-20 -max_target_seqs 10 -outfmt "7 qacc sacc pident qcovs" -out $f".blast.txt"
    python ../../Tools/label.py $f".blast.txt" 97_otu_taxonomy.txt $f".labeled.txt"
done
cp *labeled.txt ../result
cd ../..
END=`date +%s`
ELAPSED=$(( $END - $START ))
echo "negative checking takes $ELAPSED s"


TOTAL_END=`date +%s`
TOTAL_ELAPSED=$(( $TOTAL_END - $TOTAL_START ))
echo "total takes $TOTAL_ELAPSED s"
