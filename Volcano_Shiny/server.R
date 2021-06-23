#------------------------------------------------------------------------
#                       ---- Server Script ----
#  this script runs all internal operations to make your shiny app work
#------------------------------------------------------------------------


# Load packages
library(dplyr)
library(stringr)
library(countrycode)
library(here)



function(input, output, session) {
  
  # Import and clean data  ----------------------------------------
  # this dataset comes from the May 12, 2020 TidyTuesday dataset, "eruptions"
  # here, we upload data from the TidyTuesday repo and slightly manipulate it
  # to give us some variable options to play with. 
  volcano <-
    
    # read data from tidytuesday repo
    readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-05-12/volcano.csv')  %>%

    # select columns of interest
    select(volcano_name, 
           primary_volcano_type,
           last_eruption_year, 
           country,
           latitude,
           longitude,
           elevation,
           evidence_category,
           population_within_5_km,
           population_within_10_km,
           population_within_30_km,
           population_within_100_km
    ) %>%
    
    # change last eruption year to numeric
    mutate(last_eruption_year = as.numeric(last_eruption_year),
           
           # consolidate volcano types, as they are spelled many ways in the original dataset (i.e. "Stratovolcano" vs "Strato-volcano")
           volcano_type_consolidated = case_when(grepl("Caldera",primary_volcano_type) ~ "Caldera",
                                                 grepl("strato",str_to_lower(primary_volcano_type)) ~ "Stratovolcano",
                                                 grepl("shield",str_to_lower(primary_volcano_type)) ~ "Shield",
                                                 grepl("cone",str_to_lower(primary_volcano_type)) ~ "Cone",
                                                 grepl("volcanic field",str_to_lower(primary_volcano_type)) ~ "Volcanic Field",
                                                 grepl("complex",str_to_lower(primary_volcano_type)) ~ "Complex",
                                                 grepl("lava dome",str_to_lower(primary_volcano_type)) ~ "Lava Dome",
                                                 grepl("submarine",str_to_lower(primary_volcano_type)) ~ "Submarine",
                                                 TRUE ~  "Other"))   %>%
    
    # add a continent column
    # some countries have two values, like "Chile-Argentina" - here, we will just take the first, separated by "-"
    mutate(country2 = str_extract(country,"[^-]+")) %>% 
    
    # create a continent column using `countrycode` package
    mutate(continent = countrycode(sourcevar = country2,
                                   origin = "country.name",
                                   destination = "continent",
                                   custom_match = c(`Antarctica` = "Antarctica",
                                                    `Undersea Features` = "Under Sea")
    ))  %>%
    
    # change continent into factor (this helps keep order consistent)
    mutate(  continent  = factor(continent, levels = c("Americas","Asia","Europe","Oceania","Africa","Antarctica","Under Sea")))
  #------------ end data cleaning -----------------
  
  
  
  
  # Create Reactive Subset ------------------------------------------------ 
  # Make a subset of the data as a reactive value
  # this subset pulls volcano rows only in the selected types of volcano from the UI checkbox
  selected_volcanoes <- reactive({
    
    # start with full dataset
    volcano %>% 
      
      # select only volcanoes in the selected volcano type (from checkboxes in the UI)
      filter(volcano_type_consolidated %in% input$volcano_type) %>%
      
      # Space to add your suggested filer here!! 
      # --- --- --- --- --- --- --- --- --- --- --- --- ---
      # filter() %>%
      # --- --- --- --- --- --- --- --- --- --- --- --- ---
      
      # change volcano type into factor (this makes plotting it more consistent re order of colors)
      mutate(volcano_type_consolidated = factor(volcano_type_consolidated,
                                                levels =  unique(volcano$volcano_type_consolidated) ) )
  })
  
 
  
  # make output element for continents barplot 
  #------------------------------------------------------------
  output$continentplot <- renderPlot({
    
    # create basic barplot
    barplot <- ggplot(data = volcano,
                      aes(x=continent,
                          fill = volcano_type_consolidated))+
      # update theme and axis labels:
      theme_bw()+
      theme(plot.background = element_rect(color="transparent",fill = "transparent"),
            panel.background = element_rect(color="transparent",fill="transparent"),
            panel.border = element_rect(color="transparent",fill="transparent"))+
      labs(x=NULL, y=NULL, title = NULL) +
      theme(axis.text.x = element_text(angle=45,hjust=1, size = 10))
    
    
    # IF a selected_volcanoes() object exists, update the blank ggplot. 
    # basically this makes it not mess up when nothing is selected
    if(nrow(selected_volcanoes()) >=1){ 
      
      # add bars to barplot
      barplot <- barplot +
        geom_bar(data = selected_volcanoes(), show.legend = F) +
        scale_fill_manual(values = RColorBrewer::brewer.pal(9,"Set1"), 
                          drop=F) +
        scale_x_discrete(drop=F)
      
    } # end if statement
    
    # print the plot
    barplot
    
  }) # end renderplot command
  
  
  
  # make output element for volcano map
  #------------------------------------------------------------
  output$volcanomap <- renderLeaflet({
    
    # add blank leaflet map 
    leaflet(options = leafletOptions(minZoom = 2, maxZoom = 10, zoomControl = TRUE)) %>%
      # add map tiles from CartoDB. 
      addProviderTiles("CartoDB.VoyagerNoLabels") %>%
      # set lat long and zoom to start
      setView(lng = -30, lat = 40, zoom = 3)
    
  })
  
  #  # add proxy for showing volcanoes of a certain type 
  #  --- --- --- ---   NOTE:   --- --- --- ---
  # when using leaflet in shiny, we use leafletProxy to add or subtract elements from an existing map! 
  # If we don't use "proxy," and just redo the leaflet() from above, we will be reloading the entire app,
  # meaning it would recenter and start at it's beginning zooming point each time something is changed. 
  # that's not what we want.  We won't go into more details for now, but that's what this code means.  
  # read more about leaflet and Shiny here: https://rstudio.github.io/leaflet/shiny.html
  
  observe({ # "observe" in shiny speak = "do this whenever reactive elements change"
    
    # make a colorpalette function for the 9 volcano types
    pal <- colorFactor(RColorBrewer::brewer.pal(9,"Set1"), 
                       domain = NULL)
    
    # when something is changed, clear existing points, and add new ones
    leafletProxy("volcanomap") %>%
      clearMarkers() %>%       # clear points from last selected options
      addCircleMarkers(        # add new points from "selected_volcanoes()" reactive object
        data = selected_volcanoes(),
        lng = ~longitude,
        lat = ~latitude,
        radius = ~6,
        color = ~pal(volcano_type_consolidated),
        stroke = FALSE, fillOpacity = 0.9,
        # create a popup with the volcano name and some info
        # --- --- --- --- ---  CHALLENGE  --- --- --- --- --- ---
        # if you want, see if you can add "country" or "last eruption year" to the popup box
        popup = ~paste("<b>",volcano_name,"</b>",
                       "<br>",
                       "<b> Type: </b>",volcano_type_consolidated, "<br>",
                       "<b> Continent: </b>",continent, "<br>",
                       "<b> Elevation: </b>", elevation, "m.", "<br>",
                       "<b> Last Eruption: </b>", last_eruption_year) 
      ) # end add circle markers
    
  }) # end observe
  
  
} # end the server page

