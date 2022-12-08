# Extract data and metadata from WHO Europe health for all database and combine
# with Scotland's data prepared in the hfa-indicator-production repository.
# URL WHO health for all: https://dw.euro.who.int/
# Their database is only updated annually/every two years? so no need to run 
# parts 1 ato 3 unless there has been a new release.

# TODO:
# Figure out if there is a better way through the API rather than 
#   downloading and unzipping zip
# What to do with Yes/NO cases, no clear explanation on metadata - This refers to one indicator - inclusion in European health information initiative
# do I need the indicator metadat from the api(update dates)
# What is the data mask column?
# Does the exclusion of urban and rural makes sense
# Probabbly the techdoc with definitions will need to include the caveats for all countries
# which could be shown in a similar way to the ind tech doc of the profiles tool
# Mid year pop by sex needs to eb taken out

# Endocrine, nutritional and metabolic diseases, all ages, per 100 000, by sex (age-standardized death rate)
# needs to be
# Endocrine/nutrition/metabolic disease/disorder involving immune mechanism, all ages, per 100 000, by sex (age-standardized death rate)
# Diabetes, all ages, per 100 000, by sex (age-standardized death rate)
# needs to be
# Diabetes mellitus, all ages, per 100 000, by sex (age-standardized death rate)

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
library(data.table) # for reading csv's efficiently
library(lubridate) # for dates

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
unzip(temp, exdir = paste0(data_folder, "WHO Data/2021/")) #unzip in data folder
unlink(temp) #delete temporary folder

#Finds all the csv files containing data in the right format
files <-  list.files(path = paste0(data_folder, "WHO Data/2021"), pattern = "table", 
                     full.names = TRUE)
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
  
table(who_data$yes_no) # few cases, not sure what to do with them (HFA 633 WHO Member States participating in the European Health Information Initiative (EHII))

###############################################.
## Part 2 - Preparing lookups ----
###############################################.
# Preparing geography lookup 
# Reading country group mappings from metadata file
country_groupings <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                         sheet = "Country groups mapping", skip = 2,
                         col_names = c("short_name", "code", "who_euro", "eu_members", 
                                       "eu_before_may2004", "eu_after_may2004",
                                       "cis","carinfonet","seehn","nordic", 
                                       "small"))
# Read country codes from metadata file
geo_lookup <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                         sheet = "Countries") %>% 
  clean_names #column names in lower case and with underscore

# Merge them together
geo_lookup <- left_join(geo_lookup, country_groupings, by = c("short_name", "code"))

# Formatting 
geo_lookup <- geo_lookup %>% 
  rename(country_code = code, country_name = short_name) %>% 
  select(-c(iso_2:who_code, full_name))

#Scotland geo information
scot_geo <- data.frame(country_code = "SCO", country_name = "Scotland", 
                       who_euro = "yes", eu_members = "yes", eu_before_may2004 = "yes", 
  eu_after_may2004 = NA, cis = NA, carinfonet = NA, seehn = NA, 
  nordic = NA, small = "yes")

#country groupings info
group_geo <- data.frame(country_code = c("WHO_EURO", "NORDIC", "CIS", "EU_MEMBERS", "EU_AFTER_MAY2004", 
                                         "CARINFONET", "EU_BEFORE_MAY2004", "SEEHN", "SMALL"),
                       country_name = c("WHO Europe", "Nordic countries", "CIS", "EU Members",
                                        "EU after May 2004", "CARINFONET", 
                                        "EU before May 2004", "SEEHN", "Small countries"),
                       who_euro = c("yes", rep(NA, 8)), 
                       eu_members = c(rep(NA, 3), "yes", rep(NA, 5)), 
                       eu_before_may2004 = c(rep(NA, 6), "yes", rep(NA, 2)),
                       eu_after_may2004 = c(rep(NA, 4), "yes", rep(NA, 4)), 
                       cis = c(rep(NA, 2), "yes", rep(NA, 6)), 
                       carinfonet = c(rep(NA, 5), "yes", rep(NA, 3)), 
                       seehn = c(rep(NA, 7), "yes", rep(NA, 1)), 
                       nordic = c(rep(NA, 1), "yes", rep(NA, 7)), 
                       small = c(rep(NA, 8), "yes"))


