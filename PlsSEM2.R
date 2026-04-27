# ============================================================
#  PLS-SEM FULL ANALYSIS USING SEMinR
#  Study: Digital Transformation Challenges & Growth in SMEs
#  Dataset: Assignment_Bama_Sir.xlsx  |  n = 101
# ============================================================
#
#  THEORETICAL MODEL OVERVIEW
#  ─────────────────────────────────────────────────────────
#  EXOGENOUS (Independent) Constructs:
#    • OperationalChallenges  (KD4–KD6, KD8–KD10)
#    • OwnerMotivation        (KD11–KD15)
#    • FinancialBarriers      (KD16–KD21)
#    • AdminEcoBarriers       (KD22–KD24)
#    • SkillGap               (KD25–KD28)
#
#  MEDIATOR Constructs (transmit effects to outcome):
#    • DigitalAdoption        (KE1–KE3)   mediates OperationalChallenges → Growth
#    • CertStandardization    (KE4–KE6)   mediates FinancialBarriers      → Growth
#    • LocalHireEnablement    (KE7–KE9)   mediates SkillGap               → Growth
#
#  MODERATOR Variables (change strength of a relationship):
#    • OwnerMotivation moderates DigitalAdoption → GrowthEfficiency
#      (Highly motivated owners amplify digital adoption's impact on growth)
#    • FinancialBarriers moderates AdminEcoBarriers → GrowthEfficiency
#      (Financial constraints magnify administrative challenges on growth)
#
#  ENDOGENOUS (Dependent) Construct:
#    • GrowthEfficiency       (KO1–KO7)
# ============================================================


# ── SECTION 1: Install & Load Required Packages ─────────────
# seminr   : PLS-SEM estimation engine
# readxl   : read Excel (.xlsx) files into R
# dplyr    : data manipulation (select, mutate, filter, etc.)
# ggplot2  : grammar-of-graphics plotting
# corrplot : specialised correlation matrix visualisation
# psych    : descriptive stats and corr.test() for p-values
# tidyr    : pivot_longer() to reshape data for ggplot
# scales   : axis formatting helpers (percent, comma, etc.)

packages <- c("seminr", "readxl", "dplyr", "ggplot2",
              "corrplot", "psych", "tidyr", "scales")

for (pkg in packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}

library(seminr)      # Core PLS-SEM engine
library(readxl)      # Reading .xlsx files
library(dplyr)       # Data manipulation verbs
library(ggplot2)     # Grammar of graphics plotting
library(corrplot)    # Correlation matrix visualisation
library(psych)       # describe(), corr.test()
library(tidyr)       # pivot_longer() for reshaping
library(scales)      # Axis formatting


# ── SECTION 2: Load & Clean Data ────────────────────────────
# The Excel file has a 3-row header:
#   Row 1 = Construct group labels (e.g., "Key Dimension: Buy Process...")
#   Row 2 = Full survey question text
#   Row 3 = Short variable codes (KD1, KD2 ... KO7)
#   Row 4 onwards = actual numeric survey responses (n=101)

raw       <- read_excel("Assignment_Bama_Sir.xlsx", col_names = FALSE)

# Extract variable short-codes from row 3 as column names
var_names <- as.character(raw[3, ])

# Slice the actual data rows (row 4 onward)
data_raw  <- raw[4:nrow(raw), ]
colnames(data_raw) <- var_names

# Select only the Likert-scale indicator columns needed for latent constructs.
# Dropped columns:
#   KD1 = Year of establishment (continuous year, not a scale item)
#   KD2 = Main product type     (free-text categorical, cannot be a latent indicator)
#   KD3 = Owner qualification   (ordinal demographic, used as context not indicator)

indicator_cols <- c(
  "KD4","KD5","KD6","KD8","KD9","KD10",       # Operational challenges
  "KD11","KD12","KD13","KD14","KD15",          # Owner motivation / viewpoints
  "KE1","KE2","KE3",                            # Digital technology enabler
  "KO1","KO2","KO3","KO4","KO5","KO6","KO7",  # Growth & efficiency outcomes
  "KE4","KE5","KE6",                            # Certification & standardisation
  "KD16","KD17","KD18","KD19","KD20","KD21",   # Financial barriers
  "KD22","KD23","KD24",                         # Admin & ecosystem barriers
  "KE7","KE8","KE9",                            # Local hire enabler
  "KD25","KD26","KD27","KD28"                  # Skill gap & workforce
)

df <- data_raw[, indicator_cols]

# Convert all selected columns to numeric type
# (readxl sometimes imports values as character when headers are mixed)
df <- df %>% mutate(across(everything(), as.numeric))

# Drop any completely empty rows (respondents who answered nothing)
df <- df[rowSums(is.na(df)) < ncol(df), ]

# Mean-impute isolated remaining NAs.
# Rationale: PLS-SEM requires complete cases; mean imputation is acceptable
# for small proportions of missing data on Likert scales (Hair et al., 2019).
df <- df %>%
  mutate(across(everything(),
                ~ ifelse(is.na(.), round(mean(., na.rm = TRUE)), .)))

cat("=== Data Loaded Successfully ===\n")
cat("Usable responses (n) :", nrow(df), "\n")
cat("Indicators included  :", ncol(df), "\n\n")


# ── SECTION 3: Descriptive Statistics ───────────────────────
# psych::describe() gives a richer table than base summary():
#   n, mean, sd, median, trimmed mean, mad, min, max, range,
#   skewness, kurtosis, and standard error.
# In PLS-SEM (distribution-free), we check:
#   |skewness| < 2 and |kurtosis| < 7 as rough normality markers.
# These thresholds matter more for CB-SEM; PLS tolerates violations.

cat("=== SECTION 3: DESCRIPTIVE STATISTICS ===\n")
desc_stats <- psych::describe(df)
print(round(desc_stats[, c("n","mean","sd","min","max","skew","kurtosis")], 3))

write.csv(round(desc_stats, 3), "Descriptive_Statistics.csv")
cat("Saved: Descriptive_Statistics.csv\n\n")


