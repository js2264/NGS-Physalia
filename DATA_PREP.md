# Setup (in maestro)

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
mkdir Share/reads -p
mkdir Share/genome/ -p
mkdir Share/RNA/ -p
mkdir Share/MNase/ -p
mkdir Share/ATAC/ -p
mkdir Share/ChIP/ -p
mkdir Share/HiC/ -p
mkdir Share/Celegans/ -p
mkdir tmp -p
```

# Lab 1

```sh
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR992/004/SRR9929264/SRR9929264_1.fastq.gz -o tmp/Ctl_rep1_R1.fq.gz
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR992/004/SRR9929264/SRR9929264_2.fastq.gz -o tmp/Ctl_rep1_R2.fq.gz
gunzip tmp/Ctl_rep1_R1.fq.gz
head -n 3960384 tmp/Ctl_rep1_R1.fq | gzip > Share/reads/Ctl_rep1_R1.fq.gz
gunzip tmp/Ctl_rep1_R2.fq.gz
head -n 3960384 tmp/Ctl_rep1_R2.fq | gzip > Share/reads/Ctl_rep1_R2.fq.gz

mkdir -p genomes/R64-1-1/STAR/
STAR \
    --runMode genomeGenerate \
    --genomeDir genomes/R64-1-1/STAR/ \
    --genomeFastaFiles Share/genome/R64-1-1.fa \
    --sjdbGTFfile Share/genome/R64-1-1.gtf \
    --genomeSAindexNbases 10

STAR \
    --genomeDir genomes/R64-1-1/STAR/ \
    --readFilesIn Share/reads/Ctl_rep1_R1.fq.gz Share/reads/Ctl_rep1_R2.fq.gz \
    --readFilesCommand zcat \
    --runThreadN 2 \
    --outFileNamePrefix Ctl_rep1. \
    --outSAMtype BAM Unsorted \
    --outSAMunmapped None \
    --outSAMattributes Standard

samtools stats Ctl_rep1.Aligned.out.bam > Ctl_rep1.stats

samtools sort --write-index -o Ctl_rep1_sorted.bam Ctl_rep1.Aligned.out.bam

bamCoverage \
    --bam Ctl_rep1_sorted.bam \
    --outFileName Ctl_rep1.bw \
    --outFileFormat bigwig \
    --binSize 10 \
    --numberOfProcessors 2 \
    --normalizeUsing CPM \
    --extendReads
bamCoverage \
    --bam Ctl_rep1_sorted.bam \
    --outFileName Ctl_rep1.fwd.bw \
    --outFileFormat bigwig \
    --binSize 10 \
    --numberOfProcessors 2 \
    --normalizeUsing CPM \
    --extendReads \
    --filterRNAstrand forward
bamCoverage \
    --bam Ctl_rep1_sorted.bam \
    --outFileName Ctl_rep1.rev.bw \
    --outFileFormat bigwig \
    --binSize 10 \
    --numberOfProcessors 2 \
    --normalizeUsing CPM \
    --extendReads \
    --filterRNAstrand reverse

