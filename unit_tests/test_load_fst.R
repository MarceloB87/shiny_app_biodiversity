library(testthat)
library(fst)

# Function to load and validate .fst files
load_and_validate_fst <- function(file_path) {
  data <- tryCatch({
    read_fst(file_path)
  }, error = function(e) {
    stop("Failed to read .fst file: ", e$message)
  })
  
  # Check if the data is a data frame
  if (!is.data.frame(data)) {
    stop("The loaded data is not a data frame.")
  }
  
  # Check for expected columns
  required_columns <- c("scientificName", "vernacularName", "individualCount", "longitudeDecimal", "latitudeDecimal", "countryCode", "eventDate")
  if (!all(required_columns %in% colnames(data))) {
    stop("Missing required columns in the data.")
  }
  
  tryCatch({
    as.numeric(data$longitudeDecimal)
  }, error = function(e) {
    stop("Failed to read .fst file: ", e$message)
  })
  
  # Check longitude and latitude data types
  tryCatch({
     # Evaluate the expression
    as.numeric(as.character(data$longitudeDecimal))
    },
    warning = function(w) {
      # Convert warning to error
      stop("Column 'longitudeDecimal' can´t be converted to numeric value. Warning occurred: ", conditionMessage(w))
    },
    error = function(e) {
      # Propagate other errors
      stop("Error occurred: ", conditionMessage(e))
    })
  
  tryCatch({
    # Evaluate the expression
    as.numeric(as.character(data$latitudeDecimal))
  },
  warning = function(w) {
    # Convert warning to error
    stop("Column 'latitudeDecimal' can´t be converted to numeric value. Warning occurred: ", conditionMessage(w))
  },
  error = function(e) {
    # Propagate other errors
    stop("Error occurred: ", conditionMessage(e))
  })
  
  return(data)
}

# Paths to the test .fst files (ensure these paths are correct in your environment)
fst_files <- list.files(pattern = ".fst", "data/")
fst_files <- fst_files[fst_files!="OTHER_country_codes.fst"]

test_that("Different .fst files load correctly", {
  for (file_name in fst_files) {
    file_path <- paste0("data/",file_name)
    print(file_path)
    # Test loading and validating the .fst file
    testthat::expect_silent({
      data <- load_and_validate_fst(file_path)
      expect_true(is.data.frame(data), info = paste(file_name, "should be a data frame"))
      expect_true(all(c("scientificName", "longitudeDecimal", "latitudeDecimal") %in% colnames(data)), info = paste(file_name, "should have required columns"))
    })
    
    # Additional checks if needed
    testthat::expect_true(nrow(data) > 0, info = paste(file_name, "should not be empty"))
  }
})


