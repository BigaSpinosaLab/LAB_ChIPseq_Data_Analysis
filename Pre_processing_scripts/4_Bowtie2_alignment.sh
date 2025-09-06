#!/bin/bash

#SBATCH --job-name=Bowtie_alignment 
#SBATCH --partition=long
#SBATCH --cpus-per-task=4 
#SBATCH --mem=32G
#SBATCH --nodes=1  
#SBATCH --output=logs/Bowtie_align.out
#SBATCH --error=logs/Bowtie_align.err
#SBATCH --array=1-12%2

#=========================
# Initial considerations 
#=========================

# Bowtie2 alignment requires a genome INDEX (previously computed) - see 2a_Bowtie2_Build_Index script.
# Please, check the tool manual to understand the options for execution and assess
# wether you want to include additional parameters

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: This script is ASSUMING THAT FASTQ SUFFIXES ARE OF THE TYPE:
# *R1_val_1.fq.gz  and *R2_val_1.fq.gz for paired-end data and .fq.gz for single end.
# This is the typical suffix you get when you execute TrimGalore.
# If this is not the case, go to > Execution section
# and adapt the code to your needs

# REMARK: Only unique mappers (and with MAPQ>20) are retained. If you want to keep multimappers,
# you will have to adapt the execution

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

# Folder where proper Bowtie2 index is stored - INCLUDING BASENAME
INDEX=$ROOTDIR/$(sed -n 15p ChIPseq_User_defined_parameters.txt)

# Folder where data to be aligned is located (i.e 'trimmed_data')
DATA=$WKD'/trimmed_data'

# Folder where Bowtie2 alignment results will be stored
OUT=$WKD'/Bowtie_align/Other_results'

# Folder where BAM files will be finally stored
OUTBAM=$WKD'/Bowtie_align/BAM'

# Folder where Alignment stats files will be finally stored
OUTSTATS=$WKD'/Bowtie_align/Other_results'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Link to Bowtie2 aligner manual
# http://bowtie-bio.sourceforge.net/bowtie2/manual.shtml#the-bowtie2-aligner

# Specify image/s name to be used (tool-related)
BOWTIE='bowtie2_v2.4.4.sif '  #This image inludes Bowtie2 2.4.4
SAMTOOLS='samtools_v1.15.sif' # This image includes SAMTOOLS 1.15  

# Specify any particular tool parameters
# Number of threads                         
T='8' 

# ADAPT if data is paired end or single end
DATA_CONF=$(sed -n 24p ChIPseq_User_defined_parameters.txt)

#=========================
# Execution: Alignment with Bowtie2
#=========================

# Command for samtools execution -> easier to read piped command below
SAMTOOLS_exec="singularity exec $IMAGES_PATH/$SAMTOOLS samtools"

if [ $DATA_CONF = "SINGLE" ]; then
    
    for FILENAME in $DATA/*.fq.gz; do
    
        NAME=${FILENAME%.fq.gz}
        SAMPLE=$(basename $NAME)
    
        # Construct the full execution command for Bowtie2 alignment + remove those with MAPQ < 20 or unmapped + unique mappers + create BAM index
        echo "singularity exec $IMAGES_PATH/$BOWTIE bowtie2 --threads $T -x $INDEX -U $FILENAME --end-to-end --no-unal 2> $OUTSTATS/$SAMPLE.align.stats.txt | $SAMTOOLS_exec view -F 4 -h -q20 | grep -v 'XS:i:' | $SAMTOOLS_exec sort -O BAM | tee $OUTBAM/$SAMPLE.sorted.unique.bam | $SAMTOOLS_exec index - $OUTBAM/$SAMPLE.sorted.unique.bam.bai"

    done > $WKD'/scripts/cmds/Bowtie2_align_samples.cmd'

else # In case paired-end data is under analysis

    for FILENAME in $DATA/*_R1_val_1.fq.gz; do
          
        NAME=${FILENAME%_R1_val_1.fq.gz}
        SAMPLE=$(basename $NAME)
    
        # Forward and Reverse Reads for that sample
      	READ1=$NAME'_R1_val_1.fq.gz'
      	READ2=$NAME'_R2_val_2.fq.gz'
    
        # Construct the full execution command for Bowtie2 alignment + remove those with MAPQ < 20 or unmapped + unique mappers + create BAM index
        echo "singularity exec $IMAGES_PATH/$BOWTIE bowtie2 --threads $T -x $INDEX -1 $READ1 -2 $READ2 --no-mixed --end-to-end --no-discordant --no-unal 2> $OUTSTATS/$SAMPLE.align.stats.txt | $SAMTOOLS_exec view -F 4 -h -q30 | grep -v 'XS:i:' | $SAMTOOLS_exec sort -O BAM | tee $OUTBAM/$SAMPLE.sorted.unique.bam | $SAMTOOLS_exec index - $OUTBAM/$SAMPLE.sorted.unique.bam.bai"
    
    done > $WKD'/scripts/cmds/Bowtie2_align_samples.cmd'
    
fi

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  Samples alignment in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/Bowtie2_align_samples.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED


#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Bowtie2 alignment completed' 
echo "Processing Time: $DIFF seconds"
