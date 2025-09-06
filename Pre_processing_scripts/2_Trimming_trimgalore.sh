#!/bin/bash

#SBATCH --job-name=trimming_HE 
#SBATCH --partition=long
#SBATCH --nodes=1  
#SBATCH --output=logs/trimming.out
#SBATCH --error=logs/trimming.err
#SBATCH --array=1-4%2

#=========================
# Initial considerations 
#=========================

# REMARK - array execution - Adapt the number of array tasks to the number of samples 
# i.e. if you have 12 samples to trim (24 fastq files if paired-end) you would need to 
# specify 1-12. %2 means that only two tasks will be simultaneously sent for execution

# REMARK: This script is ASSUMING THAT FASTQ SUFFIXES ARE OF THE TYPE:
# *R1_001.fastq.gz and *R2_001.fastq.gz (latter for paired-end data). 
# If this is not the case, go to > Execution section
# and adapt the code to your needs

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

# Folder where raw data is stored
RAWDATA=$WKD'/raw_data'

# Folder where trimmed data will be stored
TRIMDATA=$WKD'/trimmed_data'

#=========================
# Singularity image and Tool Parametrization
#=========================

# Link to trim galore manual
# https://github.com/FelixKrueger/TrimGalore/blob/master/Docs/Trim_Galore_User_Guide.md

# Specify image/s name to be used (tool-related)
TRIMGALORE='trimgalore_v0.6.6.sif'  #This image inludes TRIMGALORE 0.6.6

# Specify any particular tool parameters
# Quality criteria: by default is 20. For ChIPseq it is not mandatory => less restringent criteria                          
MIN_QUAL='15' 

# Stringency parameter: minimum overlap with adapter sequence to be trimmed (3'). Default: 1b
STRINGENCY='3'

# REMARK: There are other paramters that could be included such as :
# Custom adapter, minimum length, error rate for the adapter
# Check the tool manual for additional parameters

# ADAPT if data is paired end or single end
DATA_CONF=$(sed -n 24p ChIPseq_User_defined_parameters.txt)

#=========================
# Execution: Reads trimming
#=========================

# Command file preparation: to execute batch array

cd $RAWDATA

for FILENAME in *_R1_001.fastq.gz
do
    BASENAME=${FILENAME%_R1_001.fastq.gz}
    
    # Construct the full execution command
    if [ $DATA_CONF = "PAIRED" ]; then
      echo "singularity exec $IMAGES_PATH/$TRIMGALORE trim_galore -o $TRIMDATA --stringency $STRINGENCY -q $MIN_QUAL --paired $RAWDATA'/'$BASENAME'_R1_001.fastq.gz' $RAWDATA'/'$BASENAME'_R2_001.fastq.gz'"
    else
      echo "singularity exec $IMAGES_PATH/$TRIMGALORE trim_galore -o $TRIMDATA --stringency $STRINGENCY -q $MIN_QUAL $RAWDATA'/'$BASENAME'_R1_001.fastq.gz'"
    fi

done > $WKD'/scripts/cmds/trimgalore_samples.cmd'


# Execute command in batch array

DATE=$(date +%m-%d-%Y--%T)
echo "Starting Trimming in array mode: $DATE"
echo ''

SEEDFILE=$WKD'/scripts/cmds/trimgalore_samples.cmd'
SEED=$(sed -n ${SLURM_ARRAY_TASK_ID}p $SEEDFILE)
eval $SEED

#=========================
# End Preprocessing
#=========================

END=$(date +%s)
DIFF=$(( $END - $START ))
echo 'Trimming completed' 
echo "Processing Time: $DIFF seconds"