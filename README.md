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
- Jump to [References](https://github.com/AndreHolzer/ATAC-seq-pipeline#references)



## Requirements

- #### **R**

  **Install the latest version of R**

  The full installation guide can be found [here][https://cran.r-project.org/]. 

  Quick download links:

   - [R-3.6.3-win.exe](https://cran.r-project.org/bin/windows/base/R-3.6.3-win.exe) (for Windows, double click and follow installation menu, default settings can be used)

   - [R-3.6.3.nn.pkg](https://cran.r-project.org/bin/macosx/R-3.6.3.nn.pkg) (for Mac OS X 10.11 (El Capitan) and higher, except Mac OS Catalina) 
   
   - [R-3.6.3.pkg](https://cran.r-project.org/bin/macosx/R-3.6.3.pkg) (for Mac OS Catalina)

   - [R for Linux](https://cran.r-project.org/bin/linux/) (for Linux)

- #### **RStudio**

  **Install the latest version of RStudio**

  The full installation guide can be found [here][https://rstudio.com]. 

  Quick download links:

   - [RStudio Installation](https://rstudio.com/products/rstudio/download/#download) (for Windows, double click and follow installation menu, default settings can be used)

   - [RStudio Installation](https://rstudio.com/products/rstudio/download/#download) (for Mac) 
   
   - [RStudio Installation](https://rstudio.com/products/rstudio/download/#download) (for Linux)


## Installation

Install software/database in the following order on a personal computer.

1. **Clone/Download the repository from Github**

   Get the latest version of the tool using the Pull or Git clone command

   ```
   conda env create -f envs/core.yaml
   ```

   or for Windows: got to the [GitHub page](https://github.com/AndreHolzer/GCMS-data-extraction-tool) and download and save the repository as .zip file ([Quick download](https://github.com/AndreHolzer/GCMS-data-extraction-tool/archive/master.zip))

   

3. **Install pipeline's Conda environment**

   The environment needs to be created only once. It will be activated once you start the tool.

   ```
   conda env create -f envs/core.yaml
   ```

   To update the environment (if you need extra programs), you can run the following command:

   ```
   conda env update -f envs/core.yaml
   ```





## Usage



run .bat file via double click









1. Activate virtual Snakemake environment using conda**

   ```bash
   conda activate ATAC-seq_snakemake-env
   ```

   

2. **Edit the configuration file config.yaml with the parameters of your choice**

   > **IMPORTANT**: DO NOT BLINDLY USE A TEMPLATE/EXAMPLE INPUT YAML FILE. READ THROUGH THE FOLLOWING GUIDE TO MAKE A CORRECT CONFIG FILE.

   The input config.yaml file specifies all essential input parameters and files that are required for a successful execution of the pipeline. Please make sure to specify absolute paths rather than relative paths in your input config.yaml files.

   - [Example config.yaml file]()

   Edit the `config.yaml` file to set your specific configurations, such as:

   - `rawdata`: directory where all zipped raw fastq files are stored
   - `md5sum`: file where all md5sums are stored
   - `outfolder`: directory where all your output files are located
   - `celltype`: what cell type/tissue your samples came from
   - `samples`: names of the sample to be processed
   - …



3. **Run the Snakemake pipeline**

   ***On local computer***

   Add the snakemake file `Snakefile` and the edited configuration file `config.yaml` to your project directory, and run the following commands:

   ```
   source activate peakcalling
   snakemake --configfile config.yaml
   ```

   ***On cluster***

   Or, you can submit the job onto the hydrogen cluster, or even add a cluster configuration file (e.g. the `cluster.json` provided), which allows you to specify the computational resource (such as memory usage) allocated for each snakemake rule.

   ```
   ....
   ```

   Once you are done you can deactivate the conda environment again

   ```
   source deactivate
   ```

   

4. **Output**

   There will be X output folders: `bedfiles` stores all the .bed files converted from .bam files, `peakcalling` stores the peak calling outputs, and `count` stores peak counts for each sample.

   The final peak count per sample matrix is stored in `count/{celltype}_per_sample_count.txt`.

   A directed acyclic graph illustrating the dependencies between jobs can be generated using:

   ```
   snakemake --configfile config.yaml --dag | dot -Tsvg > pipeline_dag.svg
   ```





## Support & Help

If you have questions or suggestions, mail us at [andre.holzer.biotech@gmail.com](mailto:andre.holzer.biotech@gmail.com?subject=ATAC-Seq_pipeline), or file a [GitHub issue](https://github.com/AndreHolzer/GDatEx/issues). Please use issues to the GitHub repository for feature requests or bug reports.



## Citation

**If you adopt/run this pipeline for your analysis, cite it as follows :**

**DOI: …**



##### **Developer**

- **Andre Holzer** - *PhD Student, Department of Plant Sciences, Univeristy of Cambridge* [https://orcid.org/0000-0003-2439-6364][https://orcid.org/0000-0003-2439-6364]

- **Matthew P Davey ** - *Senior Research Associate, Department of Plant Sciences, Univeristy of Cambridge*

  [https://orcid.org/0000-0002-5220-4174](https://orcid.org/0000-0002-5220-4174)

We'd also like to acknowledge Monika Krolikowski who contributed prototype some parts of this pipeline.



## References

**Packages and software used:** 

- **tabula-py** Copyright (c) 2016 Michiaki Ariga

[https://cran.r-project.org/]: 
