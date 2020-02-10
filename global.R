# packages
library(dplyr)
library(tidyr)
library(readxl)
library(janitor)
library(webshot)
library(htmlwidgets)
library(rgdal)
library(leaflet)
library(htmltools)
library(odbc)
library(leaflet.extras)
library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinythemes)
library(jsonlite)

# data
who_data <- readRDS("data/WHO_HFA_data.rds")

#load map - used http://mapshaper.org/ to make map less detailed
shapefile_europe = readOGR(dsn=".", layer="shapefile_europe") # opens up the simpleHB layer of the Shapefile
shapefile_europe <- spTransform(shapefile_europe, CRS("+init=epsg:4326"))

Indicator <- sort(unique(who_data$ind_name))

Year <- sort(unique(who_data$year))

Sex <- sort(unique(who_data$sex))
