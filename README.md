# Molecular-Activity-Prediction-using-Chemoinformatics-Machine-Learning
Predicting whether a molecule is non-active, weakly active, or strongly active against a target enzyme based on structural 167-bit binary MACCS arrays

## 📌 Objective
The goal of this project is to predict the biological activity of molecules against a specific target enzyme using Machine Learning. Molecules are represented via MACCS structural fingerprints (167-bit binary arrays), and the task is a multi-class classification problem: Not Active (0), Weakly Active (1), and Strongly Active (2).

## 🧬 Domain Context
In Chemoinformatics, high-dimensional binary representations (like MACCS keys) are used to map physical sub-structures to digital formats. This project tackles the challenge of applying ML to sparse, high-dimensional binary data to aid in computational drug design.

## 🛠️ Data Engineering & Feature Selection Strategy
The dataset exhibited severe class imbalance (58.1% Not Active vs. 16% Strongly Active). 
* **Sampling:** Addressed using a custom stratified sampling approach combining oversampling of the minority class and undersampling of the majority class.
* **Dimensionality Challenge:** Standard distance metrics (like Euclidean) and clustering (PCA, K-Means) fail on high-dimensional binary arrays. 
* **Feature Selection Pipeline:** Instead of a single method, a consensus approach was used to extract the most critical substructures:
  1. Statistical Testing ($\chi^2$)
  2. Association Rule Mining (Apriori)
  3. Random Forest Feature Importance
  4. Mutual Information (Information Gain)

## 📊 Model Evaluation
Several algorithms were evaluated on a stratified 20% holdout test set. Due to the class imbalance, models were optimized for balanced F1-Score and ROC-AUC rather than raw accuracy.

| Model | Accuracy | Precision | Recall | F1-Score | ROC-AUC |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Linear Baseline** | 16.02% | 12.37% | 33.40% | 15.28% | 51.96% |
| **Random Forest** | 56.56% | 51.34% | 52.95% | 51.83% | 69.96% |
| **XGBoost** | 53.86% | 50.93% | 55.36% | 51.35% | 71.65% |
| **SVM (Top Performer)**| **56.95%** | **51.91%** | **53.72%** | **52.53%** | **70.71%** |

## 📁 Repository Structure
* `/data` - Raw and processed molecular datasets.
* `/scripts`
  * `01_data_cleaning_and_eda.R` - Data ingestion and exploratory analysis.
  * `02_feature_selection.R` - Multi-method feature extraction.
  * `03_model_training.R` - Pipeline for SVM, XGBoost, RF, and Ensembles.
  * `04_model_evaluation.R` - Confusion matrices and performance metrics.
