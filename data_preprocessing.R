require(fst)     # Load the 'fst' package for fast serialization of data
require(dplyr)   # Load the 'dplyr' package for data manipulation
require(data.table)  # Load the 'data.table' package for fast data reading and manipulation
require(readr)  # Load the 'readr' package for reading data from CSV files

# Compute the number of rows in the CSV file for a specific column
filename <- "occurence.csv"
n_row_data <- nrow(fread(filename, select = "individualCount", fill = TRUE))

#################################
#### Read all country data
# Reason: To read all information related to countries, continents, and country codes
country_data <- fread(filename, 
                      select = c("continent","country","countryCode"),
                      colClasses = "factor",  # Ensure columns are read as factors where appropriate
                      fill = TRUE)  # Fill missing values with NAs

# Load data on country centroid locations
country_centroids <- readr::read_csv("data/country_centroids.csv") %>%
  mutate(country = ifelse(is.na(country), "NA", country)) %>%
  select(country, latitude, longitude)

## Create a dictionary table with country, country codes, and continent
# Reason: To summarize information related to countries, continents, and country codes to avoid data redundancy
country_dictionary <- country_data %>% 
  count(continent, country, countryCode) %>%  # Count occurrences of each combination of continent, country, and country code
  arrange(continent, country, countryCode) %>%  # Arrange the data by continent, country, and country code
  mutate(continent = as.character(continent),   # Convert continent and countryCode to character for consistency
         countryCode = as.character(countryCode),
         continent = ifelse(continent == "", "Ocean", continent)) %>%  # Replace empty continent values with "Ocean"
  left_join(country_centroids,  # Join with country centroids data
            by = c("countryCode" = "country")) 
# Write the country dictionary to a CSV file
fwrite(country_dictionary, file = "data/country_dictionary.csv")

## Check for NA values in countryCode
# Reason: To check for completeness of data
na_countryCode <- country_data %>% distinct() %>% 
  filter(is.na(countryCode))

# Conclusion: NA values are caused by incorrect interpretation of the "NA" code for Namibia
# Continent: Africa; Country: Namibia

## Add an ID column to each row for countries
# Reason: To create an identifier for each row to optimize data retrieval for each country
country_data <- country_data %>% mutate(row_id = 1:nrow(.))

## Count entries by country
# Reason: To evaluate the number of rows per country to determine the best strategy for data storage and retrieval
country_freq_tbl <- country_data %>% 
  count(countryCode) %>%  # Count the number of entries per countryCode
  arrange(n) %>%  # Arrange by number of entries
  mutate(countryCode = ifelse(is.na(countryCode), "NA", as.character(countryCode)),
         n_sum = cumsum(n),  # Compute cumulative sum of entries
         p = n / sum(n) * 100) %>%  # Compute percentage of total entries
  arrange(desc(n))  # Arrange by descending number of entries

# Conclusion: 87% of data comes from only one country: Netherlands.
# It has been decided to separate the dataset into three files: one for Poland species, one for Netherlands species, and
# one for all other countries.

# Store rows for each relevant country group
poland_id <- country_data %>% filter(countryCode == "PL") %>% select(row_id)
other_id <- country_data %>% filter(!countryCode %in% c("PL", "NL")) %>% select(row_id)
netherlands_id <- country_data %>% filter(countryCode == "NL") %>% select(row_id)

# Save identifiers for rows in different country groups
# save(poland_id, other_id, netherlands_id, file = "country_rows_id.Rdata")
# Save the country dictionary to an RData file
# save(country_dictionary, file = "country_dictionary.Rdata")

# Remove objects from memory to free up space
rm(country_data, country_freq_tbl, na_countryCode)

# Clear memory cache
gc()

#################
## Create a dictionary table for taxonomic ranks, kingdoms, and families
# Reason: To summarize taxonomic information to avoid data redundancy
taxonomic_data <- fread(filename, 
                        select = c("taxonRank", "kingdom", "family", "scientificName"),
                        fill = TRUE)