geo_lookup <- rbind(geo_lookup, scot_geo, group_geo)

saveRDS(geo_lookup, paste0(data_folder, "Lookups/geo_lookup.rds"))
saveRDS(geo_lookup,  "data/geo_lookup.rds")

###############################################.
# Preparing indicator lookup 
# Extracting list of indicators available for WHO HFA
url_indicators <- "http://dw.euro.who.int/api/v3/measures?filter=DATA_SOURCE:HFA"
#read data into JSON object
list_indicators <- readLines(url_indicators, encoding="UTF-8", warn=F)
list_indicators <- fromJSON(list_indicators,simplifyDataFrame = TRUE)

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

write_csv(ind_uk, paste0(data_folder, "Lookups/uk_ind_available.csv"))

# combine uk indicators with indicator list

list_indicators <- left_join(list_indicators, ind_uk, by = c("code" = "ind_code"))

write_csv(list_indicators, paste0(data_folder,"Lookups/indicators_from_WHO_HFA.csv"))

#Reading different parts of information about the indicators
indlabels <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                        sheet = "Labels", range = "A2:B620") %>% clean_names()
indunittype <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                          sheet = "Labels", range = "A623:B674") %>% clean_names()
indclass <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                       sheet = "Classifications") %>% clean_names()
indunit <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                      sheet = "Measure list") %>% clean_names()
inddesc <- read_excel(paste0(data_folder, "Lookups/HFA Metadata.xlsx"), 
                      sheet = "Measure notes") %>% 
  clean_names() %>% filter(is.na(country_code)) #only general descriptions/notes

# notes relative to UK, for information mainly
desc_uk <- read_excel(paste0(data_folder, "Lookups/", "HFA Metadata.xlsx"), sheet = "Measure notes") %>% 
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

saveRDS(indicator_lookup, paste0(data_folder, "Lookups/indicator_lookup.rds"))
saveRDS(indicator_lookup, "data/indicator_lookup.rds")

###############################################.
## Part 3 - Merging WHO data with metadata  ----
###############################################.
who_data <- left_join(who_data, geo_lookup, by="country_code")
who_data <- left_join(who_data, indicator_lookup, by="ind_code")

#recode yes_no to value = 1 = yes. value = 2 = no. For HFA 633
who_data <- who_data %>% 
  mutate(value = case_when(yes_no == "YES" ~ 1,
                           yes_no == "NO" ~ 0,
                           T ~ value))

who_data <- who_data %>% # Taking out some columns
  select(-c(country_code, yes_no, who_euro:small))

# Recoding sex
who_data <- who_data %>% mutate(sex = recode(sex, "ALL" = "All", 
                                             "FEMALE" = "Female" ,"MALE" = "Male" ))

# Patterns in titles to change
patterns_change <- c(", per 100 000", " per 100 000",
                     " per 1000 population",
                     ", by sex", ", males", ", females", ", female", 
                     "Age-standardized p", "Crude d")

patterns_sex <- c(", by sex", ", males", ", females", ", female", ",females")

# Cleaning the names and identifying duplicated indicators
# who_data <- who_data %>% 
#   mutate(ind_basename = stri_replace_all_fixed(ind_name, 
#                                                pattern =patterns_change, 
#                                                replacement = c(rep("", 7), "P", "D"), 
#                                                vectorize_all = FALSE),
# ind_basesex = stri_replace_all_fixed(ind_name,
#                                      pattern =patterns_sex,
#                                      replacement = c(rep("", 5)),
#                                      vectorize_all = FALSE))
who_data_unfiltered <- who_data %>% 
  mutate(ind_name = stri_replace_all_fixed(ind_name, 
                                              pattern =patterns_sex,
                                              replacement = c(rep("", 5)),
                                              vectorize_all = FALSE))

# Identifiying indicators by sex which information is already in the overall one
# If they only have one sex and their name has changed is to be excluded.
ind_to_exclude <- who_data %>% select(ind_name, ind_basesex, sex) %>% unique() %>% 
  group_by(ind_name, ind_basesex) %>% count() %>% 
  mutate(changed = case_when(ind_name != ind_basesex ~1 , TRUE ~0),
         to_excl = case_when(changed == 1 & n == 1 ~1, TRUE ~0)) %>% 
  filter(changed == 1 & n == 1) %>% pull(ind_name)

