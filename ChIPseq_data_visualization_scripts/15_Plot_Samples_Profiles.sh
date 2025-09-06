#!/bin/bash

#SBATCH --job-name=PlotProf
#SBATCH --partition=long
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --nodes=1  
#SBATCH --output=logs/Plot_Profiles.out
#SBATCH --error=logs/Plot_Profiles.err

#=========================
# Initial considerations 
#=========================

# This script is for generating profile plots for scores over sets of genomic regions.
# Typically, these regions are genes, but any other regions defined in BED file is OK
# Profiles computed over BigWig files

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

# Folder where input BigWig files are available with normalized data
DATA=$WKD'/BigWig'

# Folder where results will be stored: 
OUT=$WKD'/Other/Profiles'

#=========================
# Singularity image and Tool Parametrization
#=========================

# PlotProfile of different samples from deepTools

# First, a count matrix is created based on the BigWig files (already normalized) for
# specific bed files and then plot the profile for those

# Txt file where all required information (bed;name) is stored
BEDINFO=$(sed -n 76p ChIPseq_User_defined_parameters.txt)

# Number of characters to be cut (suffix) in BigWig filenames to have the sample lables
CUTLENGTH_BIGWIG=$(sed -n 80p ChIPseq_User_defined_parameters.txt)

# Before region ref point distance
DISTANCE_REF_BEFORE=$(sed -n 84p ChIPseq_User_defined_parameters.txt)

# After region ref point distance
DISTANCE_REF_AFTER=$(sed -n 88p ChIPseq_User_defined_parameters.txt)

# Specify image/s name to be used (tool-related)
DEEPTOOLS='deepTools_v3.5.1.simg'  #This image inludes deepTools v3.5.1

# Specify any particular tool parameters
# Number of processors
T=4

#=========================
# Execution: Density plots around genomic regions
#=========================

bwfiles=$(ls $DATA/*.bw)
labels=$(for f in $DATA/*.bw; do basename $f | rev | cut -c$CUTLENGTH_BIGWIG- | rev ;done)

# Compute matrices considering all bigwig files of interest

while IFS=";" read -r bed name; 
do
    # Compute Matrix 
    
    singularity exec $IMAGES_PATH/$DEEPTOOLS computeMatrix reference-point \
            --referencePoint center \
            -b $DISTANCE_REF_BEFORE -a $DISTANCE_REF_AFTER \
            --regionsFileName $bed \
            --scoreFileName $bwfiles \
            --samplesLabel $labels \
            --binSize 50 \
            --averageTypeBins mean \
            -p max \
            --skipZeros \
            -out $OUT/$name'_Matrix_peaks.gz' \
            --outFileNameMatrix $OUT/$name'_Matrix_individual_values.tab'
            
      # Plot Profile
      
      singularity exec $IMAGES_PATH/$DEEPTOOLS plotProfile \
                --matrixFile $OUT/$name'_Matrix_peaks.gz' \
                -out $OUT/$name'_Peaks_profile.pdf' \
                --regionsLabel "" \
                --perGroup \
                --refPointLabel $name" center peaks"
                
done < $BEDINFO
            
#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Plotting profiles completed' 
echo "Processing Time: $DIFF seconds"


