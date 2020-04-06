# GCMS data extraction software

Extracts peak data from GCMS .pdf output files and saves data as .txt files.



This tool reads in a number of meta data files, collects information from two specified columns and outputs the information in a new file. As input files, tab seperated files must be used. You can generate them from ecxel files by saving them as "Tab seperated text (.txt)".



cross-platform

Can be operated fully automated using either GUI interface, R markdown, or from command line.

can process up to 198 files at the same time. 



Input file names: 

no spaces. Only of .pdf, .tsv, .csv, .txt, .xlsx format





## For Windows

### Requirements

- #### Conda

  **Install the latest version of Miniconda** 

  The full installation guide can be found [here][https://conda.io/projects/conda/en/latest/user-guide/install/index.html].

  > **IMPORTANT**:  Make sure that you select the correct installer for your machine. Here we show how to do it for Windows

  1. Download the installer:

     [Miniconda installer for Windows](https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe).

  2. [Verify your installer hashes](https://conda.io/projects/conda/en/latest/user-guide/install/download.html#hash-verification). 
  
  3. Double-click the `.exe` file.

  4. Follow the instructions on the screen.

     If you are unsure about any setting, accept the defaults. You can change them later.

     When installation is finished, from the **Start** menu, open the Anaconda Prompt.

  5. Test your installation. In your terminal window or Anaconda Prompt, run the command `conda list`. A list of installed packages appears if it has been installed correctly.

     
  
  **Updating conda**

  1. Open your Anaconda Prompt from the start menu.
2. Navigate to the `anaconda` directory.
  3. Run `conda update conda`.



### Installation

Install software/database in the following order on a personal computer.

1. **Clone/Download the repository from Github**

   Get the latest version of the pipeline using the Pull or Git clone command

2. 

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