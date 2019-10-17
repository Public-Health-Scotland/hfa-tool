# Read in Health for All dataset from https://gateway.euro.who.int/en/api/

# TODO:
# Figure out if there is a better way through the API rather than 
#   downloading and unzipping zip
# What to do with Yes/NO cases, no clear explanation on metadata
# move filepaths so things get saved in the hfa data folder and not in the project

############################.
## Filepaths, packages ----
############################.

library(httr) #to connect to API
library(jsonlite) # to parse data file
library(dplyr) #data manipulation
library(readr) #csv writing/reading
library(janitor) #cleaning column names
library(readxl) #Read excel files


if (sessionInfo()$platform %in% c("x86_64-redhat-linux-gnu (64-bit)", "x86_64-pc-linux-gnu (64-bit)")) {  
  data_folder <- "/PHI_conf/ScotPHO/HfA/data/"
  lookups <- "/PHI_conf/ScotPHO/HfA/HFA2018/Dev_work_tabs/HfA/" 
} else {
  data_folder <- "//stats/ScotPHO/HfA/data/"
  lookups <- "//stats/ScotPHO/HfA/HFA2018/Dev_work_tabs/HfA/" 
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
unzip(temp, exdir = "./data/") #unzip in data folder
unlink(temp) #delete temporary folder

#Finds all the csv files in the shiny folder
files <-  list.files(path = "./data", pattern = "table", full.names = TRUE)
# To check dates of update of each file and who did it
View(file.info(files,  extra_cols = TRUE))

# reads the data and combines it
#File 3 has additional columns "PLACE_RESIDENCE" and "YES_NO"
who_data <- do.call(bind_rows, lapply(files, read_csv, col_types = cols(.default = "c"))) %>% 
  setNames(tolower(names(.))) %>% #names to lower case
  # Excluding urban and rural cuts
  filter(!(place_residence %in% c("RURAL", "URBAN"))) %>% 
  mutate_at(c("year", "value"), as.numeric) %>% 
  select(-place_residence)
  
table(who_data$yes_no) # few cases, not sure what to do with them

###############################################.
# Preparing geography lookup 

# Reading country group mappings from metadata file
country_groupings <- read_excel("data/HFA Metadata.xlsx", 
                         sheet = "Country groups mapping", skip = 2,
                         col_names = c("short_name", "code", "who_euro", "eu_members", 
                                       "eu_before_may2004", "eu_after_may2004",
                                       "cis","carinfonet","seehn","nordic", 
                                       "small"))
# Read country codes from metadata file
geo_lookup <- read_excel("data/HFA Metadata.xlsx", sheet = "Countries") %>% 
  clean_names #column names in lower case and with underscore

# Merge them together
geo_lookup <- left_join(geo_lookup, country_groupings, by = c("short_name", "code"))

saveRDS(geo_lookup, "data/geo_lookup.rds")
geo_lookup <- readRDS("data/geo_lookup.rds")

###############################################.
# Preparing indicator lookup 
# Extracting list of indicators available for WHO HFA
url_indicators <- "http://dw.euro.who.int/api/v3/measures?filter=DATA_SOURCE:HFA"
#read data into JSON object
list_indicators <- readLines(url_indicators, encoding="UTF-8", warn=F)
list_indicators <- fromJSON(list_indicators,simplifyDataFrame = TRUE)

write_csv(list_indicators, "data/indicators_from_WHO_HFA.csv")


#Read in Metadata file

#Indicator Labels
indlabels <- read_excel("data/HFA Metadata.xlsx", sheet = "Labels", range = "A2:B613") %>% clean_names()
indunittype <- read_excel("data/HFA Metadata.xlsx", sheet = "Labels", range = "A616:B667")  %>% clean_names()
indclass <- read_excel("data/HFA Metadata.xlsx", sheet = "Classifications") %>% clean_names()
inddesc <- read_excel("data/HFA Metadata.xlsx", sheet = "Measure list") %>% clean_names()


indicator_lookup <- left_join(indlabels, inddesc, by = c("code" = "measure_code"))
indicator_lookup <- left_join(indicator_lookup, indclass, by = c("code" = "measure_code"))
indicator_lookup <- left_join(indicator_lookup, indunittype, by =  "unit_type")

# Merge with data from API?

saveRDS(ind_lookup, "data/indicator_lookup.rds")

##########################################################################################################


#HfANonScot <- merge(x=HfANonScot, y=CountryDetails, by.x = "COUNTRY_REGION",  by.y = "Code", all.x = TRUE)


#Merging Country Details to Non-Scot data

#Selecting only the columns to be matched on
CountryDetails <- CountryDetails %>%
  select("Code", "Short_Name" = `Short name`, "Full_Name" = `Full name`)

HfANonScot <- left_join(HfANonScot, CountryDetails, by = c("COUNTRY_REGION" = "Code"))
#HfANonScot <- HfANonScot %>%
#  mutate(CountryFullName = CountryDetails$"Full name"[CountryDetails$"Code" == HfANonScot$COUNTRY_REGION])

HfANonScot <-  mutate (HfANonScot, IsCtryGrp = (HfANonScot$COUNTRY_REGION %in% c("WHO_EURO","EU_MEMBERS","EU_BEFORE_MAY2004","EU_AFTER_MAY2004","CIS","CARINFONET","SEEHN","NORDIC","SMALL")))

#To Do - Country group is an array by Country and 9 groups
    #Merging Country Group Details to Non-Scot data
    #Selecting only the columns to be matched on
    CountryGrpDetails <- CountryGrpDetails %>%
       select("Code", "CountryGrpShrtName" = `Short name`, "CountryGrpFullName" = `Full name`)
     
     HfANonScot <- left_join(HfANonScot, CountryGrpDetails, by = c("COUNTRY_REGION" = "Code"))


#Merging Indicator details to Non-Scot data

#Should only join on "Measure code"
HfANonScot <- left_join(HfANonScot, IndDesc)



saveRDS(HfANonScot,"data/HFA2018NonScotJoined")


  
  ##END