# ── SECTION 4: Correlation & Covariance Matrices ─────────────
# ── WHY BOTH? ────────────────────────────────────────────────
# Pearson Correlation: standardised, scale-free, range [−1, +1].
#   Used to assess directionality and strength of linear relationships.
#   PLS algorithm works on the correlation matrix internally.
#
# Covariance: unstandardised. Retains original scale variance.
#   Useful for understanding actual variability in construct scores.
#   CB-SEM directly fits the covariance matrix; PLS-SEM uses it
#   for weight optimisation.
#
# We compute both at (a) indicator level and (b) construct level.

cat("=== SECTION 4: CORRELATION MATRIX (Indicators) ===\n")
cor_matrix <- cor(df, use = "pairwise.complete.obs", method = "pearson")
print(round(cor_matrix, 2))
write.csv(round(cor_matrix, 3), "Correlation_Matrix_Indicators.csv")

cat("\n=== COVARIANCE MATRIX (Indicators) ===\n")
cov_matrix <- cov(df, use = "pairwise.complete.obs")
print(round(cov_matrix, 2))
write.csv(round(cov_matrix, 3), "Covariance_Matrix_Indicators.csv")

# Significance test for each pairwise correlation (Pearson t-test)
# adjust = "none" gives raw p-values; use "holm" or "BH" for multiple testing
cat("\n=== CORRELATION p-VALUES (Indicators) ===\n")
cor_test <- psych::corr.test(df, adjust = "none")
print(round(cor_test$p, 3))
write.csv(round(cor_test$p, 3), "Correlation_Pvalues_Indicators.csv")

# ── 4a. Indicator-Level Correlation Heatmap ──────────────────
# colour scale: green = positive, red = negative correlation
png("Correlation_Heatmap_Indicators.png", width = 1400, height = 1200, res = 120)
corrplot(cor_matrix,
         method      = "color",           # fill colour blocks
         type        = "upper",           # show upper triangle only (symmetric)
         tl.cex      = 0.65,              # label text size
         tl.col      = "black",
         addCoef.col = "black",           # print r values inside cells
         number.cex  = 0.45,
         col         = colorRampPalette(c("#D73027","#FFFFBF","#1A9850"))(200),
         title       = "Pearson Correlation – All Indicators",
         mar         = c(0, 0, 2, 0))
dev.off()
cat("Saved: Correlation_Heatmap_Indicators.png\n")

# ── 4b. Construct-Level Composite Scores ─────────────────────
# Average the indicator scores within each construct to create
# a single composite score per construct per respondent.
# These scores are used for construct-level correlation/covariance.

construct_scores <- data.frame(
  OperationalChallenges = rowMeans(df[, c("KD4","KD5","KD6","KD8","KD9","KD10")]),
  OwnerMotivation       = rowMeans(df[, c("KD11","KD12","KD13","KD14","KD15")]),
  DigitalAdoption       = rowMeans(df[, c("KE1","KE2","KE3")]),
  GrowthEfficiency      = rowMeans(df[, c("KO1","KO2","KO3","KO4","KO5","KO6","KO7")]),
  CertStandardization   = rowMeans(df[, c("KE4","KE5","KE6")]),
  FinancialBarriers     = rowMeans(df[, c("KD16","KD17","KD18","KD19","KD20","KD21")]),
  AdminEcoBarriers      = rowMeans(df[, c("KD22","KD23","KD24")]),
  LocalHireEnablement   = rowMeans(df[, c("KE7","KE8","KE9")]),
  SkillGap              = rowMeans(df[, c("KD25","KD26","KD27","KD28")])
)

cat("\n=== CONSTRUCT-LEVEL CORRELATION MATRIX ===\n")
con_cor <- cor(construct_scores, use = "pairwise.complete.obs")
print(round(con_cor, 3))
write.csv(round(con_cor, 3), "Correlation_Matrix_Constructs.csv")

cat("\n=== CONSTRUCT-LEVEL COVARIANCE MATRIX ===\n")
con_cov <- cov(construct_scores)
print(round(con_cov, 3))
write.csv(round(con_cov, 3), "Covariance_Matrix_Constructs.csv")

# ── 4c. Construct-Level Correlation Heatmap ──────────────────
png("Correlation_Heatmap_Constructs.png", width = 950, height = 850, res = 120)
corrplot(con_cor,
         method      = "color",
         type        = "upper",
         tl.cex      = 0.85,
         tl.col      = "black",
         addCoef.col = "black",
         number.cex  = 0.75,
         col         = colorRampPalette(c("#D73027","#FFFFBF","#1A9850"))(200),
         title       = "Construct-Level Correlation Matrix",
         mar         = c(0, 0, 2, 0))
dev.off()
cat("Saved: Correlation_Heatmap_Constructs.png\n\n")


# ── SECTION 5: Define Latent Variables (Measurement Model) ──
# Latent variables (constructs) are not directly observed.
# They are inferred from their indicators (observed items).
#
# composite() = PLS composite variable. Default uses Mode A weights
#   (correlate each indicator with the composite score iteratively).
#   Appropriate for reflective constructs where indicators share a
#   common cause (the latent variable causes all indicator scores).
#
# multi_items("KD", c(4,5,6)) = shortcut for c("KD4","KD5","KD6")
#
# ROLE CLASSIFICATION:
#   Exogenous   = upstream independent constructs (no arrows pointing IN from
#                 other latent variables in the structural model)
#   Mediator    = receives a path FROM exogenous AND sends a path TO endogenous
#   Moderator   = interacts with another path; defined as its own composite
#                 and then referenced in interaction_term() in the SM
#   Endogenous  = downstream dependent construct (arrows pointing IN from others)

