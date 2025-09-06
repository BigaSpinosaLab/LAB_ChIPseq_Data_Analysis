# ChIP-seq data analysis
This repository includes scripts for pre-processing ChIPseq data to obtain the proper BAM files, peak calling and generating corresponding BigWig files. Called peaks can be imported into R (or other) and further analyzed for i.e. differential binding.  

Considerations to bear in mind:

- All scripts include comments so they are self-explanatory. Nevertheless, below is a brief explanation of how scripts are structured.
- Scripts are prepared to be executed in a HPC environment with SLURM. Even in a similar context, the SLURM directive should be adapted to the specific HPC used and user requirements.
- All scripts required a singularity image containing a specific tool to be run. They can be obtained by executing a singularity recipe or pulling an existing Docker container.
- There is one specific script per analysis step and part of them should be sequentially run. With SLURM, it is possible to run them sequentially using the parameter --dependency when submitting a job to the HPC.

## General Pipeline and scripts structure 

The scripts folder contains the folder bash scripts to complete this part of the analysis. There is one script per specific step in the pipeline, specifically:

- 0_Create_dir_tree_ChIPseq.sh: used to create the proper directory tree for storing intermediate and final results. Rest of scripts rely on this structure.
- 1_Quality_check_data.sh: used to run FASTQ quality check with basic metrics. This can be used for raw and trimmed data.
- 2_Trimming_trimgalore.sh: used to run reads trimming. This is optional depending on the quality/adapters presence in your reads.
- 3_Bowtie2_Build_Index.sh: used to build the required Bowtie2 index for reads alignment. This is not required if you already have an index for the genome assembly under test.
- 4_Bowtie2_alignment.sh: used to align FASTQ files with Bowtie2 aligner tool.
- 5_BAM_MarkDUP.sh: used to mark duplicates in the aligned reads by means of Picard tool.
- 6_Remove_Blacklisted_regions.sh: used to remove ChIPseq blacklisted regions listed by ENCODE.
- 7_OPTIONAL_BAM_RemoveDUP.sh: use to remove already marked duplicates. This is required if PhantomPeaktools is going to be executed. ONLY APPLICABLE FOR SINGLE-END READS. 
- 8_QC_phantompeaktools.sh: used to execute PhantomPeakTools as a QC (NSC and RSC computation). Additionally, result can be used as the input fragment size for peak calling. ONLY APPLICABLE FOR SINGLE-END READS.
- 9_QC_Library_Complexity_metrics.sh: used to assess library complexity (ENCODE Quality metrics such as NRF). 
- 10_QC_FingerPrints.sh: used to assess the ChIPseq quality.
- 11_Create_BigWig.sh: used to obtain BigWig files for later visualization in i.e. IGV.
- 12_MACS2_Peak_calling.sh: used for peak calling (narrow profile peaks such as TFs and specific histone marks) with MACS2 tool.
- 13_epic2_peak_calling.sh: used for peak calling (broad profile peaks such as specific histone marks) with epic2 (SICER) tool.
- 14_Plot_samples_correlation.sh: used to evaluate the correlation among samples from the same dataset in terms of signal across the genome.
- 15_Plot_Samples_Profiles.sh: used to generate density/profile plots to assess the ChIP signal aroung specific genomic regions defined in a BED file.

Importantly, there is a txt file 'ChIPseq_User_defined_parameters.txt' that MUST BE ADAPTED for each ChIPseq data analysis project. It basically contains the required data paths and essential parameter values.

### Scripts structure

All scripts follow the same structure with following sections:

- User defined parameters. This sections specifies the required parameters to define. Most of the scripts do not require anything.
- General configuration. This defines correct paths and sets singularity binding. User do not have to change anything in this part.
- Singularity image and tool parametrization. Definition of the singularity image to be used and the tools parameters to consider.
- Execution. Execution of the corresponding tool using previous information.
  
## Proposed methods section

