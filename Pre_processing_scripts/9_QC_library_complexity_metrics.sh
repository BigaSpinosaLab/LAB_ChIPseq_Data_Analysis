#!/bin/bash

#SBATCH --job-name=LibComplexity_Metrics
#SBATCH --partition=long
#SBATCH --cpus-per-task=2 
#SBATCH --mem=8G
#SBATCH --nodes=1  
#SBATCH --output=logs/LibComplexity_Metrics.out
#SBATCH --error=logs/LibComplexity_Metrics.err

#=========================
# Initial considerations 
#=========================

# This script is for computing standard QC metrics defined by ENCODE:  
# NRF, PBC1 and PBC2. If you run Picard for marking duplicates, you also have
# an estimation of the library size, as a measure of library complexity.

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: BAM files suffix is expected to be: .filtered_blacklisted.bam

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

# Folder where BAM files are stored: the ones with dups
DATA=$WKD'/Bowtie_align/BAM_Markdup'

# Folder where Library Complexity metrics are stored
OUT_BAMQC=$WKD'/Bowtie_align/QC/Library_Complexity'

#=========================
# Singularity image and Tool Parametrization
#=========================

##       QC on BAM files from ChIPseq experiment: 
##  Metrics: NRF, PBC1 and PBC2 as defined in ENCODE 
##  https://www.encodeproject.org/data-standards/terms/#library

# Use of Custom Python script from PEPATAC (ATAC-seq analysis)
# This custom script covers these three metrics from the obtained BAM file

BAMQC=$IMAGES_PATH/'pepatac/tools/bamQC.py'

# We need to call the PEPATAC images to load the proper Python modules

# Specify image/s name to be used (tool-related)
PEPATAC='pepatac_v0.10.3.sif' 

################################################################################
## 3. Execution in a loop
################################################################################

# REMARK: *Execution in batch array mode was failing

# Create a running pepatac instance for all samples
singularity instance start -B $ROOTDIR:$ROOTDIR $IMAGES_PATH/$PEPATAC pepatac_instance

for FILENAME in $DATA/*.filtered_blacklisted.bam
do
     NAME=${FILENAME%.bam}
     SAMPLE=$(basename $NAME)

     # LC metrics execution using PEPATAC script
     
    singularity exec instance://pepatac_instance \
        $BAMQC -i $FILENAME \
        --cores 6 \
        -o $OUT_BAMQC/$SAMPLE.bamQC.tsv

done

# Close the running pepatac instance
singularity instance stop pepatac_instance

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'BAM library complexity metrics completed' 
echo "Processing Time: $DIFF seconds"
