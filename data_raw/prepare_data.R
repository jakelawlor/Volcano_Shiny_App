### ----------------------------------------------
### ----------------------------------------------
### This script loads and wrangles data 
### that we will use
### ----------------------------------------------
### ----------------------------------------------

### Load Packages -------------------------
# Load packages
library(dplyr)
library(stringr)
library(countrycode)
library(here)



# Import and clean data  ----------------------------------------
volcano <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-05-12/volcano.csv') 

volcano <- volcano %>%
  
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
         
         # consolidate volcano types
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


  
volcano %>% glimpse()


readr::write_rds(volcano, here("data","volcanoes.rds"))

