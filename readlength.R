
# Metainfo ----------------------------------------------------------------

# @AUTHOR: Chun-Jie Liu
# @CONTACT: chunjie.sam.liu.at.gmail.com
# @DATE: Wed Jul 27 15:37:31 2022
# @DESCRIPTION: filename

# Library -----------------------------------------------------------------

library(magrittr)
library(ggplot2)
library(patchwork)
library(rlang)


# datadir -----------------------------------------------------------------

datadir="/scr1/users/liuc9/bam-qc"

# Function ----------------------------------------------------------------

fn_loaddata <- function(.x) {
  
  
  # .x <- fastqcdatas[[1]]
  
  aname <- strsplit(
    x = .x,
    split = "/"
  )[[1]]
  
  tissue <- aname[[6]]
  samplename <- strsplit(x = aname[[7]], split = "\\.")[[1]][[1]]
  
  d <- readr::read_lines(file = .x, num_threads =2)
  
  start <- which(grepl("#Length\tCount", d)) + 1
  m <- which(grepl(">>END_MODULE", d))
  end <- m[which(m - start > 0)[[1]]] - 1
  
  tibble::tibble(
    a = d[c(start:end)]
  ) %>% 
    tidyr::separate(col = a, into = c("readlength", "count"), sep = "\t") %>% 
    dplyr::mutate_all(.funs = as.numeric) ->
    lengthdist
  lengthdist %>% 
    dplyr::arrange(-count) %>% 
    dplyr::slice(1) %>% 
    dplyr::pull(1) ->
    readlengthmode
    
  
  readlength <- gsub(pattern = "Sequence length\t", replacement = "", x = d[[9]]) 
  
  tibble::tibble(
    tissue = tissue,
    samplename = samplename,
    readlength = readlength,
    readlengthmode = readlengthmode,
    readlengthdist = list(lengthdist)
  )
  
}

fastqcdatas <- list.files(
  path = datadir,
  pattern = "fastqc_data.txt",
  all.files =TRUE,
  full.names = TRUE,
  recursive = TRUE
)

# fastqcdatas %>% 
#   purrr::map(
#     .f = fn_loaddata
#   ) %>% 
#   dplyr::bind_rows() ->
length(fastqcdatas)

parallelMap::parallelStartSocket(25)
parallelMap::parallelLibrary("magrittr")
fastqcdatas_loaded <- parallelMap::parallelMap(fn_loaddata, fastqcdatas)
parallelMap::parallelStop() 

# merge data --------------------------------------------------------------

fastqcdatas_loaded %>% 
  dplyr::bind_rows() ->
  readlength_dist

readlength_dist %>% 
  dplyr::group_by(readlength) %>% 
  dplyr::count()

readlength_dist %>% 
  dplyr::filter(readlengthmode == 101)

readlength_dist %>% 
  dplyr::group_by(readlength) %>% 
  dplyr::count()

readlength_dist %>% 
  dplyr::group_by(readlengthmode) %>% 
  dplyr::count() 

readlength_dist %>% 
  dplyr::group_by(tissue) %>% 
  dplyr::count() %>% 
  dplyr::arrange(-n)


readlength_dist %>% 
  dplyr::select(1, 2, 4) %>% 
  readr::write_tsv(
    file = "/home/liuc9/scratch/bam-qc/gtexv8_rna_seq_readlength.tsv"
  )



# save image --------------------------------------------------------------

save.image(file = "data/readlength.rda")
