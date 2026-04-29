# 📊 PLS-SEM Analysis: SME Digital Transformation & Growth

> Structural Equation Modelling (PLS-SEM) of key dimensions, enablers, and growth outcomes for Small & Medium Enterprises using the **SEMinR** package in R.

---

## 📁 Repository Structure

```
├── Assignment_Bama_Sir.xlsx       # Raw survey dataset (100 SME respondents)
├── SEM_Analysis_Bama_Sir_v4.R     # Main analysis script (composite + reflective)
├── Stage1_Composite_Model.png     # Output: composite model diagram
├── Stage2_Reflective_Model.png    # Output: reflective model diagram
└── README.md
```

---

## 🧭 Research Framework

This study models the relationship between **operational dimensions of SMEs**, **digital enablers**, and **growth outcomes** using a two-stage PLS-SEM approach.

### Constructs

| Role | Construct | Indicators | Type |
|---|---|---|---|
| Exogenous | Buy Process & Procurement | KD4, KD5, KD6, KD8 | Reflective |
| Exogenous | Operational Process | KD9, KD10, KD11 | Composite |
| Exogenous | Owner's View on Digitalization | KD12–KD15 | Composite |
| Exogenous | Financial Challenges | KD19, KD20, KD22 | Reflective |
| Exogenous | Admin & Ops Challenges | KD23, KD24 | Reflective |
| Exogenous | Skill Gap & Workforce | KD25, KD26, KD27 | Reflective |
| Mediator | Digital Technology Enabler | KE1, KE2, KE3 | Reflective |
| Mediator | Certification & Standards | KE4, KE5, KE6 | Composite |
| Mediator | Local Hire Strategy | KE7, KE8, KE9 | Composite |
| Endogenous | Growth & Efficiency | KO4, KO7 | Composite |

### Structural Hypotheses

```
H1 : BuyProcess    →  DigiTech
H2 : OperProcess   →  DigiTech
H3 : OwnersView    →  DigiTech
H4 : OwnersView    →  GrowthEff
H5 : FinChallenge  →  GrowthEff
H6 : AdminOpsChall →  GrowthEff
H7 : SkillGap      →  LocalHire
H8 : DigiTech      →  CertStd
H9 : DigiTech      →  GrowthEff
H10: CertStd       →  GrowthEff
H11: LocalHire     →  GrowthEff
```

---

## 🔬 Two-Stage Analysis Approach

### Stage 1 — Composite Model (Mode A)
All 10 constructs estimated as **composites** using PLS Mode A (correlation-based weights). This is the stable baseline — no matrix inversion, no AVE/HTMT assumptions. Outputs path coefficients, R², f², VIF, and bootstrapped significance.

### Stage 2 — Reflective Model (Mixed)
Constructs re-specified as **reflective** where empirically supported (avg inter-item *r* ≥ 0.30). Constructs with low inter-item correlations remain as composites. Outputs full convergent and discriminant validity assessment (loadings, AVE, CR, Cronbach's α, HTMT).

| Construct | Avg inter-item *r* | Stage 2 specification |
|---|---|---|
| DigiTech | 0.41 | Reflective ✓ |
| SkillGap | 0.48 | Reflective ✓ |
| AdminOpsChall | 0.46 | Reflective ✓ |
| FinChallenge | 0.40 | Reflective ✓ |
| BuyProcess | 0.29 | Reflective (borderline) |
| OperProcess | −0.21 | Composite |
| OwnersView | 0.14 | Composite |
| CertStd | 0.19 | Composite |
| LocalHire | 0.12 | Composite |
| GrowthEff | −0.32 | Composite |

---

## ⚙️ Requirements

- **R** ≥ 4.0
- Packages:

```r
install.packages(c("seminr", "readxl", "dplyr"))
```

---

## 🚀 Usage

1. Clone the repository and open R or RStudio.
2. Place `Assignment_Bama_Sir.xlsx` in your working directory.
3. Run the script:

```r
source("SEM_Analysis_Bama_Sir_v4.R")
```

The script will sequentially:
- Load and clean the data (outlier fix, mean imputation, duplicate indicator removal)
- Estimate the **composite model** and print all measurement + structural results
- Bootstrap the composite model (1000 iterations) and compute indirect effects
- Estimate the **reflective model** and print loadings, AVE, CR, HTMT
- Bootstrap the reflective model and print the full hypothesis table
- Save two model diagram PNGs to your working directory

---

## 🧹 Data Cleaning Notes

| Issue | Resolution |
|---|---|
| `KO5` ≡ `KD13` (r = 1.000) | `KO5` excluded from `GrowthEff` |
| `KO6` ≡ `KD15` (r = 1.000) | `KO6` excluded from `GrowthEff` |
| `KO7` had one entry of `12` (scale is 1–5) | Capped to 5 |
| `KD1` (year), `KD2` (product text), `KD3` (education) | Excluded — non-Likert |
| `KO1`, `KO2`, `KO3` (categorical market variables) | Excluded from latent constructs |
| Remaining NAs | Mean imputation per column |

The two perfectly duplicated indicator pairs (`KD13`↔`KO5` and `KD15`↔`KO6`) caused a **rank-deficient indicator correlation matrix** (rank 35 of 37), which produced the `solve.default() singular matrix` error in earlier versions. Removing the outcome-side duplicates restored full rank (35/35) and resolved all estimation errors.

---

## 📈 Output Interpretation

**Composite model**
- Weights: relative contribution of each indicator to its composite
- R² > 0.19 = weak, > 0.33 = moderate, > 0.67 = substantial
- f² > 0.02 = small, > 0.15 = medium, > 0.35 = large effect size
- VIF < 5 required (< 3 preferred) to rule out multicollinearity

**Reflective model** (additional checks)
- Outer loadings > 0.708 ideal; > 0.50 acceptable
- AVE > 0.50 → convergent validity
- CR > 0.70 and Cronbach's α > 0.70 → internal consistency
- HTMT < 0.85 (conservative) or < 0.90 (liberal) → discriminant validity

**Significance (both models)**
- Bootstrapped T-statistic > 1.96 → significant at p < 0.05
- 95% CI not crossing zero → significant indirect effect (mediation)

---

## 📦 Key Package

[**SEMinR**](https://cran.r-project.org/web/packages/seminr/) — Hair, J.F., Risher, J.J., Sarstedt, M., & Ringle, C.M. (2019). *PLS-SEM using R: A workbook.* Springer.

---

## 👤 Author

**Dip** — MBA in Business Analytics  
Assignment submitted to: Bama Sir
