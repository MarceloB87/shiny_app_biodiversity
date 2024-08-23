# Global Biodiversity Information Facility Data Visualization Shiny App

This Shiny application visualizes species data from the Global Biodiversity Information Facility (GBIF). It allows users to select countries, view species data on a map, and explore data through tables and timelines. The app is designed for ease of use and flexibility, allowing for dynamic data updates based on user input.

You can access the app via **shinyapps.io** by [clicking here](https://meborges.shinyapps.io/app_final/).

## Features

- **Country Selection**: Users can select a country from a dropdown menu, which updates the data displayed in the app.
- **Species Selection**: A module allows users to select specific species from the available data, either by Scientific Name or vernacularName.
- **Data Table**: Displays detailed information about the selected species.
- **Species Map**: Visualizes species observations on an interactive map using Leaflet.
- **Species Timeline**: Shows a timeline of species observations.

## Prerequisites

- R (version 4.3.0 or higher)
- RStudio (optional, but recommended for development)
- The following R packages:
  - `shiny`
  - `dplyr`
  - `ggplot2`
  - `data.table`
  - `leaflet`
  - `fst`
  - `plotly`
  - `DT`

## Installation

1.**Install Dependencies**

Run the following commands in your R console to install the necessary packages:

install.packages(c("shiny", "dplyr", "ggplot2", "data.table", "leaflet", "fst", "plotly", "DT"))

2. **Usage**

2.1 Source External Scripts

Ensure that the external R scripts required by the app are present in the source/ and modules/ directories.

2.2 Run the App

Open app.R in RStudio or another R environment, and run the following command:

shiny::runApp("app.R")

This will launch the Shiny application in your default web browser.

3. **Application Structure**

* app.R: Main application script that defines the UI and server logic.
* source/: Directory containing external R scripts with functions and app source code.
- app_source.R: Includes utility functions and shared resources.
* modules/: Directory containing Shiny modules.
- species_select_module.R: Module for selecting species.
- species_table_module.R: Module for displaying the species table.
- species_map_module.R: Module for rendering the species map.
- species_timeline_module.R: Module for displaying the species timeline.

## Performance Optimization

The app employs several strategies to optimize performance:

### **A) Data Pre-processing**

Due to the large size of the original datasource file (`biodiversity-data.tar.gz`), which is 2GB compressed and approximately 21GB uncompressed, working directly with this data would be impractical. 

To address this, the data has been pre-processed to reduce redundancy and improve efficiency. This involves:

- Selecting only the relevant data for analysis.
- Creating separate files for related tables, such as those containing information about countries or taxonomic details by species.
- Segmenting the data into smaller files for different regions, including a specific table for Poland and separate files for other countries.

For detailed instructions on data pre-processing, refer to the `data_preprocessing.R` script.

**Steps to Recreate Data Pre-processing:**

1. Download the data from [this link](https://drive.google.com/file/d/1l1ymMg-K_xLriFv1b8MgddH851d6n2sU/view?usp=sharing).
2. Extract the file `biodiversity-data/occurence.csv` into the same folder as the `data_preprocessing.R` script.
3. Run the `data_preprocessing.R` script.

The pre-processed files will be saved in the `data/` folder, which must be present for the app to function correctly.

### **B) App Initialization**

To ensure fast initialization, the following strategies have been employed:

- The app initially loads only the pre-processed species data for Poland.
- Other elements in the app's environment are stored as reactive elements and updated only when necessary.

### **C) App Usage**

The app's architecture is designed to minimize redundant processing:

- Selecting a new species does not reload the map; instead, it updates only the species' spatial distribution information.
- Information for a new country is updated only after pressing the button to update the country.
- When a new country is selected and the update button is pressed, the code checks if the data for that country is already loaded. A new file is loaded only if the data is not already present in the environment.

These optimizations ensure that the app displays and updates species and country information efficiently, with minimal disk space usage.

## **UI Styling**

The user interface is designed to be simple and functional, with a focus on usability:

- A straightforward layout with a limited number of input options and outputs to avoid information overload.
- Utilization of a Bootswatch theme to enhance the visual design.
- CSS elements embedded in R, such as `div()`, to adjust spacing between elements.

## **Unit testing**

Unit testing is employed to ensure the correctness of the app's functionality. Here is a simple example of unit testing for reading fst files:

The tests check the following aspects:

- Whether the data file exists.
- If all required columns are present.
- Whether the longitude and latitude columns contain numeric values.

For more details and reproducing the test, refer to the 'unit_tests/test_load_fst.R' file.
