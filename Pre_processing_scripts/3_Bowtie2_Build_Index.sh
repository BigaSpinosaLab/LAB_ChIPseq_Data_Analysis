#!/bin/bash

#SBATCH --job-name=index_Bowtie2
#SBATCH --partition=long
#SBATCH --cpus-per-task=1
#SBATCH --mem=30G
#SBATCH --nodes=1  
#SBATCH --output=logs/index_Bowtie2.out
#SBATCH --error=logs/index_Bowtie2.err

#=========================
# Initial considerations 
#=========================

# NOTE: You can skip this script if you already have an index built in a previous
# project. You only need to rebuild it if you are using a different ref genome assembly

#=========================
# General configuration: paths and singularity images binding
#=========================

# Root directory in the cluster 
ROOTDIR=$(sed -n 6p ChIPseq_User_defined_parameters.txt)
# Project working directory. STAR index will be stored there
WKD=$ROOTDIR/$(sed -n 12p ChIPseq_User_defined_parameters.txt)
# FASTA sequence reference genome
FASTA=$ROOTDIR/$(sed -n 18p RNAseq_User_defined_parameters.txt)
 
START=$(date +%s)
# Enable Singularity image to look into the general path (equivalent to -B)
export SINGULARITY_BIND=$ROOTDIR 
# Path to images folder in cluster
IMAGES_PATH=$ROOTDIR"/images"
# Path to databases folder in cluster
DB_PATH=$ROOTDIR"/db_files"

# Folder where to store the Bowtie index
INDEX=$WKD'/Bowtie_align/Index'

# Prefix to the Bowtie2 index files
NAME=$(sed -n 21p ChIPseq_User_defined_parameters.txt)

#=========================
# Singularity image and Tool Parametrization
#=========================

# Bowtie2 index SHALL be re-computed in following case:
#	 .- different reference genome

# Link to Bowtie2-build manual
# http://bowtie-bio.sourceforge.net/bowtie2/manual.shtml#the-bowtie2-build-indexer

# Specify image/s name to be used (tool-related)
BOWTIE2='bowtie2_v2.4.4.sif'  #This image inludes Bowtie2 2.4.4

# Specify any particular tool parameters
# Number of threads                         
T='8' 

#=========================
# Execution: Build Genome Index
#=========================

DATE=$(date +%m-%d-%Y--%T)
echo "Starting building Genome Index: $DATE"
echo ''

singularity exec $IMAGES_PATH/$BOWTIE2 bowtie2-build --threads $T $FASTA $NAME  

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Genome Index Built' 
echo "Processing Time: $DIFF seconds"
