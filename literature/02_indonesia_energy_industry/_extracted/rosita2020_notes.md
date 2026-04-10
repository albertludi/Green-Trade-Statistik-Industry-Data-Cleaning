---
source: rosita2020.md
notes_type: academic
generated: 2026-03-17
---

# Does Energy Efficiency Development in Manufacturing Industry Decouple Industrial Growth from CO2 Emissions in Indonesia?
**Authors:** Tita Rosita, Zaekhan, Rachmawati Dwi Estuningsih, Nona Widharosa | **Year:** 2020 | **Journal:** International Journal of Environmental Studies (doi:10.1080/00207233.2020.1811575)

## 1. Research Question
Does energy efficiency improvement in Indonesia's manufacturing industry lead to decoupling of CO2 emissions from industrial economic growth? The paper decomposes CO2 emission changes into five component effects (economic activity, industrial structure, energy intensity, energy mix, and emission coefficient) and computes decoupling indices by sub-sector, technology intensity, and firm size for 2010–2014.

## 2. Audience
Environmental economics; energy policy; industrial ecology; Indonesian manufacturing and climate policy; researchers using LMDI decomposition and decoupling analysis.

## 3. Method / Identification Strategy
Index Decomposition Analysis (IDA) using the Logarithmic Mean Divisia Index (LMDI) additive method (Ang 2005). CO2 emissions decomposed into five effects: (1) industrial economic activity (total output Q), (2) industrial structure (sectoral output share Si), (3) energy intensity (Ei/Qi), (4) energy mix (Eij/Ei), (5) emission coefficient (Cij/Eij). A decoupling index D_T is then computed from the decomposition, following Diakoulaki and Mandaraka (2007). D_T ≥ 1 = absolute decoupling; 0 < D_T < 1 = relative decoupling; D_T < 0 = no decoupling. Analysis performed at three levels of disaggregation: 24 ISIC 2-digit sub-sectors, OECD technology intensity classification (H/M-H/M/M-L), and firm size (by number of labourers). No causal identification — accounting decomposition.

## 4. Data
- **Source:** Statistik Industri (Large and Medium Industry Statistics), BPS Indonesia; emission factors from IPCC guidelines; energy-to-BOE conversion from Ministry of Energy and Mineral Resources (ESDM)
- **Unit of observation:** Firm (large and medium manufacturing establishments), aggregated to sub-sector, technology group, and size group for analysis
- **Sample size / N:** Not reported explicitly; covers all large and medium firms in the survey (2010–2014); output in constant 2010 billion IDR prices
- **Time period:** 2010–2014 (5 years)
- **Coverage:** Indonesian large and medium manufacturing firms; 24 ISIC 2-digit sub-sectors; 7 fuel types (petrol, diesel, kerosene, coal, natural gas, LPG, electricity); OECD technology intensity groups (H, M-H, M, M-L); 5 firm size groups by number of labourers (20–99, 100–199, 200–499, 500–999, >1000)

## 5. Statistical Methods
- LMDI additive decomposition (Ang 2005): ΔC = ΔC_act + ΔC_str + ΔC_int + ΔC_mix + ΔC_emf
- CO2 estimated using IPCC method: C = Σ(E_ij × η_j × O_j × 44/12 × f_ij), where f_ij = CO2 emission factor after conversion to tonne coal equivalent (Table 2 in paper)
- Decoupling index D_T = ΔF_T / ΔC_act where ΔF_T = ΔC − ΔC_act (inhibiting effects relative to activity-driven emissions)
- Partial decoupling indices computed for each component (D_str, D_int, D_mix, D_emf)
- No econometric estimation — pure accounting/decomposition

## 6. Key Findings
- **Overall industry (2010–2014):** Total decoupling index D_tot = −0.50 — no decoupling. Economic activity drives CO2 increase faster than inhibiting components (energy efficiency, structure, mix) can offset.
- **Sub-sector decoupling results (Table 3, selected):**
  - Absolute decoupling (D_tot ≥ 1): Metal goods/25 (D=1.04), Leather and footwear/15 (D=1.55), Repair and installation/33 (D=2.60)
  - Relative decoupling (0 < D_tot < 1): Textile/13 (D=0.72), Basic metals/24 (D=0.55), Garments/14 (D=0.25), Pharmaceuticals/21 (D=0.66)
  - No decoupling (D_tot < 0): majority of sub-sectors, including non-metallic minerals/23 (D=−0.56), tobacco/12 (D=−2.85), motor vehicles/29 (D=−2.30), rubber and plastic/22 (D=−2.16)
- **By technology intensity (Table 4):** Only medium-low (M-L) technology shows relative decoupling (D_tot = 0.05); all other technology groups show no decoupling. D_int = 0.26 for M-L (energy intensity improvement). High and medium technology firms show partial structural decoupling but not total.
- **By firm size (Table 5):** Only firms with 500–999 labourers show relative decoupling (D_tot = 0.10). All other size groups show no decoupling. Main contributor in 500–999 group is D_int = 0.35.
- **Key cross-cutting finding:** Energy efficiency improvement (falling energy intensity) does not automatically produce decoupling. Industrial structure and energy mix effects are also needed. Economic activity growth is the dominant driver of CO2 emissions across nearly all sub-sectors.
- **GDP and energy context (Table 1):** Manufacturing GDP grew 28.04% (avg. 6.38%/yr, 2010–2014); energy consumption grew at avg. −2.17%/yr (declining in some years); energy intensity fell from 0.30 to 0.21 BOE/Rp. million.

## 7. Contributions
- Innovates by combining LMDI decomposition with firm-level characteristics (sub-sector, technology intensity, firm size) — prior Indonesian studies used only sub-sector decomposition without firm characteristics
- Provides a systematic mapping of which sub-sectors, technology groups, and firm sizes are closest to and furthest from decoupling — directly actionable for targeted policy
- Shows that M-L technology firms (not high-tech) are the group showing relative decoupling — counterintuitive finding with policy implications for SME energy efficiency programmes
- Covers the Statistik Industri data for 2010–2014 with explicit CO2 estimation methodology (IPCC-based, with emission factor table)

## 8. Replication Feasibility
- **Data access:** Statistik Industri (BPS Indonesia) for large and medium firms — same data as the SI/IBS panel used in related papers; access via BPS application; ESDM energy conversion coefficients publicly available; IPCC emission factors (Table 2 in paper) are standard
- **Code availability:** No replication archive cited; LMDI decomposition is well documented and implementable in standard software (Excel, Python, R, Stata)
- **Barriers:** Fuel energy data in heterogeneous physical units requiring BOE conversion; matching firms across years for consistent sub-sector/size classification; 2010 constant price deflation required for output