taxonomic_dictionary <- taxonomic_data %>%
  select(taxonRank, kingdom, family, scientificName) %>%  # Select relevant columns
  distinct() %>%  # Remove duplicate rows
  arrange(taxonRank, kingdom, family, scientificName)  # Arrange by taxonomic rank

# Write the full taxonomic dictionary to a CSV file
fwrite(taxonomic_dictionary, file = "taxonomic_dictionary.csv")

# Create a shorter version of the taxonomic dictionary
taxonomic_dictionary_short <- taxonomic_dictionary %>%
  select(kingdom, family, scientificName) %>%  # Select a subset of columns
  distinct() %>%  # Remove duplicate rows
  mutate(family = gsub("_", " ", family),  # Replace underscores with spaces in family names
         family = stringr::str_to_title(family),  # Convert family names to title case
         family = gsub(" And ", " and ", family),  # Fix common capitalization issues
         family = gsub(" Or ", " or ", family))  # Fix common capitalization issues

# Write the short taxonomic dictionary to a CSV file
fwrite(taxonomic_dictionary_short, file = "data/taxonomic_dictionary_short.csv")

# Remove objects from memory to free up space
rm(taxonomic_data, taxonomic_dictionary)

# Clear memory cache
gc()

#################

# Read biodiversity data from the CSV file
biodiversity_data <- fread(filename, 
                           select = c("scientificName", "vernacularName", "individualCount",
                                      "longitudeDecimal", "latitudeDecimal", "countryCode", "eventDate"),
                           colClasses = "factor",  # Ensure columns are read as factors where appropriate
                           fill = TRUE)

# Extract data for Poland and write it to an 'fst' file
PL_data <- biodiversity_data %>%
  slice(poland_id$row_id)  # Select rows for Poland
write_fst(PL_data, path = "biodiversity_app/data/PL_data.fst")

# Clean up
rm(PL_data)
gc()

# Extract data for other countries and write it to 'fst' files
OTHER_data <- biodiversity_data %>%
  slice(other_id$row_id)

# Convert data columns to appropriate types
OTHER_data = OTHER_data %>%
  mutate(individualCount = as.numeric(as.character(individualCount)),
         longitudeDecimal = as.numeric(as.character(longitudeDecimal)),
         latitudeDecimal = as.numeric(as.character(latitudeDecimal)),
         eventDate = as.Date(eventDate, format = "%Y-%m-%d"))

# Count entries by countryCode and categorize into groups
OTHER_data_count = OTHER_data %>% 
  count(countryCode) %>%
  mutate(countryCode = as.character(countryCode)) %>%
  mutate(countryCode = ifelse(is.na(countryCode), "NA", countryCode)) %>%
  arrange(n) %>%
  mutate(m = cumsum(n),  # Compute cumulative sum of entries
         group = cut(m, breaks = c(seq(1, max(m), by = 300000), max(m)), include.lowest = TRUE, labels = FALSE),
         group = as.numeric(as.factor(group))) %>%  # Group data for processing
  select(countryCode, group)

# Join the country groups with the main data
OTHER_data <- OTHER_data %>% left_join(OTHER_data_count, by = "countryCode")

# Write data for each group to separate 'fst' files
for (group_n in 1:max(OTHER_data_count$group)) {
  sub_OTHER_data <- OTHER_data %>% filter(group == group_n) %>% select(-group)
  filename <- paste0("data/country_group_", group_n, ".fst")
  print(paste0("Writing: ", filename))
  write_fst(sub_OTHER_data, path = filename)
}

# Save the country group information to an 'fst' file
write_fst(OTHER_data_count, path = "data/OTHER_country_codes.fst")

# Clean up
rm(OTHER_data)
gc()

## Omitted from this code version
# The following code for Netherlands data is commented out
# NL_data <- biodiversity_data %>%
#   slice(netherlands_id$row_id)
# write_fst(NL_data, path = "biodiversity_app/data/NL_data.fst")
# rm(NL_data)
# gc()
