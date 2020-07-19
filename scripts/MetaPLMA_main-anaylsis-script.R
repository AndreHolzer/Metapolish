# Things to do:
#  - Integrate binning and summary of identical compounds!
#  - Integrate command line operation

# Step 0: Initialise 

#Step 0.1: Load packages

list.of.packages = c("here","tidyverse","knitr","tcltk","readxl","matrixStats","openxlsx","tools","stringr","utils","pdftools","ggplot2","ggpubr","BBmisc","ggsci","scales","RColorBrewer","devtools","RJSONIO","httr")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages) > 0) {install.packages(new.packages)}
lapply(list.of.packages, require, character.only=T)

# # download required packages for MetaboAnalyst
# metanr_packages <- function(){
#   metr_pkgs <- c("impute", "pcaMethods", "globaltest", "GlobalAncova", "Rgraphviz", "preprocessCore", "genefilter", "SSPA", "sva", "limma", "KEGGgraph", "siggenes","BiocParallel", "MSnbase", "multtest","RBGL","edgeR","fgsea","devtools","crmn")
#   list_installed <- installed.packages()
#   new_pkgs <- subset(metr_pkgs, !(metr_pkgs %in% list_installed[, "Package"]))
#   if(length(new_pkgs)!=0){if (!requireNamespace("BiocManager", quietly = TRUE))
#     install.packages("BiocManager")
#     BiocManager::install(new_pkgs)
#     print(c(new_pkgs, " packages added..."))
#   }
#   
#   if((length(new_pkgs)<1)){
#     print("No new packages added...")
#   }
# }
# metanr_packages()
# 
# # Install MetaboAnalystR with documentation
# devtools::install_github("xia-lab/MetaboAnalystR", build = TRUE, build_vignettes = TRUE, build_manual =T)
# # Load the MetaboAnalystR package
# library("MetaboAnalystR")
# 


# Step 0.2: Define global variables 

# Date
date <- format(Sys.Date(), format="%Y-%m-%d")
# GUI to allow user to selection working directory
wd <- tk_choose.dir(here(), caption = "Select your working directory")
setwd(wd)
# Name of the output directory (will be created in your current working directory)
outfolder <- file.path(str_c(date,"_GCSM-analysis-results"))
# create output dir
dir.create(outfolder, showWarnings = TRUE)


# Step 1: Select input files (pdf, excel, tsv or csv files)

# GUI to allow user selection
filters <- matrix(c("All accepted",".pdf .tsv .csv .xlsx .txt", "PDF files",".pdf","Comma seperated files",".csv","Tab seperated files",".tsv","Excel files" ,".xlsx","Text files",".txt", "All files", "*"), 7, 2, byrow = TRUE)
files <- tk_choose.files(caption = "Choose GCMS files to analyse", multi = TRUE, filter = filters)

# identify file type by extension
ext <- file_ext(files)
file_format <- unique(ext)

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

# define form variable
form <- "yes"

## Step 1.1: read pdf and convert to tsv
if(file_format == "pdf"){
  
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
        
        # create output dir
        dir.create(file.path(outfolder,"pdf2tsv"))
        
        # save extracted data from pdf file as .tsv file
        write.table(final.table, file.path(outfolder,"pdf2tsv", paste0(date,"_",basename(files[file]),".tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
        
      }
    }
    
    # concatenate tables from different files into list format
    file.list <- c()
    file.list[[file]] <- final.table 
    
  }
  
  # Inform user about pdf to tsv conversion and ask if data looks good to proceed (GUI)
  out <- tk_messageBox(type = "yesnocancel", message = "Note: .pdf to .tsv conversion completed successfully. \n\nPlease check the created .tsv files. \n\nDo they contain the correct information? \n\n(Yes: Analysis will be continued) \n(No: Please adjust .tsv files and restart)"
                       , caption = "Question", default = "")
  
  ## Alternative: Inform user about pdf to tsv conversion and ask if data looks good to proceed (R terminal)
  #out <- if (interactive()){
  #  askYesNo("Note: .pdf to .tsv conversion completed successfully. Please check the created .tsv files. \nQuestion: Do they contain the correct information? \n          (Yes: .tsv files will be used automatically for further analysis)\n          (no: Please adjust .tsv files and restart program using the adjusted files) ")
  #}
  
  # if data as not okay or question was canceled stop program 
  if(out != TRUE | is.na(out)){
    stop(str_c("Program was stopped to be restarted with the adjusted .tsv files."))
  }
}