who_data <- who_data %>% filter(!(ind_name %in% ind_to_exclude)) %>%
  select(-ind_basesex, -ind_name) %>% 
  rename(ind_name = ind_basename)

saveRDS(who_data, paste0(data_folder, "WHO Data/2021/WHO_HFA_data.rds"))
saveRDS(who_data_unfiltered, paste0(data_folder, "WHO Data/2021/WHO_HFA_data_unfiltered.rds"))

who_data <- read_rds(paste0(data_folder, "WHO Data/2021/WHO_HFA_data.rds"))
who_data_unfiltered <- read_rds(paste0(data_folder, "WHO Data/2021/WHO_HFA_data_unfiltered.rds"))
###############################################.
## Part 4 - Prepare Scotland data ----
###############################################.
# Creating backup
whoscot_data <- readRDS(paste0(data_folder, "/WHO Data/2019/WHO_Scot_data.rds"))
saveRDS(whoscot_data, paste0(data_folder, "Backups/WHO_Scot_backup_data_", today() ,".rds"))

#Finds all the csv files in the shiny folder
files_scot <-  list.files(path = paste0(data_folder, "Scotland Data"), 
                          pattern = "*.rds", full.names = TRUE)
# To check dates of update of each file and who did it
View(file.info(files_scot,  extra_cols = TRUE))

# reads the data and combines it, variables to lower case and variable with filename
# scot_data <- do.call(rbind, lapply(files_scot, function(x){
#   fread(x)[,file_name:= x] %>% clean_names() })) %>%
#   mutate(file_name = gsub(paste0(data_folder, "Scotland Data/"), "", file_name),
#          country_code = "SCO") %>% 
#   rename(ind_code = ind_id)

scot_data <- do.call(bind_rows, lapply(files_scot, read_rds)) %>% 
  clean_names() %>% 
  rename(ind_code = ind_id) %>% 
  mutate(country_code = "SCO")

# # to check if there is more then one file for the same indicator. This should be empty
# scot_data %>% select(ind_code, file_name) %>% unique %>% group_by(ind_code) %>%
#   add_tally() %>% filter(n >1) %>% View()

# Merge with lookups
indicator_lookup <- readRDS(paste0(data_folder,"Lookups/indicator_lookup.rds"))
geo_lookup <- readRDS(paste0(data_folder, "Lookups/geo_lookup.rds"))

scot_data <- left_join(scot_data, geo_lookup, by = "country_code")
scot_data <- left_join(scot_data, indicator_lookup, by = "ind_code")

scot_data <- scot_data %>% # Taking out some columns
  select(ind_code, sex, year, value, country_name, description, domain, measure_type, ind_name)

scot_indicators <- unique(scot_data$ind_code)

###############################################.
## Merging WHO and Scotland data ----
whoscot_data <- rbind(scot_data, who_data, fill = TRUE)
whoscot_data_unfiltered <- rbind(scot_data, who_data_unfiltered, fill = TRUE)

whoscot_data_scot_indicators <- who_data_unfiltered %>% 
  filter(ind_code %in% scot_indicators) %>% 
  rbind(scot_data)


saveRDS(whoscot_data, paste0(data_folder, "WHO Data/2021/WHO_Scot_data.rds"))
saveRDS(whoscot_data, "data/WHO_Scot_data.rds")  

saveRDS(whoscot_data_unfiltered, paste0(data_folder, "WHO Data/2021/WHO_Scot_data_unfiltered.rds"))
saveRDS(whoscot_data_unfiltered, "data/WHO_Scot_data_unfiltered.rds") 

whoscot_data <- readRDS(paste0(data_folder,"WHO Data/WHO_Scot_data.rds")) 

##END



testing_sex_of_indicators <- who_data_unfiltered %>% 
  filter(ind_code %in% scot_indicators) %>% 
  filter(sex %in% c("Male", "Female"))

indicators_by_sex <- unique(testing_sex_of_indicators$ind_code)

indicators_by_sex