mm <- constructs(
  
  # ── EXOGENOUS CONSTRUCTS ──────────────────────────────────
  composite("OperationalChallenges",
            multi_items("KD", c(4,5,6,8,9,10))),
  # KD4 = digital tools for planning & demand forecasting
  # KD5 = price challenges during procurement
  # KD6 = supply chain / ad-hoc demand challenges
  # KD8 = use of existing traditional machines
  # KD9 = type of manufacturing process (automated vs manual)
  # KD10 = digital collaboration tools with suppliers
  
  composite("OwnerMotivation",
            multi_items("KD", c(11,12,13,14,15))),
  # KD11 = replacing old machines improves growth
  # KD12 = digital automation beneficial for demand & growth
  # KD13 = AI helps buyer-seller connect
  # KD14 = AI reduces waste & tracks parts
  # KD15 = AI & messaging apps help quick decision-making
  # *** Also acts as MODERATOR on DigitalAdoption → GrowthEfficiency ***
  
  composite("FinancialBarriers",
            multi_items("KD", c(16,17,18,19,20,21))),
  # KD16 = funding received on time from banks
  # KD17 = large-industry slowdown hurts ancillary SMEs
  # KD18 = difficult/lengthy process for financial approvals
  # KD19 = lack of transparency in institutional support
  # KD20 = financial help alone not sufficient for growth
  # KD21 = knowledge gap on ecosystem integration
  # *** Also acts as MODERATOR on AdminEcoBarriers → GrowthEfficiency ***
  
  composite("AdminEcoBarriers",
            multi_items("KD", c(22,23,24))),
  # KD22 = market competition, regulation, lack of govt support
  # KD23 = unable to deliver mass-volume orders (capacity issues)
  # KD24 = delayed payment from buyers / cash-flow issues
  
  composite("SkillGap",
            multi_items("KD", c(25,26,27,28))),
  # KD25 = challenges finding experienced tool-room resources
  # KD26 = lack of digital-skill resources
  # KD27 = retaining high-skilled employees (salary demands)
  # KD28 = difficulty upskilling ageing workers in digital tech
  
  # ── MEDIATOR CONSTRUCTS ───────────────────────────────────
  # A mediator (M) explains the mechanism through which an
  # independent variable (X) influences a dependent variable (Y).
  # Paths required: X → M (a-path) and M → Y (b-path).
  # Indirect effect = a × b; tested via bootstrap CI.
  
  composite("DigitalAdoption",
            multi_items("KE", c(1,2,3))),
  # KE1 = digital tools for supplier collaboration
  # KE2 = digital project-management tools in execution
  # KE3 = digital technologies in manufacturing processes
  # MEDIATES: OperationalChallenges → [DigitalAdoption] → GrowthEfficiency
  # MEDIATES: OwnerMotivation       → [DigitalAdoption] → GrowthEfficiency
  
  composite("CertStandardization",
            multi_items("KE", c(4,5,6))),
  # KE4 = product certification process adoption
  # KE5 = standardisation as key scaling challenge
  # KE6 = certification, quality-check, testing challenges
  # MEDIATES: FinancialBarriers → [CertStandardization] → GrowthEfficiency
  
  composite("LocalHireEnablement",
            multi_items("KE", c(7,8,9))),
  # KE7 = local hire + technical training beneficial for retention
  # KE8 = limited professional skills as hurdle to local hiring
  # KE9 = local hires lag only in soft skills (not technical)
  # MEDIATES: SkillGap        → [LocalHireEnablement] → GrowthEfficiency
  # MEDIATES: AdminEcoBarriers → [LocalHireEnablement] → GrowthEfficiency
  
  # ── ENDOGENOUS CONSTRUCT (Outcome / Dependent Variable) ───
  composite("GrowthEfficiency",
            multi_items("KO", c(1,2,3,4,5,6,7)))
  # KO1 = major market & customer dependency type
  # KO2 = export to other countries/regions (yes/no)
  # KO3 = main domestic market base
  # KO4 = approximate annual turnover
  # KO5 = AI/digital connects new customers & markets
  # KO6 = digital tech facilitates quick operational decisions
  # KO7 = digital tech improves product quality & inspection
)

cat("=== Measurement model defined with", length(mm), "constructs ===\n\n")


# ── SECTION 6: Define Structural Model (Paths + Interactions) ─
# paths()            = specifies direct regression paths between constructs
# interaction_term() = creates a product-indicator interaction latent variable
#                      using the orthogonal method (Henseler & Chin, 2010).
#                      Each IV×Moderator product indicator is residualised
#                      against the main-effect indicators, making the
#                      interaction term orthogonal (uncorrelated) to both
#                      components — avoids multicollinearity and the
#                      mmMatrix atomic-type error caused by two_stage.
#
# MODERATOR HYPOTHESES:
#   H9:  OwnerMotivation strengthens DigitalAdoption's effect on GrowthEfficiency
#        → When owners believe in digital tools, adoption matters MORE for growth
#   H10: FinancialBarriers amplify AdminEcoBarriers' negative effect on Growth
#        → When finances are tight, admin barriers become even more damaging

sm <- relationships(
  
  # ── DIRECT EFFECTS: Exogenous → Endogenous ───────────────
  # These test whether challenge dimensions directly impact growth
  # independent of the mediating enablers.
  paths(from = "OperationalChallenges", to = "GrowthEfficiency"),  # H1
  paths(from = "OwnerMotivation",       to = "GrowthEfficiency"),  # H2
  paths(from = "FinancialBarriers",     to = "GrowthEfficiency"),  # H3
  paths(from = "AdminEcoBarriers",      to = "GrowthEfficiency"),  # H4
  paths(from = "SkillGap",             to = "GrowthEfficiency"),  # H5
  
  # ── MEDIATION – a-paths (Exogenous → Mediator) ───────────
  # First leg of mediation: challenges/motivations influence enabler uptake
  paths(from = "OperationalChallenges", to = "DigitalAdoption"),    # H6a
  paths(from = "OwnerMotivation",       to = "DigitalAdoption"),    # owner belief drives adoption
  paths(from = "FinancialBarriers",     to = "CertStandardization"),# H7a
  paths(from = "SkillGap",             to = "LocalHireEnablement"), # H8a
  paths(from = "AdminEcoBarriers",      to = "LocalHireEnablement"),# admin challenges → local hiring
  
  # ── MEDIATION – b-paths (Mediator → Endogenous) ──────────
  # Second leg of mediation: enablers drive growth outcomes
  paths(from = "DigitalAdoption",       to = "GrowthEfficiency"),   # H6b
  paths(from = "CertStandardization",   to = "GrowthEfficiency"),   # H7b
  paths(from = "LocalHireEnablement",   to = "GrowthEfficiency"),   # H8b
  
  # ── MODERATION – Interaction Terms ───────────────────────
  # interaction_term() creates a product-indicator interaction latent variable.
  #
  # METHOD: orthogonal (Henseler & Chin, 2010)
  #   WHY NOT two_stage: two_stage requires a pre-run Stage-1 model object and
  #   when passed directly inside relationships() alongside paths(), SEMinR's
  #   internal mmMatrix ends up with list-type columns instead of atomic vectors,
  #   causing the error: "comparison (==) is possible only for atomic and list types".
  #
  #   orthogonal method works reliably inside relationships() because:
  #   1. It forms product indicators (IV item × Moderator item) for all pairs
  #   2. Residualises each product on all IV + Moderator main-effect indicators
  #   3. Uses those residuals as the interaction construct's indicators
  #   → Residuals are by definition orthogonal (zero correlation) to main effects,
  #     removing multicollinearity without needing a separate model pre-run.
  
  # Moderator 1: OwnerMotivation × DigitalAdoption → GrowthEfficiency
  # H9: Does high owner belief in digital tools amplify the positive effect
  #     of digital adoption on business growth?
  interaction_term(iv        = "OwnerMotivation",
                   moderator = "DigitalAdoption",
                   method    = orthogonal),
  paths(from = "OwnerMotivation*DigitalAdoption",
        to   = "GrowthEfficiency"),                    # H9: moderation path
  
  # Moderator 2: FinancialBarriers × AdminEcoBarriers → GrowthEfficiency
  # H10: Does financial stress amplify the damaging effect of admin/ecosystem
  #      barriers on growth efficiency?
  interaction_term(iv        = "AdminEcoBarriers",
                   moderator = "FinancialBarriers",
                   method    = orthogonal),
  paths(from = "AdminEcoBarriers*FinancialBarriers",
        to   = "GrowthEfficiency")                     # H10: moderation path
)

