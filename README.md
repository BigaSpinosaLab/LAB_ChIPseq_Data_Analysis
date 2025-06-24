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
- 3a_BAM_MarkDUP.sh: used to mark duplicates in the aligned reads by means of SAMtools. NOTE: Applied for single-end reads.
- 3b_BAM_MarkDUP.sh: used to mark duplicates in the aligned reads by means of Picard. NOTE: Applied for paired-end reads.
- (OPTIONAL) 4_BAM_RemoveDUP.sh: use to remove already marked duplicates. This is required if PhantomPeaktools is going to be executed. Not required for peak calling.
- 5_Remove_Blacklisted_regions.sh: used to remove ChIPseq blacklisted regions listed by ENCODE.
- 6a_QC_BAM_phantompeaktools.sh: used to execute PhantomPeakTools as a QC (NSC and RSC computation). Additionally, result can be used as the input fragment size for peak calling. ONLY APPLICABLE FOR SINGLE-END READS.
- 6b_QC_Library_Complexity.sh: used to assess library complexity with Preseq. NOTE: If BAM mark duplicates is executed with Picard tool there is no need to execute this since estimated lib size is an output.
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
  
## Proposed methods section

Following paragraph can be used in a methods section to explain ChIP-seq data pre-processing analysis and peak calling. Information can be adapted/customized in any case.

"Quality control was performed on raw data with FASTQC tool (v0.11.9). Raw reads were trimmed to remove adapters presence with Trimgalore (v0.6.6). Default parameters were used except for a minimum quality of 15 (Phred score) and an adapter removal stringency of 3bp overlap.  trimmed reads were aligned to the reference genome with Bowtie2 (v2.4.4) which was executed with default parameters. Required genome index was built with corresponding fasta file retrieved from Ensembl (*Specify the specific org assembly and release XXX* i.e. http://ftp.ensembl.org/pub/release-XXX/). Multimapped reads and those exhibiting MAPQ < 20 were removed. Duplicated reads were marked with SAMtools (v1.15). NSC and RSC quality metrics were computed with PhantomPeakQualTools (v1.2). ENCODE blacklisted regions (mm10 v2) were removed prior to peak calling. BigWig files were individually generated using deepTools (v3.5.1) bamCoverage with -binSize 10 -smoothLength 30 - effectiveGenomeSize (*define effective GenomeSize*) -normalizeUsing RPGC and -extendReads Fragment_Length options. The effective genome size was particularized to a read length of 50bp and directly retrieved from deepTools web site (https://deeptools.readthedocs.io/en/develop/content/feature/effectiveGenomeSize.html). Fragment_Length was retrieved from PhantomPeakQualTools results. Peak calling was conducted by means of epic2 (v0.0.52) with -effective-genome-fraction (*compute genome fraction*) -fragment-size Fragment_Length options and chromosome sizes only referring to canonical chromosomes [ALTERNATIVELY, 'Peakc calling']"

References for required tools:

- FASTQC: Andrews S.,FASTQC: a quality control tool for high throughput sequence data. https://github.com/s-andrews/FastQC
- Trimgalore: Felix Krueger, Frankie James, Phil Ewels, Ebrahim Afyounian, & Benjamin Schuster-Boeckler. (2021). FelixKrueger/TrimGalore: v0.6.7 - DOI via Zenodo (0.6.7). Zenodo. https://doi.org/10.5281/zenodo.5127899

