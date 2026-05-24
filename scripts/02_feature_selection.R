###############################################################################
# 02_FEATURE_SELECTION.R
# Purpose: Apply a multi-method consensus approach to extract the most 
#          predictive MACCS substructures from high-dimensional binary data.
###############################################################################

# --- Load Required Libraries ---
library(arules)
library(randomForest)
library(FSelectorRcpp)
library(dplyr)

# --- Method 1: Statistical Testing (Chi-Square) ---
activity <- as.numeric(database$Labels)
p_values <- numeric(167)

for (i in 2:169) {
  features <- database[[i]]
  contingency_table <- table(features, activity)
  p_values[i] <- chisq.test(contingency_table)$p.value
}

names(p_values) <- colnames(database)[2:168]
statistic_pvalues <- p_values[p_values >= 0.01 & p_values <= 0.05]
statistic_features_initial <- names(statistic_pvalues)

# Map back to renamed features
statistic_features_renamed <- names(name_mapping)[name_mapping %in% statistic_features_initial]

# --- Method 2: Rule Mining (Apriori) ---
# Filter data using statistically significant features first to reduce dimensionality
database_trans <- database[, statistic_features_initial]
database_trans[] <- lapply(database_trans, function(x) factor(ifelse(x == 1, "Yes", "No")))
database_trans$activity <- as.factor(database$Labels)

transactions <- as(database_trans, "transactions")
rules <- apriori(transactions, 
                 parameter = list(supp = 0.02, conf = 0.7, maxlen = 10),
                 appearance = list(rhs = "activity=2.0", default = "lhs"))

# Extract top rules mapped to renamed features
rule_mining_features <- names(name_mapping)[name_mapping %in% c("NC(C)N", "QHAAQH", "N=A", "Aromatic Ring > 1", "QQ > 1 (&...)  Spec Incomplete", "O > 3 (&...) Spec Incomplete")]

# --- Method 3: Random Forest Feature Importance ---
set.seed(123)
rf_model_fs <- randomForest(as.factor(Labels) ~ ., data=binary_database_renamed, importance=TRUE, ntree=100)
feature_importance <- importance(rf_model_fs)
ranked_features <- sort(feature_importance[, 1], decreasing = TRUE)
rf_top_features <- names(ranked_features)[1:10]

# --- Method 4: Mutual Information ---
mi_scores <- information_gain(Labels ~ ., data = binary_database_renamed)
mi_top_features <- mi_scores %>% arrange(desc(importance)) %>% pull(attributes) %>% .[1:10]

# --- Consensus Aggregation ---
# Combine results from all 4 methods to find the most frequently selected features
all_features <- c(statistic_features_renamed, rule_mining_features, rf_top_features, mi_top_features)
feature_counts <- table(all_features)
sorted_feature_counts <- sort(feature_counts, decreasing = TRUE)

# Select the top consensus features for model training
top_features <- names(sorted_feature_counts)[1:22]  
print(top_features)

