who_data <- readRDS("data/WHO_HFA_data.rds") %>%
  na.omit()
# filter the data at this level before merging to the shapefile

saveRDS(who_data, "data/WHO_HFA_data.rds")


# 
# 
# shapefile map ---------------------------------------------------------------------
# #load map - used http://mapshaper.org/ to make map less detailed
# shapefile_europe = readOGR(dsn=".", layer="CNTR_RG_01M_2016_4326") # opens up the simpleHB layer of the Shapefile
# shapefile_europe <- spTransform(shapefile_europe, CRS("+init=epsg:4326"))

# # select the WHO europe region countries from the shapefile (without UK)
# shapefile_europe <- subset(shapefile_europe, 
#                            NAME_ENGL %in% c("Albania", "Andorra", "Armenia", "Austria", "Azerbaijan", 
#                                             "Belarus", "Belgium", "Bosnia and Herzegovina",
#                                             "Bulgaria", "Croatia", "Cyprus", "Czechia", "Denmark", 
#                                             "Estonia", "Finland", "France", "Georgia", "Germany", "Greece", 
#                                             "Hungary", "Iceland", "Ireland", "Israel", "Italy", "Kazakhstan", 
#                                             "Kyrgyzstan", "Latvia", "Lithuania", "Luxembourg", "Malta", "Monaco", 
#                                             "Montenegro", "Netherlands", "North Macedonia", "Norway", "Poland", 
#                                             "Portugal", "Moldova", "Romania", "Russian Federation", "San Marino", "Serbia", 
#                                             "Slovakia", "Slovenia", "Spain", "Sweden", "Switzerland", "Tajikistan", 
#                                             "Turkey", "Turkmenistan", "Ukraine", "United Kingdom", "Uzbekistan", "Ireland"))
# 

#writeOGR(shapefile_europe,".", "shapefile_europe", driver="ESRI Shapefile")
shapefile_europe = readOGR(dsn=".", layer="shapefile_europe") # opens up the simpleHB layer of the Shapefile
shapefile_europe <- spTransform(shapefile_europe, CRS("+init=epsg:4326"))

#colourpal <- colorNumeric("GnBu", domain = shapefile_europe@data$value)

labels = paste(
  "<b>", shapefile_europe@data$NAME_ENGL, "</b> <br>", shapefile_europe@data$ind_name, "<br>",
  shapefile_europe@data$value, shapefile_europe@data$measure_type) %>%
  lapply(htmltools::HTML)

leaflet(data = shapefile_europe) %>%
  addPolygons(weight = 1,
              fillColor = ~colourpal(value),
              opacity = 1,
              color = "white",
              highlight = highlightOptions(weight = 5,
                                           color = "#666",
                                           bringToFront = TRUE),
              label = labels,
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto"))