cp ~/rsg_fast/jaseriza/autobcl2fastq/adapters.txt Share/
cp ~/genomes/S288c/S288c.fa Share/genome/R64-1-1.fa
cp ~/genomes/S288c/S288c.gtf Share/genome/R64-1-1.gtf
cp Ctl_rep1.Log.final.out Share/RNA/
cp Ctl_rep1.Aligned.out.bam Share/RNA/
cp Ctl_rep1.stats Share/RNA/
cp Ctl_rep1_sorted.bam Share/RNA/
cp Ctl_rep1.bw Share/RNA/
cp Ctl_rep1.fwd.bw Share/RNA/
cp Ctl_rep1.rev.bw Share/RNA/
```

# Lab 2

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
for SRR in SRR9929263 SRR9929264 SRR9929273 SRR9929282 SRR9929271 SRR9929265 SRR9929280 SRR9929274; do
    fasterq-dump --log-level info --force -v --split-files --progress --threads 2 $SRR --outdir tmp/ --mem 20GB
done

# rename to corresponding TEMP_REP
mv tmp/SRR9929263_1.fastq tmp/RNAseq_WT_rep1_R1.fq
mv tmp/SRR9929263_2.fastq tmp/RNAseq_WT_rep1_R2.fq
mv tmp/SRR9929264_1.fastq tmp/RNAseq_WT_rep2_R1.fq
mv tmp/SRR9929264_2.fastq tmp/RNAseq_WT_rep2_R2.fq
mv tmp/SRR9929273_1.fastq tmp/RNAseq_WT_rep3_R1.fq
mv tmp/SRR9929273_2.fastq tmp/RNAseq_WT_rep3_R2.fq
mv tmp/SRR9929282_1.fastq tmp/RNAseq_WT_rep4_R1.fq
mv tmp/SRR9929282_2.fastq tmp/RNAseq_WT_rep4_R2.fq
mv tmp/SRR9929271_1.fastq tmp/RNAseq_HS_rep1_R1.fq
mv tmp/SRR9929271_2.fastq tmp/RNAseq_HS_rep1_R2.fq
mv tmp/SRR9929265_1.fastq tmp/RNAseq_HS_rep2_R1.fq
mv tmp/SRR9929265_2.fastq tmp/RNAseq_HS_rep2_R2.fq
mv tmp/SRR9929280_1.fastq tmp/RNAseq_HS_rep3_R1.fq
mv tmp/SRR9929280_2.fastq tmp/RNAseq_HS_rep3_R2.fq
mv tmp/SRR9929274_1.fastq tmp/RNAseq_HS_rep4_R1.fq
mv tmp/SRR9929274_2.fastq tmp/RNAseq_HS_rep4_R2.fq

for SAMPLE in RNAseq_WT_rep1 RNAseq_WT_rep2 RNAseq_WT_rep3 RNAseq_WT_rep4 RNAseq_HS_rep1 RNAseq_HS_rep2 RNAseq_HS_rep3 RNAseq_HS_rep4; do
    sbatch -c 12 --mem 24G --qos fast --wrap "module load STAR; STAR \
        --genomeDir genomes/R64-1-1/STAR/ \
        --readFilesIn tmp/${SAMPLE}_R1.fq tmp/${SAMPLE}_R2.fq \
        --runThreadN 2 \
        --outFileNamePrefix ${SAMPLE}. \
        --outSAMtype BAM Unsorted \
        --outSAMunmapped None \
        --outSAMattributes Standard"
done

for SAMPLE in RNAseq_WT_rep1 RNAseq_WT_rep2 RNAseq_WT_rep3 RNAseq_WT_rep4 RNAseq_HS_rep1 RNAseq_HS_rep2 RNAseq_HS_rep3 RNAseq_HS_rep4; do
    sbatch -c 12 --mem 24G --qos fast --wrap "module load samtools; samtools sort --threads 10 --write-index -o ${SAMPLE}_R64-1-1.bam ${SAMPLE}.Aligned.out.bam"
done

featureCounts \
    -a Share/genome/R64-1-1.gtf \
    -o RNAseq_counts.txt \
    -t transcript \
    -g gene_id \
    -s 2 \
    -p -P -B -D 10000 -C \
    -T 15 \
    RNAseq*R64-1-1.bam

cp RNAseq_WT_rep1_R64-1-1.bam Share/RNA/
cp RNAseq_WT_rep2_R64-1-1.bam Share/RNA/
cp RNAseq_WT_rep3_R64-1-1.bam Share/RNA/
cp RNAseq_WT_rep4_R64-1-1.bam Share/RNA/
cp RNAseq_HS_rep1_R64-1-1.bam Share/RNA/
cp RNAseq_HS_rep2_R64-1-1.bam Share/RNA/
cp RNAseq_HS_rep3_R64-1-1.bam Share/RNA/
cp RNAseq_HS_rep4_R64-1-1.bam Share/RNA/
cp RNAseq_counts.txt Share/RNA/RNAseq_counts.txt
```

# Lab 3