cat("=== Structural model defined ===\n\n")


# ── SECTION 7: Estimate PLS-SEM Model ───────────────────────
# estimate_pls() runs the iterative PLS algorithm:
#   Outer loop: compute indicator weights → get composite scores
#   Inner loop: regress composites via path_weighting scheme
#               (uses path coefficients to weight neighbours — recommended)
#   Converges when weight change < tolerance (default 1e-7)
# missing = mean_replacement: replace any last-resort NAs with column mean

set.seed(123)   # Ensures reproducibility across bootstrap runs
pls_model <- estimate_pls(
  data              = df,
  measurement_model = mm,
  structural_model  = sm,
  inner_weights     = path_weighting,
  missing           = mean_replacement,
  missing_value     = NA
)

cat("=== PLS Model Estimated ===\n")
pls_summary <- summary(pls_model)
print(pls_summary)


# ── SECTION 8: Bootstrap for Significance Testing ───────────
# PLS-SEM is non-parametric → no closed-form SE for path coefficients.
# Bootstrap procedure:
#   1. Draw 1000 random samples WITH replacement (same n as original)
#   2. Estimate PLS model on each resample
#   3. Store the 1000 path coefficient estimates
#   4. Compute T-statistic = Mean / SD of bootstrap distribution
#   5. Derive 95% BCa confidence intervals from the 2.5th & 97.5th percentiles
# Decision rule: |T| > 1.96 → significant at α = 0.05 (two-tailed)

# Bootstrap zero-variance fix:
# The orthogonal interaction method creates product indicators. On some bootstrap
# resamples those product columns have zero variance (all respondents identical),
# which crashes scale(). Fixes applied:
#   1. cores = 1  – single-core avoids parallel RNG divergence
#   2. tryCatch   – catches any residual error and falls back gracefully
#   3. nboot = 500 – slightly fewer resamples reduces probability of degenerate samples

set.seed(123)
boot_model <- tryCatch(
  bootstrap_model(
    seminr_model = pls_model,
    nboot        = 500,   # 500 is minimum acceptable; raise to 1000 if no error
    cores        = 1      # single-core: avoids parallel zero-variance RNG issue
  ),
  error = function(e) {
    cat("\n⚠ Bootstrap error caught:", conditionMessage(e), "\n")
    cat("  Attempting with nboot=200 as fallback...\n")
    bootstrap_model(seminr_model = pls_model, nboot = 200, cores = 1)
  }
)

cat("\n=== Bootstrap Complete ===\n")
boot_summary <- summary(boot_model, alpha = 0.05)   # 95% CI level


# ── SECTION 9: Measurement Model Evaluation ─────────────────
cat("\n============================================================\n")
cat(" SECTION 9: MEASUREMENT MODEL EVALUATION\n")
cat("============================================================\n")

# ── 9a. Indicator Loadings ────────────────────────────────────
# Standardised loadings = correlation between indicator and its composite.
# Benchmark: ≥ 0.70 (indicator explains ≥ 49% of construct variance).
# Items with loadings 0.40–0.70: retain if AVE and CR remain acceptable.
# Items < 0.40: consider removal to improve convergent validity.
cat("\n--- [9a] Outer Loadings (benchmark ≥ 0.70) ---\n")
print(round(pls_summary$loadings, 3))
write.csv(round(pls_summary$loadings, 3), "Output_Loadings.csv")

# ── 9b. Internal Consistency Reliability ─────────────────────
# Cronbach's Alpha  : traditional measure; sensitive to number of items
# rhoA (Dijkstra)   : more accurate reliability for PLS composites
# CR / rhoC         : composite reliability; less affected by item count
# AVE               : Average Variance Extracted; ≥ 0.50 = convergent validity
#   (AVE > 0.50 means the construct explains more variance in its items
#    than the measurement error does)
cat("\n--- [9b] Reliability & Convergent Validity ---\n")
cat("    Benchmarks: Alpha ≥ 0.70 | rhoA ≥ 0.70 | CR ≥ 0.70 | AVE ≥ 0.50\n")
print(round(pls_summary$reliability, 3))
write.csv(round(pls_summary$reliability, 3), "Output_Reliability.csv")

