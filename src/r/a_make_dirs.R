
# load all ibraries
x <- c("tidyverse", "sf", "assertthat", "rvest", 'tmap', 'raster', 'ncdf4', 'rasterVis', 'tabularaster')
lapply(x, library, character.only = TRUE, verbose = FALSE)

# load all functions
source('src/functions/helper_functions.R')
source("src/functions/download-data.R")

# key rojections
p4string_ed <- "+proj=eqdc +lat_0=0 +lon_0=0 +lat_1=33 +lat_2=45 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs"   #http://spatialreference.org/ref/esri/102005/
p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"   #http://spatialreference.org/ref/sr-org/6903/

# define the amount of cores st_par runs on
ncore <- parallel::detectCores()

# create main directories
prefix <- ("data")

# create main raw folder and all subfolders to hold raw/unprocessed data
raw_prefix <- file.path(prefix, "raw")
us_prefix <- file.path(raw_prefix, "cb_2016_us_state_20m")
colleges_dir <- file.path(raw_prefix, "colleges")

# Check if directory exists for all variable aggregate outputs, if not then create
var_dir <- list(prefix, raw_prefix, us_prefix, colleges_dir)
lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))
