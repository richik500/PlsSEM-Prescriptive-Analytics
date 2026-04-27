
  data <- read_excel("Modified_SM_Final.xlsx", sheet = 2)
  
  # Install & Load Packages
  install.packages("seminr")
  install.packages("readxl")
  install.packages("dplyr")
  
  library(seminr)
  library(readxl)
  library(dplyr)
  
  # Load Dataset (Sheet 2)
  getwd()
  data <- read_excel("Modified_SM_Final.xlsx", sheet = 2)
  
  # Clean column names (important: removes extra spaces like CSLE )
  colnames(data) <- trimws(colnames(data))
  
  # Convert all to numeric (safe step)
  data <- data %>% mutate(across(everything(), as.numeric))
  
  # Remove missing values
  data <- na.omit(data)
  
  # Define Measurement Model (ALL SINGLE-ITEM CONSTRUCTS)
  measurement_model <- constructs(
    
    composite("OMDT", single_item("OMDT")),
    composite("WITI", single_item("WITI")),
    composite("CBDR", single_item("CBDR")),
    composite("HRCS", single_item("HRCS")),
    composite("QAAD", single_item("QAAD")),
    composite("TDR", single_item("TDR")),
    composite("APDL", single_item("APDL")),
    composite("AUDT", single_item("AUDT")),
    composite("ASTL", single_item("ASTL")),
    composite("CSLE", single_item("CSLE")),
    composite("AIST", single_item("AIST"))
    
  )
  
  # Define Structural Model
  structural_model <- relationships(
    
    paths(from = c("OMDT", "WITI", "CBDR", "HRCS", "QAAD",
                   "TDR", "APDL", "AUDT", "ASTL", "CSLE"),
          to = "AIST")
    
  )
  
  # Estimation of PLS-SEM Model
  pls_model <- estimate_pls(
    data = data,
    measurement_model = measurement_model,
    structural_model = structural_model
  )
  
  # View Model Summary
  summary(pls_model)
  
  # Path Coefficients
  pls_model$path_coefficients
  
  # Bootstrapping
  boot_model <- bootstrap_model(
    seminr_model = pls_model,
    nboot = 5000
  )
  
  # Error Fix
  colSums(is.na(data))
  data <- data[complete.cases(data), ]
  str(data)
  data <- data %>%
    mutate(across(everything(), ~as.numeric(as.character(.))))
  sapply(data, function(x) var(x, na.rm = TRUE))
  data <- data %>% select(where(~ var(., na.rm = TRUE) != 0))
  
  
  #Rebuilding Model & Bootstrap
  pls_model <- estimate_pls(
    data = data,
    measurement_model = measurement_model,
    structural_model = structural_model
  )
  boot_model <- bootstrap_model(pls_model, nboot = 1000)
  
  summary(boot_model)
  plot(boot_model)
  
  # Plot
  plot(boot_model,
       title = "Bootstrapped SEM Model",
       show_weights = TRUE,
       show_loadings = TRUE,
       show_significance = TRUE)
  
  structural_model <- relationships(
    paths(from = c("OMDT","WITI","CBDR","HRCS","QAAD",
                   "TDR","APDL","AUDT","ASTL","CSLE"),
          to = "AIST")
  )
  plot(boot_model, layout = "tree")
  