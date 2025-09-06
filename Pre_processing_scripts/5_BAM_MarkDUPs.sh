#!/bin/bash

#SBATCH --job-name=MarkDUPs 
#SBATCH --partition=long
#SBATCH --nodes=1  
#SBATCH --output=logs/MarkDUPs.out
#SBATCH --error=logs/BAM_MarkDUPs.err
# #SBATCH --array=1-8%3

#=========================
# Initial considerations 
#=========================

# Marking duplicates is essential for peak calling. Marked duplicates are not removed
# by default. You should removed them if you wanna execute PhantomPeakTools

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: It is expected that BAM files to dup-mark have the following suffix:
# .sorted.unique.bam. If this is not the case, adapt the code (Go to Execution section)

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

# Folder where the BAM data to be marked-duplicate (i.e 'Bowtie_align/BAM')
DATA=$WKD'/Bowtie_align/BAM'

# Folder where BAM files MARKDUP will be finally stored
OUTBAM=$WKD'/Bowtie_align/BAM_Markdup'

# Folder where Dup stats files will be finally stored
OUTSTATS=$WKD'/Bowtie_align/Other_results'

#=========================
# Singularity image and Tool Parametrization
#=========================

# ChIP-seq data will contain duplicates that should not be considered for peak-calling
# In this step we are going to mark them so we can also check the %duplication rate

# Link to Picard mark duplicates
# https://gatk.broadinstitute.org/hc/en-us/articles/360037052812-MarkDuplicates-Picard

# Specify image/s name to be used (tool-related)
PICARD='picard_v2.27.4.simg' 

#=========================
# Execution: Mark Duplicates with PICARD
#=========================

# Command for samtools execution -> easier to read for below command
PICARD_exec="singularity exec $IMAGES_PATH/$PICARD /opt/miniconda/bin/picard"

for FILENAME in $DATA/*.sorted.unique.bam
do
          NAME=${FILENAME%.bam}
          SAMPLE=$(basename $NAME)

          echo "$PICARD_exec MarkDuplicates --INPUT $FILENAME --OUTPUT $OUTBAM/$SAMPLE.markdup.bam --METRICS_FILE $OUTSTATS/$SAMPLE.markdup.stats.txt --CREATE_INDEX true"

done > $WKD'/scripts/cmds/BAM_markdup_samples.cmd'


# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  Samples Marking Duplicates in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/BAM_markdup.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Picard Mark Duplicates completed' 
echo "Processing Time: $DIFF seconds"