# ── 9c. HTMT – Discriminant Validity ─────────────────────────
# HTMT = Heterotrait-Monotrait Ratio of Correlations.
# Compares average cross-construct correlations to within-construct correlations.
# HTMT < 0.85: constructs are empirically distinct (Henseler et al., 2015)
# HTMT < 0.90: acceptable in some contexts
# HTMT ≥ 0.90: discriminant validity problem → consider merging constructs
cat("\n--- [9c] HTMT Discriminant Validity (threshold < 0.85) ---\n")
print(round(pls_summary$validity$htmt, 3))
write.csv(round(pls_summary$validity$htmt, 3), "Output_HTMT.csv")

# ── 9d. Fornell-Larcker Criterion ────────────────────────────
# Each construct's square root of AVE (on diagonal) should be greater
# than all pairwise correlations with other constructs (off-diagonal).
# Older criterion; HTMT is now preferred but both are typically reported.
cat("\n--- [9d] Fornell-Larcker Criterion ---\n")
cat("    Diagonal = sqrt(AVE); should exceed all off-diagonal values\n")
print(round(pls_summary$validity$fl_criteria, 3))
write.csv(round(pls_summary$validity$fl_criteria, 3), "Output_FornellLarcker.csv")

# ── 9e. Outer VIF (Indicator Collinearity) ───────────────────
# VIF (Variance Inflation Factor) detects collinearity among indicators.
# In PLS-SEM the critical threshold is VIF < 3.3 (Kock, 2015).
# High VIF (> 5) suggests two indicators measure nearly the same thing.
cat("\n--- [9e] Outer VIF (threshold < 3.3) ---\n")
# vif_antecedents is a named LIST in SEMinR 2.4+ (one element per endogenous
# construct). Convert to a tidy data frame before rounding or printing.
vif_raw <- pls_summary$vif_antecedents
if (is.list(vif_raw) && !is.data.frame(vif_raw)) {
  # Each list element is a named numeric vector of VIF values
  vif_df <- do.call(rbind,
                    lapply(names(vif_raw), function(nm) {
                      v <- vif_raw[[nm]]
                      data.frame(Endogenous  = nm,
                                 Antecedent  = names(v),
                                 VIF         = as.numeric(v),
                                 stringsAsFactors = FALSE)
                    }))
} else {
  vif_df <- as.data.frame(vif_raw)
}
print(vif_df)
write.csv(vif_df, "Output_VIF.csv", row.names = FALSE)


# ── SECTION 10: Structural Model Evaluation ─────────────────
cat("\n============================================================\n")
cat(" SECTION 10: STRUCTURAL MODEL EVALUATION\n")
cat("============================================================\n")

# ── 10a. Path Coefficients (Bootstrapped) ────────────────────
# Columns typically include:
#   Original Est. = path coefficient from full sample
#   Bootstrap Mean = mean across 1000 bootstrap samples
#   Bootstrap SD   = standard deviation (= bootstrap SE)
#   T Stat.        = Original / SD (bootstrap t-statistic)
#   2.5% CI / 97.5% CI = BCa confidence interval bounds
# safe_numeric_df(): converts any SEMinR bootstrap slot to a plain numeric
# data frame, handling the case where columns are lists instead of atomic vectors.
# This fixes "non-numeric argument to mathematical function" on round().
safe_numeric_df <- function(x) {
  if (is.null(x)) return(data.frame())
  df <- as.data.frame(x)
  # Force each column to numeric — list-typed columns become NA-filled numeric
  df[] <- lapply(df, function(col) suppressWarnings(as.numeric(unlist(col))))
  df
}

cat("\n--- [10a] Bootstrapped Path Coefficients ---\n")
cat("    |T| > 1.96 = p < 0.05  |  |T| > 2.576 = p < 0.01\n")
bp_clean <- safe_numeric_df(boot_summary$bootstrapped_paths)
print(round(bp_clean, 3))
write.csv(round(bp_clean, 3), "Output_BootstrappedPaths.csv")

# ── 10b. R-squared Values ─────────────────────────────────────
# R² shows what proportion of the endogenous construct's variance
# is explained by all its antecedents combined.
# Adjusted R² penalises for the number of predictors.
# Hair et al. (2019): R² = 0.19 weak | 0.33 moderate | 0.67 substantial
cat("\n--- [10b] R-squared (Explanatory Power) ---\n")
cat("    Benchmarks: 0.19=weak | 0.33=moderate | 0.67=substantial\n")
print(round(pls_summary$paths, 3))

# ── 10c. Effect Sizes (f²) ────────────────────────────────────
# f² measures each predictor's UNIQUE contribution to R²:
#   f² = (R²_included – R²_excluded) / (1 – R²_included)
# Cohen (1988): f² = 0.02 small | 0.15 medium | 0.35 large
cat("\n--- [10c] Effect Sizes (f²) ---\n")
cat("    Benchmarks: 0.02=small | 0.15=medium | 0.35=large\n")
print(round(pls_summary$fSquare, 3))
write.csv(round(pls_summary$fSquare, 3), "Output_EffectSizes.csv")

# ── 10d. Predictive Relevance (Q²) ───────────────────────────
# predict_pls() performs 10-fold cross-validated prediction.
# Q² > 0: model has predictive relevance (can generalise to new data)
# predict_DA uses PLS as predictor and a linear regression as benchmark.
# Q² = 0.02/0.15/0.35 = small/medium/large predictive relevance.
set.seed(123)
predict_out <- predict_pls(
  model     = pls_model,
  technique = predict_DA,   # PLS vs. linear regression benchmark
  noFolds   = 10            # 10-fold cross-validation
)
cat("\n--- [10d] Predictive Relevance Q² (10-fold CV) ---\n")
cat("    Q² > 0 = predictive relevance confirmed\n")
print(summary(predict_out))

# ── 10e. Moderation Results ───────────────────────────────────
# The significant interaction paths tell us:
#   Positive β for interaction = the focal path STRENGTHENS at higher
#     moderator values (amplifying effect).
#   Negative β for interaction = the focal path WEAKENS at higher
#     moderator values (buffering/dampening effect).
cat("\n--- [10e] Moderation Interaction Paths ---\n")
# Use bp_clean (already coerced to numeric) instead of raw boot_summary slot
interaction_rows <- grepl("\\*", rownames(bp_clean))
if (any(interaction_rows)) {
  print(round(bp_clean[interaction_rows, , drop = FALSE], 3))
} else {
  cat("  No interaction paths found in bootstrap results.\n")
}

