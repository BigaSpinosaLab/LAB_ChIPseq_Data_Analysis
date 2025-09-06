#!/bin/bash

#SBATCH --job-name=FingerPrints
#SBATCH --partition=fast
#SBATCH --cpus-per-task=4 
#SBATCH --mem=24G
#SBATCH --nodes=1  
#SBATCH --output=logs/FingerPrints.out
#SBATCH --error=logs/FingerPrints.err

#=========================
# Initial considerations 
#=========================

# This script is a visual quality control to assess if the ChIP experiment worked
# Cumulative enrichment, aka BAM fingerprint, is yet another way of checking the 
# quality of ChIP-seq signal. It determines how well the signal in the ChIP-seq 
# sample can be differentiated from the background distribution of reads in the 
# control input sample.
# BAM should have duplicates marked

#=========================
# General configuration: paths and singularity images binding
#=========================

# Root directory
ROOTDIR=$(sed -n 6p ChIPseq_User_defined_parameters.txt)
# Project working directory. 
WKD=$ROOTDIR/$(sed -n 12p ChIPseq_User_defined_parameters.txt)

START=$(date +%s)
# Enable Singularity image to look into the general path (equivalent to -B)
export SINGULARITY_BIND=$ROOTDIR 
# Path to images folder in cluster
IMAGES_PATH=$ROOTDIR"/images"
# Path to databases folder in cluster
DB_PATH=$ROOTDIR"/db_files"

# Folder where BAM files (duplicates are automatically ignored)
DATA=$WKD'/Bowtie_align/BAM_Markdup' 

# Folder where phantompeaktools results are stored
OUTPLOT=$WKD'/Bowtie_align/QC/FingerPrints'

#=========================
# Singularity image and Tool Parametrization
#=========================

# QC on BAM files from ChIPseq experiment: plotFingerPrints (deepTools)

# Link to plotFingerPrints (deepTools) 
# https://deeptools.readthedocs.io/en/latest/content/tools/plotFingerprint.html

# Specify image/s name to be used (tool-related)
DEEPTOOLS='deepTools_v3.5.1.simg ' # This image includes deepTools v3.5.1

# Number of characters to be cut (suffix) in BAM filenames to have the sample lables
CUTLENGTH=$(sed -n 65p ChIPseq_User_defined_parameters.txt)

# Extension reads length:
EXTENSION=$(sed -n 69p ChIPseq_User_defined_parameters.txt)

#=========================
# Execution: QC fingerprints
#=========================

bamfiles=$(ls $DATA/*.sorted.unique.markdup.filtered_blacklisted.bam)
labels=$(for f in $DATA/*.sorted.unique.markdup.filtered_blacklisted.bam; do basename $f | rev | cut -c$CUTLENGTH- | rev ;done)

singularity exec $IMAGES_PATH/$DEEPTOOLS plotFingerprint \
          --ignoreDuplicates --bamfiles $bamfiles \
          --labels $labels \
          --extendReads $EXTENSION \
          -T 'Fingerprints' -plot $OUTPLOT'/Fingerprints_ChIP_experiment.pdf'

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'plot FingerPrints completed' 
echo "Processing Time: $DIFF seconds"