```sh
cd ~/Projects/20260413_Physalia-Epigenomics

fasterq-dump --log-level info --force -v --split-files --progress --threads 2 SRR31398330 --outdir tmp/ --mem 20GB

mv tmp/SRR31398330_1.fastq tmp/MNase_20_R1.fq
mv tmp/SRR31398330_2.fastq tmp/MNase_20_R2.fq
gzip tmp/MNase_20_R1.fq
gzip tmp/MNase_20_R2.fq
mv tmp/MNase_20_R1.fq.gz Share/reads/
mv tmp/MNase_20_R2.fq.gz Share/reads/

trim_galore \
    --cores 15 \
    --length 20 \
    --gzip \
    --paired \
    --output_dir ./ \
    Share/reads/MNase_20_R1.fq.gz Share/reads/MNase_20_R2.fq.gz

bowtie2-build Share/genome/R64-1-1.fa genomes/R64-1-1

bowtie2 \
    --threads 15 \
    -x genomes/R64-1-1 \
    -1 MNase_20_R1_val_1.fq.gz \
    -2 MNase_20_R2_val_2.fq.gz \
    > MNase_20.sam

samtools fixmate \
    -@ 15 \
    --output-fmt bam \
    -r -m \
    MNase_20.sam MNase_20.bam

samtools view \
    -@ 15 \
    --output-fmt bam \
    -f 0x001 -f 0x002 -F 0x004 -F 0x008 -q 20 \
    --fast \
    MNase_20.bam \
    -o MNase_20_filtered.bam

samtools sort \
    -@ 15 \
    --output-fmt bam \
    -l 9 \
    --write-index \
    MNase_20_filtered.bam \
    -o MNase_20_filtered_sorted.bam


bamCoverage \
    --bam MNase_20_filtered_sorted.bam \
    --outFileName MNase_20_filtered_sorted.CPM.bw \
    --binSize 10 \
    --numberOfProcessors 15 \
    --normalizeUsing CPM \
    --skipNonCoveredRegions \
    --extendReads

bamCoverage \
    --bam MNase_20_filtered_sorted.bam \
    --outFileName MNase_20_filtered_sorted.135-160bp.nuc-center.CPM.bw \
    --binSize 1 \
    --smoothLength 10 \
    --numberOfProcessors 15 \
    --normalizeUsing CPM \
    --skipNonCoveredRegions \
    --MNase

cp MNase_20_R1.fq.gz_trimming_report.txt Share/MNase/
cp MNase_20_R2.fq.gz_trimming_report.txt Share/MNase/
cp MNase_20_R1_val_1.fq.gz Share/reads/
cp MNase_20_R2_val_2.fq.gz Share/reads/
cp MNase_20_filtered_sorted.bam Share/MNase/
cp MNase_20_filtered_sorted.CPM.bw Share/MNase/
cp MNase_20_filtered_sorted.135-160bp.nuc-center.CPM.bw Share/MNase/
```

# Lab 4

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
rsync sftpcampus:Rsg_reads/3_YEAST/Mycoplasma/LM292_nxq_R1.fq.gz Share/reads/ATAC_rep1_R1.fq.gz
rsync sftpcampus:Rsg_reads/3_YEAST/Mycoplasma/LM292_nxq_R2.fq.gz Share/reads/ATAC_rep1_R2.fq.gz
rsync sftpcampus:Rsg_reads/3_YEAST/Mycoplasma/LM307_nxq_R1.fq.gz Share/reads/ATAC_rep2_R1.fq.gz
rsync sftpcampus:Rsg_reads/3_YEAST/Mycoplasma/LM307_nxq_R2.fq.gz Share/reads/ATAC_rep2_R2.fq.gz
~/repos/tinyMapper/tinyMapper.sh --mode ATAC --sample Share/reads/ATAC_rep1 --genome ~/genomes/S288c/S288c --output tm/ --threads 16
~/repos/tinyMapper/tinyMapper.sh --mode ATAC --sample Share/reads/ATAC_rep2 --genome ~/genomes/S288c/S288c --output tm/ --threads 16

micromamba run -n yapc_env yapc atac wt tm/tracks/ATAC_rep1/ATAC_rep1*.bw tm/tracks/ATAC_rep2/ATAC_rep2*.bw


