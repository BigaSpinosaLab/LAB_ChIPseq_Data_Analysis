#!/bin/bash

################################################################################
##       Create Project directory tree for an standard ChIP-seq analysis with 
##                      Bowtie2 aligner and MACS2/epic2 peak callers
################################################################################

# Project directory tree consists of (inside main project folder):
#   
#    .- raw_data: Includes raw data (FASTQ files). Subdirs: FASTQC and MULTIQC
#    .- trimmed_data: Includes trimmed data (from i.e. trimgalore). Subdirs: FASTQC and MULTIQC
#    .- Bowtie_align: Includes output from Bowtie alignment and Index**
#    .- MACS2_peak_calling: includes output from MACS2 (peak calling)
#    .- epic2_peak_calling: includes output from epic2 (peak calling)
#    .- scripts: Includes all scripts used to analyze the data
#    .- BigWig: Includes generated bigwig files from BAMs
#    .- Other: To include some (optional but recommended) plots

# **If it is built during this project execution

# IMPORTANT REMARK: It is assumed that an initial 'scripts' folder has been 
# previously created during the project preparation

# NOTE: This is the main set of subfolders. Adapt this script for additional subfolders

#=========================
# User defined parameters
#=========================

ROOTDIR=$(sed -n 6p ChIPseq_User_defined_parameters.txt)
WKD=$ROOTDIR/$(sed -n 12p ChIPseq_User_defined_parameters.txt)

mkdir -p $WKD/{raw_data/{FASTQC,MULTIQC},trimmed_data/{FASTQC,MULTIQC}}
mkdir -p $WKD/Bowtie_align/{Index,BAM,BAM_Markdup,BAM_NoDups,Other_results,QC/{PhantomPeakTools,Library_Complexity,FingerPrints}}
mkdir -p $WKD/{BigWig,MACS2_peak_calling/{Peaks,Other_results},epic2_peak_calling}
mkdir -p $WKD/scripts/{cmds,logs}
mkdir -p $WKD/Other/Profiles
