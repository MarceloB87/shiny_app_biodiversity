# UI function for the species selection module
speciesSelectUI <- function(id) {
  ns <- NS(id)  # Namespace function to ensure unique IDs in Shiny modules
  
  # Create a tagList to hold UI elements
  tagList(
    # Dropdown for selecting a species, initialized with no choices (to be populated later)
    selectizeInput(
      ns("species"),
      "Type and select a species:",
      choices = NULL  # Choices will be populated dynamically
    )
  )
}

# Server function for the species selection module
speciesSelectServer <- function(id, species_list, country_data, country_code, update_trigger) {
  
  moduleServer(id, function(input, output, session) {
    
    # Update the species list when the update button is clicked or when the country changes
    observeEvent(update_trigger(), {
      req(country_code())  # Ensure a country is selected before proceeding
      
      # Get unique vernacular and scientific names from the current country data
      unique_vernacular_names <- sort(unique(country_data()$vernacularName))
      unique_scientific_names <- sort(unique(country_data()$scientificName))
      
      # Combine the unique names into a single vector, including "All" as the first option
      new_vector <- c("All", unique_vernacular_names[unique_vernacular_names != ""], unique_scientific_names)
      
      # Update the species list reactive value
      species_list(new_vector)
    })
    
    # Update the species selectizeInput choices based on the species list
    observe({
      req(species_list())  # Ensure the species list is available
      updateSelectizeInput(
        session, "species",
        choices = species_list(),  # Update choices with the new species list
        selected = species_list()[1]  # Default to the first item in the list (usually "All")
      )
    })
    
    # Return the selected species as a reactive expression
    reactive(input$species)
  })
}
