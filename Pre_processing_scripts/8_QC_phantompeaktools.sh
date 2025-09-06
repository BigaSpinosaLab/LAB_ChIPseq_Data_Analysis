#!/bin/bash

#SBATCH --job-name=PhantomPeak
#SBATCH --partition=long
#SBATCH --cpus-per-task=2 
#SBATCH --mem=8G
#SBATCH --nodes=1  
#SBATCH --output=logs/PhantomPeakTools.out
#SBATCH --error=logs/PhantomPeakTools.err
#SBATCH --array=1-8%3

#=========================
# Initial considerations 
#=========================

# This script is for executing PhantomPeakTools. As it is defined, BAM files should only
# include single-end reads. If your data is paired-end, you must extra-processed
# BAM files to be able to execute PhantomPeakTools.

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: BAM files should not include: unmapped, multimappers, low quality mappers or 
# duplicates

# QC metrics based on Strand cross-correlation. They are based on the fact that 
# a high-quality ChIP-seq experiment produces significant clustering of enriched 
# DNA sequence tags at locations bound by the protein of interest, and that the 
# sequence tag density accumulates on forward and reverse strands centered around 
# the binding site. 

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

# Folder where BAM files already WITHOUT duplicates are stored
DATA=$WKD'/Bowtie_align/BAM_NoDups'

# Folder where phantompeaktools results are stored
OUTPHANTOM=$WKD'/Bowtie_align/QC/PhantomPeakTools'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Link to PhantomPeakTools github
# https://github.com/kundajelab/phantompeakqualtools

# Specify image/s name to be used (tool-related)
PHANTOM='phantompeakqualtools_v1.2.sif' # This image includes PhantomPeakTools v1.2 

#=========================
# Execution: PhantomPeak tools
#=========================

# Command for samtools execution -> easier to read for below command
PHANTOMPEAK_exec="singularity exec $IMAGES_PATH/$PHANTOM Rscript /usr/bin/phantompeakqualtools-1.2/run_spp.R"

for FILENAME in $DATA/*.NoDups.filtered_blacklisted.bam
do
    NAME=${FILENAME%.bam}
    SAMPLE=$(basename $NAME)
    
    # Construct the phantompeaktools execution
    
    echo "$PHANTOMPEAK_exec -c=$FILENAME -savp=$OUTPHANTOM/$SAMPLE.spp.pdf -out=$OUTPHANTOM/$SAMPLE.spp.out"
                            
done > $WKD'/scripts/cmds/PhantomPeakTools.cmd'

# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "  PhantomPeakTools in array mode: $DATE"
echo " "

SEEDFILE=$WKD'/scripts/cmds/PhantomPeakTools.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'BAM phantompeaktools completed' 
echo "Processing Time: $DIFF seconds"
