# GCMS data extraction software

Extracts peak data from GCMS .pdf output files and saves data as .txt files.



This tool reads in a number of meta data files, collects information from two specified columns and outputs the information in a new file. As input files, tab seperated files must be used. You can generate them from ecxel files by saving them as "Tab seperated text (.txt)".



cross-platform

Can be operated fully automated using either GUI interface, R markdown, or from command line.

can process up to 198 files at the same time. 



Input file names: 

no spaces. Only of .pdf, .tsv, .csv, .txt, .xlsx format



(Once publicly available insert DOI by Zenodo)

This pipeline is using the **Snakemake workflow** management system , providing a reproducible and scalable data analyses which allows a fully automated processing of **Assay for Transposase-Accessible Chromatin using sequencing** (ATAC-seq) data. The pipeline is very easy to install, includes extensive quality control and reporting functions and can be run on stand alone machines as well as cluster engines such as PBS or Condor (others possible). 

The pipeline is optimised for paired-end ATAC-seq data and allows a full end-to-end data analysis, starting from raw FASTQ files all the way to peak calling and signal track generation. Due to the characteristics of Snakemake the pipeline can also be started from intermediate stages and allows easy resuming of runs. While running, the pipeline produces several reports, including quality control measures, analysis of reproducibility and relaxed thresholding of peaks, fold-enrichment and pvalue signal tracks. 

<figure class="image" >
  <p align="center"> 
    <img src="https://github.com/AndreHolzer/ATAC-seq-pipeline/blob/master/other/scATAC-seq_workflow.jpg?raw=true" width="500">
    <br>
    <em><b>Fig. 1:</b> Schematic diagram displaying the individual steps of the ATAC-seq pipeline</em>
   </p> 
</figure>

The pipeline has been tested on both Mac and Linux operating system analysing plant and algae ATAC-seq data and comes with a genome database for *Arabidopsis thaliana* (TAIR10) and the green model alga *Chlamydomonas reinhardtii* (v5.6 + v4.0). However, custom genomes in FASTA format can be used as well.



### Features

- **Simplicity**: The pipeline provides a reproducible and scalable data analyses which can be executed across different platforms such as your personal computer as well as on cluster engines such as PBS or Condor.

- **End-to-end data analysis**: Starting from raw FASTQ files all the way to peak calling and signal track generation and supports single-end or paired-end ATAC-seq data.

- **Supported genomes**: In difference to most other published pipelines for ATAC-Seq analysis, this pipeline was designed for the use in plant and algae research. We provide a genome database for *A. thaliana* (TAIR10) and *C. reinhardtii* (v5.6 + v4.0). Nevertheless, you can also use the pipeline together with your genome database of choice (human, mouse, etc.).



### **Quick links:**

