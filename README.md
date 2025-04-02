# Cervical Cancer Survival Prediction Model bade on PET Radiomics

This repository contains code for predicting survival outcomes in cervical cancer patients using an ensemble of machine learning models.

## Project Structure

```
.
├── InferenceModel.R      # Main analysis script
├── Data.csv             # Validation dataset
├── model/               # Directory containing model files
│   ├── Combined_UCI_GLMB_Fold_1.rds
│   ├── Combined_UCI_GLMB_Fold_2.rds
│   └── Combined_UCI_GLMB_Fold_3.rds
└── normalize/           # Directory containing normalization parameters
    ├── Combined_normalize_Fold_1.rds
    ├── Combined_normalize_Fold_2.rds
    └── Combined_normalize_Fold_3.rds
```

## Requirements

- R (version 4.1.2 or higher)
- Required R packages:
  - survival
  - caret
  - readxl

## Installation

1. Clone this repository:
```bash
git clone https://github.com/GhasemHajianfar/CervicalSurvivalPrediction.git
cd CervicalSurvivalPrediction
```

2. Install required R packages:
```R
install.packages(c("survival", "caret", "readxl"))
```

## Usage

1. Ensure your data is in the correct format and saved as `Data.csv` in the project directory.

2. Run the analysis script with the working directory as an argument:
```bash
Rscript InferenceModel.R /path/to/your/project
```

The script will:
- Load the trained models
- Process the validation data
- Generate ensemble predictions
- Calculate the Harrell's C-index
- Save results to CSV files

## Output Files

- `final_predictions.csv`: Contains the ensemble predictions for each patient
- `cindex_result.csv`: Contains the calculated Harrell's C-index

## Model Details

The model uses an ensemble of three models trained on different folds of the data. Each model:
- Uses GLMB (Generalized Linear Model Boosting) approach
- Includes feature selection
- Is trained on normalized data

## Error Handling

The script includes comprehensive error handling for:
- Missing files
- Data format issues
- Model loading errors
- Calculation errors
- Invalid working directory

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Citation

If you use this code in your research, please cite:
Pre-Treatment PET Radiomics for Prediction of Disease-Free Survival in Cervical Cancer (submitted to Medical Physics)