## Step 1.2: read excel and convert to csv
if(file_format == "xlsx"){
  file.list <- lapply(files, read.xlsx, sheet = 1, rowNames = TRUE, colNames = TRUE, skipEmptyRows = TRUE, skipEmptyCols = TRUE, na.strings = "NA")  
  
  # Ask user whether input is in Shimatzu format
  form <- tk_messageBox(type = "yesno", message = "Are the selected .xlsx files already in the standard 3 tab format. \n\nYES: Theses are manually curated files of correct format.  \n\nNo: These files are in Shimadzu format and need adjustment."
                       , caption = "Question", default = "")
}

## Step 1.3: load csv data    
if(file_format == "csv"){
  file.list <- lapply(files, read_csv, col_names = TRUE)
}

## Step 1.4: load tsv or txt data    
if(file_format == "tsv" | file_format == "txt"){
  file.list <- lapply(files, read_tsv, na = c("", "NA"), col_names = TRUE)
}

# check if data format needs correction 
if(exists("form") & form != "yes"){
  
  ## correction of file.list data in case data is in Shimadzu ourput format:
  for (file in 1:length(files)){
    df <- file.list[[file]]
    #adjust column names
    colnames(df) <- df[7,]
    # remove header lines
    df = df[-(1:7),]
    #correct column nmaes
    df$RT <- df$Ret.Time
    df$Response <- df$Area
    df$Compound <- df$Name
    #select required data
    subset <- select(df, Compound, RT, Response)
    #correct fil.list entry
    file.list[[file]] <- subset
  }
}


# Step 2: Load dry weight data (if existing)  

# GUI to allow user to select file contaning weights
filters <- matrix(c("All accepted",".tsv .txt .csv .xlsx", "Tab seperated files",".tsv","Excel files" ,".xlsx","Text files",".txt", "All files", "*"), 5, 2, byrow = TRUE)
dw.file <- tk_choose.files(caption = "File with dry weight data for normalisation", multi = FALSE, filter = filters)

# select action based on user selection
if (identical(dw.file, character(0))){
  message(str_c("No file containing sample weight information was selected. Continued without normalisation!"))
} else {
  
  # identify file type by extension
  ext <- file_ext(dw.file)
  file_format <- unique(ext)
  
  # Report error if file format is wrong
  if(!(ext %in% c("xlsx","tsv","csv","txt")) ){
    message(str_c("Incorrect extension of file ",dw.file,". Only files of supported format (.xlsx,.tsv,.csv,.txt). Continued without normalisation."))
  }
  
  ## Step 2.2: read excel and convert to csv
  if(file_format == "xlsx"){
    dw.file.info <- read.xlsx(dw.file, sheet = 1, colNames = TRUE, skipEmptyRows = TRUE, skipEmptyCols = TRUE, na.strings = "NA")  
  }
  
  ## Step 2.3: load csv data    
  if(file_format == "csv"){
    dw.file.info <- read_csv(dw.file, col_names = TRUE)
  }
  
  ## Step 2.4: load tsv or txt data    
  if(file_format == "tsv" | file_format == "txt"){
    dw.file.info <-  read_tsv(dw.file, col_names = TRUE)
  }
  
}


# Step 3: combine information into a dataframe

# initialise list to store raw data matrixes in 
GCMS.raw <- vector(mode = 'list', length = length(files)) 
GCMS.raw.RT <- vector(mode = 'list', length = length(files)) 
GCMS.raw.Resp <- vector(mode = 'list', length = length(files)) 
# annotate with file names
names(GCMS.raw) <- basename(files)

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
    # check if Compound name is similar a douplicate
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