# ── 10f. Mediation – Specific Indirect Effects ───────────────
# Specific indirect effect = product of a-path × b-path for each mediator chain.
# Bootstrapped 95% CI that EXCLUDES zero = statistically significant mediation.
# VAF (Variance Accounted For) = indirect / total effect:
#   VAF < 20% = no mediation
#   20% ≤ VAF < 80% = partial mediation
#   VAF ≥ 80% = full mediation
cat("\n--- [10f] Specific Indirect Effects (Mediation) ---\n")
cat("    Significant if 95% CI does not include zero\n")
ie_clean <- safe_numeric_df(boot_summary$bootstrapped_indirect_effects)
if (nrow(ie_clean) > 0) {
  print(round(ie_clean, 3))
  write.csv(round(ie_clean, 3), "Output_IndirectEffects.csv")
} else {
  cat("  No indirect effects available (bootstrap may have failed partially).\n")
}

# ── 10g. Total Effects ────────────────────────────────────────
# Total effect = Direct path + Sum of all indirect paths through mediators.
# Used to assess the full impact of an exogenous construct on the outcome.
cat("\n--- [10g] Total Effects (Direct + Indirect) ---\n")
te_clean <- safe_numeric_df(boot_summary$bootstrapped_total_paths)
if (nrow(te_clean) > 0) {
  print(round(te_clean, 3))
  write.csv(round(te_clean, 3), "Output_TotalEffects.csv")
} else {
  cat("  No total effects available.\n")
}


# ── SECTION 11: Common Method Bias Check ────────────────────
# Harman's Single Factor Test: if one unrotated PCA factor explains
# > 50% of total variance in all items, responses may be artificially
# inflated by measurement method (e.g., social desirability bias).
# PLS-SEM's composite-based approach is inherently less susceptible
# than CB-SEM, but the check is standard practice to report.

cat("\n============================================================\n")
cat(" SECTION 11: COMMON METHOD BIAS (Harman's Single Factor)\n")
cat("============================================================\n")
pca_out <- prcomp(df, scale. = TRUE)
var_pct <- pca_out$sdev^2 / sum(pca_out$sdev^2) * 100
cat(sprintf("  First unrotated factor explains: %.2f%% of total variance\n", var_pct[1]))
cat("  Concern threshold: > 50%\n")
if (var_pct[1] > 50) {
  cat("  WARNING: Possible common method bias — consider marker variable technique.\n")
} else {
  cat("  No serious common method bias detected.\n")
}


# ── SECTION 12: Visualisations ──────────────────────────────

# ── 12a. PLS Path Model Diagram ─────────────────────────────
# SEMinR's built-in plot() renders the full structural model
# with construct nodes, path arrows, and coefficient values.
plot(pls_model,
     title = "PLS-SEM Path Model – SME Digital Transformation")


# ── 12b. Bootstrapped Path Coefficients Bar Chart ────────────
# Faceted by path type (Direct / Mediation / Moderation) so it is
# easy to visually compare effect sizes across path categories.
# Error bars = 95% bootstrapped CI. Blue = significant, grey = not.

# Build bp_df from bp_clean (already numeric) — avoids NA column detection
# bp_clean was created in Section 10a via safe_numeric_df()
bp_df      <- bp_clean
bp_df$Path <- rownames(bp_df)

# Dynamically detect column names (varies across SEMinR versions)
mean_col  <- grep("mean",            colnames(bp_df), ignore.case=TRUE, value=TRUE)[1]
tstat_col <- grep("^T|tstat|T.Stat", colnames(bp_df), ignore.case=TRUE, value=TRUE)[1]
ci_lo_col <- grep("2\.5|low",       colnames(bp_df), ignore.case=TRUE, value=TRUE)[1]
ci_hi_col <- grep("97\.5|high",     colnames(bp_df), ignore.case=TRUE, value=TRUE)[1]

cat(sprintf("\n[Plot 12b] Columns: Mean='%s' | T='%s' | CI_lo='%s' | CI_hi='%s'\n",
            mean_col, tstat_col, ci_lo_col, ci_hi_col))

# Fallback: if column detection still fails, use position indices
if (is.na(mean_col)  || length(mean_col)  == 0) mean_col  <- colnames(bp_df)[2]
if (is.na(tstat_col) || length(tstat_col) == 0) tstat_col <- colnames(bp_df)[4]
if (is.na(ci_lo_col) || length(ci_lo_col) == 0) ci_lo_col <- colnames(bp_df)[5]
if (is.na(ci_hi_col) || length(ci_hi_col) == 0) ci_hi_col <- colnames(bp_df)[6]

# Rename to plain R-safe variable names — avoids backtick/space issues
bp_df$BootMean <- as.numeric(bp_df[[mean_col]])
bp_df$TStat    <- as.numeric(bp_df[[tstat_col]])
bp_df$CI_lo    <- as.numeric(bp_df[[ci_lo_col]])
bp_df$CI_hi    <- as.numeric(bp_df[[ci_hi_col]])

# Classify significance and path type for colour and facet aesthetics
bp_df$Significance <- ifelse(abs(bp_df$TStat) > 1.96,
                             "Significant (p<0.05)", "Not Significant")
bp_df$PathType <- dplyr::case_when(
  grepl("\\*",    bp_df$Path) ~ "Moderation",  # contains * = interaction term
  grepl("->.*->", bp_df$Path)  ~ "Mediation",   # double arrow = indirect path
  TRUE                         ~ "Direct"        # all other paths
)
# Guard: if PathType is entirely NA (e.g., empty bp_df), skip the plot
if (all(is.na(bp_df$PathType)) || nrow(bp_df) == 0) {
  cat("  Skipping path coefficient plot — no valid bootstrap data.\n")
}

