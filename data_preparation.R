# Extract data and metadata from WHO Europe health for all database
# https://dw.euro.who.int/

# TODO:
# Figure out if there is a better way through the API rather than 
#   downloading and unzipping zip
# What to do with Yes/NO cases, no clear explanation on metadata
# move filepaths so things get saved in the hfa data folder and not in the project
# do I need the indicator metadat from the api(update dates)
# What is the data mask column?
# Does the exclusion of urban and rural makes sense
# Probabbly the techdoc with definitions will need to include the caveats for all countries
# which could be shown in a similar way to the ind tech doc of the profiles tool

############################.
## Filepaths, packages ----
############################.
library(httr) #to connect to API
library(jsonlite) # to parse data file
library(dplyr) #data manipulation
library(readr) #csv writing/reading
library(janitor) #cleaning column names
library(readxl) #Read excel files
library(stringi) #for string manipulation

if (sessionInfo()$platform %in% c("x86_64-redhat-linux-gnu (64-bit)", "x86_64-pc-linux-gnu (64-bit)")) {  
  data_folder <- "/PHI_conf/ScotPHO/HfA/Data/"
} else {
  data_folder <- "//stats/ScotPHO/HfA/Data/"
}

###############################################.
## Part 1 - Extracting data from WHO API ----
###############################################.
# Download data for WHO HFA 
#This provides metadata on the dataset including download lin
url_hfa_meta <- "http://dw.euro.who.int/api/v3/export_data_set/HFA"

#Read metadata
who_hfa_metadata <- readLines(url_hfa_meta, encoding="UTF-8") %>% 
  fromJSON(., simplifyDataFrame = TRUE)

# This is the url needed for the next step
url_hfa <- who_hfa_metadata[["download_url"]]

# Download zip file with all data and unzip
temp <- tempfile() #create temporary folder
download.file(url_hfa, temp)
unzip(temp, exdir = data_folder) #unzip in data folder
unlink(temp) #delete temporary folder

#Finds all the csv files containing data in the right format
files <-  list.files(path = data_folder, pattern = "table", full.names = TRUE)
# To check files on folder
View(file.info(files,  extra_cols = TRUE))

# reads the data and combines it
#File 3 has additional columns "PLACE_RESIDENCE" and "YES_NO"
who_data <- do.call(bind_rows, lapply(files, read_csv, col_types = cols(.default = "c"))) %>% 
  clean_names() %>% #names to lower case
  # Excluding urban and rural cuts
  filter(!(place_residence %in% c("RURAL", "URBAN"))) %>% 
  mutate_at(c("year", "value"), as.numeric) %>% 
  select(-place_residence) %>% 
  rename(ind_code =measure_code, country_code = country_region)
  
table(who_data$yes_no) # few cases, not sure what to do with them

###############################################.
# Check what indicators available for UK 
ind_uk <- who_data %>% 
  mutate(gbr = case_when(country_code == "GBR" ~ 1,
                         TRUE ~ 0)) %>% 
  select(ind_code, gbr) %>% unique() %>% 
  group_by(ind_code) %>% 
  summarise(gbr = max(gbr)) %>% 
  mutate(index = as.numeric(substr(ind_code,5, 8)),
         gbr = recode(gbr, "1" = "Yes", "0" = "No")) %>% 
  arrange(index)

write_csv(ind_uk, paste0(data_folder, "uk_ind_available.csv"))

###############################################.
# Preparing geography lookup 
# Reading country group mappings from metadata file
country_groupings <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), 
                         sheet = "Country groups mapping", skip = 2,
                         col_names = c("short_name", "code", "who_euro", "eu_members", 
                                       "eu_before_may2004", "eu_after_may2004",
                                       "cis","carinfonet","seehn","nordic", 
                                       "small"))
# Read country codes from metadata file
geo_lookup <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Countries") %>% 
  clean_names #column names in lower case and with underscore

# Merge them together
geo_lookup <- left_join(geo_lookup, country_groupings, by = c("short_name", "code"))

# Formatting 
geo_lookup <- geo_lookup %>% 
  rename(country_code = code, country_name = short_name) %>% 
  select(-c(iso_2:who_code, full_name))

saveRDS(geo_lookup, paste0(data_folder, "geo_lookup.rds"))
saveRDS(geo_lookup, "data/geo_lookup.rds")
geo_lookup <- readRDS(paste0(data_folder, "geo_lookup.rds"))

