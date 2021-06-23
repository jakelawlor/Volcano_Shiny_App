#------------------------------------------------------------------------
#                       ---- Server Script ----
#  this script runs all internal operations to make your shiny app work
#------------------------------------------------------------------------
function(input, output, session) {
  
  
  # read in the prepared data 
  # (just the volcanoes spreadsheet with a new column for "continent")
  volcano <- readr::read_rds(here::here("data", "volcanoes.rds"))
  
  
  # make reactive dataset
  # ------------------------------------------------
  # Make a subset of the data as a reactive value
  # this subset pulls volcano rows only in the selected types of volcano
  selected_volcanoes <- reactive({
    volcano %>%
      
      # select only volcanoes in the selected volcano type (by checkboxes in the UI)
      filter(volcano_type_consolidated %in% input$volcano_type) %>%
      
      # Space to add your suggested filer here!! 
      # --- --- --- --- --- --- --- --- --- --- --- --- ---
      # filter() %>%
      # --- --- --- --- --- --- --- --- --- --- --- --- ---
      
      # change volcano type into factor (this makes plotting it more consistent)
      mutate(volcano_type_consolidated = factor(volcano_type_consolidated,
                                                levels = c("Stratovolcano" , "Shield",  "Cone",   "Caldera", "Volcanic Field",
                                                           "Complex" ,  "Other" ,  "Lava Dome" , "Submarine" ) ) )
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
      theme(axis.text.x = element_text(angle=45,hjust=1))
    
    
    # IF a selected_volcanoes() object exists, update the blank ggplot. 
    # basically this makes it not mess up when nothing is selected
    if(nrow(selected_volcanoes()) >=1){ 
      barplot <- barplot +
        geom_bar(data = selected_volcanoes(), show.legend = F) +
        scale_fill_manual(values = RColorBrewer::brewer.pal(9,"Set1"), 
                          drop=F) +
        scale_x_discrete(drop=F)
      
    }
    
    # print the plot
    barplot
    
  }) # end renderplot command
  
  
  
  # make output element for volcano map
  #------------------------------------------------------------
  output$volcanomap <- renderLeaflet({
    
    # add blank leaflet map 
    leaflet( options = leafletOptions(minZoom = 0, maxZoom = 10, zoomControl = TRUE)) %>%
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
  
  observe({
    
    # make a colorpalette function for the 9 volcano types
    pal <- colorFactor(RColorBrewer::brewer.pal(9,"Set1"), 
                       domain = NULL)
    
    # when something is changed, clear existing points, and add new ones
    leafletProxy("volcanomap") %>%
      clearMarkers() %>%       # clear points
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
                       "<b> Elevation: </b>", elevation, "ft.") 
      ) # end add circle markers
    
  }) # end observe
  
  
} # end the server page

