# Usage

[{% octicon arrow-left height:32 class:"right left" vertical-align:middle aria-label:hi %}](GS_T.md) [{% octicon home height:32 class:"right left" aria-label:hi %}](index.md) [{% octicon arrow-right height:32 class:"right left" aria-label:hi %}](US_E.md)

----



## Required input data and format

The tool handles two different inputs, the GC/MS peak list data (metabolite vs. peak intensity), as well as an optional file containing sample information including dry weights.

> **ATTENTION**: FILE NAMES MUST NOT CONTAIN ANY SPACES



### 1. GCMS data (required)
GCMS data must contain information on Compounds, Response time (RT) and Peak Intensity (Response) and can be provided in several formats. Several files of the same format can be processed and merged together during a single Metapolish analysis run.

- `.pdf`: format from Thermo analysis output is supported and once loaded will be converted into .tsv format ([see example input](https://github.com/AndreHolzer/Metapolish/blob/master/example_data/input/Thermo-Xcaliber-Tracefinder/Thermo-example_output_1.pdf))


- `.tsv`: format containing three columns (Compound, Retention time, Response) ([see example input](https://github.com/AndreHolzer/Metapolish/blob/master/example_data/input/Sample1.tsv))


- `.csv`: format containing three columns (Compound, Retention time, Response) ([see example input](https://github.com/AndreHolzer/Metapolish/blob/master/example_data/input/Sample1.tsv))


- `.xlsx`: format with first sheet containing three columns (Compound, Retention time, Response) or in Shimadzu output format ([see example input](https://github.com/AndreHolzer/Metapolish/blob/master/example_data/input/Shimadzu_GCMSsolution/1_1_fame.xlsx))

   
### 2. Dry weights (optional)
Dry weight information for the individual samples can be provided in a tab separate file of the following format:

   | Sample                            | DW          | Unit                 |
   | --------------------------------- | ----------- | -------------------- |
   | \<File name including extension\> | \<integer\> | \<character string\> |
   | \<File name including extension\> | \<integer\> | \<character string\> |
   | \<File name including extension\> | \<integer\> | \<character string\> |

   > **IMPORTANT**: DO NOT USE ANY OTHER COLUMN NAMES

For convineince you can simply adjust the [Sample_info.tsv](example_data/Sample_info.tsv) example file to macth your samples.




----
Let's have a look at jow to [execute the anylsis](US_E.md)