Following paragraph can be used in a methods section to explain ChIP-seq data pre-processing analysis and peak calling. Information can be adapted/customized in any case depending on what exactly was executed.

"Quality control was performed on raw data with FASTQC tool (v0.11.9). Raw reads were trimmed to remove adapters presence with Trimgalore (v0.6.6). Default parameters were used except for a minimum quality of 15 (Phred score) and an adapter removal stringency of 3bp overlap.  trimmed reads were aligned to the reference genome with Bowtie2 (v2.4.4) which was executed with default parameters. Required genome index was built with corresponding fasta file retrieved from Ensembl (*Specify the specific org assembly and release XXX* i.e. http://ftp.ensembl.org/pub/release-XXX/). Multimapped reads and those exhibiting MAPQ < 20 were removed. Duplicated reads were marked with SAMtools (v1.15). NSC and RSC quality metrics were computed with PhantomPeakQualTools (v1.2). ENCODE blacklisted regions (mm10 v2) were removed prior to peak calling. BigWig files were individually generated using deepTools (v3.5.1) bamCoverage with -binSize 10 -smoothLength 30 - effectiveGenomeSize (*define effective GenomeSize*) -normalizeUsing RPGC and -extendReads Fragment_Length options. The effective genome size was particularized to a read length of 50bp and directly retrieved from deepTools web site (https://deeptools.readthedocs.io/en/develop/content/feature/effectiveGenomeSize.html). Fragment_Length was retrieved from PhantomPeakQualTools results. Peak calling was conducted by means of epic2 (v0.0.52) with -effective-genome-fraction (*compute genome fraction*) -fragment-size Fragment_Length options and chromosome sizes only referring to canonical chromosomes [ALTERNATIVELY, 'Peak calling was conducted by means of MACS2 (v2.2.7.1) with -nomodel -extsize Fragment_Length -g (*specify genome size*) options]. The corresponding input sample was used for peak calling computation. Peaks were called with adjusted p-values (FDR) < 0.05."

References for required tools:

- FASTQC: Andrews S.,FASTQC: a quality control tool for high throughput sequence data. https://github.com/s-andrews/FastQC
- Trimgalore: Felix Krueger, Frankie James, Phil Ewels, Ebrahim Afyounian, & Benjamin Schuster-Boeckler. (2021). FelixKrueger/TrimGalore: v0.6.7 - DOI via Zenodo (0.6.7). Zenodo. https://doi.org/10.5281/zenodo.5127899
- Bowtie2: Langmead B., Salzberg S.L. (2012) Fast gapped-read alignment with Bowtie2 Nat. Methods 9:357–359
- SAMtools: Danecek P., Bonfield J.K., Liddle J., Marshall J., Ohan V., Pollard M.O., Whitwham A., Keane T., McCarthy S.A., Davies R.M. et al. (2021) Twelve years of SAMtools and BCFtools Gigascience 10
- PhantomPeakQualTools: Landt SG1, Marinov GK, Kundaje A et al. ChIP-seq guidelines and practices of the ENCODE and modENCODE consortia. Genome Res. 2012 Sep;22(9):1813-31. doi: 10.1101/gr.136184.111.
- deepTools: Ramírez F., Ryan D.P., Grüning B., Bhardwaj V., Kilpert F., Richter A.S., Heyne S., Dündar F., Manke T (2016) deepTools2: a next generation web server for deep-sequencing data analysis Nucleic Acids Res 44:W160–W165
- epic2: Stovner E.B.Sætrom P (2019) epic2 efficiently finds diffuse domains in ChIP-seq data Bioinformatics 35:4392–4393
- MACS2: Zhang Y., Liu T., Meyer C.A., Eeckhoute J., Johnson D.S., Bernstein B.E., Nusbaum C., Myers R.M., Brown M., Li W.et al. (2008) Model-based analysis of ChIP-Seq (MACS) Genome Biol 9:R137

