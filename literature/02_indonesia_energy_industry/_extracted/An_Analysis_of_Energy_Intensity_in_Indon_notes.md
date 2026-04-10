---
source: An_Analysis_of_Energy_Intensity_in_Indon.md
notes_type: academic
generated: 2026-03-17
---

# An Analysis of Energy Intensity in Indonesian Manufacturing
**Authors:** Djoni Hartono, Tony Irawan, Noer Azam Achsani | **Year:** 2011 | **Journal:** International Research Journal of Finance and Economics, 62: 77–84

## 1. Research Question
What are the determinants of energy intensity in Indonesian manufacturing firms, and do changes in energy intensity across sub-sectors arise from improvements in energy efficiency or from changes in industrial structure (activity mix)? The paper addresses a gap in firm-level analysis of Indonesian energy intensity and the stagnation in national energy efficiency since 2000.

## 2. Audience
Energy economics; industrial policy; Indonesian development economics; sub-national / firm-level analysts.

## 3. Method / Identification Strategy
Two complementary approaches. First, a decomposition analysis using the Fisher ideal index (following Boyd and Roop 2004) decomposes energy intensity changes between 2002 and 2006 into an efficiency effect and an activity effect at the sub-sector level for 9 manufacturing sub-sectors. Second, a firm-level static panel data regression estimates the determinants of energy intensity, with model specification derived from Kumar (2003) and Martin (2006). Hausman test and LM test used to select between FE, RE, and pooled OLS; robust fixed effects model preferred.

## 4. Data
- **Source:** Indonesian Industrial Statistics (Statistik Industri, BPS), 2002–2006
- **Unit of observation:** Firm (manufacturing establishments)
- **Sample size / N:** 13,743 balanced-panel firms; 68,715 total observations
- **Time period:** 2002–2006 (5 years)
- **Coverage:** Indonesian medium and large manufacturing firms; balanced panel (firms observed in all 5 years); 9 ISIC sub-sectors (food/beverages/tobacco; textile/apparel/leather; wood; paper/plastics/printing; chemicals/petroleum/rubber/plastic; non-metallic minerals; basic metals; metal products/machinery/equipment; other)

## 5. Statistical Methods
- Decomposition: Fisher ideal index decomposed into Laspeyres and Paasche indexes for efficiency (eff) and activity (act) components; base year = 2002
- Panel regression: ln(energy intensity) = f(ln(wage), ln(output), age, technology intensity, capital intensity, labor productivity, % foreign ownership, % private domestic ownership)
- Estimator: robust fixed effects (selected by Hausman and LM tests)
- Adj. R² = 0.6969
- Dependent variable: ln(energy intensity) = ln(total energy consumed / total output)

## 6. Key Findings
- **Decomposition (2002–2006):** Overall industry energy intensity rose by 0.26 percentage points. The increase is driven almost entirely by lack of efficiency improvement (efficiency component = +0.27), not activity changes (activity = −0.01). Large enterprises mirror national trends almost exactly; medium enterprises show different sub-sectoral patterns.
- **Sub-sector variation:** Non-metallic minerals shows the largest energy intensity increase (+3.49 national level); other processing shows the largest decrease (−6.48). Large enterprises drive national-level results.
- **Panel regression (Table 4):**
  - ln(wage): +0.0478 (SE 0.0105, t=4.57, p<0.001) — higher wages → more energy intensity
  - ln(output): −0.1450 (SE 0.0086, t=−16.95, p<0.001) — larger firms are more energy-efficient
  - Age: +0.0131 (SE 0.0027, t=4.87, p<0.001) — older firms are less energy-efficient
  - Technology intensity: −5.32×10⁻⁴ (SE 1.52×10⁻⁴, t=−3.49, p<0.001) — more spending on machinery → lower energy intensity
  - Capital intensity: +1.01×10⁻⁵ (SE 4.20×10⁻⁶, t=2.41, p=0.016) — more capital-intensive → higher energy intensity
  - Labor productivity: −2.53×10⁻⁸ (SE 1.51×10⁻⁸, t=−1.67, p=0.095) — higher labor productivity → lower energy intensity (weakly significant)
  - % private domestic capital: +0.0011 (SE 0.0004, t=2.43, p=0.015) — more private domestic ownership → higher energy intensity
  - % foreign capital: not significant (t=0.41, p=0.685)

## 7. Contributions
- One of the first studies to use balanced firm-level panel data (not sub-sector aggregates) for Indonesian energy intensity, avoiding the sample bias in prior sub-sector approaches
- Distinguishes efficiency from activity effects within decomposition to identify the source of Indonesian energy intensity stagnation post-2000
- Finds that large enterprises drive national trends (medium enterprises behave differently) — providing targeting guidance for energy policy
- Foreign ownership does not significantly affect energy intensity — challenges the FDI technology-transfer assumption for energy efficiency in Indonesia

## 8. Replication Feasibility
- **Data access:** Indonesian Industrial Statistics (Statistik Industri, BPS) — access via BPS Indonesia; medium-to-large firms surveyed annually; firm-level microdata requires application
- **Code availability:** Not mentioned; no replication archive
- **Barriers:** Constructing a balanced panel requires careful firm matching across years; energy quantity data in multiple units requires standardisation; relatively short panel (5 years) limits dynamics