- Jump to [Requirements](https://github.com/AndreHolzer/ATAC-seq-pipeline#requirements)
- Jump to [Installation](https://github.com/AndreHolzer/ATAC-seq-pipeline#installation)
- Jump to [Usage](https://github.com/AndreHolzer/ATAC-seq-pipeline#usage)
- Jump to [Support & Help](https://github.com/AndreHolzer/ATAC-seq-pipeline#support_&_help)
- Jump to [Citation](https://github.com/AndreHolzer/ATAC-seq-pipeline#citation)



## Requirements

- #### **R**

  Install the latest version of R. A full installation guide can be found [here][https://cran.r-project.org/]. 

  Quick download links (Version 3.6.3):

   - [R for Windows](https://cran.r-project.org/bin/windows/base/R-3.6.3-win.exe)

   - [R for Mac OS El Capitan and higher](https://cran.r-project.org/bin/macosx/R-3.6.3.nn.pkg)

   - [R for Mac OS Catalina](https://cran.r-project.org/bin/macosx/R-3.6.3.pkg)
  
   - [R for Linux](https://cran.r-project.org/bin/linux/)

     

- #### **RStudio**

  Install the latest version of RStudio. More information can be found [here](https://rstudio.com).

  Quick download links:

   - [RStudio for Windows](https://rstudio.com/products/rstudio/download/#download)

   - [RStudio for Mac](https://rstudio.com/products/rstudio/download/#download)

   - [RStudio for Linux](https://rstudio.com/products/rstudio/download/#download)



## Installation

Install software/database in the following order on a personal computer.

1. **Clone/Download the repository from Github**

   Get the latest version of the tool using the Pull or Git clone command

   ```
   conda env create -f envs/core.yaml
   ```

   or for Windows: got to the [GitHub page](https://github.com/AndreHolzer/GCMS-data-extraction-tool) and download and save the repository as .zip file ([Quick download](https://github.com/AndreHolzer/GCMS-data-extraction-tool/archive/master.zip))

   

## Usage

#### **Input**

The tool can take two different inputs, the GCMS summary data (from Thermo or … ), as well as additional dry weight data sample information 

1. ##### GCMS data (required)

   GCMS data must contain information on Compounds, Response time and Response and can be provided in several formats: 

   - `.pdf`: format from Thermo output (see )
   - `.tsv`: format from Thermo output (see )
   - `.csv`: format from Thermo output (see )
   - `.xlsx`: format from Thermo output (see )

   

2. ##### Dry weights (optional)

   Dry weight information about the individual samples must be provided in a tab separate file of the following format. 

   | Sample                         | DW        | Unit              |
   | ------------------------------ | --------- | ----------------- |
   | <File name incuding extension> | <integer> | <charcter string> |
   | <File name incuding extension> | <integer> | <charcter string> |
   | <File name incuding extension> | <integer> | <charcter string> |

   > **IMPORTANT**: DO NOT USE ANY OTHER COLUMN NAMES

   Edit the [Sample_info.tsv]() file to add specific sample dry weight conditions.



#### **Modes of execution**

- ##### Fully automated (GUI)

  > **IMPORTANT**: NOT CURRENTLY SUPPORTED (WORK IN PROGRESS)

  Execute the analysis by a simple double click onto the

  - run.bat (on Windows)
  - run.sh (on Linus & Mac OS)

  

- ##### Interactive (GUI + error reporting)

  - Start RStudio and load/open the main analysis script (GCMS_main-anaylsis-script.R) from the scripts folder
  - Klick Source to start the analysis

  > **IMPORTANT**: Once the analysis has finished check progress log to see whether there were any errors.

  

#### **Data Output**

A main output folder `<date>_GCSM-analysis-results` will be created under the select output directory which will include up to three output subfolder: `pdf2tsv` stores information that was extracted from from .pdf files (if input files where of this type), `plots` stores all plots generated, and `results` stores all matrixes containing Retention time and Response data for all sample.

A final summary of the RT and Response data is stored in `<date>_GCSM-analysis-results/results/<date>_GCMS_analysis-results.xlsx`.



## Support & Help

If you have questions or suggestions, mail us at [andre.holzer.biotech@gmail.com](mailto:andre.holzer.biotech@gmail.com?subject=ATAC-Seq_pipeline), or file a [GitHub issue](https://github.com/AndreHolzer/GDatEx/issues). Please use issues to the GitHub repository for feature requests or bug reports.



## Citation

**If you adopt/run this pipeline for your analysis, cite it as follows :**

**DOI: …**



##### **Developer**

- **Andre Holzer** - *PhD Student, Department of Plant Sciences, Univeristy of Cambridge* [https://orcid.org/0000-0003-2439-6364][https://orcid.org/0000-0003-2439-6364]

- **Matthew P Davey ** - *Senior Research Associate, Department of Plant Sciences, Univeristy of Cambridge* [https://orcid.org/0000-0002-5220-4174](https://orcid.org/0000-0002-5220-4174)

We'd also like to acknowledge Aom Buayam who contributed prototype some parts of this tool.