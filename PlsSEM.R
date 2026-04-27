# ============================================================
# PLS-SEM Analysis using SEMinR
# Dataset: Assignment_Bama_Sir.xlsx
# ============================================================

# ── 1. Install & Load Packages ──────────────────────────────
if (!requireNamespace("seminr",    quietly = TRUE)) install.packages("seminr")
if (!requireNamespace("readxl",    quietly = TRUE)) install.packages("readxl")
if (!requireNamespace("dplyr",     quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("ggplot2",   quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("corrplot",  quietly = TRUE)) install.packages("corrplot")

library(seminr)
library(readxl)
library(dplyr)
library(ggplot2)
library(corrplot)

# ── 2. Load & Prepare Data ──────────────────────────────────
# Read the Excel file (data starts at row 4, row 3 = variable names)
raw <- read_excel("Assignment_Bama_Sir.xlsx", col_names = FALSE)

# Row 3 contains variable codes; rows 4+ are data
var_names <- as.character(raw[3, ])          # variable codes
data_raw  <- raw[4:nrow(raw), ]              # actual responses

colnames(data_raw) <- var_names

# Keep only Likert-scale / numeric indicator columns
# (drop KD1=Year, KD2=Product type, KD3=Qualification – these are categorical)
indicators_to_use <- c(
  "KD4","KD5","KD6","KD8",          # Buy Process, Demand Planning & Procurement
  "KD9","KD10",                      # Current Operational Process / Legacy Machines
  "KE1","KE2","KE3",                 # Enabler: Affordable Digital Technologies
  "KD11","KD12","KD13","KD14","KD15",# Owner's Viewpoints on Automation & Digitalization
  "KO1","KO2","KO3","KO4",           # Key Outcome: Growth & Efficiency
  "KO5","KO6","KO7",                 # Key Outcome (continued)
  "KE4","KE5","KE6",                 # Enabler: Certification & Standardization
  "KD16","KD17","KD18","KD19","KD20","KD21", # Financial Challenges
  "KD22","KD23","KD24",              # Admin & Operational Challenges
  "KE7","KE8","KE9",                 # Enabler: Engaging Local Hire
  "KD25","KD26","KD27","KD28"        # Skill Gap & Workforce Management
)

df <- data_raw[, indicators_to_use]

# Convert all to numeric
df <- df %>% mutate(across(everything(), as.numeric))

# Remove rows with all NAs
df <- df[rowSums(is.na(df)) < ncol(df), ]

# Optional: mean-impute remaining NAs (for demonstration)
df <- df %>% mutate(across(everything(), ~ ifelse(is.na(.), mean(., na.rm = TRUE), .)))

cat("Dataset dimensions after cleaning:", nrow(df), "rows x", ncol(df), "columns\n")

# ── 3. Descriptive Statistics ───────────────────────────────
cat("\n--- Descriptive Statistics ---\n")
print(summary(df))

# ── 4. Define Measurement Model ─────────────────────────────
# Constructs are defined as reflective (most common in PLS-SEM surveys).
# Adjust to composite() / composite_formative() if constructs are formative.

mm <- constructs(
  # KEY DIMENSIONS (Exogenous / Independent constructs)
  composite("BuyProcess",      multi_items("KD", c(4,5,6,8))),
  composite("OperationalProc", multi_items("KD", c(9,10))),
  composite("OwnerViewpoint",  multi_items("KD", c(11,12,13,14,15))),
  composite("FinancialChallenge", multi_items("KD", c(16,17,18,19,20,21))),
  composite("AdminChallenge",  multi_items("KD", c(22,23,24))),
  composite("SkillGap",        multi_items("KD", c(25,26,27,28))),
  
  # KEY ENABLERS (Mediating / Exogenous constructs)
  composite("DigitalTech",     multi_items("KE", c(1,2,3))),
  composite("CertStandard",    multi_items("KE", c(4,5,6))),
  composite("LocalHire",       multi_items("KE", c(7,8,9))),
  
  # KEY OUTCOME (Endogenous / Dependent construct)
  composite("GrowthEfficiency", multi_items("KO", c(1,2,3,4,5,6,7)))
)

# ── 5. Define Structural Model ──────────────────────────────
# Hypothesised paths:
#   Key Dimensions  →  Key Outcome (direct effects)
#   Key Enablers    →  Key Outcome (enabling effects)
#   Key Dimensions  →  Key Enablers (dimensions drive enabler adoption)

sm <- relationships(
  # Direct effects of Key Dimensions on Growth & Efficiency
  paths(from = c("BuyProcess","OperationalProc","OwnerViewpoint",
                 "FinancialChallenge","AdminChallenge","SkillGap"),
        to   = "GrowthEfficiency"),
  
  # Effects of Key Enablers on Growth & Efficiency
  paths(from = c("DigitalTech","CertStandard","LocalHire"),
        to   = "GrowthEfficiency"),
  
  # Key Dimensions influencing Enablers (antecedents)
  paths(from = c("BuyProcess","OperationalProc","OwnerViewpoint"),
        to   = "DigitalTech"),
  
  paths(from = c("FinancialChallenge","AdminChallenge"),
        to   = "CertStandard"),
  
  paths(from = c("SkillGap","AdminChallenge"),
        to   = "LocalHire")
)

# ── 6. Estimate PLS-SEM Model ───────────────────────────────
set.seed(123)
pls_model <- estimate_pls(
  data              = df,
  measurement_model = mm,
  structural_model  = sm,
  inner_weights     = path_weighting   # path weighting scheme (recommended)
)

cat("\n--- PLS Model Summary ---\n")
print(summary(pls_model))

# ── 7. Bootstrap for Significance Testing ───────────────────
set.seed(123)
boot_model <- bootstrap_model(
  seminr_model = pls_model,
  nboot        = 1000,
  cores        = 2          # adjust based on your machine
)

cat("\n--- Bootstrap Summary ---\n")
boot_summary <- summary(boot_model)
print(boot_summary)

# ── 8. Measurement Model Evaluation ─────────────────────────
pls_summary <- summary(pls_model)

cat("\n============================================================\n")
cat("MEASUREMENT MODEL EVALUATION\n")
cat("============================================================\n")

# 8a. Loadings
cat("\n--- Indicator Loadings ---\n")
print(pls_summary$loadings)

# 8b. Reliability & Validity
cat("\n--- Reliability (rhoA, Composite Reliability, AVE) ---\n")
print(pls_summary$reliability)

# 8c. HTMT (Discriminant Validity)
cat("\n--- HTMT Ratios (Discriminant Validity – should be < 0.85) ---\n")
print(pls_summary$validity$htmt)

# 8d. VIF (Collinearity)
cat("\n--- Inner VIF (should be < 5) ---\n")
print(pls_summary$vif_antecedents)

# ── 9. Structural Model Evaluation ──────────────────────────
cat("\n============================================================\n")
cat("STRUCTURAL MODEL EVALUATION\n")
cat("============================================================\n")

# 9a. Path Coefficients with bootstrap CIs
cat("\n--- Path Coefficients (Bootstrapped) ---\n")
print(boot_summary$bootstrapped_paths)

# 9b. R-squared
cat("\n--- R-squared Values ---\n")
print(pls_summary$paths)

# 9c. Effect sizes (f²)
cat("\n--- Effect Sizes (f²) ---\n")
print(pls_summary$fSquare)

# 9d. Predictive Relevance (Q²) via blindfolding
set.seed(123)
predict_model <- predict_pls(
  model         = pls_model,
  technique     = predict_DA,
  noFolds       = 10
)
cat("\n--- Predictive Relevance (Q² – should be > 0) ---\n")
print(summary(predict_model))

# ── 10. Visualise Results ───────────────────────────────────

# 10a. Plot the PLS path model
plot(pls_model,
     title = "PLS-SEM Path Model – SME Digital Transformation")

# 10b. Bootstrapped path coefficients bar chart
boot_paths_df <- as.data.frame(boot_summary$bootstrapped_paths)
boot_paths_df$Path <- rownames(boot_paths_df)

ggplot(boot_paths_df,
       aes(x = reorder(Path, `Bootstrap Mean`),
           y = `Bootstrap Mean`,
           fill = ifelse(`T Stat.` > 1.96, "Significant (p<0.05)", "Not Significant"))) +
  geom_col() +
  geom_errorbar(aes(ymin = `2.5% CI`, ymax = `97.5% CI`), width = 0.3) +
  coord_flip() +
  scale_fill_manual(values = c("Significant (p<0.05)" = "#2E86AB",
                               "Not Significant"      = "#A8DADC")) +
  labs(title    = "Bootstrapped Path Coefficients (95% CI)",
       subtitle = "PLS-SEM – SME Digital Transformation Study",
       x        = "Path",
       y        = "Path Coefficient",
       fill     = "Significance") +
  theme_minimal(base_size = 12)

ggsave("PLS_SEM_Path_Coefficients.png", width = 10, height = 7, dpi = 300)
cat("\nPath coefficient plot saved as 'PLS_SEM_Path_Coefficients.png'\n")

# 10c. Loadings heatmap
loadings_mat <- pls_summary$loadings
corrplot(loadings_mat,
         method  = "color",
         is.corr = FALSE,
         tl.cex  = 0.7,
         title   = "Indicator Loadings Heatmap",
         mar     = c(0,0,2,0))

# ── 11. Common Method Bias Check (Harman's Single Factor) ───
cat("\n============================================================\n")
cat("COMMON METHOD BIAS – Harman's Single Factor Test\n")
cat("============================================================\n")
pca_result <- prcomp(df, scale. = TRUE)
variance_explained <- pca_result$sdev^2 / sum(pca_result$sdev^2) * 100
cat(sprintf("Variance explained by first factor: %.2f%%\n", variance_explained[1]))
cat("(CMB concern if > 50%)\n")

# ── 12. Mediation Analysis ───────────────────────────────────
# Example: Does DigitalTech mediate BuyProcess → GrowthEfficiency?
cat("\n============================================================\n")
cat("MEDIATION ANALYSIS (Specific Indirect Effects)\n")
cat("============================================================\n")
cat("\n--- Bootstrapped Indirect Effects ---\n")
print(boot_summary$bootstrapped_indirect_effects)

# ── 13. Export Key Results to CSV ───────────────────────────
write.csv(as.data.frame(pls_summary$loadings),
          "PLS_Loadings.csv", row.names = TRUE)

write.csv(as.data.frame(pls_summary$reliability),
          "PLS_Reliability.csv", row.names = TRUE)

write.csv(as.data.frame(boot_summary$bootstrapped_paths),
          "PLS_BootstrappedPaths.csv", row.names = TRUE)

write.csv(as.data.frame(pls_summary$validity$htmt),
          "PLS_HTMT.csv", row.names = TRUE)

cat("\n✔ Analysis complete. CSV outputs saved.\n")
cat("Files: PLS_Loadings.csv | PLS_Reliability.csv | PLS_BootstrappedPaths.csv | PLS_HTMT.csv\n")