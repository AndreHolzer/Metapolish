# GCMS data analysis software

![Scripting](https://img.shields.io/badge/Language-R-red.svg)[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)![Current Version](https://img.shields.io/badge/Version-v1.0-blue.svg)(Work in progress!) 

This tool is written in **R** and provides reproducible and scalable data processing of **Gas Chromatography Mass Spectrometry (GC/MS)** information. The tool bridges the gap between output of pre-analysis software like [**Thermo…**]() and required matrix input formats for downstream analysis using common tools such as [**MetaboAnalyst**](https://www.metaboanalyst.ca). 

This tool is very easy to install, includes additional plotting and reporting functions and can be run on machines operating Windows, Mac OS or Linux. It reads in a number of pre-processed GC/MS meta data files, collects additional sample information regarding dry weight and creates condensed outputs suitable for further downstream analysis. As input files, tab separated files can be used alongside the common .pdf export summary formats from Thermo … . Up to 198 input files of the type .pdf, .tsv, .csv, .txt or .xlsx can be processed at the same time.  

The tool can be operated using either GUI interface, R markdown, or soon from command line (the latter which is still work in progress). The tool has been tested on both Mac and Windows operating systems, analysing GC/MS data obtained from algae samples. 

<figure class="image" >
  <p align="center"> 
    <img src="https://github.com/AndreHolzer/GCMS-data-extraction-tool/blob/master/other/scATAC-seq_workflow.jpg?raw=true" width="500">
    <br>
    <em><b>Fig. 1:</b> Schematic diagram displaying the individual steps of the tool</em>
   </p> 
</figure>



### Features

- **Simplicity**: The tool provides a reproducible and scalable data analyses which can be executed across operating systems.
- **Integrated data extraction from .pdf files **: Starting from .pdf files the tool allows easy extraction of GC/MS summary data from common pre-processing tools such as Thermo … or ….



### **Quick links:**

- Jump to [Requirements](https://github.com/AndreHolzer/GCMS-data-extraction-tool#requirements)
- Jump to [Installation](https://github.com/AndreHolzer/GCMS-data-extraction-tool#installation)
- Jump to [Usage](https://github.com/AndreHolzer/GCMS-data-extraction-tool#usage)
- Jump to [Support & Help](https://github.com/AndreHolzer/GCMS-data-extraction-tool#support_&_help)
- Jump to [Citation](https://github.com/AndreHolzer/GCMS-data-extraction-tool#citation)



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

The tool takes two different inputs, the GCMS summary data, as well as additional sample information regarding dry weights.

> **IMPORTANT**: FILE NAMES MUST NOT CONTAIN ANY SPACES

1. ##### GCMS data (required)

   GCMS data must contain information on Compounds, Response time and Response and can be provided in several formats: 

   - `.pdf`: format from Thermo analysis output is supported and once loaded will be converted into .tsv format ([see example input](https://github.com/AndreHolzer/GCMS-data-extraction-tool/blob/master/example_data/Thermo-example_output_1.pdf))
   - `.tsv`: format containing three columns (Compound, Retention time, Response) ([see example input](example_data/Sample1.tsv))
   - `.csv`: format containing three columns (Compound, Retention time, Response) ([see example input](example_data/Sample1.tsv))
   - `.xlsx`: format with first sheet containing three columns (Compound, Retention time, Response)  ([see example input](example_data/Sample1.tsv))

   

2. ##### Dry weights (optional)

   Dry weight information about the individual samples must be provided in a tab separate file of the following format. 

   | Sample                            | DW          | Unit                 |
   | --------------------------------- | ----------- | -------------------- |
   | \<File name including extension\> | \<integer\> | \<character string\> |
   | \<File name including extension\> | \<integer\> | \<character string\> |
   | \<File name including extension\> | \<integer\> | \<character string\> |

   > **IMPORTANT**: DO NOT USE ANY OTHER COLUMN NAMES

   Edit the [Sample_info.tsv](example_data/Sample_info.tsv) file to add specific sample dry weight conditions.



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
