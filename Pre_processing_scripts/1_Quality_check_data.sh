#!/bin/bash

#SBATCH --job-name=QC_raw
#SBATCH --partition=long
#SBATCH --nodes=1  
#SBATCH --output=logs/QC_raw.out
#SBATCH --error=logs/QC_raw.err

#=========================
# User defined parameters: Select raw or trimmed data
#=========================

# Root directory
ROOTDIR=$(sed -n 6p ChIPseq_User_defined_parameters.txt)
# Project name
PROJECT=$(sed -n 9p ChIPseq_User_defined_parameters.txt)
# Project working directory
WKD=$ROOTDIR/$(sed -n 12p ChIPseq_User_defined_parameters.txt)

# SPECIFY the location to your raw data or trimmed data. 
# Comment or uncomment the relevant one

TYPE="Raw"
DATA=$WKD/'raw_data'

# TYPE="Trimmed"
# DATA=$WKD/'trimmed_data'

#=========================
# General configuration: paths and singularity images binding
#=========================

START=$(date +%s)
# Enable Singularity image to look into the general path (equivalent to -B)
export SINGULARITY_BIND=$ROOTDIR 
# Path to images folder in cluster
IMAGES_PATH=$ROOTDIR"/images"
# Path to databases folder in cluster
DB_PATH=$ROOTDIR"/db_files"

# Location where to add the output results (FASTQC and MULTIQC)
OUTFASTQC=$DATA/'FASTQC'
OUTMULTIQC=$DATA/'MULTIQC'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Specify image/s name to be used (tool-related)
FASTQC='fastqc_v0.11.9.sif'  #This image inludes FASTQC 0.11.9
MULTIQC='multiqc_v1.12.sif' # This images includes MultiQC 1.12

# Specify any particular tool parameters
T='10'            # Number of threads

#=========================
# Execution: Quality Assessment
#=========================

echo ''
echo 'Begin Quality Assessment:FASTQC.............................. '`date`
echo ''

# WARNING: If there are other file types inside $DATA, FASTQC will output an error for them. But
# relevant files (.fastq or .fq will be perfectly inspected)

# NOTE: FASTQC typically would be run with  -o $OUTFASTQC  but it returns writtable error

singularity exec $IMAGES_PATH/$FASTQC fastqc $DATA/* -t $T --noextract 

# Dirty solution to previous writtable error
mv $DATA/*.html $OUTFASTQC
mv $DATA/*.zip $OUTFASTQC

echo ''
echo 'Run MULTIQC.............................. '`date`
echo ''

cd $OUTMULTIQC

singularity exec $IMAGES_PATH/$MULTIQC multiqc $OUTFASTQC \
					--title $PROJECT': Quality Assessment of '$TYPE' Reads' \
					--filename $PROJECT'_Summary_QC_'$TYPE'_reads.html'

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Processing Time: $DIFF seconds"