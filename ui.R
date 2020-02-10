shinyUI(
  fluidPage(theme = shinytheme("lumen"),
            shinyjs::useShinyjs(),
            
            tabPanel("Populate a Map",
                     id="map",
                     icon = icon("globe"),
                     
                     # Map tab -----------------------------------------------------------------
                             
                              # Filter for indicator
                              column(9,
                                     div(title="Select a health indicator",
                                         p(tags$b("indicator selection")),
                                         id='IndicatorMap',
                                         selectInput(inputId = "IndicatorMap",
                                                     label= NULL,
                                                     choices =  c("Select an indicator", unique(Indicator))#,
                                                     #selectize = TRUE,
                                                     #selected = "NULL"
                                         ))),
                     
                     #filter for year
                     column(3,
                            div(title="Select a year",
                                p(tags$b("year selection")),
                                id='YearMap',
                                selectInput(inputId = "YearMap",
                                            label= NULL,
                                            choices =  c("Select a Year", unique(Year))#,
                                            #selectize = TRUE,
                                            #selected = "NULL"
                                ))),
                     
                     
                     column(3,
                            div(title="Select sex",
                                p(tags$b("sex selection")),
                                id='SexMap',
                                selectInput(inputId = "SexMap",
                                            label= NULL,
                                            choices =  c("Select Sex", unique(Sex))#,
                                            #selectize = TRUE,
                                            #selected = "NULL"
                                ))),
                              
                     
                  
                              
          
                     # This is the actual map. Produced in Server.R
                     mainPanel(width = 12,
                               leafletOutput(outputId = "mapfunction", height = 500)
                               
                     )) # end of tab
  )
)