# combine all RT data of all datasets into a single dataframe
matrix.RT <- reduce(GCMS.raw.RT, full_join, by = "Compound")
# combine all Response data of all datasets into single dataframe
matrix.Resp <- reduce(GCMS.raw.Resp, full_join, by = "Compound")

# adjust column names
colnames(matrix.RT) <- c("Compound", basename(files))
colnames(matrix.Resp) <- c("Compound", basename(files))

# order dataframes according to Compound names
matrix.RT.ordered <- matrix.RT[order(matrix.RT$Compound),]
matrix.Resp.ordered <- matrix.Resp[order(matrix.Resp$Compound),]

# add mean and sd of Retention times 
matrix.RT.ordered$Mean <- rowMeans(matrix.RT.ordered[2:length(matrix.RT.ordered)], na.rm = TRUE)
matrix.RT.ordered$SD <- rowSds(as.matrix(matrix.RT.ordered[2:length(matrix.RT.ordered)]), na.rm = TRUE)

## replace NA values
#matrix.RT.ordered[is.na(matrix.RT.ordered)] <- ''
#matrix.Resp.ordered[is.na(matrix.Resp.ordered)] <- ''

# replace NA values
matrix.Resp.ordered.NA <- matrix.Resp.ordered
matrix.Resp.ordered.NA[is.na(matrix.Resp.ordered.NA)] <- 0

# initialise dataframes
df.RT.ordered <- data.frame()
df.Resp.ordered <- data.frame()

