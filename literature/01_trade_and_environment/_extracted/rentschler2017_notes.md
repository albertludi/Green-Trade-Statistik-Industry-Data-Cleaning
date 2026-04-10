---
source: rentschler2017.md
notes_type: academic
generated: 2026-03-17
---

# Energy Price Variation and Competitiveness: Firm Level Evidence from Indonesia
**Authors:** Jun Rentschler, Martin Kornejew | **Year:** 2017 | **Journal:** Energy Economics (doi:10.1016/j.eneco.2017.08.015)

## 1. Research Question
Does energy price variation adversely affect the long-run competitiveness (profitability) of firms? And how do firms adapt to higher energy prices via fuel substitution, energy efficiency improvements, and cost pass-on? The paper addresses a gap in the fossil fuel subsidy (FFS) reform literature, which had focused on household impacts while largely ignoring firm-level effects.

## 2. Audience
Energy economics; industrial organisation; developing-country policy; fossil fuel subsidy reform literature.

## 3. Method / Identification Strategy
Exploits persistent inter-regional energy price differentials arising from Indonesia's archipelagic geography and infrastructure gaps. Since national regulations nominally set uniform prices but logistical constraints create structural, province-level price variation, the study treats regional price differences as quasi-exogenous variation in long-run energy prices. Cross-sectional OLS with sector and province fixed effects. Four separate regression set-ups: (1) cost-share regression for competitiveness; (2) translog cost function for inter-fuel substitution; (3) energy intensity regression for efficiency response; (4) unit sales price regression for pass-on. No IV used; identification relies on reduced-form variation from structural price differences being exogenous to individual firm performance.

## 4. Data
- **Source:** Survei Industri Mikro dan Kecil (BPS Statistics Indonesia, 2015) — Indonesia Micro and Small Industries Survey 2013
- **Unit of observation:** Firm (micro and small enterprises, 1–19 employees)
- **Sample size / N:** 36,759 firms after cleaning (original: 41,402; excluded 3,543 seasonal and 1,100 missing cost/sales)
- **Time period:** Cross-section, 2013
- **Coverage:** All 34 Indonesian provinces; manufacturing and mining sectors; 9 aggregated ISIC sectors; energy prices computed for electricity, petrol, diesel, kerosene, and LPG (collectively 78.4% of total energy costs)

## 5. Statistical Methods
- OLS log-linear regression of ln(cost share) on ln(energy prices) with sector and province fixed effects (Eq. 3)
- Translog cost function (homothetically separable) estimated via SUR/OLS to obtain partial own and cross price elasticities and Uzawa-Allen / Morishima elasticities of substitution
- Energy intensity regression: ln(energy intensity of revenue) on ln(energy prices)
- Pass-on regression: ln(average unit sales price) on ln(energy prices), controlling for ln(total costs) and ln(wage)
- Robust standard errors throughout; outlier treatment at 2.5th/97.5th percentile of provincial price distributions
- Robustness: alternative labour cost imputation methods, Heckman selection model, clustering SEs at province/industry level, inclusion of seasonal firms

## 6. Key Findings
- **Competitiveness (cost shares):** Higher energy prices are associated with significantly higher long-run unit costs in 4 of 5 energy types. Diesel shows the largest and most robust effect: +1% diesel price → +0.373% (SE 0.098) cost share across all sectors. LPG is second: +0.232% (SE 0.036). Electricity effect: +0.052% (SE 0.009). Adjusted R² = 0.214 for full sample.
- **Inter-fuel substitution:** All energy pairs are substitutes except petrol–LPG (complements). Own-price elasticities: electricity –1.51, LPG –2.90, kerosene –5.68. Kerosene and diesel are the strongest substitutes.
- **Energy efficiency:** Higher energy prices are associated with lower energy intensity of revenue (firms improve efficiency). A 1% increase in electricity price reduces energy intensity by –0.624 (SE 0.118) KJ/IDR.
- **Pass-on:** Positive and significant pass-on for electricity (0.051*) and LPG (0.180*). Wages are passed on at a higher and more significant rate than energy.
- Sector heterogeneity is substantial: diesel matters most for coal mining; kerosene is important for tobacco and coal mining; LPG is important for mining and tobacco.
- Overall conclusion: effects are small in magnitude — drastic long-run competitiveness losses from FFS reform are unlikely, but response capacity is heterogeneous.

## 7. Contributions
- First micro-econometric study of energy prices and firm competitiveness in the context of FFS reform for Indonesia specifically
- Integrates four response mechanisms (absorption, substitution, efficiency, pass-on) in a single empirical framework at the firm level
- Demonstrates that regional price differences within a single regulatory environment can be exploited for identification of long-run price effects
- Shows that firms' adaptive capacity (substitution, efficiency) is substantial but incomplete, with policy implications for complementary measures alongside FFS reform

## 8. Replication Feasibility
- **Data access:** BPS Survei Industri Mikro dan Kecil 2013 — available from BPS Indonesia, but access for foreign researchers may require formal application
- **Code availability:** Not mentioned; no replication archive cited
- **Barriers:** Dataset requires translation from Indonesian (authors acknowledge language assistance); price variables must be constructed from cost and quantity data; province minimum wage data needed (BPS 2016); moderately complex data preparation
- **Energy content conversion factors** are published (Table 5 in paper, from BP 2016; EIA 2016; IPCC 2006) — straightforward to replicate
