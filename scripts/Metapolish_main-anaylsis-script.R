## HEADER --------------------------------------------
#
# Title: Metapolish - Metabolite Peak List Merging, Annotation & Polishing Tool
# Author: Dr Andre Holzer, https://orcid.org/0000-0003-2439-6364, andre.holzer.biotech@gmail.com, Univeristy of Cambridge
# Date: `r paste(Sys.Date())`
# Copyright (c) Holzer, `r paste(format(Sys.Date(), "%Y"))`
#


## Step 0: Initialise (mandatory) ----
cat("=============================\n")
cat("Step 0: Initialise (mandatory)\n")
cat("=============================\n")

## Step 0.1: Load packages ----

# define packages, install and load them
list.of.packages = c("here","tidyverse","knitr","tcltk","readxl","matrixStats","openxlsx","purrr","dplyr","tools","stringr","utils","pdftools","ggplot2","ggpubr","BBmisc","ggsci","scales","RColorBrewer","devtools","RJSONIO","httr","data.table")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages) > 0) {install.packages(new.packages)}
lapply(list.of.packages, require, character.only=T)


## Step 0.2: Define global variables ----

# Date
date <- format(Sys.Date(), format="%Y-%m-%d")
# GUI to allow user to selection working directory
wd <- tk_choose.dir(here(), caption = "Select your working directory")
setwd(wd)
# Name of the output directory (will be created in your current working directory)
outfolder <- file.path(str_c(date,"_Metapolish-results"))
# remove existing outfolder with same name
unlink(outfolder, recursive = TRUE, force = FALSE)
# create output dir
dir.create(outfolder, showWarnings = FALSE)

# report step
message(str_c("\nINFO: Initialisation completed successfully"))

# remove NULL function
nullToNA <- function(x) {
  x[sapply(x, is.null)] <- "NA"
  return(x)
}

### Step 1: Read peak data input files (mandatory) ----
cat("\n\n=============================\n")
cat("Step 1: Read peak data input files (mandatory) \n")
cat("=============================\n")


## Step 1.1: Select input files (pdf, excel, tsv or csv files) ----

# GUI to allow user selection
filters <- matrix(c("All accepted",".pdf .tsv .csv .xlsx .txt", "PDF files",".pdf","Comma seperated files",".csv","Tab seperated files",".tsv","Excel files" ,".xlsx","Text files",".txt", "All files", "*"), 7, 2, byrow = TRUE)
files <- tk_choose.files(caption = "Choose GCMS files to analyse", multi = TRUE, filter = filters)

# report step
message(str_c("\nINFO: Loading the following sample file: ", files))

# identify file type by extension
ext <- file_ext(files)
file_format <- unique(ext)

# check if file format is supported and consistent
for (file in 1:length(files)){
  # Report error if file format is wrong
  if(!(ext[[file]] %in% c("pdf","xlsx","tsv","csv","txt")) ){
    stop(str_c("Incorrect extension of file ",file,": Please select only files of supported format (.pdf,.xlsx,.tsv,.csv,.txt)."))
  }
  # Report error if not all files are of same format
  if(length(file_format) > 1){
    stop(str_c("Inconsitent file extensions. All files must be of same file format."))
  }
} 


## Step 1.2: Read pdf and convert to tsv ----