###############################################.
# Preparing indicator lookup 
# Extracting list of indicators available for WHO HFA
url_indicators <- "http://dw.euro.who.int/api/v3/measures?filter=DATA_SOURCE:HFA"
#read data into JSON object
list_indicators <- readLines(url_indicators, encoding="UTF-8", warn=F)
list_indicators <- fromJSON(list_indicators,simplifyDataFrame = TRUE)

list_indicators <- left_join(list_indicators, ind_uk, by = c("code" = "measure_code"))

write_csv(list_indicators, paste0(data_folder,"indicators_from_WHO_HFA.csv"))

#Reading different parts of information about the indicators
indlabels <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Labels", range = "A2:B613") %>% clean_names()
indunittype <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Labels", range = "A616:B667") %>% clean_names()
indclass <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Classifications") %>% clean_names()
indunit <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Measure list") %>% clean_names()
inddesc <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Measure notes") %>% 
  clean_names() %>% filter(is.na(country_code)) #only general descriptions/notes

# notes relative to UK, for information mainly
desc_uk <- read_excel(paste0(data_folder, "HFA Metadata.xlsx"), sheet = "Measure notes") %>% 
  clean_names() %>% filter(country_code == "GBR") #only general descriptions/notes

# Merging together to produce indicator lookup
indicator_lookup <- left_join(indlabels, inddesc, by = c("code" = "measure_code"))
indicator_lookup <- left_join(indicator_lookup, indunit, by = c("code" = "measure_code"))
indicator_lookup <- left_join(indicator_lookup, indclass, by = c("code" = "measure_code"))
indicator_lookup <- left_join(indicator_lookup, indunittype, by =  "unit_type")

# Formatting
indicator_lookup <- indicator_lookup %>% 
  rename(ind_name =label, description = note, domain = category, 
         measure_type = unit, ind_code = code) %>% 
  select(ind_code, ind_name, description, domain, measure_type)

saveRDS(indicator_lookup, paste0(data_folder, "indicator_lookup.rds"))
saveRDS(indicator_lookup, "data/indicator_lookup.rds")

indicator_lookup <- readRDS(paste0(data_folder,"indicator_lookup.rds"))

###############################################.
# Merging WHO data with metadata 
who_data <- left_join(who_data, geo_lookup, by="country_code")
who_data <- left_join(who_data, indicator_lookup, by="ind_code")

who_data <- who_data %>% # Taking out some columns
  select(-c(ind_code, country_code, yes_no, who_euro:small, description, domain))
  
saveRDS(who_data, paste0(data_folder, "WHO_HFA_data.rds"))
saveRDS(who_data, "data/WHO_HFA_data.rds")

who_data <- readRDS(paste0(data_folder,"WHO_HFA_data.rds"))

who_data2 <- who_data %>% 
  mutate(ind_name2= grepl(", by sex", ind_name, fixed=TRUE))


patterns_change <- c(" (age-standardized death rate)", ", per 100 000", " per 100 000",
                     " per 1000 population",
                     ", by sex", ", males", ", females", ", female", 
                     "Age-standardized p", "Crude d")


who_data3 <- who_data %>% 
  mutate(ind_basename = stri_replace_all_fixed(ind_name, 
                                              pattern =patterns_change, 
                                               replacement = c(rep("", 8), "P", "D"), 
                                              vectorize_all = FALSE),
         test =  case_when(ind_name != ind_basename ~ T,
                           TRUE ~ F))

who_data3 <- who_data3 %>% 
  filter(test == T)

# The idea is that these indicators we could select only the overall ones, but some exceptions
# filter by Endocrine/nutrition/metabolic disease to see problems
# also External causes of injury and poisoning, 
test <- who_data3 %>% select(ind_name, ind_basename, sex) %>% unique() %>% 
  group_by(ind_name, ind_basename) %>% count()

###############################################.
## Scotland data ----
###############################################.

scot_data <- read_excel(paste0(data_folder, "HFA19UK_Scotland_completed.xlsx"), 
                        sheet = "HFA19GB_Scotland", range = "A2:AZ164") %>% clean_names()

# This is the data for Scotland received from ONS
scot_data <- scot_data %>% filter(!(is.na(x2017)) | !(is.na(x2018))) %>% 
  select(indicator_title, pop_group, x2017, x2018)


  ##END