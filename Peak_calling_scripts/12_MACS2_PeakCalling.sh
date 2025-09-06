#!/bin/bash

#SBATCH --job-name=MACS2_peak_calling 
#SBATCH --partition=long
#SBATCH --cpus-per-task=2 
#SBATCH --mem=12G
#SBATCH --nodes=1  
#SBATCH --output=logs/MACS2.narrow.out
#SBATCH --error=logs/MACS2.narrow.err
#SBATCH --array=1-6%1

#=========================
# Initial considerations 
#=========================

# This script is for peak calling with MACS2. Please execute epic2 if you expect
# broad profiles for your peaks.
# MACS2 peak caller requires aligned reads in BAM format (typically from Bowtie2)
# For ChIPseq: BAM should only include unique mappers and duplicates should be marked

# It is mandatory to have a corresponding input file (associated to IP samples),
# at least one input file per condition. Fragment length should be included in case
# of single-end data so no-model is used. 
# User is requested to have a txt file with the correspondance IP <-> input samples


# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

#=========================
# General configuration: paths and singularity images binding
#=========================

# Root directory
ROOTDIR=$(sed -n 6p ChIPseq_User_defined_parameters.txt)
# Project working directory. 
WKD=$ROOTDIR/$(sed -n 12p ChIPseq_User_defined_parameters.txt)

# SPECIFY the file name where the sample;input is included. Remember to create
# one txt per type of calling (i.e. broad or narrow) according to previous
# configuration. Include a Return in the last row file!
SAMPLESHEET=$WKD/$(sed -n 49p ChIPseq_User_defined_parameters.txt)

START=$(date +%s)
# Enable Singularity image to look into the general path (equivalent to -B)
export SINGULARITY_BIND=$ROOTDIR 
# Path to images folder in cluster
IMAGES_PATH=$ROOTDIR"/images"
# Path to databases folder in cluster
DB_PATH=$ROOTDIR"/db_files"

# Folder where input BAM files are available
DATA=$WKD'/Bowtie_align/BAM_Markdup'

# Folder where MACS2 output results will be stored: 
OUTPEAKS=$WKD'/MACS2_peak_calling/Other_results'

#=========================
# Singularity image and Tool Parametrization
#=========================

# MACS2 peak caller requires aligned reads in BAM format (typically from Bowtie2)
# For ChIPseq: BAM should only include unique mappers and duplicates should be marked

# Link to MACS2 peak caller manual
# https://pypi.org/project/MACS2/

# Specify image/s name to be used (tool-related)
MACS2='macs2_v2.2.7.1.sif '  #This image inludes MACS2 2.2.7.1

# Specify any particular tool parameters

# Effective genome size. MACS2 has precomputed values 
GSIZE=$(sed -n 42p ChIPseq_User_defined_parameters.txt)

# Data is paired end or single end
DATA_CONF=$(sed -n 24p ChIPseq_User_defined_parameters.txt)

# Adj p-val (q-val) to be used as threshold criteria: 5% by default
FDR=0.05

# NOTE: MACS2 does not consider duplicates for peak calling
KEEPDUP="" # "--keep-dup all" if you wanna change this behaviour

#=========================
# Execution: MACS2 peak calling - for narrow peaks
#=========================

if [ $DATA_CONF = "SINGLE" ]; then

    while IFS=";" read -r sample input fragment; do
      # Sample name
      NAME=${sample%.sorted.unique.markdup.filtered_blacklisted.bam}
  
      # Peak calling with MACS2 - Narrow peak profile
      echo "singularity exec $IMAGES_PATH/$MACS2 macs2 callpeak -B $KEEPDUP --nomodel --extsize $fragment -g $GSIZE -q $FDR -t $DATA/$sample -c $DATA/$input --outdir $OUTPEAKS -n $NAME"

    done < $SAMPLESHEET > $WKD'/scripts/cmds/MACS2_peak_calling_samples.cmd'

else # In case paired-end data is under analysis

    while IFS=";" read -r sample input; do
      # Sample name
      NAME=${sample%.sorted.unique.markdup.filtered_blacklisted.bam}
  
      # Peak calling with MACS2 - Narrow peak profile
      echo "singularity exec $IMAGES_PATH/$MACS2 macs2 callpeak -B $KEEPDUP -f BAMPE -g $GSIZE -q $FDR -t $DATA/$sample -c $DATA/$input --outdir $OUTPEAKS -n $NAME"

    done < $SAMPLESHEET > $WKD'/scripts/cmds/MACS2_peak_calling_samples.cmd'
    
fi

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  Samples peak calling in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/MACS2_peak_calling_samples.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

##  Move files different from the resulting BED files (narrow or broad Peak files)
mv $OUTPEAKS/*.narrowPeak $WKD'/MACS2_peak_calling/Peaks'

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'MACS2 peak calling completed' 
echo "Processing Time: $DIFF seconds"