# if file format is pdf
if(file_format == "pdf"){
  # initialise file.list
  file.list <- c()
  # loop over all input files
  for (file in 1:length(files)){
    # read pdf file and split into rows
    pages <- pdf_text(files[file]) %>% strsplit(split = "\n")
    # set read to default ("no")
    read <- "no"
    # set run counter to 0
    run <- 0
    # go through the pages and extract table information
    for (p in 1:length(pages)){
      # select text from a page
      page.text<-pages[p][[1]]
      #identify start position for text extraction based on grep result
      start_pos <- tail(grep("Compound", page.text), n=1)
      # set read to yes if start signal was recognised
      if(length(start_pos) == 1){
        read <- "yes"
      }
      # read table data from page
      if(read == "yes"){
        # increase run number
        run <- run + 1
        # first run
        if(run == 1){
          # subset page text vector
          page.text.table <- page.text[(start_pos+1):(length(page.text)-1)]
        }
        # further runs
        if(run > 1){
          # subset page text vector
          page.text.table <- page.text[6:(length(page.text)-1)]
        }
        
        # extract relavant information
        # extract Compound names
        # remove double spaces and insert '\t' as wildcard
        page.text.table.corrected <- gsub(' {2,}','\t',page.text.table) 
        # convert character vector into dataframe
        page.text.df <- data.frame(page.text.table.corrected)
        # add column name
        colnames(page.text.df) <- c("Compound")
        # expand dataframe using column seperation based on wildcard 
        page.text.df <- separate(page.text.df, Compound, into = as.character(c(1:10)), sep='\t')
        # select columns of interest
        page.text.df.final <- select(page.text.df, 1)
        # adjust column names
        colnames(page.text.df.final) <- c("Compound")
        
        # add RT and Response data
        page.text.df.final$RT <- str_extract(string = page.text.table, pattern = "\\s[0-9]{1,}[.][0-9]{2}\\s")
        page.text.df.final$Response <- str_extract(string = page.text.table, pattern = "\\s[0-9]{2,}\\s")
        
        # create full dataframe from pdf table
        if(run == 1){
          final.table <- page.text.df.final
        }
        # add data from further pages to final dataframe
        if(run > 1){
          final.table <- rbind(final.table, page.text.df.final)
        }
      }
    }
    #correct data shift by rows in final table
    # initialise array of rows to be removed
    keep <- c()
    # loop over all rows
    for (i in 2: nrow(final.table)){
      # if compound name is missing in row i but existing in the one above
      if (final.table$Compound[i] == "" & final.table$Compound[(i-1)] != ""){
        # if the opposite is true for RT and Response values
        if(is.na(final.table$RT[i-1]) & is.na(final.table$Response[i-1]) & !is.na(final.table$RT[i]) & !is.na(final.table$Response[i])){
          # copy RT and Resp values to row above and correct row shift
          final.table$RT[i-1] <- final.table$RT[i]
          final.table$Response[i-1] <- final.table$Response[i]
        } 
      } else {
        # save row number to keep after
        keep <- c(keep,i)  
      }
    }
    # remove rows created due to shift
    final.table.corrected <- slice(final.table,keep) 
    
    # create output dir
    dir.create(file.path(outfolder,"pdf2tsv"), showWarnings = FALSE)
    # save extracted data from pdf file as .tsv file
    write.table(final.table.corrected, file.path(outfolder,"pdf2tsv", paste0(date,"_",basename(files[file]),".tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
    # report file generation
    message(str_c("\nINFO: Data was extracted from .pdf files and stored in .tsv format under: ",file.path(outfolder,"pdf2tsv", paste0(date,"_",basename(files[file]),".tsv"))))
    # add table to file.list
    file.list[[file]] <- final.table.corrected 
  }
  
  # Inform user about pdf to tsv conversion and ask if data looks good to proceed (GUI)
  out <- tk_messageBox(type = "yesnocancel", message = str_c("Note: .pdf to .tsv conversion completed successfully. \n\nPlease check the created .tsv files under:  ",file.path(outfolder,"pdf2tsv"),"\n\nDo they contain the correct information? \n\n(Yes: Analysis will be continued) \n(No: Please adjust .tsv files and restart)")
                       , caption = "Question", default = "")
  
  # if data as not okay or question was canceled stop program 
  if(out != "yes" | is.na(out)){
    stop(str_c("\n INFO: Program was stopped to be restarted with the adjusted .tsv files."))
  } else {
    # report file generation
    message(str_c("\nINFO: Anaylsis was continued with automatically converted pdf2tsv files"))
  }
  
}


## Step 1.3: Read excel files ----
# define form variable
form <- "yes"
# if files are in excel format
if(file_format == "xlsx"){
  file.list <- lapply(files, read.xlsx, sheet = 1, rowNames = TRUE, colNames = TRUE, skipEmptyRows = TRUE, skipEmptyCols = TRUE, na.strings = "NA")  
  
  # Ask user whether input is in Shimatzu format
  form <- tk_messageBox(type = "yesno", message = "Are the selected .xlsx files already in the standard 3 tab format. \n\nYES: Theses are manually curated files of correct format.  \n\nNo: These files are in Shimadzu format and need adjustment."
                       , caption = "Question", default = "")
  
  # check if data format needs correction 
  if(exists("form") & form != "yes"){
    
    ## correction of file.list data in case data is in Shimadzu output format:
    for (file in 1:length(files)){
      df <- file.list[[file]]
      # identify header line
      hline <- which(rownames(df) == "Peak#")
      #adjust column names
      colnames(df) <- df[hline,]
      # remove header lines
      df = df[-(1:hline),]
      #correct column nmaes
      df$RT <- df$Ret.Time
      df$Response <- df$Area
      df$Compound <- df$Name
      #select required data
      subset <- select(df, Compound, RT, Response)
      #correct file.list entry
      file.list[[file]] <- subset
    }
    # report step
    message(str_c("\nINFO: Data was corrected for Shimadzu output format"))
  } else {
    # report step
    message(str_c("\nINFO: Data was NOT corrected for Shimadzu output format"))
  }
}


## Step 1.4: Read csv files ----
if(file_format == "csv"){
  file.list <- lapply(files, read_csv, col_names = TRUE)
}


## Step 1.5: Read tsv or txt files ----   
if(file_format == "tsv" | file_format == "txt"){
  file.list <- lapply(files, read_tsv, na = c("", "NA"), col_names = TRUE)
}

# report step
message(str_c("\nINFO: Sample data was read in successfully"))


### Step 2: Load dry weight data (optional) ----
cat("\n\n=============================\n")
cat("Step 2: Load dry weight data (optional)\n")
cat("=============================\n")


# GUI to allow user to select file contaning weights
filters <- matrix(c("All accepted",".tsv .txt .csv .xlsx", "Tab seperated files",".tsv","Excel files" ,".xlsx","Text files",".txt", "All files", "*"), 5, 2, byrow = TRUE)
dw.file <- tk_choose.files(caption = "File with dry weight data for normalisation", multi = FALSE, filter = filters)

# select action based on user selection
if (identical(dw.file, character(0))){
  message(str_c("\nINFO: No file containing sample weight information was selected. Continued without normalisation!"))
} else {
  # report step
  message(str_c("\nINFO: Loading the following sample info file: ", dw.file))
  # identify file type by extension
  ext <- file_ext(dw.file)
  file_format <- unique(ext)
  # Report error if file format is wrong
  if(!(ext %in% c("xlsx","tsv","csv","txt")) ){
    message(str_c("\nERROR: Incorrect extension of file ",dw.file,". Only files of supported format (.xlsx,.tsv,.csv,.txt). Continued without normalisation."))
  }
  
  
  ## Step 2.2: Read dry weight excel files ----
  if(file_format == "xlsx"){
    dw.file.info <- read.xlsx(dw.file, sheet = 1, colNames = TRUE, skipEmptyRows = TRUE, skipEmptyCols = TRUE, na.strings = "NA")  
  }
  
  
  ## Step 2.3: Read dry weight csv files ----   
  if(file_format == "csv"){
    dw.file.info <- read_csv(dw.file, col_names = TRUE)
  }
  
  
  ## Step 2.4: Read dry weight tsv or txt files ----
  if(file_format == "tsv" | file_format == "txt"){
    dw.file.info <-  read_tsv(dw.file, col_names = TRUE)
  }
  # report step
  message(str_c("\nINFO: Sample info data was read in successfully"))
}


### Step 3: Merge sample information into a matrix (mandatory) ----
cat("\n\n=============================\n")
cat("Step 3: Merge sample information into a matrix (mandatory)\n")
cat("=============================\n")

## Step 3.1: Create matrix by merging files by metabolite names ----

# initialise list to store raw data matrixes in 
GCMS.raw <- vector(mode = 'list', length = length(files)) 
GCMS.raw.RT <- vector(mode = 'list', length = length(files)) 
GCMS.raw.Resp <- vector(mode = 'list', length = length(files)) 
# annotate with file names
names(GCMS.raw) <- basename(files)
# loop over all files
for (file in 1:length(files)){
  # store raw data as list of dataframes
  GCMS.raw[[file]] <- file.list[[file]]
  # create RT dependent in Compound names in case they are NA entries
  for (row in 1:nrow(GCMS.raw[[file]])){
    #check if Compound name is = NA
    if(is.na(GCMS.raw[[file]]$Compound[row])){
      # name as Unknown + retention time
      GCMS.raw[[file]]$Compound[row] <- str_c("Unknown_",as.character(GCMS.raw[[file]]$RT[row]))
    } 
    # check if Compound name is similar / a douplicate
    if(duplicated(GCMS.raw[[file]]$Compound)[row]){
      # add retention time to name
      GCMS.raw[[file]]$Compound[row] <- str_c(GCMS.raw[[file]]$Compound[row]," - RT:",as.character(GCMS.raw[[file]]$RT[row]))
    } 
  }
  # RT and Response as numeric 
  GCMS.raw[[file]]$RT <- as.numeric(GCMS.raw[[file]]$RT)
  GCMS.raw[[file]]$Response <- as.numeric(GCMS.raw[[file]]$Response)
  # store only Compound and RT raw data as list of dataframes
  GCMS.raw.RT[[file]] <- select(GCMS.raw[[file]], Compound, RT)
  # store only Compound and Response raw data as list of dataframes
  GCMS.raw.Resp[[file]] <- select(GCMS.raw[[file]], Compound, Response)
}  

# combine all RT data of all datasets into a single matrix/dataframe
matrix.RT <- reduce(GCMS.raw.RT, full_join, by = "Compound")
# combine all Response data of all datasets into single matrix/dataframe
matrix.Resp <- reduce(GCMS.raw.Resp, full_join, by = "Compound")

# adjust column names
colnames(matrix.RT) <- c("Compound", basename(files))
colnames(matrix.Resp) <- c("Compound", basename(files))

# order dataframes according to Compound names
matrix.RT.ordered <- matrix.RT[order(matrix.RT$Compound),]
matrix.Resp.ordered <- matrix.Resp[order(matrix.Resp$Compound),]

# add mean and sd of retention times 
matrix.RT.ordered$Mean <- rowMeans(matrix.RT.ordered[2:length(matrix.RT.ordered)], na.rm = TRUE)
matrix.RT.ordered$SD <- rowSds(as.matrix(matrix.RT.ordered[2:length(matrix.RT.ordered)]), na.rm = TRUE)

# replace NA values
matrix.Resp.ordered.NA <- matrix.Resp.ordered
matrix.Resp.ordered.NA[is.na(matrix.Resp.ordered.NA)] <- 0

# report step
message(str_c("\nINFO: Merging sample peak data into a matrix completed successfully"))

# Section 3.1 outputs:
#matrix.RT.ordered
#matrix.Resp.ordered
#matrix.Resp.ordered.NA


## Step 3.2: Expand matrix for compounds with different RTs ----

# initialise dataframes
df.RT.ordered <- data.frame()
df.Resp.ordered <- data.frame()

# expand if SD is too large
# loop over all rows
for (i in 1:nrow(matrix.RT.ordered)){
  # if SD is too high look for outliers that where merged
  if (!is.na(matrix.RT.ordered$SD[i]) & matrix.RT.ordered$SD[i]>0.1){
    # create position vector
    pos <- c()
    # find first !NA enry
    NonNAindex <- which(!is.na(matrix.RT.ordered[i,2:(ncol(matrix.RT.ordered)-2)]))
    firstNonNA <- min(NonNAindex)
    # loop over all RTs of samples
    for (j in 2:(ncol(matrix.RT.ordered)-2)){
      # if entry differes to RT of first write into position vector
      if (!is.na(matrix.RT.ordered[i,j]) & abs(matrix.RT.ordered[i,j]-matrix.RT.ordered[i,1+firstNonNA])>0.2){
        pos <- c(pos,j)
      }
    }
    # first copy orignial row
    tempRT.1 <- matrix.RT.ordered[i,]
    tempResp.1 <- matrix.Resp.ordered[i,]
    # use position vector to expand row into several
    for (p in 1:length(pos)){
      #replace outliers with NA
      tempRT.1[1,pos[p]] <- NA
      tempResp.1[1,pos[p]] <- NA
    }
    # add corrected row to new df
    df.RT.ordered <- rbind(df.RT.ordered,tempRT.1)
    df.Resp.ordered <- rbind(df.Resp.ordered,tempResp.1)
    # create new rows for each outlier
    for (p in 1:length(pos)){
      tempRT.2 <- matrix.RT.ordered[i,]
      tempResp.2 <- matrix.Resp.ordered[i,]
      #replace outliers with NA
      tempRT.2[1,-pos[p]] <- NA 
      tempResp.2[1,-pos[p]] <- NA 
      tempRT.2[1,1] <- str_c(matrix.RT.ordered[i,1]," - RT:",matrix.RT.ordered[i,pos[p]])
      tempResp.2[1,1] <- str_c(matrix.Resp.ordered[i,1]," - RT:",matrix.RT.ordered[i,pos[p]])
      df.RT.ordered <- rbind(df.RT.ordered,tempRT.2)
      df.Resp.ordered <- rbind(df.Resp.ordered,tempResp.2)
    }
  # if SD is okay copy row to new dataframes
  } else{
    df.RT.ordered <- rbind(df.RT.ordered,matrix.RT.ordered[i,])
    df.Resp.ordered <- rbind(df.Resp.ordered,matrix.Resp.ordered[i,])
  }
}

# correct mean and sd of Retention times and add to Resp data as well
df.RT.ordered$Mean <- rowMeans(df.RT.ordered[2:(length(df.RT.ordered)-2)], na.rm = TRUE)
df.RT.ordered$SD <- rowSds(as.matrix(df.RT.ordered[2:(length(df.RT.ordered)-2)]), na.rm = TRUE)
df.Resp.ordered$Mean <- df.RT.ordered$Mean
df.Resp.ordered$SD <- df.RT.ordered$SD

# replace NA values
df.Resp.ordered.NA <- df.Resp.ordered
df.Resp.ordered.NA[is.na(df.Resp.ordered.NA)] <- 0

# report step
message(str_c("\nINFO: Merging sample peak data into polished dataframe completed successfully"))

# Section 3.2 outputs:
# df.RT.ordered
# df.Resp.ordered
# df.Resp.ordered.NA


### Step 4: Normalise response data by dry weights (optional) ----
cat("\n\n=============================\n")
cat("Step 4: Normalise response data by dry weights (optional)\n")
cat("=============================\n")

# check if dry weight data exists
if (exists("dw.file.info")){
  # initizalise normalised dataframe
  df.Resp.ordered.norm <- df.Resp.ordered
  # initizalise row count
  row <- 0
  # loop through all entries
  for(c in dw.file.info$Sample){
    row <- row + 1
    # loop through all columns
    for(col in 2:(ncol(df.Resp.ordered)-2)){
      # check if data and column name matches
      if(c == colnames(df.Resp.ordered[col])){
        df.Resp.ordered.norm[col] <- df.Resp.ordered[col] / dw.file.info$DW[row]
      }
    }
  }
  # replace NA values
  df.Resp.ordered.norm.NA <- df.Resp.ordered.norm
  df.Resp.ordered.norm.NA[is.na(df.Resp.ordered.norm.NA)] <- 0
  # report step
  message(str_c("\nINFO: Normalise response data by dry weights completed successfully."))
} else {
  # report step
  message(str_c("\nINFO: Normalise response data by dry weights was excluded due to missing sample info file."))
}

# Section 4 outputs:
# df.Resp.ordered.norm
# df.Resp.ordered.norm.NA


### Step 5: Convert compound names into metabolites (mandatory) ----
cat("\n\n=============================\n")
cat("Step 5: Convert compound names into metabolites (mandatory)\n")
cat("=============================\n")

## Step 5.1: Shorten compound names to potential metabolite names ----
  
# seperate potential metabolite names and RT time for mutiple variants
df.names <- select(df.RT.ordered, Compound) %>%
  separate(Compound, into = c("Name", "RT.variant"), sep="-\\sRT:", remove = FALSE) %>%
  # seperate Name after first comma behind a word
  separate(Name, into = c("Name"), sep=",\\s", remove = TRUE) %>%
  # remove "Methyl" from start of Name
  mutate(Name = str_replace(Name, pattern = "^Methyl", '')) %>%
  mutate(Name = str_replace(Name, pattern = "^methyl", '')) %>%
  # remove space at the start of a Name
  mutate(Name = str_replace(Name, pattern = "^\\s", '')) %>%
  # remove all other characters from start of the name other than numbers or letters
  mutate(Name = str_replace(Name, pattern = "^[^a-z,A-Z,0-9]+", '')) %>%
  # remove space at the end of a Name
  mutate(Name = str_replace(Name, pattern = "\\s$", '')) %>% 
  # remove additional junk by further separating
  separate(Name, into = c("Junk1","Junk2","Junk3","Junk4","Junk5","Name.alt"), sep="_", remove = FALSE) %>%
  # remove brackets
  mutate(Name.alt = str_replace(Name.alt, pattern = "^\\[", '')) %>%
  mutate(Name.alt = str_replace(Name.alt, pattern = "\\]$", '')) %>%
  # remove spaces at the beginning and end of name
  mutate(Name.alt = str_replace(Name.alt, pattern = "^\\s", '')) %>%
  mutate(Name.alt = str_replace(Name.alt, pattern = "\\s$", '')) %>%
  # remove TMS information from name and sotare as new variable
  mutate(Name.alt = str_replace(Name.alt, pattern = "\\s\\([1-9]{1,2}TMS\\).*", '')) %>%
  # replace missing names with NA
  mutate(Name.alt = str_replace(Name.alt, pattern = "\\[NA\\]", "NA")) %>%
  mutate(Name.alt = str_replace(Name.alt, pattern = "^[a-z]{1}$", "NA")) %>%
  mutate(Name.alt = str_replace(Name.alt, pattern = "^[A-Z]{1}$", "NA")) %>%
  mutate(Name.alt = str_replace(Name.alt, pattern = "^$", "NA")) %>%
  # remove {BP} or {BP}1 at the end
  mutate(Name.alt = str_replace(Name.alt, pattern = "\\{BP\\}$", "")) %>%
  mutate(Name.alt = str_replace(Name.alt, pattern = "\\{BP\\}1$", "")) %>%
  # remove everything until after ;
  mutate(Name.alt = str_replace(Name.alt, pattern = "^.+;\\s", "")) %>%
  # remove junk columns
  select(-Junk1,-Junk2,-Junk3,-Junk4,-Junk5)
  
# check if Name.alt exists and is not NA and overwrite existing Name  
for (row in 1:nrow(df.names)){
  if(!is.na(df.names$Name.alt[row])){
    if(df.names$Name.alt[row] != "NA"){
      df.names$Name[row] <- df.names$Name.alt[row]
    }
  }
}
# remove Name.alt column
df.names <- select(df.names, -Name.alt)
# create output dir
dir.create(file.path(outfolder,"compound2metabolite"), showWarnings = FALSE)
# write potential metabolite names in tsv file
write.table(df.names$Name, file.path(outfolder,"compound2metabolite", paste0(date,"_name-list.tsv")), quote = F, col.names = F, row.names = F, sep = '\t', na = "")
# report file generation
message(str_c("\nINFO: Compound names were partically translated to potential metabolite names and list is stored under: ",file.path(outfolder,"compound2metabolite", paste0(date,"_name-list.tsv"))))

  
## Step 5.2: Add metabolite names, KEGG and CAT IDs using the MetaboAnalyst API ----

# automatic processing 
# ATTENTION: This step can take a while ......

if (length(df.names$Name) > 99) {
  
  query_results <- data.frame()
  separations <-ceiling(length(df.names$Name)/100)
  
  for (i in 1:separations) {
    # create name vector and format type
    name.vec <- paste(df.names$Name[round(length(df.names$Name)/separations*(i-1)+1):round(length(df.names$Name)/separations*i)], collapse = ';')
    toSend = list(queryList = name.vec, inputType = "name")
    
    # The MetaboAnalyst API url
    call <- "https://rest.xialab.ca/api/mapcompounds"
    # Use httr::POST to send the request to the MetaboAnalyst API
    query_results_html <- httr::POST(call, body = toSend, encode = "json")

    # Check if server response is ok (TRUE) if not indicate error
    # 200 is ok! 401 means an error has occured on the user's end.
    
    # Define the data
    http_status_codes <- data.frame(
      Code = c(100, 101, 102, 103, 
               200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 
               300, 301, 302, 303, 304, 305, 307, 308, 
               400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424, 425, 426, 428, 429, 431, 451, 
               500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511),
      Description = c(
        "Continue: The initial part of a request has been received and has not yet been rejected by the server.",
        "Switching Protocols: The server is switching protocols as requested by the client.",
        "Processing (WebDAV): The server has received and is processing the request, but no response is available yet.",
        "Early Hints: Used to return some response headers before the final HTTP message.",
        "OK: The request has succeeded.",
        "Created: The request has been fulfilled, and a new resource has been created.",
        "Accepted: The request has been accepted for processing, but the processing is not complete.",
        "Non-Authoritative Information: The server is returning information from a different source.",
        "No Content: The server successfully processed the request, but is not returning any content.",
        "Reset Content: The server successfully processed the request, but asks the client to reset the view.",
        "Partial Content: The server is delivering only part of the resource due to a range header sent by the client.",
        "Multi-Status (WebDAV): Provides status for multiple independent operations.",
        "Already Reported (WebDAV): The members of a DAV binding have already been enumerated.",
        "IM Used: The server has fulfilled a request for the resource using the 'instance-manipulations'.",
        "Multiple Choices: There are multiple options for the resource.",
        "Moved Permanently: The resource has been moved to a new URI permanently.",
        "Found: The resource has been temporarily moved to a different URI.",
        "See Other: The response can be found under a different URI.",
        "Not Modified: The resource has not been modified since the version specified by the request headers.",
        "Use Proxy: The requested resource must be accessed through a proxy.",
        "Temporary Redirect: The request should be repeated with another URI, but future requests can still use the original URI.",
        "Permanent Redirect: The request and all future requests should be repeated using another URI.",
        "Bad Request: The server could not understand the request due to invalid syntax.",
        "Unauthorized: The client must authenticate itself to get the requested response.",
        "Payment Required: Reserved for future use.",
        "Forbidden: The client does not have access rights to the content.",
        "Not Found: The server cannot find the requested resource.",
        "Method Not Allowed: The request method is known by the server but is not supported by the target resource.",
        "Not Acceptable: The server cannot produce a response matching the list of acceptable values.",
        "Proxy Authentication Required: The client must first authenticate itself with the proxy.",
        "Request Timeout: The server timed out waiting for the request.",
        "Conflict: The request conflicts with the current state of the server.",
        "Gone: The resource is no longer available and will not be available again.",
        "Length Required: The server refuses to accept the request without a defined Content-Length.",
        "Precondition Failed: The server does not meet one of the preconditions that the requester put on the request.",
        "Payload Too Large: The request entity is larger than limits defined by the server.",
        "URI Too Long: The URI requested by the client is longer than the server is willing to interpret.",
        "Unsupported Media Type: The media format of the requested data is not supported by the server.",
        "Range Not Satisfiable: The range specified by the Range header field in the request cannot be fulfilled.",
        "Expectation Failed: The expectation given in the request's Expect header could not be met.",
        "I'm a teapot: This code was defined in 1998 as an April Fools' joke and is not expected to be implemented by actual HTTP servers.",
        "Misdirected Request: The request was directed at a server that is not able to produce a response.",
        "Unprocessable Entity (WebDAV): The request was well-formed but was unable to be followed due to semantic errors.",
        "Locked (WebDAV): The resource that is being accessed is locked.",
        "Failed Dependency (WebDAV): The request failed due to failure of a previous request.",
        "Too Early: The server is unwilling to risk processing a request that might be replayed.",
        "Upgrade Required: The client should switch to a different protocol.",
        "Precondition Required: The server requires the request to be conditional.",
        "Too Many Requests: The user has sent too many requests in a given amount of time ('rate limiting').",
        "Request Header Fields Too Large: The server is unwilling to process the request because its header fields are too large.",
        "Unavailable For Legal Reasons: The user requests an illegal resource, such as a web page censored by a government.",
        "Internal Server Error: The server encountered an unexpected condition that prevented it from fulfilling the request.",
        "Not Implemented: The server does not support the functionality required to fulfill the request.",
        "Bad Gateway: The server, while acting as a gateway or proxy, received an invalid response from the upstream server.",
        "Service Unavailable: The server is not ready to handle the request.",
        "Gateway Timeout: The server is acting as a gateway or proxy and did not get a response in time from the upstream server.",
        "HTTP Version Not Supported: The HTTP version used in the request is not supported by the server.",
        "Variant Also Negotiates: The server has an internal configuration error.",
        "Insufficient Storage (WebDAV): The server is unable to store the representation needed to complete the request.",
        "Loop Detected (WebDAV): The server detected an infinite loop while processing a request.",
        "Not Extended: Further extensions to the request are required for the server to fulfill it.",
        "Network Authentication Required: The client needs to authenticate to gain network access."
      )
    )
    
    status_code <- query_results_html$status_code
    subset <- filter(http_status_codes, Code==status_code)
    status_message <-subset$Description[1]
    
    if (!status_code %in% c(200, 0)) {
      stop(paste("Server status code is", status_code,";", status_message))
    } else {
      cat("Server Success: Status code is", status_code, ";", status_message, "\n")
    }
    
    # Parse the response into a table
    query_results_text <- content(query_results_html, "text", encoding = "UTF-8")
    query_results_json <- RJSONIO::fromJSON(query_results_text, flatten = TRUE)

    # replace NULL values with NA
    Query <- unlist(nullToNA(query_results_json[[1]]))
    Match <- unlist(nullToNA(query_results_json[[2]]))
    HMDB <- unlist(nullToNA(query_results_json[[3]]))
    PubChem <- unlist(nullToNA(query_results_json[[4]]))
    ChEBI <- unlist(nullToNA(query_results_json[[5]]))
    KEGG <- unlist(nullToNA(query_results_json[[6]]))
    METLIN <- unlist(nullToNA(query_results_json[[7]]))
    SMILES <- unlist(nullToNA(query_results_json[[8]]))
    query_results_table <- data.frame(Query,Match, HMDB, PubChem, ChEBI ,KEGG, METLIN, SMILES)
    query_results_i <- as_tibble(query_results_table) %>%
      select(-SMILES)%>%
      rename(Name=Query)%>%
      rename(Metabolite=Match)
    query_results <- rbind(query_results, query_results_i)
  }
} else  {
  # create name vector and format type
  name.vec <- paste(df.names$Name, collapse = ';')
  toSend = list(queryList = name.vec, inputType = "name")
  
  # The MetaboAnalyst API url
  call <- "https://rest.xialab.ca/api/mapcompounds"
  # Use httr::POST to send the request to the MetaboAnalyst API
  query_results_html <- httr::POST(call, body = toSend, encode = "json")
  # Check if response is ok (TRUE)
  # 200 is ok! 401 means an error has occured on the user's end.
  query_results_html$status_code==200
  # Parse the response into a table
  query_results_text <- content(query_results_html, "text", encoding = "UTF-8")
  query_results_json <- RJSONIO::fromJSON(query_results_text, flatten = TRUE)
  # replae NULL values with NA
  Query <- unlist(nullToNA(query_results_json[[1]]))
  Match <- unlist(nullToNA(query_results_json[[2]]))
  HMDB <- unlist(nullToNA(query_results_json[[3]]))
  PubChem <- unlist(nullToNA(query_results_json[[4]]))
  ChEBI <- unlist(nullToNA(query_results_json[[5]]))
  KEGG <- unlist(nullToNA(query_results_json[[6]]))
  METLIN <- unlist(nullToNA(query_results_json[[7]]))
  SMILES <- unlist(nullToNA(query_results_json[[8]]))
  query_results_table <- data.frame(Query,Match, HMDB, PubChem, ChEBI ,KEGG, METLIN, SMILES)
  query_results <- as_tibble(query_results_table) %>%
    select(-SMILES)%>%
    rename(Name=Query)%>%
    rename(Metabolite=Match)
}
  
# write name metabolite conversion to file
write.table(query_results, file.path(outfolder,"compound2metabolite", paste0(date,"_name-to-metabolite-conversion.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
# report file generation
message(str_c("\nINFO: Compound names were translated to metabolite names using MetaboAnalysist API and results are stored under: ",file.path(outfolder,"compound2metabolite", paste0(date,"_name-to-metabolite-conversion.tsv"))))

# give summary and ask user
query_results_NA<- filter(query_results, Metabolite =="NA")
nohits<-sum(table(query_results_NA$Metabolite))
htotal<-nrow(query_results)
hits <-htotal-nohits
perc<-round(hits/htotal*100,1)
  
# Inform user about conversion and ask how he wants to proceed
out <- tk_messageBox(type = "yesno", message = str_c("Note: compound to metabolite conversion completed! \n\n",hits," out of ",htotal," (",perc,"%) compounds could automatically be translated into metabolites.\n\nWe recommend to check the conversion and make manual adjustments if required. \n\nDo you want to edit the conversion now?"), caption = "Question", default = "")
  
if(out != "no"){
  
  # open MetaboAnalyst conversion tool
  url <- "https://www.metaboanalyst.ca/MetaboAnalyst/upload/ConvertView.xhtml"
  browseURL(url, browser = getOption("browser"), encodeIfNeeded = FALSE)
  
  # open outfolder
  opendir_1 <- function(dir = file.path(outfolder,"compound2metabolite")){
    if (.Platform['OS.type'] == "windows"){
      shell.exec(dir)
    } else {
      system(paste(Sys.getenv("R_BROWSER"), dir))
    }
  }
  opendir_1()
  
  # open GUI
  out<- tk_messageBox(type = "ok", message = str_c("Please adjust the '<date>_name-to-metabolite-conversion' file.\n\nThe file can be found in the compound2metabolite subfolder of your selected output directory. The first column must not be edited, only the metabolite information should be completed.\n\nTo help translating names to metabolites you can use the Metabolite ID Conversion tool from MetaboAnalyst.\n\nOnce you have completed your edits click 'ok'."))

  # upload optimized name conversion sheet
  if(out == "ok"){
    # GUI to allow user selection
    filters <- matrix(c("All accepted",".tsv .csv","Comma seperated file",".csv","Tab seperated file",".tsv"), 3, 2, byrow = TRUE)
    file <- tk_choose.files(caption = "Choose optimised conversion file", multi = FALSE, filter = filters)
      
    # import file
    # select correct file format
    ext <- file_ext(file)
    file_format <- unique(ext)
      
    # load csv data    
    if(file_format == "csv"){
      query_results_raw<- read_csv(file, na = c("", "NA"), col_names = TRUE)
      query_results<-select(query_results_raw, -Comment)%>%
      rename(Metabolite = Match) %>%
      rename(Name = Query)
    }
      
    # load tsv or txt data    
    if(file_format == "tsv" | file_format == "txt"){
      query_results_raw<- read_tsv(file, na = c("", "NA"), col_names = TRUE)
      query_results<-query_results_raw
    }
    
    # write name metabolite conversion to file
    write.table(query_results, file.path(outfolder,"compound2metabolite", paste0(date,"_name-to-metabolite-conversion_manual.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
  }
  # report step
  message(str_c("\nINFO: Compound to metabolite conversion completed! ",hits," out of ",htotal," (",perc,"%) compounds could automatically be translated into metabolites. Data was further manually edited."))
} 
if(out == "no"){
  # report step
  message(str_c("\nINFO: Compound to metabolite conversion completed! ",hits," out of ",htotal," (",perc,"%) compounds could automatically be translated into metabolites. Data was NOT manually edited."))
}

# Section 5.2 outputs:
# query_results

  
## Step 5.3 Add metabolite info to RT and Resp dataframe ----
df.metabolites <- left_join(df.names, query_results, by = "Name") %>%
  select(Compound, Name, RT.variant, Metabolite, HMDB, KEGG, PubChem, ChEBI, METLIN) %>%
  mutate(Metabolite = str_replace(Metabolite, pattern = "^$", NA_character_)) %>%
  mutate(HMDB = str_replace_na(HMDB, "-")) %>%
  mutate(KEGG = str_replace_na(KEGG, "-")) %>%
  mutate(PubChem = str_replace_na(PubChem, "-")) %>%
  mutate(ChEBI = str_replace_na(ChEBI, "-")) %>%
  mutate(METLIN = str_replace_na(METLIN, "-"))
  
df.RT.ordered.rename <- left_join(df.RT.ordered,df.metabolites, by = "Compound")
# dependent on wheter normalisation was performed or not
if (exists("df.Resp.ordered.norm")){
  df.Resp.ordered.rename <- left_join(df.Resp.ordered.norm,df.metabolites, by = "Compound")
} else {
  df.Resp.ordered.rename <- left_join(df.Resp.ordered,df.metabolites, by = "Compound")
}

# Section 5.3 outputs:
# df.RT.ordered.rename
# df.Resp.ordered.rename
  
  
### Step 6: Sort and condense dataframes (mandatory) ----
cat("\n\n=============================\n")
cat("Step 6: Sort and condense dataframes (mandatory)\n")
cat("=============================\n")  

## Step 6.1: Sort dataframes by RT and names ----
df.RT.ordered.rename.sorted <- arrange(df.RT.ordered.rename , Mean, Name)
df.Resp.ordered.rename.sorted <- arrange(df.Resp.ordered.rename, Mean, Name)
  
# Section 6.1 outputs:
# df.RT.ordered.rename.sorted
# df.Resp.ordered.rename.sorted


## Step 6.2: Fine scale: condense dataframes by merging entries of same compounds with similar RTs ----

# same name same RT (+-0.2)
# initialise dataframe
df.RT.ordered.rename.fine <- data.frame()
df.Resp.ordered.rename.fine <- data.frame()
# create temporary dataframe 
df.RT.ordered.rename.sorted.temp <- df.RT.ordered.rename.sorted
df.Resp.ordered.rename.sorted.temp <- df.Resp.ordered.rename.sorted
# loop over all rows
for (i in nrow(df.RT.ordered.rename.sorted.temp):2){
  # check if Name and RT are not NA
  if (!is.na(df.RT.ordered.rename.sorted.temp$Name[i]) & !is.na(df.RT.ordered.rename.sorted.temp$Name[i-1]) & !is.na(df.RT.ordered.rename.sorted.temp$Mean[i]) & !is.na(df.RT.ordered.rename.sorted.temp$Mean[i-1])){
    # check if Name is similar to the one above and RT not more different than 0.2
    if(abs(df.RT.ordered.rename.sorted.temp$Mean[i]-df.RT.ordered.rename.sorted.temp$Mean[i-1])<=0.2 & df.RT.ordered.rename.sorted.temp$Name[i] == df.RT.ordered.rename.sorted.temp$Name[i-1]){
      # position of non NA values to add
      NonNAindex.RT<- which(!is.na(df.RT.ordered.rename.sorted.temp[i,2:(ncol(df.RT.ordered.rename.sorted.temp)-10)]))
      NonNAindex.Resp<- which(!is.na(df.Resp.ordered.rename.sorted.temp[i,2:(ncol(df.Resp.ordered.rename.sorted.temp)-10)]))
      # loop over all positions and add non NA values to previous row (for RT)
      for (r in 1:length(NonNAindex.RT)){
        if (is.na(df.RT.ordered.rename.sorted.temp[i-1, (NonNAindex.RT[r]+1)])){
          df.RT.ordered.rename.sorted.temp[i-1, (NonNAindex.RT[r]+1)] <- df.RT.ordered.rename.sorted.temp[i, (NonNAindex.RT[r]+1)]
        } else {
          df.RT.ordered.rename.sorted.temp[i-1, (NonNAindex.RT[r]+1)] <- df.RT.ordered.rename.sorted.temp[i, (NonNAindex.RT[r]+1)]
          message(str_c("\nWARNING: for row ",i,": Compound name: ", df.RT.ordered.rename.sorted.temp[i,1]," Some RT values where overwritten during fine scale merging process! Please check intermediate files for details."))
        }
      }
      # loop over all positions and add non NA values to previous row as well as sums (for Resp)
      for (r in 1:length(NonNAindex.Resp)){
        if (is.na(df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)])){
          df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.temp[i, (NonNAindex.Resp[r]+1)]
        } else {
          df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)]+df.Resp.ordered.rename.sorted.temp[i, (NonNAindex.Resp[r]+1)]
          #message(str_c("\nINFO for row ",i,": Compound name: ", df.Resp.ordered.rename.sorted.temp[i,1]," Some Response values where summed up during fine scale merging process! Please check intermediate files for details."))
        }
      }
    } else {
      # add adjusted row to new dataframe
      df.RT.ordered.rename.fine <- rbind(df.RT.ordered.rename.fine, df.RT.ordered.rename.sorted.temp[i,])
      df.Resp.ordered.rename.fine <- rbind(df.Resp.ordered.rename.fine, df.Resp.ordered.rename.sorted.temp[i,])
    }
  } else {
    # add adjusted row to new dataframe
    df.RT.ordered.rename.fine <- rbind(df.RT.ordered.rename.fine, df.RT.ordered.rename.sorted.temp[i,])
    df.Resp.ordered.rename.fine <- rbind(df.Resp.ordered.rename.fine, df.Resp.ordered.rename.sorted.temp[i,])
  }
}
# add first line as well
df.RT.ordered.rename.fine <- rbind(df.RT.ordered.rename.fine,df.RT.ordered.rename.sorted.temp[1,])
df.Resp.ordered.rename.fine <- rbind(df.Resp.ordered.rename.fine, df.Resp.ordered.rename.sorted.temp[1,])
# correct mean and sd of Retention times and add to Resp data as well
df.RT.ordered.rename.fine$Mean <- rowMeans(df.RT.ordered.rename.fine[2:(length(df.RT.ordered.rename.fine)-10)], na.rm = TRUE)
df.RT.ordered.rename.fine$SD <- rowSds(as.matrix(df.RT.ordered.rename.fine[2:(length(df.RT.ordered.rename.fine)-10)]), na.rm = TRUE)
df.Resp.ordered.rename.fine$Mean <- df.RT.ordered.rename.fine$Mean
df.Resp.ordered.rename.fine$SD <- df.RT.ordered.rename.fine$SD
# Sort dataframes by RT and names
df.RT.ordered.rename.fine.sorted <- arrange(df.RT.ordered.rename.fine , Mean, Name)
df.Resp.ordered.rename.fine.sorted <- arrange(df.Resp.ordered.rename.fine , Mean, Name)

# report step
message(str_c("\nINFO: Fine scale condensation of peak data completed successfully"))

# Section 6.2 outputs:
# df.RT.ordered.rename.fine.sorted
# df.Resp.ordered.rename.fine.sorted


## Step 6.3: Coarse scale 1: same metabolite different RT ----

# initialise dataframe
df.RT.ordered.rename.coarse1 <- data.frame()
df.Resp.ordered.rename.coarse1 <- data.frame()
# create temporary dataframe (RT)
df.RT.ordered.rename.sorted.coarse1.temp <- arrange(df.RT.ordered.rename.fine.sorted, Metabolite, Name, Mean)
# change <double> to <character>
df.RT.ordered.rename.sorted.coarse1.temp[,2:(ncol(df.RT.ordered.rename.sorted.coarse1.temp)-10)] <- data.frame(lapply(df.RT.ordered.rename.sorted.coarse1.temp[,2:(ncol(df.RT.ordered.rename.sorted.coarse1.temp)-10)], as.character), stringsAsFactors=FALSE)
# replace NA values by "-"
df.RT.ordered.rename.sorted.coarse1.temp[,2:(ncol(df.RT.ordered.rename.sorted.coarse1.temp)-10)][is.na(df.RT.ordered.rename.sorted.coarse1.temp[,2:(ncol(df.RT.ordered.rename.sorted.coarse1.temp)-10)])] <- ""
# create temporary dataframe (Resp)
df.Resp.ordered.rename.sorted.coarse1.temp <- arrange(df.Resp.ordered.rename.fine.sorted, Metabolite, Name, Mean)
# loop over all rows
for (i in nrow(df.RT.ordered.rename.sorted.coarse1.temp):2){
  # check if Metabolite name and RT are not NA
  if (!is.na(df.RT.ordered.rename.sorted.coarse1.temp$Metabolite[i]) & !is.na(df.RT.ordered.rename.sorted.coarse1.temp$Metabolite[i-1]) & !is.na(df.RT.ordered.rename.sorted.coarse1.temp$Mean[i]) & !is.na(df.RT.ordered.rename.sorted.coarse1.temp$Mean[i-1])){
    # check if Metabolite is similar to the one above
    if(df.RT.ordered.rename.sorted.coarse1.temp$Metabolite[i] == df.RT.ordered.rename.sorted.coarse1.temp$Metabolite[i-1]){
      # all RT values to add
      values.RT<- df.RT.ordered.rename.sorted.coarse1.temp[i,2:(ncol(df.RT.ordered.rename.sorted.coarse1.temp)-10)]
      # position of non NA values to add
      NonNAindex.Resp<- which(!is.na(df.Resp.ordered.rename.sorted.coarse1.temp[i,2:(ncol(df.Resp.ordered.rename.sorted.coarse1.temp)-10)]))
      # loop over all positions and add RT values to previous row (for RT)
      for (r in 1:length(values.RT)){
        df.RT.ordered.rename.sorted.coarse1.temp[i-1,r+1] <- str_c(df.RT.ordered.rename.sorted.coarse1.temp[i-1,r+1],";",df.RT.ordered.rename.sorted.coarse1.temp[i,r+1])
      }
      # loop over all positions and add non NA values to previous row as well as sums (for Resp)
      for (r in 1:length(NonNAindex.Resp)){
        if (is.na(df.Resp.ordered.rename.sorted.coarse1.temp[i-1, (NonNAindex.Resp[r]+1)])){
          df.Resp.ordered.rename.sorted.coarse1.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.coarse1.temp[i, (NonNAindex.Resp[r]+1)]
        } else {
          df.Resp.ordered.rename.sorted.coarse1.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.coarse1.temp[i-1, (NonNAindex.Resp[r]+1)]+df.Resp.ordered.rename.sorted.coarse1.temp[i, (NonNAindex.Resp[r]+1)]
          #message(str_c("\nINFO: for row ",i,": Compound name: ", df.Resp.ordered.rename.sorted.coarse1.temp[i,1]," Some Response values where summed up during coarse1 scale merging process! Please check intermediate files for details."))
        }
      }
    } else {
      # add adjusted row to new dataframe
      df.RT.ordered.rename.coarse1 <- rbind(df.RT.ordered.rename.coarse1, df.RT.ordered.rename.sorted.coarse1.temp[i,])
      df.Resp.ordered.rename.coarse1 <- rbind(df.Resp.ordered.rename.coarse1, df.Resp.ordered.rename.sorted.coarse1.temp[i,])
    }
  } else {
    # add adjusted row to new dataframe
    df.RT.ordered.rename.coarse1 <- rbind(df.RT.ordered.rename.coarse1, df.RT.ordered.rename.sorted.coarse1.temp[i,])
    df.Resp.ordered.rename.coarse1 <- rbind(df.Resp.ordered.rename.coarse1, df.Resp.ordered.rename.sorted.coarse1.temp[i,])
  }
}
# add first line as well
df.RT.ordered.rename.coarse1 <- rbind(df.RT.ordered.rename.coarse1,df.RT.ordered.rename.sorted.coarse1.temp[1,])
df.Resp.ordered.rename.coarse1 <- rbind(df.Resp.ordered.rename.coarse1, df.Resp.ordered.rename.sorted.coarse1.temp[1,])
# separate sample RTs to calculate mean and SD for each row
# loop over all rows
for (i in 1:nrow(df.RT.ordered.rename.coarse1)){
  # initialise row RT array
  row.RT <- c()
  # loop over all samples
  for (j in 2:(length(df.RT.ordered.rename.coarse1)-10)){
    # split entries, write into array and convert to <double>
    row.RT <- c(row.RT,as.double(unlist(strsplit(df.RT.ordered.rename.coarse1[[i,j]], ";"))))
    # correct mean and sd of Retention times and add to Resp data as well
    df.RT.ordered.rename.coarse1$Mean[i] <- mean(row.RT, na.rm = TRUE)
    df.RT.ordered.rename.coarse1$SD[i] <-sd(row.RT, na.rm = TRUE)
    df.Resp.ordered.rename.coarse1$Mean[i] <- mean(row.RT, na.rm = TRUE)
    df.Resp.ordered.rename.coarse1$SD[i] <- sd(row.RT, na.rm = TRUE)
  }
}
# Sort dataframes by RT and names
df.RT.ordered.rename.coarse1.sorted <- arrange(df.RT.ordered.rename.coarse1 , Mean, Name)
df.Resp.ordered.rename.coarse1.sorted <- arrange(df.Resp.ordered.rename.coarse1 , Mean, Name)

# report step
message(str_c("\nINFO: First coarse scale condensation of peak data completed successfully"))

# Section 6.3 outputs:
# df.RT.ordered.rename.coarse1.sorted
# df.Resp.ordered.rename.coarse1.sorted


## Step 6.4: Coarse scale 2:same name different RT ----

# initialise dataframe
df.RT.ordered.rename.coarse2 <- data.frame()
df.Resp.ordered.rename.coarse2 <- data.frame()
# create temporary dataframe (RT)
df.RT.ordered.rename.sorted.coarse2.temp <- arrange(df.RT.ordered.rename.coarse1.sorted, Name)
# create temporary dataframe (Resp)
df.Resp.ordered.rename.sorted.coarse2.temp <- arrange(df.Resp.ordered.rename.coarse1.sorted, Name)
# loop over all rows
for (i in nrow(df.RT.ordered.rename.sorted.coarse2.temp):2){
  # check if Metabolite name is not NA
  if (!is.na(df.RT.ordered.rename.sorted.coarse2.temp$Name[i]) & !is.na(df.RT.ordered.rename.sorted.coarse2.temp$Name[i-1])){
    # check if Name is similar to the one above
    if(df.RT.ordered.rename.sorted.coarse2.temp$Name[i] == df.RT.ordered.rename.sorted.coarse2.temp$Name[i-1]){
      # all RT values to add
      values.RT<- df.RT.ordered.rename.sorted.coarse2.temp[i,2:(ncol(df.RT.ordered.rename.sorted.coarse2.temp)-10)]
      # position of non NA values to add
      NonNAindex.Resp<- which(!is.na(df.Resp.ordered.rename.sorted.coarse2.temp[i,2:(ncol(df.Resp.ordered.rename.sorted.coarse2.temp)-10)]))
      # loop over all positions and add RT values to previous row (for RT)
      for (r in 1:length(values.RT)){
        df.RT.ordered.rename.sorted.coarse2.temp[i-1,r+1] <- str_c(df.RT.ordered.rename.sorted.coarse2.temp[i-1,r+1],";",df.RT.ordered.rename.sorted.coarse2.temp[i,r+1])
      }
      # loop over all positions and add non NA values to previous row as well as sums (for Resp)
      for (r in 1:length(NonNAindex.Resp)){
        if (is.na(df.Resp.ordered.rename.sorted.coarse2.temp[i-1, (NonNAindex.Resp[r]+1)])){
          df.Resp.ordered.rename.sorted.coarse2.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.coarse2.temp[i, (NonNAindex.Resp[r]+1)]
        } else {
          df.Resp.ordered.rename.sorted.coarse2.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.coarse2.temp[i-1, (NonNAindex.Resp[r]+1)]+df.Resp.ordered.rename.sorted.coarse2.temp[i, (NonNAindex.Resp[r]+1)]
          #message(str_c("\nINFO for row ",i,": Compound name: ", df.Resp.ordered.rename.sorted.coarse2.temp[i,1]," Some Response values where summed up during coarse2 scale merging process! Please check intermediate files for details."))
        }
      }
    } else {
      # add adjusted row to new dataframe
      df.RT.ordered.rename.coarse2 <- rbind(df.RT.ordered.rename.coarse2, df.RT.ordered.rename.sorted.coarse2.temp[i,])
      df.Resp.ordered.rename.coarse2 <- rbind(df.Resp.ordered.rename.coarse2, df.Resp.ordered.rename.sorted.coarse2.temp[i,])
    }
  } else {
    # add adjusted row to new dataframe
    df.RT.ordered.rename.coarse2 <- rbind(df.RT.ordered.rename.coarse2, df.RT.ordered.rename.sorted.coarse2.temp[i,])
    df.Resp.ordered.rename.coarse2 <- rbind(df.Resp.ordered.rename.coarse2, df.Resp.ordered.rename.sorted.coarse2.temp[i,])
  }
}
# add first line as well
df.RT.ordered.rename.coarse2 <- rbind(df.RT.ordered.rename.coarse2,df.RT.ordered.rename.sorted.coarse2.temp[1,])
df.Resp.ordered.rename.coarse2 <- rbind(df.Resp.ordered.rename.coarse2, df.Resp.ordered.rename.sorted.coarse2.temp[1,])
# separate sample RTs to calculate mean and SD for each row
# loop over all rows
for (i in 1:nrow(df.RT.ordered.rename.coarse2)){
  # initialise row RT array
  row.RT <- c()
  # loop over all samples
  for (j in 2:(length(df.RT.ordered.rename.coarse2)-10)){
    # split entries, write into array and convert to <double>
    row.RT <- c(row.RT,as.double(unlist(strsplit(df.RT.ordered.rename.coarse2[[i,j]], ";"))))
    # correct mean and sd of Retention times and add to Resp data as well
    df.RT.ordered.rename.coarse2$Mean[i] <- mean(row.RT, na.rm = TRUE)
    df.RT.ordered.rename.coarse2$SD[i] <-sd(row.RT, na.rm = TRUE)
    df.Resp.ordered.rename.coarse2$Mean[i] <- mean(row.RT, na.rm = TRUE)
    df.Resp.ordered.rename.coarse2$SD[i] <- sd(row.RT, na.rm = TRUE)
  }
}
# Sort dataframes by RT and names
df.RT.ordered.rename.coarse2.sorted <- arrange(df.RT.ordered.rename.coarse2 , Mean, Name)
df.Resp.ordered.rename.coarse2.sorted <- arrange(df.Resp.ordered.rename.coarse2 , Mean, Name)
  
# report step
message(str_c("\nINFO: Second coarse scale condensation of peak data completed successfully"))

# Section 6.4 outputs:
# df.RT.ordered.rename.coarse2.sorted
# df.Resp.ordered.rename.coarse2.sorted

  
### Step 7: Plot retention time distributions (optional) ----
cat("\n\n=============================\n")
cat("Step 7: Plot retention time distributions (optional)\n")
cat("=============================\n")    

# create output dir
dir.create(file.path(outfolder,"plots"), showWarnings = FALSE)

## Step 7.1: On Compound level ----

# normalise matrix
# initialise dataframes
matrix.RT.ordered.normalized.mean <- matrix.RT.ordered
matrix.RT.ordered.normalized.mean.sd <- matrix.RT.ordered
# set mean to 0
for (i in 2:(ncol(matrix.RT.ordered)-2)){
  matrix.RT.ordered.normalized.mean[i] <- matrix.RT.ordered[i] - matrix.RT.ordered[(ncol(matrix.RT.ordered)-1)]
}
# normalise sd to 1 if sd is not NA or 0
for (i in 2:(ncol(matrix.RT.ordered)-2)){
  for (j in 1:nrow(matrix.RT.ordered)){
    if(!is.na(matrix.RT.ordered[[j,ncol(matrix.RT.ordered)]])){
      if(matrix.RT.ordered[[j,ncol(matrix.RT.ordered)]] != 0){
        matrix.RT.ordered.normalized.mean.sd[[j,i]] <- matrix.RT.ordered.normalized.mean[[j,i]] / matrix.RT.ordered[[j,ncol(matrix.RT.ordered)]]
      } else {
        matrix.RT.ordered.normalized.mean.sd[[j,i]] <- matrix.RT.ordered.normalized.mean[[j,i]]
      }
    } else {
      matrix.RT.ordered.normalized.mean.sd[[j,i]] <- matrix.RT.ordered.normalized.mean[[j,i]]
    }
  }
}

# prepare data for plotting 
subset <- matrix.RT.ordered.normalized.mean.sd[1:(ncol(matrix.RT.ordered.normalized.mean.sd)-2)]
subset.clean <- gather(subset, key = "Sample", value = "RT", 2:ncol(subset))

# color vector 
qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]
col_vector = unlist(mapply(brewer.pal, qual_col_pals$maxcolors, rownames(qual_col_pals)))
col_vector_3 = c(col_vector,col_vector,col_vector)

# make boxplot (version 1)
ggboxplot(subset.clean, x = "Compound", y = "RT",
          title = "", ylab = "Retention time (normalized)",
          palette = col_vector_3, xlim = c(-3,3),
          rotate = TRUE, 
          add = "jitter", add.params = list(size = 0.3, jitter = 0.2))+
  geom_jitter(aes(colour = Sample), size = 2, jitter = 0.2)

# save plots
ggsave(file.path(outfolder,"plots", str_c(date,"_Retention-time-distribution_v1.pdf")), width = 40, height = 50, units = "cm")
ggsave(file.path(outfolder,"plots", str_c(date,"_Retention-time-distribution_v1.png")), width = 40, height = 50, units = "cm")

# make boxplot (version 2)
ggplot(subset.clean, aes(x=reorder(Compound, RT), y=RT)) +
  geom_boxplot(color = "black",fill="grey",show.legend = FALSE) +
  coord_flip()+
  theme_minimal()+
  theme(axis.ticks = element_blank())+
  xlab("")+
  geom_jitter(aes(colour = Sample), size = 2, jitter = 0.2)

# save plots
ggsave(file.path(outfolder,"plots", str_c(date,"_Retention-time-distribution_v2.pdf")), width = 40, height = 50, units = "cm")
ggsave(file.path(outfolder,"plots", str_c(date,"_Retention-time-distribution_v2.png")), width = 40, height = 50, units = "cm")

# report file generation
message(str_c("\nINFO: Retention time distribution was plotted on compound level and output ist stored under: ",file.path(outfolder,"plots", str_c(date,"_Retention-time-distribution.pdf"))))


## Step 7.2: On metabolite level ----



### Step 8: Export/Save RT and Resp matrix/dataframes (mandatory) ----
cat("\n\n=============================\n")
cat("Step 8: Export/Save RT and Resp matrix/dataframes (mandatory)\n")
cat("=============================\n")  

# create output dir
dir.create(file.path(outfolder,"peak_data"), showWarnings = FALSE) 

# Section 3.1 outputs:
# matrix.RT.ordered
# matrix.Resp.ordered
# matrix.Resp.ordered.NA

# Section 3.2 outputs:
# df.RT.ordered
# df.Resp.ordered
# df.Resp.ordered.NA

# Section 4 outputs:
# df.Resp.ordered.norm
# df.Resp.ordered.norm.NA

# Section 5.2 outputs:
# query_results

# Section 5.3 outputs:
# df.RT.ordered.rename
# df.Resp.ordered.rename

# Section 6.1 outputs:
# df.RT.ordered.rename.sorted
# df.Resp.ordered.rename.sorted

# Section 6.2 outputs:
# df.RT.ordered.rename.fine.sorted
# df.Resp.ordered.rename.fine.sorted

# Section 6.3 outputs:
# df.RT.ordered.rename.coarse1.sorted
# df.Resp.ordered.rename.coarse1.sorted

# Section 6.4 outputs:
# df.RT.ordered.rename.coarse2.sorted
# df.Resp.ordered.rename.coarse2.sorted

# polish dataframes for saving:
df.RT.ordered <- rename(df.RT.ordered, Mean_RT = Mean, SD_RT =SD) %>%
  arrange(Mean_RT, Compound)
df.Resp.ordered <- rename(df.Resp.ordered, Mean_RT = Mean, SD_RT =SD) %>%
  arrange(Mean_RT, Compound)
for (c in 2:length(df.Resp.ordered)){
  df.Resp.ordered[,c][is.na(df.Resp.ordered[,c])] <- 0
}
if (exists("df.Resp.ordered.norm.NA")){
  df.Resp.ordered.norm <- rename(df.Resp.ordered.norm, Mean_RT = Mean, SD_RT =SD) %>%
    arrange(Mean_RT, Compound)
  for (c in 2:length(df.Resp.ordered.norm)){
    df.Resp.ordered.norm[,c][is.na(df.Resp.ordered.norm[,c])] <- 0
  }
}
df.RT.ordered.rename.sorted <- rename(df.RT.ordered.rename.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant)
df.Resp.ordered.rename.sorted <- rename(df.Resp.ordered.rename.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant)
for (c in 2:(length(df.Resp.ordered.rename.sorted)-7)){
  df.Resp.ordered.rename.sorted[,c][is.na(df.Resp.ordered.rename.sorted[,c])] <- 0
}
df.RT.ordered.rename.fine.sorted <- rename(df.RT.ordered.rename.fine.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant, -Compound)
df.Resp.ordered.rename.fine.sorted <- rename(df.Resp.ordered.rename.fine.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant, -Compound)
for (c in 1:(length(df.Resp.ordered.rename.fine.sorted)-7)){
  df.Resp.ordered.rename.fine.sorted[,c][is.na(df.Resp.ordered.rename.fine.sorted[,c])] <- 0
}
df.RT.ordered.rename.coarse1.sorted <- rename(df.RT.ordered.rename.coarse1.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant, -Compound)
df.Resp.ordered.rename.coarse1.sorted <- rename(df.Resp.ordered.rename.coarse1.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant, -Compound)
for (c in 1:(length(df.Resp.ordered.rename.coarse1.sorted)-7)){
  df.Resp.ordered.rename.coarse1.sorted[,c][is.na(df.Resp.ordered.rename.coarse1.sorted[,c])] <- 0
}
df.RT.ordered.rename.coarse2.sorted <- rename(df.RT.ordered.rename.coarse2.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant, -Compound)
df.Resp.ordered.rename.coarse2.sorted <- rename(df.Resp.ordered.rename.coarse2.sorted, Mean_RT = Mean, SD_RT =SD) %>%
  select( -RT.variant, -Compound)
for (c in 1:(length(df.Resp.ordered.rename.coarse2.sorted)-7)){
  df.Resp.ordered.rename.coarse2.sorted[,c][is.na(df.Resp.ordered.rename.coarse2.sorted[,c])] <- 0
}

## Step 8.1: Save RT data in .xlsx file format ----
wb = createWorkbook()
addWorksheet(wb, "RTs.raw")
writeData(wb, sheet = 1, df.RT.ordered)
if (exists("df.Resp.ordered.norm.NA")){
  addWorksheet(wb, "RTs.raw.norm_(temp)")
  writeData(wb, sheet = 2, df.RT.ordered)
  # set sheet number
  s<-3
} else {
  s<-2
}
addWorksheet(wb, "RTs.annotated.sorted")
writeData(wb, sheet = s, df.RT.ordered.rename.sorted)
addWorksheet(wb, "RTs.fine-scale")
writeData(wb, sheet = (s+1), df.RT.ordered.rename.fine.sorted)
addWorksheet(wb, "RTs.coarse-scale1")
writeData(wb, sheet = (s+2), df.RT.ordered.rename.coarse1.sorted)
addWorksheet(wb, "RTs.coarse-scale2")
writeData(wb, sheet = (s+3), df.RT.ordered.rename.coarse2.sorted)
saveWorkbook(wb, file.path(outfolder,"peak_data",paste0(date,"_Metapolish_analysis-results_retention-times_all-files.xlsx")), overwrite = TRUE)


## Step 8.2: Save RT data in .tsv file format ----

# create output dir
dir.create(file.path(outfolder,"peak_data","tsv"), showWarnings = FALSE)

# save main output files in .tsv format
write.table(df.RT.ordered, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_RTs.raw.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.RT.ordered.rename.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_RTs.annotated.sorted.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.RT.ordered.rename.fine.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_RTs.fine-scale.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.RT.ordered.rename.coarse1.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_RTs.coarse-scale1.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.RT.ordered.rename.coarse2.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_RTs.coarse-scale2.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")


## Step 8.3: Save Response data in .xlsx file format ----
wb = createWorkbook()
addWorksheet(wb, "Resp.raw")
writeData(wb, sheet = 1, df.Resp.ordered)
if (exists("df.Resp.ordered.norm")){
  addWorksheet(wb, "Resp.raw.norm_(temp)")
  writeData(wb, sheet = 2, df.Resp.ordered.norm)
  # set sheet number
  s<-3
} else {
  s<-2
}
addWorksheet(wb, "Resp.annotated.sorted")
writeData(wb, sheet = s, df.Resp.ordered.rename.sorted)
addWorksheet(wb, "Resp.fine-scale")
writeData(wb, sheet = (s+1), df.Resp.ordered.rename.fine.sorted)
addWorksheet(wb, "Resp.coarse-scale1")
writeData(wb, sheet = (s+2), df.Resp.ordered.rename.coarse1.sorted)
addWorksheet(wb, "Resp.coarse-scale2")
writeData(wb, sheet = (s+3), df.Resp.ordered.rename.coarse2.sorted)
saveWorkbook(wb, file.path(outfolder,"peak_data",paste0(date,"_Metapolish_analysis-results_response-data_all-files.xlsx")), overwrite = TRUE)


## Step 8.4: Save Response data in .tsv file format ----

# create output dir
dir.create(file.path(outfolder,"peak_data","tsv"), showWarnings = FALSE) 

# save main output files in .tsv format
write.table(df.Resp.ordered, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_Resp.raw.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.Resp.ordered.rename.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_Resp.annotated.sorted.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.Resp.ordered.rename.fine.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_Resp.fine-scale.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.Resp.ordered.rename.coarse1.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_Resp.coarse-scale1.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(df.Resp.ordered.rename.coarse2.sorted, file.path(outfolder,"peak_data","tsv", paste0(date,"_Metapolish_analysis-results_Resp.coarse-scale2.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")

# report output file generation
message(str_c("\nINFO: All Metapolish analysis results were saved under: ",file.path(outfolder,"peak_data")))

# open outfolder
opendir <- function(dir = outfolder){
  if (.Platform['OS.type'] == "windows"){
    shell.exec(dir)
  } else {
    system(paste(Sys.getenv("R_BROWSER"), dir))
  }
}
opendir()

# Work in Progress
# Features for the next version:
#   - Integrate command line operation
#   - Integrate CAS numbers
