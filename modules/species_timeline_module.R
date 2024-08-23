# UI function for the species timeline module
speciesTimelineUI <- function(id) {
  ns <- NS(id)  # Namespace function to ensure unique IDs in Shiny modules
  
  # Return a Plotly output for displaying a timeline plot with a specified height
  plotly::plotlyOutput(ns("timeline"), height = 280)
}

# Server function for the species timeline module
speciesTimelineServer <- function(id, filtered_data) {
  moduleServer(id, function(input, output, session) {
    
    # Render the timeline plot when the filtered data changes
    output$timeline <- plotly::renderPlotly({
      req(filtered_data())  # Ensure that filtered data is available
      data <- filtered_data()  # Get the filtered data
      
      # Prepare the data for plotting by grouping observations by year and summarizing
      spp_observation_time_tbl <- data %>%
        data.frame() %>%
        mutate(Year = lubridate::year(as.Date(eventDate))) %>%  # Extract the year from event dates
        group_by(Year) %>%
        summarise(Observations = sum(individualCount, na.rm = TRUE)) %>%
        ungroup()
      
      # Define limits for the y-axis (observations) and x-axis (years)
      y_limits <- c(0, max(spp_observation_time_tbl$Observations, na.rm = TRUE) * 1.1)
      x_limits <- range(spp_observation_time_tbl$Year)
      
      # Ensure y-axis has a minimum limit and x-axis starts from 1984 if necessary
      if (max(y_limits) < 5) y_limits <- c(0, 5.1)
      if (min(x_limits) > 1984) x_limits[1] <- 1984
      
      # Define breaks for the x-axis (years)
      x_breaks <- unique(floor(pretty(seq(min(x), (max(x) + 1)), n = 10)))
      
      # Create a ggplot object for the timeline
      spp_plot <- spp_observation_time_tbl %>%
        ggplot(aes(x = Year, y = Observations)) +
        geom_col(fill = "steelblue", width = 1) +  # Plot observations as bars
        labs(title = "Observations by year\n", x = "", y = "") +  # Add title and remove axis labels
        theme_minimal() +  # Use a minimal theme for the plot
        theme(axis.line.x = element_line(colour = "darkgrey", linewidth = 0.6)) +  # Customize x-axis line
        scale_y_continuous(
          limits = y_limits,
          expand = c(0, 0),
          breaks = function(x) unique(floor(pretty(seq(min(x), (max(x) + 1) * 1.1))))
        ) +
        scale_x_continuous(
          limits = x_limits + c(-1, 1),  # Add some padding to the x-axis limits
          breaks = x_breaks  # Set custom breaks for the x-axis
        ) +
        theme(
          panel.grid.minor = element_blank(),  # Remove minor grid lines
          panel.grid.major.x = element_blank(),  # Remove major grid lines on the x-axis
          axis.text.x = element_text(angle = 45, vjust = 0.5, hjust = 0.4),  # Rotate x-axis labels
          plot.title = element_text(hjust = 0.4, face = "bold")  # Center and bold the title
        )
      
      # Convert the ggplot object to a Plotly object and remove the mode bar
      plotly::ggplotly(spp_plot) %>% config(displayModeBar = FALSE)
    })
  })
}
