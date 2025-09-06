#!/bin/bash

#SBATCH --job-name=Black_Regions
#SBATCH --partition=long
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --nodes=1  
#SBATCH --output=logs/Black_Regions.out
#SBATCH --error=logs/Black_Regions.err
#SBATCH --array=1-8%3

#=========================
# Initial considerations 
#=========================

# Genome regions defined as black-regions should be removed from ChIPseq data.
# Those are defined regions known to generate artifact in this type of data.
# They include High Signal and Low Mappability regions

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: It is expected that BAM files have the following suffix:
# .markdup.bam. If this is not the case, adapt the code (Go to Execution section)

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

# Folder where the BAM data is (there must be corresponding index file)
DATA=$WKD'/Bowtie_align/BAM_Markdup'

# Folder where to store BAM files without blacklisted regions
OUTBAM=$WKD'/Bowtie_align/BAM_Markdup'

# BED file including blacklisted regions
BL=$ROOTDIR/$(sed -n 28p ChIPseq_User_defined_parameters.txt)

#=========================
# Singularity image and Tool Parametrization
#=========================

# Remove BlackListed regions: ENCODE Black list using bedtools
# https://github.com/Boyle-Lab/Blacklist

# Specify image/s name to be used (tool-related)
SAMTOOLS='samtools_v1.15.sif'   
BEDTOOLS='bedtools_v2.30.0.sif'

# Specify any particular tool parameters
T=4  # Number of threads for samtools

#=========================
# Execution: Remove BlackListed regions with BEDtools
#=========================

# Command for samtools execution -> easier to read for below command
SAMTOOLS_exec="singularity exec $IMAGES_PATH/$SAMTOOLS samtools"

for FILENAME in $DATA/*.markdup.bam 
do
        NAME=${FILENAME%.bam}
        SAMPLE=$(basename $NAME)
        
        echo "singularity exec $IMAGES_PATH/$BEDTOOLS bedtools intersect -abam $FILENAME -b $BL -v | $SAMTOOLS_exec sort -O BAM | tee $OUTBAM/$SAMPLE.filtered_blacklisted.bam | $SAMTOOLS_exec index - $OUTBAM/$SAMPLE.filtered_blacklisted.bam.bai"
        
done > $WKD'/scripts/cmds/Remove_BL.cmd'

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  Removing blacklisted regions and creating index for the new BAM: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/Remove_BL.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED


#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'BL removed' 
echo "Processing Time: $DIFF seconds"
