# Required packages
required_packages <- c("survival", "caret", "readxl")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg)
    library(pkg, character.only = TRUE)
  }
}

# Function to calculate Harrell's C-index
calculate_harrell_cindex <- function (formula, data) 
{
  cox1 <- coxph(formula, data)
  y <- cox1[["y"]]
  p <- ncol(y)
  time <- y[, p - 1]
  status <- y[, p]
  x <- cox1$linear.predictors
  n <- length(time)
  ord <- order(time, -status)
  time <- time[ord]
  status <- status[ord]
  x <- x[ord]
  wh <- which(status == 1)
  total <- concordant <- 0
  for (i in wh) {
    if (i < n) {
      for (j in ((i + 1):n)) {
        if (time[j] > time[i]) {
          total <- total + 1
          if (x[j] < x[i]) 
            concordant <- concordant + 1
          if (x[j] == x[i]) 
            concordant <- concordant + 0.5
        }
      }
    }
  }
  return(list(concordant = concordant, total = total, cindex = concordant/total))
}

# Main function to run the analysis
run_analysis <- function(work_dir) {
  tryCatch({
    # Set working directory
    if (!dir.exists(work_dir)) {
      stop(paste("Directory not found:", work_dir))
    }
    setwd(work_dir)
    cat(sprintf("Working directory set to: %s\n", work_dir))
    
    # Load models
    cat("Loading models...\n")
    load_model <- function(s) {
      model_path <- file.path(work_dir, "model", paste0("Combined_UCI_GLMB_Fold_", s, ".rds"))
      if (!file.exists(model_path)) {
        stop(paste("Model file not found:", model_path))
      }
      readRDS(model_path)
    }
    
    fold_models <- lapply(1:3, load_model)
    
    # Load normalization features
    cat("Loading normalization features...\n")
    load_norm_feature <- function(s) {
      norm_path <- file.path(work_dir, "normalize", paste0("Combined_normalize_Fold_", s, ".rds"))
      if (!file.exists(norm_path)) {
        stop(paste("Normalization file not found:", norm_path))
      }
      readRDS(norm_path)
    }
    
    norm_features <- lapply(1:3, function(s) load_norm_feature(s))
    
    # Read validation data
    cat("Reading validation data...\n")
    data_path <- file.path(work_dir, "Data.csv")
    if (!file.exists(data_path)) {
      stop(paste("Data file not found:", data_path))
    }
    validate_df <- read.csv(data_path)
    
    # Prepare validation data and normalize
    cat("Preparing and normalizing validation data...\n")
    validate_dfr_list <- list()
    model_preds <- list()
    
    for (i in 1:3) {
      cat(sprintf("Processing fold %d...\n", i))
      vec.fs <- fold_models[[i]][["features"]]
      validate_subset <- validate_df[, vec.fs]
      target <- validate_df[, (length(validate_df) - 1):length(validate_df)]
      
      norm_mean <- norm_features[[i]]$mean[names(norm_features[[i]]$mean) %in% colnames(validate_subset)]
      norm_sd <- norm_features[[i]]$std[names(norm_features[[i]]$std) %in% colnames(validate_subset)]
      
      validate_subset <- scale(validate_subset, center = norm_mean, scale = norm_sd)
      validate_dfr <- cbind(target, validate_subset)
      validate_dfr_list[[i]] <- validate_dfr
      
      model_preds[[i]] <- predict(fold_models[[i]], newdata = validate_dfr)$data$response
    }
    
    # Compute ensemble prediction
    cat("Computing ensemble predictions...\n")
    ensemble_pred <- rowMeans(do.call(cbind, model_preds))
    ensemble_pred <- data.frame(
      time = target$time,
      event = target$censor,
      response = ensemble_pred
    )
    
    # Ensure numeric types
    ensemble_pred$time <- as.numeric(ensemble_pred$time)
    ensemble_pred$event <- as.numeric(ensemble_pred$event)
    ensemble_pred$response <- as.numeric(ensemble_pred$response)
    
    # Calculate C-index
    cat("Calculating Harrell's C-index...\n")
    EV_ci <- calculate_harrell_cindex(Surv(time, event) ~ response, ensemble_pred)$cindex
    
    # Save results
    cat("Saving results...\n")
    write.csv(ensemble_pred, file.path(work_dir, "final_predictions.csv"), row.names = FALSE)
    write.csv(data.frame(cindex = EV_ci), file.path(work_dir, "cindex_result.csv"), row.names = FALSE)
    
    cat(sprintf("\nAnalysis completed successfully!\nC-index: %.4f\n", EV_ci))
    return(EV_ci)
    
  }, error = function(e) {
    cat(sprintf("Error: %s\n", e$message))
    return(NULL)
  })
}

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  cat("Usage: Rscript InferenceModel.R <working_directory>\n")
  cat("Example: Rscript InferenceModel.R /path/to/your/project\n")
  quit(status = 1)
}

# Run the analysis with the provided working directory
work_dir <- args[1]
run_analysis(work_dir)