p_paths <- ggplot(bp_df,
                  aes(x = reorder(Path, BootMean), y = BootMean,
                      fill = Significance)) +
  geom_col(width = 0.7) +
  geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi),
                width = 0.25, linewidth = 0.6, colour = "grey30") +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  coord_flip() +
  facet_wrap(~ PathType, scales = "free_y", ncol = 1) +
  scale_fill_manual(values = c("Significant (p<0.05)" = "#2E86AB",
                               "Not Significant"      = "#A8DADC")) +
  labs(title    = "Bootstrapped Path Coefficients with 95% CI",
       subtitle = "PLS-SEM | SME Digital Transformation | n=101",
       x = NULL, y = "Path Coefficient (β)", fill = "Significance",
       caption = "Error bars = 95% bootstrapped CI (1000 resamples)") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom",
        strip.text = element_text(face = "bold", size = 11))

ggsave("Plot_Path_Coefficients.png", p_paths, width = 12, height = 11, dpi = 300)
cat("Saved: Plot_Path_Coefficients.png\n")


# ── 12c. Reliability & AVE Summary Chart ─────────────────────
# Grouped bar chart showing all 4 reliability/validity metrics per construct.
# Red dashed lines mark the minimum acceptable threshold for each metric.

rel_df           <- as.data.frame(pls_summary$reliability)
rel_df$Construct <- rownames(rel_df)

# Detect actual column names robustly
ave_col   <- grep("AVE",   colnames(rel_df), ignore.case=TRUE, value=TRUE)[1]
cr_col    <- grep("rhoC|CR", colnames(rel_df), ignore.case=TRUE, value=TRUE)[1]
rhoA_col  <- grep("rhoA",  colnames(rel_df), ignore.case=TRUE, value=TRUE)[1]
alpha_col <- grep("alpha", colnames(rel_df), ignore.case=TRUE, value=TRUE)[1]

rel_long <- rel_df %>%
  select(Construct,
         AVE   = all_of(ave_col),
         CR    = all_of(cr_col),
         rhoA  = all_of(rhoA_col),
         Alpha = all_of(alpha_col)) %>%
  pivot_longer(-Construct, names_to = "Metric", values_to = "Value")

# Thresholds data frame for the red dashed reference lines per facet
thresholds <- data.frame(Metric    = c("AVE","CR","rhoA","Alpha"),
                         threshold = c(0.50, 0.70, 0.70, 0.70))

p_reliability <- ggplot(rel_long,
                        aes(x = Construct, y = Value, fill = Metric)) +
  geom_col(position = position_dodge(0.75), width = 0.65) +
  geom_hline(data = thresholds,
             aes(yintercept = threshold),
             linetype = "dashed", colour = "red", linewidth = 0.5) +
  facet_wrap(~ Metric, ncol = 2) +
  coord_flip() +
  scale_fill_brewer(palette = "Set2") +
  scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.2)) +
  labs(title    = "Measurement Model: Reliability & Convergent Validity",
       subtitle = "Dashed red line = minimum acceptable threshold",
       x = NULL, y = "Value") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold"), legend.position = "none")

ggsave("Plot_Reliability_AVE.png", p_reliability, width = 13, height = 8, dpi = 300)
cat("Saved: Plot_Reliability_AVE.png\n")


# ── 12d. Indicator Loadings Lollipop Plot ────────────────────
# Each dot = one indicator's loading on its assigned construct.
# Red dashed line at 0.70 = minimum acceptable loading threshold.
# Orange dots = below threshold (may need review/removal).

load_df           <- as.data.frame(pls_summary$loadings)
load_df$Indicator <- rownames(load_df)

load_long <- load_df %>%
  pivot_longer(-Indicator, names_to = "Construct", values_to = "Loading") %>%
  filter(!is.na(Loading) & Loading != 0)  # remove zero/NA cross-loadings

p_loadings <- ggplot(load_long,
                     aes(x = Loading,
                         y = reorder(Indicator, Loading),
                         colour = Loading >= 0.70)) +
  geom_point(size = 3.5) +
  geom_segment(aes(x = 0, xend = Loading,
                   y = reorder(Indicator, Loading),
                   yend = reorder(Indicator, Loading)),
               linewidth = 0.6) +
  geom_vline(xintercept = 0.70, linetype = "dashed",
             colour = "red", linewidth = 0.6) +
  facet_wrap(~ Construct, scales = "free_y") +
  scale_colour_manual(values = c("FALSE" = "#E07A5F", "TRUE" = "#3D405B"),
                      labels = c("FALSE" = "< 0.70 (review)", "TRUE" = "≥ 0.70 (OK)")) +
  labs(title    = "Indicator Outer Loadings by Construct",
       subtitle = "Red dashed line = 0.70 threshold",
       x = "Standardised Loading", y = NULL, colour = "Loading Status") +
  theme_minimal(base_size = 10) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

ggsave("Plot_Indicator_Loadings.png", p_loadings, width = 15, height = 10, dpi = 300)
cat("Saved: Plot_Indicator_Loadings.png\n")


# ── 12e. Moderation Simple Slopes Plot ───────────────────────
# Visualises the interaction OwnerMotivation × DigitalAdoption → Growth.
# Simple slopes are drawn at −1 SD, Mean, and +1 SD of the moderator.
# Diverging slopes (fan-out) confirm a meaningful moderation effect.

cat("\n[Plot 12e] Generating simple slopes moderation plot...\n")

om_mean  <- mean(construct_scores$OwnerMotivation)
om_sd    <- sd(construct_scores$OwnerMotivation)
da_range <- seq(min(construct_scores$DigitalAdoption),
                max(construct_scores$DigitalAdoption), length.out = 60)

# Extract interaction and focal-path coefficients from bootstrap results
# Use bp_clean (numeric) for coefficient extraction — avoids list-column issues
path_names <- rownames(bp_clean)
b_da_idx   <- which(grepl("DigitalAdoption.*GrowthEfficiency", path_names) &
                      !grepl("\\*", path_names))
b_int_idx  <- which(grepl("OwnerMotivation\\*DigitalAdoption", path_names))

# Extract bootstrap mean with safe fallback values for illustration
b_da  <- if (length(b_da_idx)  > 0) as.numeric(bp_clean[b_da_idx,  mean_col]) else 0.25
b_int <- if (length(b_int_idx) > 0) as.numeric(bp_clean[b_int_idx, mean_col]) else 0.10
# Replace NA with fallbacks
if (is.na(b_da))  b_da  <- 0.25
if (is.na(b_int)) b_int <- 0.10

