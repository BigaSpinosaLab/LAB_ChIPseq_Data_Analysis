#!/bin/bash

#SBATCH --job-name=PlotCorr
#SBATCH --partition=long
#SBATCH --cpus-per-task=4
#SBATCH --mem=12G
#SBATCH --nodes=1  
#SBATCH --output=logs/Plot_Corr.out
#SBATCH --error=logs/Plot_Corr.err

#=========================
# Initial considerations 
#=========================

# This script is for generating plots showing the correlation among ChIPseq samples.
# Specifically, the following plots (in png) are generated: (i) Heatmap with Pearson
# correlation, (ii) Heatmap with Spearman correlation, (iii) PCA with top 1k bins and
# (iv) PCA with top 10k bins
# BAM should have duplicates marked

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

# Folder where input BAM files are available: Deduplicated BAM files
DATA=$WKD'/Bowtie_align/BAM_Markdup' # BAM with marked duplicates so can be ignored

# Folder where results will be stored: 
OUT=$WKD'/Other'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Plot Correlation between samples with plotCorrelation from deepTools
# First, compute the read coverages for genomic regions for two or more BAM files. 
# The analysis can be performed for the entire genome by running the program in ‘bins’ mode.  

# Correlation or PCA is computed over previous matrix

# Link to deepTools > multiBamSummary
# https://deeptools.readthedocs.io/en/develop/content/tools/multiBamSummary.html

# Link to deepTools > plotCorrelation
# https://deeptools.readthedocs.io/en/develop/content/tools/plotCorrelation.html

# Link to deepTools > plotPCA
# https://deeptools.readthedocs.io/en/develop/content/tools/plotPCA.html

# Specify image/s name to be used (tool-related)
DEEPTOOLS='deepTools_v3.5.1.simg'  #This image inludes deepTools v3.5.1

# Specify any particular tool parameters
# Number of processors
T=4

# Number of characters to be cut (suffix) in BAM filenames to have the sample lables
CUTLENGTH=$(sed -n 65p ChIPseq_User_defined_parameters.txt)

#=========================
# Execution: deepTools: Compute Read coverages along genome
#=========================

bamfiles=$(ls $DATA/*.sorted.unique.markdup.filtered_blacklisted.bam)
labels=$(for f in $DATA/*.sorted.unique.markdup.filtered_blacklisted.bam; do basename $f | rev | cut -c$CUTLENGTH- | rev ;done)

singularity exec $IMAGES_PATH/$DEEPTOOLS multiBamSummary bins \
            --bamfiles $bamfiles --labels $labels -p max \
            --ignoreDuplicates -out $OUT/bamsummary_readCounts.npz


# Plot Spearman Correlation
singularity exec $IMAGES_PATH/$DEEPTOOLS plotCorrelation \
            -in $OUT/bamsummary_readCounts.npz \
            --corMethod spearman \
            --skipZeros \
            --plotTitle "Spearman Correlation of Read Counts" \
            --whatToPlot heatmap \
            --colorMap RdYlBu --plotNumbers \
            -o $OUT/Heatmap_SpearmanCorr_readCounts.png
            
# Plot PEarson Correlation
singularity exec $IMAGES_PATH/$DEEPTOOLS plotCorrelation \
            -in $OUT/bamsummary_readCounts.npz \
            --corMethod pearson \
            --skipZeros \
            --plotTitle "Pearson Correlation of Read Counts" \
            --whatToPlot heatmap \
            --colorMap RdYlBu --plotNumbers \
            -o $OUT/Heatmap_PearsonCorr_readCounts.png
            
# Plot PCA. By default, it is based on the top1k more variable bins (10kb size)
singularity exec $IMAGES_PATH/$DEEPTOOLS plotPCA \
            -in $OUT/bamsummary_readCounts.npz \
            --transpose \
            --plotTitle "PCA of Read Counts" \
            -o $OUT/PCA_readCounts_Top1k_bins.png
            
            
# Plot PCA. Plot it with 10k
singularity exec $IMAGES_PATH/$DEEPTOOLS plotPCA \
            -in $OUT/bamsummary_readCounts.npz \
            --transpose \
            --ntop 10000 \
            --plotTitle "PCA of Read Counts (all)" \
            -o $OUT/PCA_readCounts_Top10k_bins.png

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Correlation plots already completed' 
echo "Processing Time: $DIFF seconds"


