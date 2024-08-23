# UI function for the species table module
speciesTableUI <- function(id) {
  ns <- NS(id)  # Namespace function to ensure unique IDs in Shiny modules
  
  # Return a DTOutput for displaying a data table
  DTOutput(ns("table"))
}

# Server function for the species table module
speciesTableServer <- function(id, filtered_data, species) {
  moduleServer(id, function(input, output, session) {
    
    # Render the data table when the filtered data or selected species changes
    output$table <- renderDT({
      req(filtered_data())  # Ensure that filtered data is available
      
      # If "All" species is selected, display a message prompting the user to select a species
      if (species() == "All") {
        spp_info <- matrix(data = rep("Select a species", 4), 4, 1)
      } else {
        # Otherwise, generate a table with species information
        spp_info <- filtered_data() %>%
          select(scientificName, vernacularName) %>%
          slice(1) %>%  # Take the first row of the filtered data
          left_join(taxonomic_dictionary_short, by = "scientificName") %>%
          select(kingdom, family, scientificName, vernacularName) %>%
          mutate(scientificName = paste0("<i>", scientificName, "</i>")) %>%  # Italicize the scientific name
          t()  # Transpose the data to create a single column of information
      }
      
      # Create a data frame to store labels and corresponding species information
      info_table <- data.frame(
        labels = c("<b>Kingdom</b>", "<b>Family</b>", "<b>Scientific name</b>", "<b>Common Name</b>"),
        info = spp_info[, 1]  # Extract the first column of transposed data
      )
      
      # Render the data table with specific options
      datatable(
        info_table,
        colnames = c("", ""),  # No column names
        rownames = FALSE,  # Do not display row names
        options = list(dom = 't', ordering = FALSE),  # Disable table ordering and other features
        escape = FALSE  # Allow HTML content in the table (for formatting)
      )
    })
  })
}
