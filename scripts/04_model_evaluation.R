###############################################################################
# 04_MODEL_EVALUATION.R
# Purpose: Evaluate base models on the holdout test set and implement a 
#          stacking ensemble meta-model.
###############################################################################

# --- Load Required Libraries ---
library(caret)
library(pROC)

# True labels from the holdout set
true_class <- testing_data$Labels

# --- Helper Function for Evaluation ---
evaluate_model <- function(predictions, model_name) {
  conf_matrix <- confusionMatrix(predictions, true_class)
  
  precision <- mean(conf_matrix$byClass[, "Precision"], na.rm = TRUE) * 100
  recall <- mean(conf_matrix$byClass[, "Recall"], na.rm = TRUE) * 100
  f1 <- mean(conf_matrix$byClass[, "F1"], na.rm = TRUE) * 100
  accuracy <- conf_matrix$overall["Accuracy"] * 100
  
  roc_multi <- multiclass.roc(as.numeric(true_class), as.numeric(predictions))
  roc_auc <- auc(roc_multi) * 100
  
  cat(sprintf("\n--- %s Metrics ---\n", model_name))
  cat(sprintf("Precision: %.2f%%\nRecall: %.2f%%\nF1-Score: %.2f%%\nAccuracy: %.2f%%\nROC-AUC: %.2f%%\n", 
              precision, recall, f1, accuracy, roc_auc))
}

# --- Base Model Predictions ---
pred_tree <- factor(predict(tree_model, newdata = testing_data, type = "class"), levels = c(0, 1, 2))
pred_rf <- factor(predict(rf_model, newdata = testing_data), levels = c(0, 1, 2))

test_matrix <- as.matrix(testing_data[, top_features])
pred_xgb <- factor(predict(xgb_model, newdata = xgb.DMatrix(data = test_matrix)), levels = c(0, 1, 2))

pred_nn_prob <- predict(nn_model, newdata = testing_data, type = "raw")
pred_nn <- factor(apply(pred_nn_prob, 1, function(x) which.max(x) - 1), levels = c(0, 1, 2))

pred_svm <- factor(predict(svm_model, newdata = testing_data), levels = c(0, 1, 2))

# --- Evaluate Base Models ---
evaluate_model(pred_tree, "Decision Tree")
evaluate_model(pred_rf, "Random Forest")
evaluate_model(pred_xgb, "XGBoost")
evaluate_model(pred_nn, "Neural Network")
evaluate_model(pred_svm, "Support Vector Machine")

# --- Stacking Ensemble Learning ---
# Compile base predictions into meta-features
meta_features <- data.frame(
  tree = as.numeric(pred_tree),
  rf = as.numeric(pred_rf),
  xgb = as.numeric(pred_xgb),
  nn = as.numeric(pred_nn),
  svm = as.numeric(pred_svm)
)

meta_features$Labels <- as.numeric(true_class)

# Train the Meta-model (using multinomial logistic regression)
library(nnet)
meta_model <- multinom(Labels ~ ., data = meta_features, trace = FALSE)

# Evaluate Meta-model
meta_predictions <- predict(meta_model, newdata = meta_features)
meta_predictions <- factor(meta_predictions, levels = c(0, 1, 2))

evaluate_model(meta_predictions, "Stacking Ensemble")