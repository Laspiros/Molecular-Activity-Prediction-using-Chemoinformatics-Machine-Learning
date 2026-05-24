###############################################################################
# 01_DATA_CLEANING_AND_EDA.R
# Purpose: Load raw MACCS fingerprint data, handle missing values, map 
#          column names, and perform exploratory data analysis (EDA).
###############################################################################

# --- Load Required Libraries ---
library(readxl)
library(ggplot2)

# --- Load Dataset ---
# Note: Ensure the working directory contains the dataset
database <- read_excel("MAAC_Fingerprints.xlsx")

# --- Initial Exploration ---
str(database)
dim(database)
head(database)

# --- Data Cleaning ---
# Remove the first (index) and last (Labels) columns to isolate features
binary_database <- database[, -c(1, ncol(database))]

# Check for missing values
cat('\nMissing values found:\n')
print(sum(is.na(binary_database)))

# Check for zero-variance predictors (rows containing only 0s or only 1s)
cat('\nRows that contain only zeros:\n')
print(sum(rowSums(binary_database == 1) == 0))

cat('\nRows that contain only ones:\n')
print(sum(rowSums(binary_database == 0) == 1))

# --- Feature Renaming ---
# Rename complex structural names to generic 'featureX' for modeling compatibility
new_names <- paste0("feature", seq_len(ncol(binary_database)))
original_names <- colnames(binary_database)
name_mapping <- setNames(original_names, new_names)

binary_database_renamed <- binary_database
colnames(binary_database_renamed) <- new_names

# Re-attach target labels and format as numeric (0, 1, 2)
binary_database_renamed$Labels <- as.numeric(as.character(database$Labels))

# --- Exploratory Data Analysis (EDA) ---
# Visualize the class distribution to identify data imbalance
ggplot(database, aes(x = as.factor(Labels))) + 
  geom_bar(fill = "steelblue") +  
  labs(title = "Distribution of Molecular Activity Labels", 
       x = "Activity Label (0=None, 1=Weak, 2=Strong)", 
       y = "Count")

# Generate a pie chart for activity distribution
volume <- factor(database$Labels, 
                 levels = c("0.0", "1.0", "2.0"), 
                 labels = c("Not active", "Weakly active", "Strongly active"), 
                 ordered = TRUE)

freq <- table(volume)
percentages <- round(100 * freq / sum(freq), 1)
labels <- paste0(names(freq), "\n", percentages, "%")

pie(freq, labels = labels, col = c("red", "yellow", "green"), 
    radius = 1, main = "Molecular Activity Distribution")