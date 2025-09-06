#!/bin/bash

#SBATCH --job-name=BAM_RemoveDups
#SBATCH --partition=long
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --nodes=1  
#SBATCH --output=logs/BAM_RemoveDUPS.out
#SBATCH --error=logs/BAM_RemoveDUPS.err
#SBATCH --array=1-8%3

#=========================
# Initial considerations 
#=========================

# This script is OPTIONAL since duplicates removal is only required if PhantomPeakTools
# wants to be used.

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: It is expected that BAM files have been dup-marked and blacklisted regions removed.
# So, files are expected to have the following suffix:
# .markdup.filtered_blacklisted.bam. If this is not the case, adapt the code (Go to Execution section)

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

# Folder where the mark-duplicated BAM data is located
DATA=$WKD'/Bowtie_align/BAM_Markdup'

# Folder where BAM files Remove DUP will be stored
OUTBAM=$WKD'/Bowtie_align/BAM_NoDups'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Specify image/s name to be used (tool-related)
SAMTOOLS='samtools_v1.15.sif' # This image includes SAMTOOLS 1.15  

# Specify any particular tool parameters
T=4  # Number of threads for samtools

#=========================
# Execution: Remove duplicates with SAMtools
#=========================

# Command for samtools execution -> easier to read for below command
SAMTOOLS_exec="singularity exec $IMAGES_PATH/$SAMTOOLS samtools"

for FILENAME in $DATA/*.markdup.filtered_blacklisted.bam
do
    NAME=${FILENAME%.markdup.filtered_blacklisted.bam}
    SAMPLE=$(basename $NAME)

    # Create a new bam file without duplicates for QC purposes
    echo "$SAMTOOLS_exec view -F 1024 -bh $FILENAME | tee $OUTBAM/$SAMPLE.NoDups.filtered_blacklisted.bam | $SAMTOOLS_exec index - $OUTBAM/$SAMPLE.NoDups.filtered_blacklisted.bam.bai"

done > $WKD'/scripts/cmds/BAM_remove_dups.cmd'

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  Samples Removing Duplicates in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/BAM_remove_dups.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Duplicates removed' 
echo "Processing Time: $DIFF seconds"