# expand if SD is too large
# loop over all rows
for (i in 1:nrow(matrix.RT.ordered)){
  # if SD is too high look for outliers that where merged
  if (!is.na(matrix.RT.ordered$SD[i]) & matrix.RT.ordered$SD[i]>0.05){
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
      tempResp.2[1,1] <- str_c(matrix.Resp.ordered[i,1]," - RT:",matrix.Resp.ordered[i,pos[p]])
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


# Step 4: normalise response data by dry weights

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
  
  df.Resp.ordered.rename <- df.Resp.ordered.norm
} else {
  df.Resp.ordered.rename <- df.Resp.ordered
}


# Step 5: Convert Compound names into metabolites

  ## Step 5.1: Shorten Compound names to potential metabolite names
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
  dir.create(file.path(outfolder,"compound2metabolite"))
  # write potential metabolite names in tsv file
  write.table(df.names$Name, file.path(outfolder,"compound2metabolite", paste0(date,"_name-list.tsv")), quote = F, col.names = F, row.names = F, sep = '\t', na = "")
  
  # Step 5.2: Add KEGG and CAT IDs using the MetaboAnalyst API

  # automatic processing 
  # create name vector and format type
  name.vec <- paste(df.names$Name, collapse = ';')
  toSend = list(queryList = name.vec, inputType = "name")
  
  # The MetaboAnalyst API url
  call <- "http://api.xialab.ca/mapcompounds"
  # Use httr::POST to send the request to the MetaboAnalyst API
  query_results <- httr::POST(call, body = toSend, encode = "json")
  # Check if response is ok (TRUE)
  # 200 is ok! 401 means an error has occured on the user's end.
  query_results$status_code==200
  # Parse the response into a table
  query_results_text <- content(query_results, "text", encoding = "UTF-8")
  query_results_json <- RJSONIO::fromJSON(query_results_text, flatten = TRUE)
  query_results_table <- t(rbind.data.frame(query_results_json))
  rownames(query_results_table) <- query_results_table[,1]
  query_results <- as_tibble(query_results_table) %>%
    select(-smiles)%>%
    rename(Name=query)%>%
    rename(Metabolite=hit)%>%
    rename(HMDB=hmdb_id)%>%
    rename(PubChem=pubchem_id)%>%
    rename(ChEBI=chebi_id)%>%
    rename(KEGG=kegg_id)%>%
    rename(METLIN=metlin_id)
  
  # write name metabolite conversion to file
  write.table(query_results, file.path(outfolder,"compound2metabolite", paste0(date,"_name-to-metabolite-conversion.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
  
  # give summary and ask user
  hits<-table(query_results$Metabolite)[1]
  total<-nrow(query_results)
  perc<-round(table(query_results$Metabolite)[1]/nrow(query_results)*100,1)
  
  # Inform user about conversion and ask how he wants to proceed
  out <- tk_messageBox(type = "yesno", message = str_c("Note: compound to metabolite conversion completed! \n\n",hits," out of ",total," (",perc,"%) compounds could automatically be translated into metabolites.\n\nWe recommend to check the conversion and make manual adjustments if required. \n\nDo you want to edit the conversion now?")
                         , caption = "Question", default = "")
  
  if(out != "no"){
    url <- "https://www.metaboanalyst.ca/MetaboAnalyst/upload/ConvertView.xhtml"
    browseURL(url, browser = getOption("browser"), encodeIfNeeded = FALSE)
    out<- tk_messageBox(type = "ok", message = str_c("Please edit the <DATE>_name-list.tsv file manually and upload it here.\n\n The file can be found in the compound2metabolite subfolder of your output directory. Once submitted you can make some adjustements within MetaboAnalysit. Once you are done please make sure you download the file again and confirm with the ok button"))
  
    # upload optimized name conversion sheet
    if(out == "ok"){
      # GUI to allow user selection
      filters <- matrix(c("All accepted",".tsv .csv","Comma seperated files",".csv","Tab seperated files",".tsv"), 3, 2, byrow = TRUE)
      file <- tk_choose.files(caption = "Choose optimised ID conversion files", multi = FALSE, filter = filters)
      
      # import file
      # select correct file format
      ext <- file_ext(files)
      file_format <- unique(ext)
      
      ## load csv data    
      if(file_format == "csv"){
        query_results_raw<- read_csv(file, na = c("", "NA"), col_names = TRUE)
      }
      
      ## load tsv or txt data    
      if(file_format == "tsv" | file_format == "txt"){
        query_results_raw<- read_tsv(file, na = c("", "NA"), col_names = TRUE)
      }
      
      query_results<-select(query_results_raw, -SMILES, -Comment)%>%
        rename(Metabolite = Match) %>%
        rename(Name = Query)
    }
  }
  
  # Step 5.3 Add metabolite info to RT and Resp dataframe
  df.metabolites <- left_join(df.names, query_results, by = "Name") %>%
    mutate(Metabolite = str_replace(Metabolite, pattern = "^$", NA_character_)) %>%
    mutate(HMDB = str_replace_na(HMDB, "-")) %>%
    mutate(KEGG = str_replace_na(KEGG, "-")) %>%
    mutate(PubChem = str_replace_na(PubChem, "-")) %>%
    mutate(ChEBI = str_replace_na(ChEBI, "-")) %>%
    mutate(METLIN = str_replace_na(METLIN, "-"))
  
  df.RT.ordered.rename <- left_join(df.RT.ordered,df.metabolites, by = "Compound")
  df.Resp.ordered.rename <- left_join(df.Resp.ordered,df.metabolites, by = "Compound")
  
  
# Step 6: Sort and condense dataframes
  
  # Step 6.1: Sort dataframes by RT and names
  df.RT.ordered.rename.sorted <- arrange(df.RT.ordered.rename , Mean, Name)
  df.Resp.ordered.rename.sorted <- arrange(df.Resp.ordered.rename, Mean, Name)
  
  # Step 6.2: Condense dataframes by merging entries of same compounds with similar RTs (Fine scale)
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
            message(str_c("WARNING for row ",i,": Compound name: ", df.RT.ordered.rename.sorted.temp[i,1]," Some RT values where overwritten during fine scale merging process! Please check intermediate files for details."))
          }
        }
        # loop over all positions and add non NA values to previous row as well as sums (for Resp)
        for (r in 1:length(NonNAindex.Resp)){
          if (is.na(df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)])){
            df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.temp[i, (NonNAindex.Resp[r]+1)]
          } else {
            df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)]+df.Resp.ordered.rename.sorted.temp[i, (NonNAindex.Resp[r]+1)]
            message(str_c("WARNING for row ",i,": Compound name: ", df.Resp.ordered.rename.sorted.temp[i,1]," Some Response values where summed up during fine scale merging process! Please check intermediate files for details."))
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
  # Sort dataframes by RT and names
  df.RT.ordered.rename.fine.sorted <- arrange(df.RT.ordered.rename.fine , Mean, Name)
  df.Resp.ordered.rename.fine.sorted <- arrange(df.Resp.ordered.rename.fine , Mean, Name)
  # correct mean and sd of Retention times and add to Resp data as well
  df.RT.ordered.rename.fine.sorted$Mean <- rowMeans(df.RT.ordered.rename.fine.sorted[2:(length(df.RT.ordered.rename.fine.sorted)-10)], na.rm = TRUE)
  df.RT.ordered.rename.fine.sorted$SD <- rowSds(as.matrix(df.RT.ordered.rename.fine.sorted[2:(length(df.RT.ordered.rename.fine.sorted)-10)]), na.rm = TRUE)
  df.Resp.ordered.rename.fine.sorted$Mean <- df.RT.ordered.rename.fine.sorted$Mean
  df.Resp.ordered.rename.fine.sorted$SD <- df.RT.ordered.rename.fine.sorted$SD
  
  # same name/metabolite different RT (coarse scale)
  # initialise dataframe
  df.RT.ordered.rename.coarse <- data.frame()
  df.Resp.ordered.rename.coarse <- data.frame()
  # create temporary dataframe 
  df.RT.ordered.rename.sorted.coarse.temp <- arrange(df.RT.ordered.rename.fine.sorted, Name, Metabolite, Mean)
  df.Resp.ordered.rename.sorted.coarse.temp <- arrange(df.Resp.ordered.rename.fine.sorted, Name, Metabolite, Mean)
  
  df.Resp.ordered.rename.coarse.name <- df.Resp.ordered.rename.sorted.coarse.temp %>% 
    group_by(Name) %>%
    summarise_at(vars(2:(ncol(df.Resp.ordered.rename.sorted.coarse.temp)-10)), sum, na.rm = TRUE)
  
  df.RT.mean <- df.RT.ordered.rename.sorted.coarse.temp %>% 
    group_by(Name) %>%
    summarise_at(vars(Mean), mean, na.rm = TRUE)
  
  df.RT.sd.new <- df.RT.ordered.rename.sorted.coarse.temp %>% 
    group_by(Name) %>%
    summarise_at(vars(Mean), sd, na.rm = TRUE)
  
  df.RT.sd.old <- df.RT.ordered.rename.sorted.coarse.temp %>% 
    group_by(Name) %>%
    summarise_at(vars(SD), sum, na.rm = TRUE)
  
  summarise_all(funs(trimws(paste(., collapse = '; '))))
  summarise_at(c("Mean"), mean, na.rm = TRUE)
  
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
            message(str_c("WARNING for row ",i,": Compound name: ", df.RT.ordered.rename.sorted.temp[i,1]," Some RT values where overwritten during fine scale merging process! Please check intermediate files for details."))
          }
        }
        # loop over all positions and add non NA values to previous row as well as sums (for Resp)
        for (r in 1:length(NonNAindex.Resp)){
          if (is.na(df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)])){
            df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.temp[i, (NonNAindex.Resp[r]+1)]
          } else {
            df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)] <- df.Resp.ordered.rename.sorted.temp[i-1, (NonNAindex.Resp[r]+1)]+df.Resp.ordered.rename.sorted.temp[i, (NonNAindex.Resp[r]+1)]
            message(str_c("WARNING for row ",i,": Compound name: ", df.Resp.ordered.rename.sorted.temp[i,1]," Some Response values where summed up during fine scale merging process! Please check intermediate files for details."))
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
  
