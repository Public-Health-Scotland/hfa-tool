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

setwd("/PHI_conf/ScotPHO/1.Analysts_space/Laura/Rpro/hfa_map")

#get the basemap
map_europe <- leaflet() %>% addSearchOSM() %>%
  addProviderTiles(providers$OpenStreetMap.Mapnik) %>% 
  setView(lng=25, lat=54, zoom=2.5)

#view the basemap
map_europe

# shapefile map ---------------------------------------------------------------------
#load map - used http://mapshaper.org/ to make map less detailed
ShapeFile1 = readOGR(dsn=".", layer="CNTR_RG_01M_2016_4326") # opens up the simpleHB layer of the Shapefile
ShapeFile1 <- spTransform(ShapeFile1, CRS("+init=epsg:4326"))
