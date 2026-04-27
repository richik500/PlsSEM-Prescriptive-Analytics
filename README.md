# PLS-SEM Analysis — SME Digital Transformation
### Partial Least Squares Structural Equation Modelling using `SEMinR` in R

> **Study context:** This project investigates the barriers, enablers, and outcomes of digital transformation in Small and Medium Enterprises (SMEs), using survey data from 101 respondents. Two structural models are included — the original model and a revised model based on a modified construct mapping.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Theoretical Model](#theoretical-model)
  - [Original Model](#original-model)
  - [Modified Model](#modified-model)
- [Construct Mapping](#construct-mapping)
- [Data Description](#data-description)
- [Installation & Requirements](#installation--requirements)
- [How to Run](#how-to-run)
- [Analysis Pipeline](#analysis-pipeline)
- [Outputs](#outputs)
- [Key Methodological Decisions](#key-methodological-decisions)
- [Known Issues & Fixes Applied](#known-issues--fixes-applied)
- [References](#references)

---

## Project Overview

This repository contains a complete PLS-SEM pipeline built in R using the [`SEMinR`](https://cran.r-project.org/package=seminr) package. The analysis covers:

- **Measurement model evaluation** — loadings, reliability (α, ρA, CR), convergent validity (AVE), discriminant validity (HTMT, Fornell-Larcker)
- **Structural model evaluation** — bootstrapped path coefficients, R², effect sizes (f²), predictive relevance (Q²)
- **Mediation analysis** — specific indirect effects with 95% bootstrapped confidence intervals
- **Moderation analysis** — interaction terms using the orthogonal method, visualised via simple slopes
- **Correlation & covariance** — at both indicator and construct level
- **Common method bias** — Harman's single-factor test

---

## Repository Structure

```
.
├── Assignment_Bama_Sir.xlsx      # Raw survey data  (n = 101, DO NOT modify)
├── Modified_SM_Final.xlsx        # Revised construct mapping document
│
├── PLS_SEM_Full_Analysis.R       # Script 1 — Original structural model
├── PLS_SEM_Modified_SM.R         # Script 2 — Modified structural model
│
├── outputs/
│   ├── *.csv                     # All tabular results (loadings, paths, etc.)
│   └── *.png                     # All plots (heatmaps, path charts, etc.)
│
└── README.md
```

---

## Theoretical Model

### Original Model

```
Exogenous (Independent)          Mediators               Endogenous
────────────────────────         ─────────               ──────────
OperationalChallenges  ──────►  DigitalAdoption   ──►
OwnerMotivation        ──────►  CertStandard      ──►   GrowthEfficiency
FinancialBarriers      ──────►  LocalHireEnable   ──►
AdminEcoBarriers       ──────────────────────────────►
SkillGap               ──────────────────────────────►

Moderators
──────────
OwnerMotivation   × DigitalAdoption   ──►  GrowthEfficiency  (H9)
FinancialBarriers × AdminEcoBarriers  ──►  GrowthEfficiency  (H10)
```

**Hypotheses (Original Model)**

| ID | Path | Expected Direction |
|----|------|--------------------|
| H1 | OperationalChallenges → GrowthEfficiency | + |
| H2 | OwnerMotivation → GrowthEfficiency | + |
| H3 | FinancialBarriers → GrowthEfficiency | − |
| H4 | AdminEcoBarriers → GrowthEfficiency | − |
| H5 | SkillGap → GrowthEfficiency | − |
| H6a | OperationalChallenges → DigitalAdoption | + |
| H6b | DigitalAdoption → GrowthEfficiency | + |
| H7a | FinancialBarriers → CertStandardization | − |
| H7b | CertStandardization → GrowthEfficiency | + |
| H8a | SkillGap → LocalHireEnablement | + |
| H8b | LocalHireEnablement → GrowthEfficiency | + |
| H9  | OwnerMotivation × DigitalAdoption → GrowthEfficiency | + (amplify) |
| H10 | FinancialBarriers × AdminEcoBarriers → GrowthEfficiency | − (magnify) |

---

### Modified Model

Based on `Modified_SM_Final.xlsx`, original indicators are re-grouped into new theoretically refined constructs:

```
Organizational Readiness          Local Ecosystem           Endogenous
──────────────────────            ───────────────           ──────────
OMDT ──────────────────────────► ASTL (Mediator)  ───────►
WITI ──────────────────────────►                           DigitalGrowth
CBDR ──────────────────────────────────────────────────►  (KO5–KO7)
HRCS ──────────────────────────►
APDL ──────────────────────────────────────────────────►
AUDT ──────────────────────────────────────────────────►
CSLE ──────────────────────────►
AIST ──────────────────────────────────────────────────►

Moderator
─────────
OMDT × ASTL ──► DigitalGrowth  (H14)
```

---

## Construct Mapping

### Original Model Constructs

| Construct | Full Name | Indicators |
|-----------|-----------|------------|
| `OperationalChallenges` | Operational Process Challenges | KD4–KD6, KD8–KD10 |
| `OwnerMotivation` | Owner Viewpoints on Automation | KD11–KD15 |
| `FinancialBarriers` | Financial Challenges | KD16–KD21 |
| `AdminEcoBarriers` | Admin & Ecosystem Barriers | KD22–KD24 |
| `SkillGap` | Skill Gap & Workforce | KD25–KD28 |
| `DigitalAdoption` | Digital Technology Enabler | KE1–KE3 |
| `CertStandardization` | Certification & Standardisation | KE4–KE6 |
| `LocalHireEnablement` | Engaging Local Hire | KE7–KE9 |
| `GrowthEfficiency` | Growth & Efficiency Outcomes | KO1–KO7 |

### Modified Model Constructs

| Construct | Full Name | Indicators | Role |
|-----------|-----------|------------|------|
| `OMDT` | Owner Mindset_Digital Transformation | KD13, KD14, KD15 | Exogenous + Moderator |
| `WITI` | Willingness to Invest_Training & Infra | KD11, KD12 | Exogenous |
| `CBDR` | Certification Benefit_Digital Readiness | KE4, KE6 | Exogenous |
| `HRCS` | Hidden Resistance to Change among Staff | KE8, KD28 | Exogenous |
| `APDL` | Actual vs Perceived Digital Literacy | KD26 | Exogenous (single-item) |
| `AUDT` | Ability to Use Digital Tools | KD28 | Exogenous (single-item) |
| `ASTL` | Availability of Skilled Talent Locally | KE7, KE8, KE9 | Mediator |
| `CSLE` | Community Support_Local Ecosystems | KD22, KD23, KD24 | Exogenous |
| `AIST` | AI as Supportive or Threatening | KD12, KD14 | Exogenous |
| `DigitalGrowth` | Digital Growth Outcomes | KO5, KO6, KO7 | Endogenous |

> **Note:** `QAAD` and `TDR` are marked *"Synthetic (External Information Based)"* in `Modified_SM_Final.xlsx` — they have no original survey indicators and are excluded from the model.

---

## Data Description

| File | Description |
|------|-------------|
| `Assignment_Bama_Sir.xlsx` | Primary survey data. **Row 1** = construct group labels. **Row 2** = full question text. **Row 3** = short variable codes (KD1–KD28, KE1–KE9, KO1–KO7). **Rows 4+** = numeric Likert responses (n = 101). |
| `Modified_SM_Final.xlsx` | Construct mapping document. Defines new latent variables by grouping existing indicators under revised theoretical factors. Not a data file — no survey responses. |

**Survey instrument structure:**

| Prefix | Domain | Items |
|--------|--------|-------|
| `KD` | Key Dimensions (challenges & context) | KD1–KD28 |
| `KE` | Key Enablers | KE1–KE9 |
| `KO` | Key Outcomes | KO1–KO7 |

**Excluded items:** KD1 (year of establishment), KD2 (product type — free text), KD3 (owner qualification — demographic).

---

## Installation & Requirements

### R version
R ≥ 4.1.0 recommended.

### Required packages

```r
install.packages(c(
  "seminr",    # PLS-SEM estimation (≥ 2.3.0)
  "readxl",    # Read .xlsx files
  "dplyr",     # Data wrangling
  "ggplot2",   # Plotting
  "corrplot",  # Correlation heatmaps
  "psych",     # Descriptive stats & corr.test()
  "tidyr",     # Data reshaping
  "scales"     # Axis formatting
))
```

All packages are auto-installed at runtime if missing — you do not need to run the above manually.

---

## How to Run

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/pls-sem-sme-digital-transformation.git
   cd pls-sem-sme-digital-transformation
   ```

2. **Open RStudio** and set your working directory to the project folder:
   ```r
   setwd("path/to/pls-sem-sme-digital-transformation")
   ```

3. **Run the desired script:**
   ```r
   # Original structural model
   source("PLS_SEM_Full_Analysis.R")

   # Modified structural model (based on Modified_SM_Final.xlsx)
   source("PLS_SEM_Modified_SM.R")
   ```

4. All CSV and PNG outputs are saved to the **working directory** automatically.

---

## Analysis Pipeline

Each script follows the same 13-section pipeline:

```
Section 1  →  Install & load packages
Section 2  →  Load & clean data (mean-impute isolated NAs)
Section 3  →  Descriptive statistics (mean, SD, skew, kurtosis)
Section 4  →  Pearson correlation & covariance matrices + heatmaps
Section 5  →  Define measurement model (composite / single_item)
Section 6  →  Define structural model (paths + interactions)
Section 7  →  Estimate PLS model (path_weighting, Mode A)
Section 8  →  Bootstrap significance (500 resamples, cores = 1)
Section 9  →  Measurement model evaluation
               ├─ 9a. Outer loadings
               ├─ 9b. Reliability (α, ρA, CR, AVE)
               ├─ 9c. HTMT discriminant validity
               ├─ 9d. Fornell-Larcker criterion
               └─ 9e. Outer VIF
Section 10 →  Structural model evaluation
               ├─ 10a. Bootstrapped path coefficients
               ├─ 10b. R² and adjusted R²
               ├─ 10c. Effect sizes (f²)
               ├─ 10d. Predictive relevance Q² (10-fold CV)
               ├─ 10e. Moderation interaction paths
               ├─ 10f. Specific indirect effects (mediation)
               └─ 10g. Total effects
Section 11 →  Common method bias (Harman's single-factor)
Section 12 →  Visualisations (7 plots)
Section 13 →  Output summary
```

---

## Outputs

### CSV Files

| File | Contents |
|------|----------|
| `*_Descriptive_Statistics.csv` | n, mean, SD, min, max, skewness, kurtosis per item |
| `*_Correlation_Indicators.csv` | Pearson r matrix — all indicators |
| `*_Covariance_Indicators.csv` | Covariance matrix — all indicators |
| `*_Correlation_Pvalues.csv` | p-values for each pairwise correlation |
| `*_Correlation_Constructs.csv` | Inter-construct correlation matrix |
| `*_Covariance_Constructs.csv` | Inter-construct covariance matrix |
| `*_Output_Loadings.csv` | Standardised outer loadings per indicator |
| `*_Output_Reliability.csv` | Cronbach's α, ρA, CR, AVE per construct |
| `*_Output_HTMT.csv` | HTMT discriminant validity ratios |
| `*_Output_FL.csv` | Fornell-Larcker criterion table |
| `*_Output_VIF.csv` | Outer collinearity VIF values |
| `*_Output_BootPaths.csv` | β, bootstrap mean, SD, T-stat, 95% CI per path |
| `*_Output_fSquare.csv` | Cohen's f² effect sizes |
| `*_Output_IndirectEffects.csv` | Specific indirect effects (mediation) |
| `*_Output_TotalEffects.csv` | Total effects (direct + indirect) |

### PNG Plots

| File | Description |
|------|-------------|
| `*_Heatmap_Indicators.png` | Full indicator-level Pearson correlation heatmap |
| `*_Heatmap_Constructs.png` | Construct-level correlation heatmap |
| `*_Plot_PathCoefficients.png` | Bootstrapped path coefficients, faceted by Direct / Mediation / Moderation |
| `*_Plot_Reliability.png` | Grouped bar chart — α, ρA, CR, AVE per construct with threshold lines |
| `*_Plot_Loadings.png` | Lollipop chart — outer loadings by construct |
| `*_Plot_SimpleSlopes.png` | Simple slopes at ±1 SD of moderator |
| `*_Plot_Mediation.png` | Forest plot of specific indirect effects with 95% CI |

---

## Key Methodological Decisions

### Composite vs. Reflective
All constructs use `composite()` (PLS Mode A), appropriate for exploratory research where indicators are treated as interchangeable Likert items sharing a common theme.

### Interaction Method: `orthogonal`
Moderation uses `method = orthogonal` (Henseler & Chin, 2010) rather than `two_stage`. The orthogonal method residualises each product indicator against main-effect indicators, removing multicollinearity **without** requiring a pre-estimated Stage-1 model object — which causes a `mmMatrix` list-type error in SEMinR ≥ 2.3 when called directly inside `relationships()`.

### Bootstrap Settings
- `nboot = 500`, `cores = 1` — single-core avoids parallel RNG zero-variance crashes on product indicators from orthogonal interactions
- `tryCatch` fallback to `nboot = 200` if any resample fails

### Missing Data
Isolated NAs are mean-imputed per column prior to estimation. Fully empty rows (respondents who answered nothing) are removed. This is standard practice for Likert-scale PLS-SEM with small proportions of missing data (Hair et al., 2019).

### Single-Item Constructs (Modified Model only)
`APDL` and `AUDT` use `single_item()`. Reliability metrics (α, ρA, CR, AVE) are undefined for single-item constructs and are not reported for them.

### Shared Indicators (Modified Model only)
KD28 appears in both `HRCS` and `AUDT`; KD12 appears in both `WITI` and `AIST`; KD14 appears in both `OMDT` and `AIST`. Shared indicators are acceptable in PLS composite models (unlike reflective CFA) because composites are not required to be unidimensional.

---
