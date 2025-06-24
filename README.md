# ChIP-seq data analysis
This repository includes scripts for pre-processing ChIPseq data to obtain the proper BAM files, peak calling and generating corresponding BigWig files. Called peaks can be imported into R (or other) and further analyzed for i.e. differential binding  

Considerations to bear in mind:

- All scripts include comments so they are self-explanatory. Nevertheless, below is a brief explanation of how scripts are structured.
- Scripts are prepared to be executed in a HPC environment with SLURM. Even in a similar context, the SLURM directive should be adapted to the specific HPC used and user requirements.
- All scripts required a singularity image containing a specific tool to be run. They can be obtained by executing a singularity recipe or pulling an existing Docker container.
- There is one specific script per analysis step and part of them should be sequentially run. With SLURM, it is possible to run them sequentially using the parameter --dependency when submitting a job to the HPC.

## General Pipeline and scripts structure 

The scripts folder contains the folder bash scripts to complete this part of the analysis. There is one script per specific step in the pipeline, specifically:

- 0_Create_dir_tree_ChIPseq.sh: used to create the proper directory tree for storing intermediate and final results. Rest of scripts rely on this structure.
- 0_Quality_check_data.sh: used to run FASTQ quality check with basic metrics. This can be used for raw and trimmed data.
- 1_Trimming_trimgalore.sh: used to run reads trimming. This is optional depending on the quality/adapters presence in your reads.
- 2a_Bowtie2_Build_Index.sh: used to build the required Bowtie2 index for reads alignment. This is not required if you already have an index for the genome assembly under test.
- 2b_Bowtie2_alignment.sh: used to align FASTQ files with Bowtie2 aligner tool.
- 3_BAM_MarkDUP.sh: used to mark duplicates in the aligned reads.
- (OPTIONAL) 4_BAM_RemoveDUP.sh: use to remove already marked duplicates. This is required if PhantomPeaktools is going to be executed. Not required for peak calling.
- 5_Remove_Blacklisted_regions.sh: used to remove ChIPseq blacklisted regions listed by ENCODE.
- 6a_QC_BAM_phantompeaktools.sh: used to execute PhantomPeakTools as a QC (NSC and RSC computation). Additionally, result can be used as the input fragment size for peak calling. ONLY APPLICABLE FOR SINGLE-END READS.
- 6b_QC_Library_Complexity.sh: used to assess library complexity with Preseq.
- 7_Create_BigWig.sh: used to obtain BigWig files for later visualization in i.e. IGV.
- 8_MACS2_Peak_calling.sh: used for peak calling (narrow profile peaks such as TFs and specific histone marks) with MACS2 tool.
- 9_epic2_peak_calling.sh: used for peak calling (broad profile peaks such as specific histone marks) with epic2 (SICER) tool.
- (OTHER) 10_Plot_samples_correlation.sh
- (OTHER) 10_Plot_samples_fingerprints.sh
- (OTHER) 10_Plot_samples_density_plots.sh

Importantly, there is a txt file 'ChIPseq_User_defined_parameters.txt' that MUST be adapted for each ChIPseq data analysis project. It basically contains the required data paths.

### Scripts structure

All scripts follow the same structure with following sections:

- User defined parameters. This sections specifies the required parameters to define. Most of the scripts do not require anything.
- General configuration. This defines correct paths and sets singularity binding. User do not have to change anything in this part.
- Singularity image and tool parametrization. Definition of the singularity image to be used and the tools parameters to consider.
- Execution. Execution of the corresponding tool using previous information.
