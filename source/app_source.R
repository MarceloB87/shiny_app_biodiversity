# Load necessary libraries
library(dplyr)       # Data manipulation
library(ggplot2)     # Data visualization
library(data.table)  # Efficient data handling
library(leaflet)     # Interactive maps
library(fst)         # Fast storage and retrieval of data frames
library(shiny)       # Web applications framework
library(bslib)       # Custom Bootstrap themes for Shiny
library(plotly)      # Interactive plots
library(DT)          # Render DataTables

# Load minimum requirement data

# Load country dictionary from a CSV file
country_dictionary <- fread("data/country_dictionary.csv")

# Load taxonomic dictionary from a CSV file
taxonomic_dictionary_short <- fread("data/taxonomic_dictionary_short.csv")

# Load data for other countries, add a column for file paths
OTHER_data_count <- read_fst("data/OTHER_country_codes.fst")
OTHER_data_count <- OTHER_data_count %>% 
  mutate(file = paste0("data/country_group_", group, ".fst"))

# Load initial species observation data for Poland
spp_observation_ini <- read_fst("data/PL_data.fst")

# Convert relevant columns to the appropriate data types
spp_observation_ini <- spp_observation_ini %>%
  mutate(
    vernacularName = as.character(vernacularName),
    scientificName = as.character(scientificName),
    individualCount = as.numeric(as.character(individualCount)),
    longitudeDecimal = as.numeric(as.character(longitudeDecimal)),
    latitudeDecimal = as.numeric(as.character(latitudeDecimal)),
    eventDate = as.Date(eventDate, format = "%Y-%m-%d")
  )

# Correct NA country code for Namibia and filter out unwanted countries
country_dictionary <- country_dictionary %>% 
  mutate(countryCode = ifelse(is.na(countryCode), "NA", countryCode)) %>%  # Correct NA values
  filter(country != "Oceans") %>%  # Remove the entry for Oceans
  filter(!grepl("Netherlands", country))  # Exclude countries with "Netherlands" in their name

# Generate species list for initial selectizeInput widget
unique_vernacular_names <- as.character(sort(unique(spp_observation_ini$vernacularName)))
unique_vernacular_names <- unique_vernacular_names[unique_vernacular_names != ""]  # Remove empty names
unique_scientific_names <- as.character(sort(unique(spp_observation_ini$scientificName)))

# Combine vernacular and scientific names into one list with "All" as the first choice
species_list <- c("All", unique_vernacular_names, unique_scientific_names)
