# Demos

## Day 1: MNase-seq

- Download reads from GEO (Henikoff 2011, MNase 20 min, `GSM754390`)
- Process manually: Map them with bowtie2
- bamCoverage: CPM, only 135-160bp

## Day 2: ATAC-seq 

- C. elegans germline dataset (Serizay et al 2020)
- Process with Nextflow
- manual peak calling with YAPC
- Comparison

## Day 3: ChIP-seq

- Process manually: map Scc1 ChIP-seq (eLife 2014 Marston lab, `SRR1103930`)
- bamCoverage: IP/input ratios
- Call peaks

## **Day 4: RNA-seq**

- map yeast stranded RNA (WT 30C, Nuño-Cabanes et al. 2020 Scientific Data)
- check strandness
- Count reads 

## **Day 5: Hi-C**

- Process HiC with hicstuff
- G2 and overlap with Scc1 peaks

# Homeworks

## Day 1: MNase-seq

* bash: Other MNase dataset (2.5 min, `GSM754391`)
* IGV: Visual inspection 
* bash: Try with other coverage extension settings 
* bash: Try without removing duplicates

## Day 2: ATAC-seq

* in R: Overlap ATAC peaks with annotated REs (Serizay et al 2020)
* in R: Check fragment sizes
* in R: Check tissue-specific ATAC peak enrichment in dataset

## Day 3: ChIP-seq

* bash: Fetch peaks (modENCODE)
* bash: Find motifs for Xnd-1
* in R, check distribution ~ genomic features

## **Day 4: RNA-seq**

* bash: Processing of a mutant (WT heat-shock 39C, Nuño-Cabanes et al. 2020 Scientific Data)
* in R: Differential gene expression analysis between samples
* in R: GO enrichment

## **Day 5: multi-omics**

* IGV: check results from MNase, Scc1 ChIP-seq and RNA-seq
* in R: plot profiles MNase @ TSSs
* in R: plot profiles RNA-seq @ Scc1 ChIP-seq 