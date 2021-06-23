#------------------------------------------------------------------------

#                   UI, or "User Interface" Script

# this script designs the layout of everything the user will see in this Shiny App
#------------------------------------------------------------------------


library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(leaflet)
library(dplyr)
library(ggplot2)


# make dashboard header
header <- dashboardHeader(
    title = "Exploring Volcanoes of the World",
    titleWidth = 350 # since we have a long title, we need to extend width element in pixels
)


# create dashboard body - this is the major UI element
body <- dashboardBody(
    tags$style(" body {
    -moz-transform: scale(0.8, 0.8); /* Moz-browsers */
    zoom: 0.8; /* Other non-webkit browsers */
    zoom: 80%; /* Webkit browsers */
}"),

# make first row of elements (actually, this will be the only row)
fluidRow(
    
    # make first column, 25% of page - width = 3 of 12 columns
    column(width = 3,
           
           
           # Box 1: text explaining what this app is
           #-----------------------------------------------
           box( width = NULL,
                status="primary", # this line can change the automatic color of the box. options are "info", "primary","warning","danger', and "success"
                title = NULL,
                # background = "black",
                
                # add some text in bold
                strong("Example Shiny Dashboard for the"  ,
                       a("BIOS2 Program", href="https://bios2.usherbrooke.ca/", target = "_blank"),
                       "training module, \"Creating Shiny Applications in R.\". "),
                
                # linebreak
                br(),
                
                # text in normal
                p("Use the space provided and suggestions in the code to add  an additional widget to the app."),
                
                # linebreak
                
                # text with link to
                p("Created by Jake Lawlor.",  strong(a("See the Code!", href="https://github.com/jakelawlor/Volcano_Shiny_App/",  target = "_blank"))),
                a("See More BIOS2 Trainings Here", href="https://bios2.github.io/",  target = "_blank"),
                
                
                
           ), # end box 1
           
           
           # box 2 : input for selecting volcano type
           #-----------------------------------------------
           box(width = NULL, status = "primary",
               title  = "Selection Criteria", solidHeader = T, 
               
               # Widget specifying the species to be included on the plot
               checkboxGroupButtons(
                   inputId = "volcano_type",
                   label = "Volcano Type",
                   choices = c("Stratovolcano" , "Shield" ,"Cone" ,   "Caldera" ,    "Volcanic Field",
                               "Complex" , "Other",   "Lava Dome"  , "Submarine"    ),
                   checkIcon = list(
                       yes = tags$i(class = "fa fa-check-square", 
                                    style = "color: steelblue"),
                       no = tags$i(class = "fa fa-square-o", 
                                   style = "color: steelblue"))
               ), # end checkboxGroupButtons
               
               
               strong("Space for your additional widget here:"),
               
               br(), br(), br(), br(), br(), # add a bunch of line breaks to leave space. these can be removed
               
               # space for your addition here:
               #-------------------------------------------
               # --- --- --- ---   HINT   --- --- --- --- 
               # here, you will paste code for another Widget to filter volcanoes on the map.
               # you'll need to paste code for some widget, name it, then call it at the top of the server page
               # when we are filtering the selected_volcanoes() reactive object. 
               
               
               # see the columns in the volcanoes dataset, and add a widget to further filter your selected_volcanoes() server object
               #  --- --- --- some suggestions: --- --- ---
               # 1. slider bar to only show volcanoes population_within_30_km > xxxx 
               # 2. slider input to show volcanoes with last_eruption_year > xxxx
               # 3. slider input to only show volcanoes with elevation > xxxx
               # 4. checkbox input to only show volcanoes in  evidence category c("xx", "xx")
               
               # see available widgets here: http://shinyapps.dreamrs.fr/shinyWidgets/
               # and here: https://shiny.rstudio.com/gallery/widget-gallery.html
               
               
           ), # end box 2
           
           
           
           # box 3: ggplot of selected volcanoes by continent
           #------------------------------------------------
           box(width = NULL, status = "primary",
               solidHeader = TRUE, collapsible = T,
               title = "Volcanoes by Continent",
               plotOutput("continentplot", # this calls to object continentplot that is made in the server page
                          height = 325)
           ) # end box 3
           
    ), # end column 1
    
    # second column - 75% of page (9 of 12 columns)
    #--------------------------------------------------
    column(width = 9,
           
           # Box 3: leaflet map
           box(width = NULL, background = "light-blue", 
               leafletOutput("volcanomap", height = 850) 
               # this draws element called volcanomap, which is created in the "server" tab
           ) # end box with map
    ) # end second column
    
) # end fluidrow
) # end body


# compile dashboard elements
dashboardPage(
    skin = "blue",
    header = header,
    sidebar = dashboardSidebar(disable = TRUE), # here, we only have one tab, so we don't need a sidebar
    body = body
)

