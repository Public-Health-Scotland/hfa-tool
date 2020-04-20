#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.


# Define server logic required to draw a histogram
function(input, output, session) {
  observeEvent(input$browser, browser())
  
  ###############################################.        
  #### Time trend plot ----
  ###############################################.  
  # Trend help pop-up
  observeEvent(input$help_trend, {
    
    showModal(modalDialog(
      title = "How to use this chart",
      p("The trend chart is designed to explore how a single indicator has changed over time for one or more geograpical area."),
      p(column(7,
               img(src="help_trend_chart2.png")),
        column(5,
               p("First select an indicator using the 'step 1' filter."),
               p("Then add one or more geographical area to the chart using the geography filters in 'Step 2'."),
               p("You can add more than one area or area type (e.g. NHS board or council area) to the trend chart."),
               p("There may be some indicators where data is not available for the full time series or at a particular geography level."),
               p("Use the mouse to hover over a data point to see detailed information on its value, time period and area."),
               p("Confidences intervals (95%) can be added or removed from the chart using the options in 'step 3'. These are shown as shaded areas."),
               p("Confidence intervals give an indication of the precision of a rate or percentage. The width of a confidence interval is related to sample size, smaller geographies like intermediate zones often have wider intervals."),
               p("Display controls in 'Step 3' allow you to switch the graph from a measure (e.g. rate or percentage) to actual numbers (e.g numbers of deaths/hospitalisations)."))),
      size = "l", easyClose = TRUE, fade=FALSE,footer = modalButton("Close (Esc)")))
  }) 
  
  #####################.
  # Reactive controls
  #Controls for chart. Dynamic selection of locality and iz.
  
  
  
  
  ###############################################.
  # Indicator definitions
  defs_data_trend <- reactive({ind_lookup %>% subset(input$indic_trend == ind_name)})
  
  output$defs_text_trend <- renderUI({
    
    HTML(paste(sprintf("<b><u>%s</b></u> <br> %s ", defs_data_trend()$ind_name, 
                       defs_data_trend()$description), collapse = "<br><br>"))
  })
  
  #####################.
  # Reactive data 
  #Time trend data. Filtering based on user input values.
  trend_data <- reactive({ 
    
    who_data %>% 
      subset(country_name %in% input$country_trend  & 
               ind_name == input$indic_trend &
               sex == input$sex_trend) %>% 
      droplevels() %>% 
      arrange(year, ind_name) #Needs to be sorted by year for Plotly
  })
  
  #####################.
  # Creating plot
  #####################.
  # titles 
  output$title_trend <- renderText(paste0(input$indic_trend))
  output$subtitle_trend <- renderText(paste0(unique(trend_data()$measure_type)))                                     
  
  
  #####################.
  #Plot 
  plot_trend_chart <- function() {
    #If no data available for that period then plot message saying data is missing
    # Also if values is all NA
    if (is.data.frame(trend_data()) && nrow(trend_data()) == 0  |
        (all(is.na(trend_data()$value)) == TRUE))
    {
      plot_nodata()
    } else { #If data is available then plot it
      
      #Creating palette of colors: colorblind proof
      #First obtaining length of each geography type, if more than 6, then 6, 
      # this avoids issues. Extra selections will not be plotted
      trend_length <- ifelse(length(input$country_trend) > 12, 12, length(input$country_trend))
      
      # First define the palette of colours used, then set a named vector, so each color
      # gets assigned to an area. I think is based on the order in the dataset, which
      # helps because Scotland is always first so always black.
      trend_palette <- c("#000000", "#a6cee3", "#1f78b4", "#b2df8a", "#33a02c", "#fb9a99",
                         "#e31a1c", "#fdbf6f", "#ff7f00", "#cab2d6", "#6a3d9a", "#b15928")
      
      trend_scale <- c(setNames(trend_palette, unique(trend_data()$country_name)[1:trend_length]))
      trend_col <- trend_scale[1:trend_length]
      
      # Same approach for symbols
      symbols_palette <-  c('circle', 'diamond', 'circle', 'diamond', 'circle', 'diamond',
                            'square','triangle-up', 'square','triangle-up', 'square','triangle-up')
      symbols_scale <- c(setNames(symbols_palette, unique(trend_data()$country_name)[1:trend_length]))
      symbols_trend <- symbols_scale[1:trend_length]
      
      #Text for tooltip
      tooltip_trend <- c(paste0(trend_data()$country_name, "<br>", trend_data()$year,
                                "<br>", paste0(unique(trend_data()$measure_type)),": ", trend_data()$value))
      
      #Creating time trend plot
      trend_plot <- plot_ly(data=trend_data(), x=~year,  y = ~value,
                            color = ~country_name, colors = trend_col, 
                            text=tooltip_trend, hoverinfo="text", height = 600 ) %>% 
        add_trace(type = 'scatter', mode = 'lines+markers', marker = list(size = 8),
                  symbol = ~country_name, symbols = symbols_trend) %>% 
        #Layout 
        layout(annotations = list(), #It needs this because of a buggy behaviour of Plotly
               margin = list(b = 160, t=5), #to avoid labels getting cut out
               yaxis = list(title = unique(trend_data()$measure_type), rangemode="tozero", fixedrange=TRUE,
                            size = 4, titlefont =list(size=14), tickfont =list(size=14)),
               xaxis = list(title = FALSE, tickfont =list(size=14), tickangle = 270, fixedrange=TRUE),
               font = list(family = '"Helvetica Neue", Helvetica, Arial, sans-serif'),
               showlegend = TRUE,
               legend = list(orientation = 'h', x = 0, y = 1.18)) %>%  #legend on top
        config(displayModeBar = FALSE, displaylogo = F) # taking out plotly logo button
      
    }
  }
  # Creating plot for ui side
  output$trend_plot <- renderPlotly({ plot_trend_chart()  }) 
  
  #####################.
  # Downloading data and plot
  #Downloading data
  
  output$download_trend <- downloadHandler(filename =  'timetrend_data.csv',
                                           content = function(file) {write.csv(trend_data(), file, row.names=FALSE)})
  
  # Downloading chart  
  output$download_trendplot <- downloadHandler(
    filename = 'trend.png',
    content = function(file){
      export(p = plot_trend_chart() %>% 
               layout(title = paste0(input$indic_trend), margin = list(t = 140)), 
             file = file, zoom = 3)
    })
  
  ###############################################.        
  #### Mapping ----
  ###############################################.
  
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
        
        #else{
          #observeEvent(input$SexMap, {
            
            #if("Select Sex" %in% input$SexMap) {
              #leaflet("mapfunction")
            #} 
            
            else {
              
              who_data_map <- who_data %>% 
                filter(ind_name == input$IndicatorMap,
                       year == input$YearMap)
              
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
          })
        }
      })
    }
  })
} #server end bracker