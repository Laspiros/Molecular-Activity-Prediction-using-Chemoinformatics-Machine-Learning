###############################################################################
# 03_MODEL_TRAINING.R
# Purpose: Handle class imbalance via stratified sampling and train multiple 
#          machine learning models on the consensus features.
###############################################################################

# --- Load Required Libraries ---
library(caret)
library(rpart)
library(randomForest)
library(xgboost)
library(nnet)
library(e1071)

# --- Train-Test Split ---
set.seed(123)
binary_database_renamed$Labels <- as.factor(binary_database_renamed$Labels)
train_index <- createDataPartition(binary_database_renamed$Labels, p = 0.8, list = FALSE)

training_data <- binary_database_renamed[train_index, ]
testing_data <- binary_database_renamed[-train_index, ]

# --- Handle Class Imbalance (Combined Sampling) ---
# Desired size equalizes classes to roughly 691 samples each
desired_size <- floor(nrow(training_data) / 3) 

class_0 <- training_data[training_data$Labels == "0", ]
class_1 <- training_data[training_data$Labels == "1", ]
class_2 <- training_data[training_data$Labels == "2", ]

set.seed(123)
class_0_balanced <- class_0[sample(1:nrow(class_0), desired_size, replace = TRUE), ]
class_1_balanced <- class_1[sample(1:nrow(class_1), desired_size, replace = TRUE), ]
class_2_balanced <- class_2[sample(1:nrow(class_2), desired_size, replace = TRUE), ]

training_data_balanced <- rbind(class_0_balanced, class_1_balanced, class_2_balanced)
training_data_balanced <- training_data_balanced[sample(1:nrow(training_data_balanced)), ]

# Build model formula using the top features from Script 02
model_formula <- as.formula(paste("Labels ~", paste(top_features, collapse = " + ")))

# --- Model 1: Decision Tree ---
tree_model <- rpart(model_formula, data = training_data_balanced, method = "class")

# --- Model 2: Random Forest ---
rf_model <- randomForest(model_formula, data = training_data_balanced)

# --- Model 3: XGBoost ---
train_matrix <- as.matrix(training_data_balanced[, top_features])
train_labels <- as.numeric(training_data_balanced$Labels) - 1  # 0-based indexing
dtrain <- xgb.DMatrix(data = train_matrix, label = train_labels)

params <- list(objective = "multi:softmax", num_class = 3, eval_metric = "mlogloss", max_depth = 6, eta = 0.3)
xgb_model <- xgb.train(params = params, data = dtrain, nrounds = 100, verbose = 0)

# --- Model 4: Neural Network ---
nn_model <- nnet(model_formula, data = training_data_balanced, size = 5, decay = 0.01, maxit = 200, trace = FALSE)

# --- Model 5: Support Vector Machine (SVM) ---
svm_model <- svm(model_formula, data = training_data_balanced, kernel = "radial", probability = TRUE)

# Note: The Stacking Ensemble requires evaluation logic contained in the next script.