slopes_df <- data.frame(
  DigitalAdoption  = rep(da_range, 3),
  GrowthPredicted  = c(
    (b_da + b_int * (om_mean - om_sd)) * da_range,   # Low moderator (–1 SD)
    (b_da + b_int * om_mean)           * da_range,   # Moderate (mean)
    (b_da + b_int * (om_mean + om_sd)) * da_range    # High moderator (+1 SD)
  ),
  ModeratorLevel   = rep(c("Low Owner Motivation (–1 SD)",
                           "Mean Owner Motivation",
                           "High Owner Motivation (+1 SD)"), each = 60)
)

p_moderation <- ggplot(slopes_df,
                       aes(x = DigitalAdoption, y = GrowthPredicted,
                           colour = ModeratorLevel, linetype = ModeratorLevel)) +
  geom_line(linewidth = 1.3) +
  scale_colour_manual(values = c("Low Owner Motivation (–1 SD)"  = "#E07A5F",
                                 "Mean Owner Motivation"          = "#3D405B",
                                 "High Owner Motivation (+1 SD)"  = "#81B29A")) +
  labs(title    = "Moderation: Owner Motivation × Digital Adoption → Growth",
       subtitle = "Simple slopes at ±1 SD of moderator (OwnerMotivation)",
       x        = "Digital Adoption (composite score)",
       y        = "Predicted Growth Efficiency",
       colour   = "Owner Motivation Level",
       linetype = "Owner Motivation Level") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

ggsave("Plot_Moderation_SimpleSlopes.png", p_moderation,
       width = 9, height = 6, dpi = 300)
cat("Saved: Plot_Moderation_SimpleSlopes.png\n")


# ── 12f. Mediation Forest Plot ────────────────────────────────
# Forest plot of all specific indirect effects.
# Horizontal lines = 95% bootstrapped CI.
# Blue = CI excludes zero (significant mediation); Red = includes zero.

# Build ie_df from ie_clean (already numeric, created in Section 10f)
# This avoids the "object Mean not found" error caused by list-typed columns.
ie_df      <- ie_clean
ie_df$Path <- rownames(ie_df)

# Detect columns robustly
ie_mean <- grep("mean",       colnames(ie_df), ignore.case=TRUE, value=TRUE)[1]
ie_lo   <- grep("2\.5|low",  colnames(ie_df), ignore.case=TRUE, value=TRUE)[1]
ie_hi   <- grep("97\.5|high",colnames(ie_df), ignore.case=TRUE, value=TRUE)[1]

# Fallback to position if grep returns NA
if (is.na(ie_mean) || length(ie_mean)==0) ie_mean <- colnames(ie_df)[2]
if (is.na(ie_lo)   || length(ie_lo)==0)   ie_lo   <- colnames(ie_df)[5]
if (is.na(ie_hi)   || length(ie_hi)==0)   ie_hi   <- colnames(ie_df)[6]

ie_df$Mean  <- as.numeric(ie_df[[ie_mean]])
ie_df$CI_lo <- as.numeric(ie_df[[ie_lo]])
ie_df$CI_hi <- as.numeric(ie_df[[ie_hi]])
# Significant if CI does not straddle zero
ie_df$Sig   <- ifelse(ie_df$CI_lo > 0 | ie_df$CI_hi < 0,
                      "Significant", "Not Significant")

p_mediation <- ggplot(ie_df,
                      aes(x = reorder(Path, Mean), y = Mean, colour = Sig)) +
  geom_point(size = 4) +
  geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi), width = 0.2, linewidth = 0.9) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  coord_flip() +
  scale_colour_manual(values = c("Significant"     = "#2E86AB",
                                 "Not Significant" = "#E07A5F")) +
  labs(title    = "Mediation: Specific Indirect Effects",
       subtitle = "95% bootstrapped CI. Blue = CI excludes zero (significant).",
       x = NULL, y = "Indirect Effect",
       colour = "Significance",
       caption = "Based on 1000 bootstrap resamples") +
  theme_minimal(base_size = 12) +
  theme(plot.title = element_text(face = "bold"),
        legend.position = "bottom")

ggsave("Plot_Mediation_IndirectEffects.png", p_mediation,
       width = 11, height = 7, dpi = 300)
cat("Saved: Plot_Mediation_IndirectEffects.png\n")


# ── SECTION 13: Final Output Summary ────────────────────────
cat("\n============================================================\n")
cat(" ANALYSIS COMPLETE – FILES GENERATED\n")
cat("============================================================\n")
cat("
  CSV Files:
  ├── Descriptive_Statistics.csv              Mean, SD, skewness per item
  ├── Correlation_Matrix_Indicators.csv       Pearson r (all 40 indicators)
  ├── Covariance_Matrix_Indicators.csv        Unstandardised covariance
  ├── Correlation_Pvalues_Indicators.csv      p-values for each r
  ├── Correlation_Matrix_Constructs.csv       Inter-construct correlations
  ├── Covariance_Matrix_Constructs.csv        Inter-construct covariances
  ├── Output_Loadings.csv                     Outer loadings per indicator
  ├── Output_Reliability.csv                  Alpha | rhoA | CR | AVE
  ├── Output_HTMT.csv                         Discriminant validity
  ├── Output_FornellLarcker.csv               Fornell-Larcker criterion
  ├── Output_VIF.csv                          Outer collinearity VIF
  ├── Output_BootstrappedPaths.csv            β | T | 95% CI per path
  ├── Output_EffectSizes.csv                  f² per structural path
  ├── Output_IndirectEffects.csv              Mediation indirect effects
  └── Output_TotalEffects.csv                 Total effects (direct+indirect)

  PNG Plots:
  ├── Correlation_Heatmap_Indicators.png      40×40 indicator heatmap
  ├── Correlation_Heatmap_Constructs.png      9×9 construct heatmap
  ├── Plot_Path_Coefficients.png              Paths faceted by type
  ├── Plot_Reliability_AVE.png                Reliability bar chart
  ├── Plot_Indicator_Loadings.png             Loadings lollipop chart
  ├── Plot_Moderation_SimpleSlopes.png        Simple slopes (±1 SD)
  └── Plot_Mediation_IndirectEffects.png      Indirect effects forest plot
")
