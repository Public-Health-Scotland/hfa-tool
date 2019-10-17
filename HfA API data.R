#Attempting to read in Health for All dataset from https://gateway.euro.who.int/en/api/
#Importing dataset to csv file



############################.
## Filepaths, packages ----
############################.

library(httr) #to connect to API
library(jsonlite) # to parse data file
library(dplyr)
#Read in Metadata xlsx file
library(readxl)
library(readr)
library(plotly)
library(purrr)

if (sessionInfo()$platform %in% c("x86_64-redhat-linux-gnu (64-bit)", "x86_64-pc-linux-gnu (64-bit)")) {  
  data_folder <- "/PHI_conf/ScotPHO/HfA/HFA2018/Dev_work_tabs/HfA/data/"
  lookups <- "/PHI_conf/ScotPHO/HfA/HFA2018/Dev_work_tabs/HfA/" 
} else {
  data_folder <- "//stats/ScotPHO/HfA/HFA2018/Dev_work_tabs/HfA/data/"
  lookups <- "//stats/ScotPHO/HfA/HFA2018/Dev_work_tabs/HfA/" 
}

###############################################.
## Part 1 - Extracting data from WHO API ----
###############################################.
# Extracting list of indicators available for WHO HFA
url_indicators <- "http://dw.euro.who.int/api/v3/measures?filter=DATA_SOURCE:HFA"
#read data into JSON object
list_indicators <- readLines(url_indicators, encoding="UTF-8", warn=F)
list_indicators <- fromJSON(list_indicators,simplifyDataFrame = TRUE)

write_csv(list_indicators, "indicators_from_WHO_HFA.csv")

#Path of data set measures (including meta data)
url <- "http://dw.euro.who.int/api/v3/data_sets/HFA"
#read data into JSON object
dataset <- readLines(url, encoding="UTF-8", warn=F)
#Convert to R object
dataset_from_api <- fromJSON(dataset,simplifyDataFrame = TRUE)
#View data in R
View(dataset_from_api)

dataset_from_api[["export_url"]]
url_hfa <- "http://dw.euro.who.int/api/v3/export/H2020_1?format=csv"
url_hfa <- "http://dw.euro.who.int/api/v3/measures?filter=DATA_SOURCE:HFA&output=data"
url_hfa <- "http://dw.euro.who.int/api/v3/measures/H2020_1?output=data"
url_hfa <- "http://dw.euro.who.int/api/v3/data_sets/HFA"
url_hfa <- "https://dw.euro.who.int/api/v3/export_data_set/HFA?lang=En"
url_hfa <- "https://dw.euro.who.int/api/v3/export/download/d4b0bda64ffc4a9396d5392a132e0726"
url_hfa <- "https://dw.euro.who.int/api/v3/export_data_set/HFA?measures=HFA_10"

# This one works to get one measure data
url_hfa <- "https://dw.euro.who.int/api/v3/Measures/HFA_11?output=data"

temp <- tempfile()
download.file("https://dw.euro.who.int/api/v3/export/download/d4b0bda64ffc4a9396d5392a132e0726",temp)
unzip(temp)
unlink(temp)

# /api/v3/measures/H2020_1?output=data r
who_hfa <- readLines(url_hfa, encoding="UTF-8") 
who_hfa <- fromJSON(who_hfa,simplifyDataFrame = TRUE)

who_hfa <- read_csv("https://dw.euro.who.int/api/v3/export/H2020_1?lang=En&format=csv")

#Reading in data from API
# Read in one csv file
#Import WHO HfA 2018 file
# url="https://dw.euro.who.int/api/v3/export_data_set/HFA?measures=HFA_10"
# url="https://dw.euro.who.int/api/v3/export_data_set/HFA"
# #returned url="https://dw.euro.who.int/api/v3/export/download/5eaa202561ee4df7ac25ada9ae40c0ad"
# #read data into JSON object
# rd <- readLines(url, encoding="UTF-8", warn=F)
# #Convert to R object
# data_from_api <- fromJSON(rd,simplifyDataFrame = TRUE)
# data_from_api <- data_from_api[["data"]]
# View(data_from_api)


# fname = "//Isdsf00d03/phip/WHO_Health_for_All/HFA2018/Dev_work_tabs/HfA/data/HFA Data (table) part 1.csv"
# hfa_csv = read_csv(fname, col_types = cols(.default = "c"))
# view(hfa_csv)

