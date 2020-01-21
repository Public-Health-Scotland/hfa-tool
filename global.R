

# TODO:
# Trend might need an option to zoom in... many similar countries+long trends make it difficult
# Need definitions
# Need renaming of variables
# See what variables are needed in file
# Incorporate Scotland data
# Do a rank chart for the data
# Do a map for the data (need shapefile)
# Indicators for male and female and then one for all three with options to choose. Need to see how to deal with this
# Similar thing with age cuts, perhaps can have column for age and sex and only enable for those indicators
# Colours change when switching between indicators

############################.
##Packages ----
############################.
library(shiny)
library(shinythemes)
library(shinyBS)
library(shinycssloaders)
library(dplyr)
library(plotly)

############################.
##Data ----
############################.
who_data <- readRDS("data/WHO_HFA_data.rds")
geo_lookup <- readRDS("data/geo_lookup.rds")
ind_lookup <- readRDS("data/indicator_lookup.rds")

indicator_list <- unique(who_data$ind_name)
country_list <- sort(unique(who_data$country_name))
sex_list <- unique(who_data$sex)

##########.
#Cookie warning
cookie_box <- div(class="alert alert-info", style = "margin-bottom: 0",
                  "This website places cookies on your device to help us improve our service 
                  to you. To find out more, see our ",
                  tags$a(href='https://www.scotpho.org.uk/about-us/scotpho-website-policies-and-statements/privacy-and-cookies',
                         " Privacy and Cookies"), "statement.",
                  HTML('<a href="#" class="close" data-dismiss="alert" aria-label="close">&check;</a>'))
############################.
##Functions ----
############################.
#Function to create plot when no data available
plot_nodata <- function(height_plot = 450) {
  text_na <- list(x = 5, y = 5, text = "No data available" , size = 20,
                  xref = "x", yref = "y",  showarrow = FALSE)
  
  plot_ly(height = height_plot) %>%
    layout(annotations = text_na,
           #empty layout
           yaxis = list(showline = FALSE, showticklabels = FALSE, showgrid = FALSE, fixedrange=TRUE),
           xaxis = list(showline = FALSE, showticklabels = FALSE, showgrid = FALSE, fixedrange=TRUE),
           font = list(family = '"Helvetica Neue", Helvetica, Arial, sans-serif')) %>% 
    config( displayModeBar = FALSE) # taking out plotly logo and collaborate button
} 

##END