cp tm/tracks/ATAC_rep1/ATAC_rep1*.bw Share/ATAC/ATAC_rep1.bw
cp tm/tracks/ATAC_rep2/ATAC_rep2*.bw Share/ATAC/ATAC_rep2.bw
cp tm/bam/genome/ATAC_rep1/ATAC_rep1*.bam Share/ATAC/ATAC_rep1.bam
cp tm/bam/genome/ATAC_rep2/ATAC_rep2*.bam Share/ATAC/ATAC_rep2.bam
cp atac_0.05.bed Share/ATAC/atac_0.05.bed
```

# Lab 5

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
wget https://genome.cshlp.org/content/suppl/2020/11/16/gr.265934.120.DC1/Supplemental_Table_S2.xlsx -O 'WBcel235_REs.xlsx'
cp WBcel235_REs.xlsx Share/Celegans/
```

# Lab 6

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
wget https://hgdownload.soe.ucsc.edu/goldenPath/ce11/bigZips/ce11.fa.gz -O 'ce11.fa.gz'
gunzip ce11.fa.gz
bedtools getfasta -fi Share/genome/ce11.fa -bed Share/modENCODE/xnd-1.bed -name > xnd-1.fa

xstreme \
    --p Share/Celegans/xnd-1.fa \
    --oc meme_out/ \
    -minw 12 \
    -maxw 16 \
    --meme-nmotifs 3 \
    --meme-p 12 \
    --meme-mod zoops \
    --streme-nmotifs 0

cp ce11.fa Share/genome/
cp xnd-1.fa Share/Celegans/
cp -r meme_out/ Share/Celegans/meme_out/
```

# Lab 7 

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR221/072/SRR22130072/SRR22130072_1.fastq.gz -o HiC_R1.fq.gz
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR221/072/SRR22130072/SRR22130072_2.fastq.gz -o HiC_R2.fq.gz

zcat HiC_R1.fq.gz | head -n 15841536 | gzip > Share/reads/HiC_R1.fq.gz
zcat HiC_R2.fq.gz | head -n 15841536 | gzip > Share/reads/HiC_R2.fq.gz

bwa-mem2 index -p genomes/R64-1-1 Share/genome/R64-1-1.fa

bwa-mem2 mem -SP5M -t 2 \
    genomes/R64-1-1 \
    Share/reads/HiC_R1.fq.gz \
    Share/reads/HiC_R2.fq.gz > HiC.sam

pairtools parse \
    -c Share/genome/R64-1-1.chrom.sizes \
    -o HiC.pairs \
    --drop-seq --drop-sam \
    --output-stats hic.stats \
    --nproc-in 2 --nproc-out 2 \
    HiC.sam

pairtools sort --nproc 2 -o HiC.sorted.pairs HiC.pairs

pairtools dedup \
    --max-mismatch 3 \
    --mark-dups \
    --output HiC.sorted.dedup.pairs \
    HiC.sorted.pairs

pairtools select 'pair_type=="UU"' HiC.sorted.dedup.pairs -o HiC_filtered.pairs

cooler cload pairs \
    -c1 2 -p1 3 -c2 4 -p2 5 \
    Share/genome/R64-1-1.chrom.sizes:1000 \
    HiC_filtered.pairs \
    HiC.cool

cooler zoomify -r 1000,5000 --balance -o HiC.mcool Share/HiC/HiC.cool


samtools faidx Share/genome/R64-1-1.fa
cat Share/genome/R64-1-1.fa.fai | cut -f 1,2 > Share/genome/R64-1-1.chrom.sizes
cp hic.stats Share/HiC/
cp HiC.sam Share/HiC/
cp HiC.pairs Share/HiC/
cp HiC_filtered.pairs Share/HiC/
cp HiC.cool Share/HiC/
cp HiC.mcool Share/HiC/
```

# Lab 8 

```sh
cd ~/Projects/20260413_Physalia-Epigenomics
wget "https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSM6703657&format=file&file=GSM6703657%5FHiC%5FMpneumo%5FG2M%2Emcool" -O HiC_G2M.mcool
cooler cp HiC_G2M.mcool::/resolutions/1000 HiC_G2M.cool
cp HiC_G2M.mcool Share/HiC/
```