#########
  
# Step 7: Plot data 
  
# create output dir
dir.create(file.path(outfolder,"plots"))

# Step 7.1: Plot Distribution of Retention times (on Compound level)

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

# Step 7.2: Plot Distribution of Retention times (on Metabolite level)



# Step 8: Save/Export data  

# create output dir
dir.create(file.path(outfolder,"results"))  

#Step 8.1: replace NA values
matrix.Resp.ordered.rename.sorted.NA <- matrix.Resp.ordered.rename.sorted
matrix.Resp.ordered.rename.sorted.NA[is.na(matrix.Resp.ordered.rename.sorted.NA)] <- '0'

#Step 8.2: Save as .tsv files
write.table(matrix.RT.ordered, file.path(outfolder,"results",paste0(date,"_GCMS_Retention-Times.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
write.table(matrix.Resp.ordered, file.path(outfolder,"results",paste0(date,"_GCMS_Responses.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
if (exists("matrix.Resp.ordered.norm")){
  write.table(matrix.Resp.ordered.norm, file.path(outfolder,"results",paste0(date,"_GCMS_Responses_normalised.tsv")), quote = F, col.names = T, row.names = F, sep = '\t', na = "")
}

#Step 8.3: Save as .xlsx file
wb = createWorkbook()
addWorksheet(wb, "Responses")
addWorksheet(wb, "Responses.NA")
addWorksheet(wb, "Retention_times")
writeData(wb, sheet = 1, matrix.Resp.ordered)
writeData(wb, sheet = 2, matrix.Resp.ordered.NA)
writeData(wb, sheet = 3, matrix.RT.ordered)
if (exists("matrix.Resp.ordered.norm")){
  addWorksheet(wb, "Responses_normalised")
  writeData(wb, sheet = 4, matrix.Resp.ordered.norm)
  addWorksheet(wb, "Responses_normalised.NA")
  writeData(wb, sheet = 5, matrix.Resp.ordered.norm.NA)
  addWorksheet(wb, "Retention_times.renamed")
  writeData(wb, sheet = 6, matrix.RT.ordered.rename.sorted)
  addWorksheet(wb, "Responses_normalised.renamed")
  writeData(wb, sheet = 7, matrix.Resp.ordered.rename.sorted)
  addWorksheet(wb, "Responses_normalised.renamed")
  writeData(wb, sheet = 8, matrix.Resp.ordered.rename.sorted.NA)
} else {
  addWorksheet(wb, "Retention_times.renamed")
  writeData(wb, sheet = 4, matrix.RT.ordered.rename.sorted)
  addWorksheet(wb, "Responses.renamed")
  writeData(wb, sheet = 5, matrix.Resp.ordered.rename.sorted)
  addWorksheet(wb, "Responses_normalised.renamed")
  writeData(wb, sheet = 6, matrix.Resp.ordered.rename.sorted.NA)
}
saveWorkbook(wb, file.path(outfolder,"results",paste0(date,"_GCMS_analysis-results.xlsx")), overwrite = TRUE)



################ Work in Progress ######################
#
# # add CAS
# # initialise CAS column 
# query_results$CAS <- ''
# # loop through all names
# for (i in 1:nrow(query_results)){
#   # create https link variable 
#   link <- str_c("https://cts.fiehnlab.ucdavis.edu/rest/convert/Chemical%20Name/CAS/",query_results$Name[i])
#   # online Chemical name to CAS conversion
#   cas.result<-try(system(paste("curl -k ",link), intern = TRUE, ignore.stderr = TRUE))
#   # check if results where returned
#   if (identical(cas.result, character(0))){
#     
#   }
#   cas.raw<-strsplit(cas.result, ",")[[1]][4]
#   cas<-strsplit(cas.raw, "\"")[[1]][4]
#   query_results$CAS[i] <- cas 
# }