#Read in WHO data (have downloaded as zip file untill API is allowed through firewall

#Read in all csv files in folder
#File 3 has additional columns "PLACE_RESIDENCE" and "YES_NO"
data_from_api <- map_df(list.files(path = data_folder,
                                   pattern="*.csv", full.names = T), read_csv, col_types = cols(.default = "c"))
saveRDS(data_from_api,"data/HFA2018NonScotNewest.rds")

HfANonScot <- readRDS("data/HFA2018NonScot.rds")

#OPTData <- readRDS("//Isdsf00d03/phip/Projects/Profiles/R Shiny/ScotPHO_profiles/data/optdata.rds")
geo_lookup <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Country groups mapping", col_names = c("code", "WHO_EURO", "EU_MEMBERS", "EU_BEFORE_MAY2004", "EU_AFTER_MAY2004","CIS","CARINFONET","SEEHN","NORDIC", "SMALL"), skip = 1)
saveRDS(geo_lookup, "data/geo_lookup.rds")
#geo_lookup <- readRDS(paste(data_folder,"geo_lookup.rds"))
geo_lookup <- readRDS("data/geo_lookup.rds")

#Read in Metadata file

#Indicator Labels
IndLabels <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Labels", range = "A2:B613")
#%>%
#  mutate(areaname = geo_lookup$areaname geo_ookup$code == code])
IndUnitType <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Labels", range = "A616:B667")
IndClass <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Classifications")
CountryDetails <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Countries")
CountryGrpDetails <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Country groups")

##########################################################################################################

IndDesc <- read_excel((paste(data_folder, "HFA Metadata.xlsx", sep = "")), sheet = "Measure list")

#Works
#IndDesc <- merge(x=IndDesc, y=IndLabels, by.x = "Measure code", by.y = "Code", all.x = TRUE) 

#Can these mutations be run at the same time?
#IndDesc <- IndDesc %>%
#  mutate(Label = IndLabels$Label[IndLabels$Code == IndDesc$"Measure code"]) %>%
#  mutate(IndClass = IndClass$Category[IndClass$"Measure code" == IndDesc$"Measure code"]) %>%
#  mutate(UnitTypeDesc = IndUnitType$Unit[IndUnitType$UNIT_TYPE == IndDesc$UNIT_TYPE])

#IndDesc <- IndDesc %>%
#  mutate(Label = (IndLabels$Label[IndDesc$"Measure code" == IndLabels$"Code"])) #%>%
#  mutate(UnitDesc = (IndUnitType$Unit[IndDesc$"UNIT_TYPE" == IndUnitType$"UNIT_TYPE"]))

#IndDesc <- IndDesc %>%
#  mutate(Label = IndLabels$Label[IndDesc$"Measure code" == IndLabels$"Code"], 
#         UnitDesc = IndUnitType$Unit[IndDesc$"UNIT_TYPE" == IndUnitType$"UNIT_TYPE"])

#Still not working - dplyr > 0.7.2 required?
#IndDesc <- IndDesc %>%
#  mutate(UnitDesc = IndUnitType$Unit[IndDesc$"UNIT_TYPE" == IndUnitType$"UNIT_TYPE"])

#IndDesc <- IndDesc %>%
#  mutate(IndCat = (IndClass$Category[IndDesc$'Measure code' == IndClass$"Measure code"]))

#Works
IndDesc <- merge(x=IndDesc, y=IndClass, by = "Measure code", all.x = TRUE) 
#Drop column "Reference link"
IndDesc$`Reference link` <- NULL
IndDesc <- merge(x=IndDesc, y=IndUnitType, by = "UNIT_TYPE", all.x = TRUE)

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

#WIP

bar_allareas <- filter(HfANonScot, "Measure code" = "HFA_1") 
  group_by(Full_Name)%>%
  mutate(max_year=max(YEAR))
  
  
  plot_ly(x=colnames(data), y=rownames(data), z = data, type = "bar", colors = colorRamp(c("red", "yellow")) )
  bar_test <- HfANonScot %>% 
    subset("Measure code" == "HFA_1") %>% 
    select(c(YEAR, Full_Name, Label)) %>%
    droplevels()
  
  p <- plot_ly(HfANonScot, x = ~Full_Name, y = ~VALUE, type = 'bar', name = 'VALUE') %>%
    layout(yaxis = list(title = 'Count'), barmode = 'group')
  
  ##END