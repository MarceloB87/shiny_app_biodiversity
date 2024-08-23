library(shiny)
library(dplyr)
library(ggplot2)
library(data.table)
library(leaflet)
library(fst)
library(plotly)
library(DT)

# Source external R scripts that contain necessary functions and Shiny modules
source("source/app_source.R")
source("modules/species_select_module.R")
source("modules/species_table_module.R")
source("modules/species_map_module.R")
source("modules/species_timeline_module.R")

# Define UI for the application that visualizes GBIF (Global Biodiversity Information Facility) data
ui <- fluidPage(
  
  # Add theme to dashboard
  theme = bs_theme(version = 5, bootswatch = "pulse"),
  
  # Application title
  titlePanel("Global Biodiversity Information Facility Data"),
  
  # Layout with sidebar and main panel
  sidebarLayout(
    
    # Sidebar panel containing input controls and outputs
    sidebarPanel(
      
      # Dropdown for selecting a country from the list in country_dictionary
      selectizeInput(
        "country", 
        "Choose a country:",
        choices = sort(country_dictionary$country),  # Sorted list of countries
        selected = "Poland"  # Default selected country
      ),
      
      # Custom spacing between input elements using CSS
      div(style = "margin-top: -15px;"),
      
      # Button to update the selected country and trigger updates in the app
      actionButton("update_country", "Select Country"),
      
      div(style = "margin-top: 10px;"),  # Add custom spacing with CSS
      
      # UI modules for selecting species, displaying the species table, and species timeline
      speciesSelectUI("speciesSelect"),
      
      div(style = "margin-top: -20px;"),  # Add custom spacing with CSS
      
      speciesTableUI("speciesTable"),
      
      div(style = "margin-top: 20px;"),  # Add custom spacing with CSS
      
      speciesTimelineUI("speciesTimeline")
    ),
    
    # Main panel to display the map and additional outputs
    mainPanel(
      # Leaflet output to display the map with species observations
      speciesMapUI("speciesMap")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Set initial reactive objects for Poland
  spp_observation <- reactiveVal(spp_observation_ini)  # Initial species observation data
  country_data <- reactiveVal(spp_observation_ini)     # Country-specific data, starting with Poland
  species_list <- reactiveVal(species_list)            # List of species for selectizeInput
  country_code <- reactiveVal("PL")                    # Default country code set to Poland ("PL")
  selected_species <- reactiveVal("All")               # Default species selection
  country_centroid <- reactiveVal()                    # Country centroid
  
  # Update country code based on user selection
  country_code <- eventReactive(input$update_country, {
    req(input$country)
    
    # Filter the country dictionary to get the code of the selected country
    new_country_code <- country_dictionary %>%
      filter(country == input$country) %>%
      select(countryCode)
    
    new_country_code$countryCode[1]  # Return the selected country's code
  })
  
  # Load and update data from other countries if not previously loaded
  observeEvent(input$update_country, {
    req(country_code())
    
    # Check if the data for the selected country is already loaded
    if (!any(grepl(country_code(), spp_observation()$countryCode))) {
      # If data is not loaded and country is not Poland, load the appropriate dataset
      if (country_code() != "PL") {
        file_group <- OTHER_data_count %>%
          filter(countryCode == country_code()) %>%
          select(group)
        country_filename <- paste0("data/country_group_", file_group[1, 1], ".fst")
      } else {
        country_filename <- "data/PL_data.fst"
      }
      
      # Read the data and update species observations
      new_data <- read_fst(country_filename) %>%
        mutate(
          vernacularName = as.character(vernacularName),
          scientificName = as.character(scientificName),
          individualCount = as.numeric(as.character(individualCount)),
          longitudeDecimal = as.numeric(as.character(longitudeDecimal)),
          latitudeDecimal = as.numeric(as.character(latitudeDecimal)),
          eventDate = as.Date(eventDate, format = "%Y-%m-%d")
        )
      
      spp_observation(new_data)
    }
  })
  
  # Filter data based on the selected country
  observeEvent(input$update_country, {
    req(country_code())
    cc <- country_code()
    country_data(spp_observation() %>% filter(countryCode == cc))
  })
  
  # Track button clicks to trigger updates in modules
  update_button <- reactive({input$update_country})
  
  # Call the species selection module server function
  selected_species <- speciesSelectServer("speciesSelect", species_list, country_data, country_code, update_button)
  
  # Filter data based on the selected species
  filtered_data <- reactive({
    req(selected_species())
    
    # Return either the full dataset or a subset based on the selected species
    if (selected_species() == "All") {
      country_data()
    } else {
      country_data() %>%
        filter(
          grepl(paste0("^", selected_species(), "$"), scientificName, ignore.case = TRUE) | 
            grepl(paste0("^", selected_species(), "$"), vernacularName, ignore.case = TRUE)
        )
    }
  })
  
  # Call the server functions for the table, timeline, and map modules
  speciesTableServer("speciesTable", filtered_data, selected_species)
  
  speciesTimelineServer("speciesTimeline", filtered_data)
  
  speciesMapServer("speciesMap", country_dictionary, filtered_data, country_centroid, update_button, country_code)
}

# Run the Shiny application 
shinyApp(ui = ui, server = server)
