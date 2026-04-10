---
source: margono2006.md
notes_type: academic
generated: 2026-03-17
---

# Efficiency and Productivity Analyses of Indonesian Manufacturing Industries
**Authors:** Heru Margono, Subhash C. Sharma | **Year:** 2006 | **Journal:** Journal of Asian Economics, 17(6): 979–995 (doi:10.1016/j.asieco.2006.09.004)

## 1. Research Question
What are the levels of technical efficiency and total factor productivity (TFP) growth in Indonesian manufacturing industries, what are the determinants of technical inefficiency, and how is TFP growth decomposed into technological progress, scale effects, and efficiency change? The paper examines whether the Asian financial crisis affected TFP differently across sectors and firm types.

## 2. Audience
Production economics; development economics; industrial organisation; Indonesian manufacturing studies; efficiency and productivity analysis (SFA/DEA literature).

## 3. Method / Identification Strategy
Stochastic Frontier Analysis (SFA) using a translog production frontier. Time-varying technical efficiency modelled following Battese and Coelli (1992), with efficiency parameterised as uit = uiT · exp{−δ(t−T)}. Technical efficiency estimated by minimum mean-square-error predictor (Eq. 6). Inefficiency determinants estimated by OLS regression of TIEit = 1 − TEit on firm size, regional location (east/west), ownership (private/public), and age. TFP growth decomposed into technological progress (TP), scale component (SC), and technical efficiency change (TE*) following Kumbhakar and Lovell (2000). Estimated using FRONTIER 4.1 (Coelli 1996) by maximum likelihood.

## 4. Data
- **Source:** Annual surveys of medium and large manufacturing firms, Central Bureau of Statistics (CBS) Indonesia
- **Unit of observation:** Firm (medium and large manufacturing establishments)
- **Sample size / N:** 733 firms total: food (ISIC 31) = 259; textile (ISIC 32) = 230; chemical (ISIC 35) = 128; metal products (ISIC 38) = 116
- **Time period:** 1993–2000 (8 years; TFP growth computed 1994–2000)
- **Coverage:** Four Indonesian manufacturing sectors (food, textile, chemical, metal products); these four sectors account for >50% of manufacturing value added; all variables in 1993 thousand rupiah prices (except labour, which is headcount)

## 5. Statistical Methods
- Translog production function: ln(y) = β₀ + βₖln(k) + βₗln(l) + βₘln(m) + βₜt + quadratic/cross terms + (v − u)
- Inputs: capital (k = depreciation + interest paid), labour (l = number of employees), materials (m = total material value)
- Output: gross total output (value)
- Time trend (t) captures technological change
- Technical efficiency: TE_it = E[exp(−u_it) | ε_it]
- Inefficiency regression: TIE_it on size dummy (DS_i: −1 small, 0 medium, +1 large), region (1=west), ownership (1=private), age
- TFP = TP + SC + TE* (decomposition method)
- Estimated by MLE; standard errors reported for all parameters

## 6. Key Findings
- **Technical efficiency (average 1993–2000):**
  - Food (ISIC 31): 50.79%
  - Textile (ISIC 32): 47.89% (lowest)
  - Chemical (ISIC 35): 68.65%
  - Metal products (ISIC 38): 68.91% (highest)
  - All sectors combined: 55.87%
  - Range: 42.4% (food, 1993) to 85.8% (metals, 2000)
- **Annual TE growth rates (1994–2000):** Food 4.83%; Textile 1.13%; Chemical 2.49%; Metals 8.93%
- **Post-crisis effect (1998–2000 vs. 1994–1997):** All sectors showed lower efficiency growth after crisis. Overall: 3.22% vs. 4.62% pre-crisis.
- **TFP growth (average 1994–2000):**
  - Food: −2.73% per annum
  - Textile: −0.26% per annum
  - Chemical: +0.50% per annum (only positive)
  - Metal products: −1.65% per annum
  - TFP decline driven by technological recess (negative TP) in all sectors; TE changes are positive but insufficient to offset technological recess
- **Inefficiency determinants:** Larger firms are more efficient (size coefficient negative and significant in all sectors). Private ownership reduces inefficiency (negative, significant) except textiles. Regional location matters only in textiles. Age effect inconsistent across sectors.
- **Elasticities:** Textile, chemical, and metal products are capital-oriented (output elasticity w.r.t. capital > w.r.t. labour or materials). Food is material-oriented.
- **Asian crisis:** TFP in 1999 was worst year across all sectors; textiles, chemicals, metals more affected than food (food is primarily domestic, others are export-oriented).

## 7. Contributions
- Applies stochastic frontier decomposition method (vs. growth accounting) to Indonesian manufacturing, providing TE, TP, SC, and TE* separately rather than conflating them
- One of few studies to cover both pre- and post-Asian crisis periods with firm-level data for Indonesian manufacturing
- Shows that TFP decline is driven by technological recess, not efficiency decline — policy implication for R&D and technology adoption rather than management improvement
- Provides cross-sector comparison (food, textile, chemical, metals) covering over half of Indonesian manufacturing value added

## 8. Replication Feasibility
- **Data access:** Annual CBS/BPS manufacturing surveys for medium and large firms — same source as Statistik Industri (SI/IBS), accessible via BPS application; years 1993–2000
- **Code availability:** FRONTIER 4.1 software used (Tim Coelli, freely available); no replication archive cited
- **Barriers:** Capital variable defined as depreciation + interest paid (not perpetual inventory method used by Timmer 1999 and others) — limits direct comparability; unbalanced aspects of the dataset (733 firms across 8 years) require clarification; labour measured as headcount (man-hours unavailable)
