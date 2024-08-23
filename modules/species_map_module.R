# UI function for the species map module
speciesMapUI <- function(id) {
  ns <- NS(id)  # Namespace function to ensure unique IDs in Shiny modules
  
  # Return a leaflet map output with a specified height
  leafletOutput(ns("map"), height = '75vh')
}

# Server function for the species map module
speciesMapServer <- function(id, country_dictionary, filtered_data, country_centroid, update_trigger, country_code) {
  moduleServer(id, function(input, output, session) {
    
    # Initial rendering of the leaflet map with a default view (centered on Poland)
    output$map <- renderLeaflet({
      leaflet() %>%
        addTiles() %>%  # Add default OpenStreetMap tiles
        setView(lng = 19.14514, lat = 51.91944, zoom = 6)  # Set the initial map view to Poland
    })
    
    # Observe changes in the update trigger (e.g., country selection) to update the map view
    observeEvent(update_trigger(), {
      
      # Retrieve the latitude and longitude of the selected country's centroid
      coords <- country_dictionary %>%
        select(countryCode, latitude, longitude) %>%
        filter(countryCode == country_code())
      
      # Store the selected country's coordinates in a reactive value
      country_centroid(coords)
      
      # Update the map view to center on the selected country's centroid
      leafletProxy("map") %>%
        setView(lng = country_centroid()$longitude, lat = country_centroid()$latitude, zoom = 6)
    })
    
    # Observe changes in the filtered data to update map markers
    observeEvent(filtered_data(), {
      leafletProxy("map", data = filtered_data()) %>%
        clearMarkers() %>%  # Remove existing markers before adding new ones
        addCircleMarkers(
          lat = ~latitudeDecimal,  # Set latitude for markers
          lng = ~longitudeDecimal,  # Set longitude for markers
          radius = 8,  # Set the radius of the markers
          weight = 1,  # Set the border weight of the markers
          color = "darkblue",  # Set the border color of the markers
          fillColor = "steelblue",  # Set the fill color of the markers
          fillOpacity = 0.8,  # Set the opacity of the marker fill
          # Add a popup with species information when a marker is clicked
          popup = ~paste(vernacularName, "<br>", "<i>", scientificName, "</i><br>", "Observations: ", individualCount)
        )
    })
  })
}