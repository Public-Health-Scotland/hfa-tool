# shiny app
shinyServer(function(input, output, session){

# file paths
  if (sessionInfo()$platform %in% c("x86_64-redhat-linux-gnu (64-bit)", "x86_64-pc-linux-gnu (64-bit)")) {  
    data_folder <- "/PHI_conf/ScotPHO/HfA/Data/"
  } else {
    data_folder <- "//stats/ScotPHO/HfA/Data/"
  }

# add UK shapefile
# shapefile_uk = readOGR(dsn=".", layer="infuse_ctry_2011")
# shapefile_uk <- spTransform(shapefile_uk, CRS("+init=epsg:4326"))
# 
# # select scotland only from the UK shape file
# shapefile_scotland <- subset(shapefile_uk,
#                              geo_label == "Scotland")

# lay the two shapefiles into the base map
output$mapfunction <- renderLeaflet({
  leaflet(options = leafletOptions(zoomControl = FALSE,
                                   minZoom = 1,maxZoom = 8)) %>%
    addProviderTiles(providers$CartoDB.Positron) %>% 
    setView(lng=25, lat=54, zoom=3)})

# leafletProxy("mapfunction", data = shapefile_scotland) %>%
#   addPolygons(weight = 1,
#               color = "red")

observeEvent(input$IndicatorMap, {

  
  if ("Select an indicator" %in% input$IndicatorMap){
    leaflet("mapfunction")
  }
  else {
    observeEvent(input$YearMap, {
  
      if("Select a Year" %in% input$YearMap) {
        leaflet("mapfunction")
      } 
      
      else{
        observeEvent(input$SexMap, {
          
          if("Select Sex" %in% input$SexMap) {
            leaflet("mapfunction")
          } 
      
          else {
            
  who_data_map <- who_data %>% 
  filter(ind_name == input$IndicatorMap,
         year == input$YearMap)

# shapefile_europe@data = merge(shapefile_europe@data, who_data_map) 
shapefile_europe <- sp::merge(shapefile_europe, who_data_map, by = "NAME_ENGL") 
  
colourpal <- colorNumeric("GnBu", domain = shapefile_europe@data$value)

labels = paste(
  "<b>", shapefile_europe@data$NAME_ENGL, "</b> <br>", shapefile_europe@data$ind_name, "<br>",
  shapefile_europe@data$value, shapefile_europe@data$measure_type) %>%
  lapply(htmltools::HTML)


leafletProxy("mapfunction", data = shapefile_europe) %>%
 
#leaflet(data = shapefile_europe) %>%
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

                                 
}
    }
) # observeEvent(input$SexMap,

} # observeEvent(input$SexMap,
} # if("Select a Year" %in% input$YearMap
) # observeEvent(input$YearMap, 

} # observeEvent(input$YearMap,
} # if ("Select an indicator" %in% input$IndicatorMap
) # observeEvent(input$IndicatorMap
}) # shiny server function 
