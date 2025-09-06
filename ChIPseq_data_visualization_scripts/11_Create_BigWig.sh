#!/bin/bash

#SBATCH --job-name=BigWig
#SBATCH --partition=long
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --nodes=1  
#SBATCH --output=logs/BigWig_creation.out
#SBATCH --error=logs/BigWig_creation.err
##SBATCH --array=1-8%2

#=========================
# Initial considerations 
#=========================

# This script is for generating BigWig files from BAM files. The generation of 
# BigWig files is highly configurable and depending on the parameter values 
# the track visualization is notably different. It is recommended to test
# different values to find the optimal visualization depending on the type of
# data you want to observe. Go to Tool Parametrization section for checking this:
# Type of normalization, BinSize and SmoothingSize

# BigWig creation proposed here is be individually created 
# (not compared i.e. to an input control)
# User is requested to have a txt file with the custom extension length if 
# you are analyzing single-end data

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: Assume your bam files include suffix sorted.unique.markdup.filtered_blacklisted.bam

#=========================
# General configuration: paths and singularity images binding
#=========================

# Root directory
ROOTDIR=$(sed -n 6p ChIPseq_User_defined_parameters.txt)
# Project working directory. 
WKD=$ROOTDIR/$(sed -n 12p ChIPseq_User_defined_parameters.txt)

# SPECIFY the file name (SINGLE-END) where the 'sample;extension_length' is included. 
SAMPLESHEET=$WKD/$(sed -n 36p ChIPseq_User_defined_parameters.txt)

START=$(date +%s)
# Enable Singularity image to look into the general path (equivalent to -B)
export SINGULARITY_BIND=$ROOTDIR 
# Path to images folder in cluster
IMAGES_PATH=$ROOTDIR"/images"
# Path to databases folder in cluster
DB_PATH=$ROOTDIR"/db_files"

# Folder where input BAM files are available 
DATA=$WKD'/Bowtie_align/BAM_Markdup' # BAM with marked duplicates so can be ignored

# Folder where BigWig files will be stored: 
OUTBW=$WKD'/BigWig'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Take alignment of reads or fragments (BAM format) and generate a coverage track
# in bigWig format.
# 
# Link to deepTools > bamCoverage 
# https://deeptools.readthedocs.io/en/develop/content/tools/bamCoverage.html

# Specify image/s name to be used (tool-related)
DEEPTOOLS='deepTools_v3.5.1.simg'  #This image inludes deepTools v3.5.1

# TOOL Parameters
# Type of normalization to be used: Not used, we will use scaleFactor (readCount)
# RPGC normalizes to 1x coverage
NORM=RPGC  # Other options: CPM, RPKM, BPM, RPGC (not supported for BamCompare) or None

# Number of processors
T=4

# BinSize (by default is 50)
BS=10

# Smoothing (should be larger than BinSize)
SMOOTH=30

# Data is paired end or single end
DATA_CONF=$(sed -n 24p ChIPseq_User_defined_parameters.txt)

# Genome size
GSIZE=$(sed -n 42p ChIPseq_User_defined_parameters.txt)

#=========================
# Execution: bamCoverage from deepTools
#=========================

if [ $DATA_CONF = "SINGLE" ]; then
    
    while IFS=";" read -r sample fragment; do
          # Sample name
          NAME=${sample%.sorted.unique.markdup.filtered_blacklisted.bam}
      
          # Create BigWig files:
          # --ignoreDuplicates # Include this parameter if duplicates to be ignored
          # --centerReads # We discard this option -> maybe wiser for TFs to visualize a sharper peak
      
          # FineTuned option for individual Coverage BigWig files
          echo "singularity exec $IMAGES_PATH/$DEEPTOOLS bamCoverage -b $DATA/$sample --smoothLength $SMOOTH  --extendReads $fragment  --normalizeUsing $NORM --effectiveGenomeSize $GSIZE --binSize $BS -of bigwig -p $T -o $OUTBW/$NAME.ext_bs10_smooth30_woCenter_wDups.bw"

    done < $SAMPLESHEET > $WKD'/scripts/cmds/Create_BigWig_wDups_bs10_smooth30.cmd'

else # In case paired-end data is under analysis

    for sample in $DATA/*.sorted.unique.markdup.filtered_blacklisted.bam; do
    
          # Sample name
          NAME=${sample%.sorted.unique.markdup.filtered_blacklisted.bam}
      
          # Create BigWig files:
          # --ignoreDuplicates # Include this parameter if duplicates to be ignored
          # --centerReads # We discard this option -> maybe wiser for TFs to visualize a sharper peak
      
          # FineTuned option for individual Coverage BigWig files
          echo "singularity exec $IMAGES_PATH/$DEEPTOOLS bamCoverage -b $sample --smoothLength $SMOOTH --normalizeUsing $NORM --effectiveGenomeSize $GSIZE --binSize $BS -of bigwig -p $T -o $OUTBW/$NAME.ext_bs10_smooth30_woCenter_wDups.bw"

    done < $SAMPLESHEET > $WKD'/scripts/cmds/Create_BigWig_wDups_bs10_smooth30.cmd'
    
fi

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  BigWig creation in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/Create_BigWig_wDups_bs10_smooth30.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'BigWig creation completed' 
echo "Processing Time: $DIFF seconds"


