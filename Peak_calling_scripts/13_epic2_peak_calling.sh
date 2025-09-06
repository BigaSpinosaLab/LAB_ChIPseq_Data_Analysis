#!/bin/bash

#SBATCH --job-name=epic2
#SBATCH --partition=long
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --nodes=1  
#SBATCH --output=logs/epic2_broad.out
#SBATCH --error=logs/epic2_broad.err
#SBATCH --array=1-6%2

#=========================
# Initial considerations 
#=========================

# This script is for peak calling with epic2. Please execute MACS2 if you expect
# narrow profiles for your peaks.
# epic2 peak caller requires aligned reads in BAM format
# For ChIPseq: BAM should only include unique mappers and duplicates should be marked

# It is mandatory to have a corresponding input file (associated to IP samples),
# at least one input file per condition. Fragment length should be included in case
# of single-end data. 
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

# SPECIFY the file name where the sample;input is included for paired-end
# or sample;input;fragment for single-end. Include a Return in the last row file!
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

# Folder where to store epic2 output 
OUT=$WKD'/epic2_peak_calling'

#=========================
# Singularity image and Tool Parametrization
#=========================

# NOTE: epic2 (ultraperformance implementation of SICER) 
# were especially developed for broad signals 

# Additional information of epic2
# https://academic.oup.com/bioinformatics/article/35/21/4392/5421513
# https://github.com/biocore-ntnu/epic2

# Specify image/s name to be used (tool-related)
EPIC='epic2_v0.0.52.sif'

# Genome size fraction. We will use the same as considered for deepTools 
# https://deeptools.readthedocs.io/en/develop/content/feature/effectiveGenomeSize.html
# Effective genome size mm10 50bp read length: 2308125349 # ADAPT IN FUNCTION OF READ LENGTH
# Genome length: 2,730,871,774 http://nov2020.archive.ensembl.org/Mus_musculus/Info/Annotation
GS_FRACTION=$(sed -n 60p ChIPseq_User_defined_parameters.txt)

# Data is paired end or single end
DATA_CONF=$(sed -n 24p ChIPseq_User_defined_parameters.txt)

# Number of processors
T=4

# FDR to consider; default is 5%
FDR=0.05

# Define the chromosome sizes file (OPTIONAL, epic2 has its own by default ==> It's the same with the only 
# difference that it does not include the non-canonical chromosomes)
CHROMSIZES=$(sed -n 52p ChIPseq_User_defined_parameters.txt)

# NOTE: # --genome  $GENOME #Not used since we're specifying the egf and chromsizes
# Other parameters not used here:
# --keep-duplicates # Include this parameter if duplicates are to be considered

#=========================
# Execution: epic2 peak calling - for broad peaks
#=========================

if [ $DATA_CONF = "SINGLE" ]; then

    while IFS=";" read -r sample input fragment; 
    do
      # Sample name
      NAME=${sample%.sorted.unique.markdup.filtered_blacklisted.bam}
    
      echo "singularity exec $IMAGES_PATH/$EPIC epic2 --treatment $DATA/$sample \
        --control $DATA/$input \
        --chromsizes $CHROMSIZES \
        --effective-genome-fraction $GS_FRACTION \
        --fragment-size $fragment \
        --false-discovery-rate-cutoff $FDR \
        --output $OUT/$NAME.epic2_peaks.txt"
      
    done < $SAMPLESHEET > $WKD'/scripts/cmds/epic2_peak_calling.cmd'

else # In case paired-end data is under analysis

    while IFS=";" read -r sample input; 
    do
      # Sample name
      NAME=${sample%.sorted.unique.markdup.filtered_blacklisted.bam}
    
      echo "singularity exec $IMAGES_PATH/$EPIC epic2 --treatment $DATA/$sample \
        --control $DATA/$input \
        --chromsizes $CHROMSIZES \
        --effective-genome-fraction $GS_FRACTION \
        --guess-bampe \
        --false-discovery-rate-cutoff $FDR \
        --output $OUT/$NAME.epic2_peaks.txt"
      
    done < $SAMPLESHEET > $WKD'/scripts/cmds/epic2_peak_calling.cmd'
    
fi

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  Peak calling in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/epic2_peak_calling.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'epic2 peak calling completed' 
echo "Processing Time: $DIFF seconds"


