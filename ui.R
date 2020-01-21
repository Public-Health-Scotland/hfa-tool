#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.


###############################################.
## Header ---- 
###############################################.
tagList( #needed for shinyjs
  navbarPage(id = "intabset", #needed for landing page
             title = div(tags$a(img(src="scotpho_reduced.png", height=40), href= "http://www.scotpho.org.uk/"),
                         style = "position: relative; top: -5px;"), # Navigation bar
             windowTitle = "ScotPHO profiles", #title for browser tab
             theme = shinytheme("cerulean"), #Theme of the app (blue navbar)
             collapsible = TRUE, #tab panels collapse into menu in small screens
             header =         
               tags$head( #CSS styles
                 cookie_box, ##Cookie box
                 tags$link(rel="shortcut icon", href="favicon_scotpho.ico"), #Icon for browser tab
                 includeCSS("www/styles.css"), #style sheet with CSS
                 HTML("<base target='_blank'>") # to make external links open a new tab
               ),
     tabPanel("Trend", icon = icon("area-chart"), value = "trend",
              sidebarPanel(width=4,
                           column(6,
                                  actionButton("browser", "Browser"),
                                  actionButton("help_trend",label="Help", icon= icon('question-circle'), class ="down")),
                           column(6,
                                  actionButton("defs_trend", label="Definitions", icon= icon('info'), class ="down")),
                           column(12,
                                  shiny::hr(),
                                  div(title="Select an indicator to see trend information. Click in this box, hit backspace and start to type if you want to quickly find an indicator.",
                                      selectInput("indic_trend", shiny::HTML("<p>Step 1. Select an indicator <br/> <span style='font-weight: 400'>(hit backspace and start typing to search for an indicator)</span></p>"), 
                                                  choices=indicator_list, selected = "Mid-year population, by sex")),
                                  shiny::hr(),
                                  selectizeInput("country_trend", "Step 2. Select the countries you are interested in", 
                                      choices = c("Select country" = "", paste(country_list)),
                                      multiple=TRUE, selected = "United Kingdom"),
                                  selectInput("sex_trend", "Step 3. Select sex", choices=sex_list)
                           )
              ),#sidebar bracket
              mainPanel(width = 8, #Main panel
                        bsModal("mod_defs_trend", "Definitions", "defs_trend", htmlOutput('defs_text_trend')),
                        h4(textOutput("title_trend"), style="color: black; text-align: left"),
                        h5(textOutput("subtitle_trend"), style="color: black; text-align: left"),
                        withSpinner(plotlyOutput("trend_plot"))
              )#mainpanel bracket
     ) #tab panel bracket
  )#navbar Page bracket
)#taglist bracket
  

