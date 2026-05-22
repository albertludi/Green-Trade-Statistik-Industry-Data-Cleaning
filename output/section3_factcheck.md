# Section 3 (Data) — Fact-Check Report

**Document checked:** `output/intro_literature_data_v1_22may.docx`
**Ground-truth source:** `Green-Trade-Emission-Handoff/docs_source/data_industry_emission.qmd`
**Date:** 2026-05-22

**Status key:** ✓ Confirmed · ~ Approximately confirmed (note discrepancy) · ✗ Not found in QMD · [PLACEHOLDER] intentionally unverified

---

## 3.1 Data sources and sample

| Claim | Category | Status | QMD evidence / note |
|---|---|---|---|
| Panel built from the Indonesian Industrial Survey (Statistik Industri / IBS), the annual census of manufacturing establishments conducted by BPS | Methodological | ✓ | L136: "the Indonesian Industrial Survey (Statistik Industri / IBS — the annual census of medium and large manufacturing establishments conducted by BPS". |
| Survey covers all medium and large establishments, defined as those with twenty or more workers | Methodological | ~ | QMD confirms "medium and large manufacturing establishments" (L136) but does **not** state the "twenty or more workers" threshold anywhere. The 20-worker cutoff is the standard BPS SI definition and is correct, but it is an external fact not documented in the QMD — verify against BPS SI methodology. |
| Sample spans 2000 to 2014 | Quantitative | ✓ | Subtitle L3 "Statistik Industri 2000–2014"; L381/L384 panel "appending the 15 annual SI files" `si2000.dta`–`si2014.dta`. |
| Survey records physical quantities of energy by fuel type and electricity source | Methodological | ✓ | L193 "maps every fuel item in the IBS/SI questionnaire"; L404 physical quantity vars (`*liu`, `*kgu`, `*m3u`, `*khu`). |
| Energy data from annual survey files; trade status, value added, industry codes from the long-form panel; linked 1:1 on plant identifier (psid) and survey year | Methodological | ✓ | L384 "merged 1:1 (psid×year) with `data8514_SI.dta`"; L145 "A `merge 1:1 psid year` is valid — `psid` is unique within each source × year". |
| Match ranges from 82 to 95 percent of establishments by year | Quantitative | ✓ | L145 "the match is not perfect (82–95% by year)"; L384 "~82–95%/year". |
| Retain only matched observations, yielding a matched panel of 326,382 firm-year observations | Quantitative | ✓ | L381/L384 "retaining matched firms only (N=326,382)"; L398 table total **326,382**. |
| Apply the outlier-trimming rule of Amiti and Konings (2007), dropping extreme year-on-year output/input growth and extreme within-industry energy levels | Methodological | ✓ | L942 D2 growth filter "directly taken from Amiti & Konings (2007 ...)"; L1040 D1/D2/D3 severe = "extreme level, growth, or intensity outliers". |
| This step removes 11,806 firm-years | Quantitative | ✓ | L1010 "`flag_any_sev` — any severe flag | 11,806"; L1950 "additional 11,806 firm-years with severe-flag anomalies". |
| ... or 3.6 percent of the matched panel | Quantitative | ~ | L1010 reports **3.62%** (and L1041/L1950 give 96.38% retained → 3.62% dropped). Document rounds to "3.6 percent" — accurate rounding, minor; consider "3.6" is fine. |
| Final analysis sample of 314,576 firm-year observations | Quantitative | ✓ | L92, L655, L1016, L1029, L1041, L1950 all give **314,576** (96.38% of matched panel). |

## 3.2 Measuring trade participation

| Claim | Category | Status | QMD evidence / note |
|---|---|---|---|
| Entire subsection bracketed "[Placeholder — to be completed by co-authors...]" | Placeholder | [PLACEHOLDER] | Intentionally unverified — defines export/import/FDI entry indicators, sustained-entry rule, cohort construction. |

## 3.3 Constructing emissions and energy-productivity measures

| Claim | Category | Status | QMD evidence / note |
|---|---|---|---|
| Most firm-level trade-environment studies rely on regulatory air-pollution data — US plants (Holladay 2016; Cherniwchan 2017; Shapiro and Walker 2018), China enforcement surveys (Rodrigue, Sheng, Tan 2024); Forslid et al. (2018) use CO₂ from Swedish administrative registers | Citation claim | — verify externally | QMD does not characterise these papers' data sources. Consistent with the Literature Review (Sections 2.3/2.4 of the same document). Verify against the cited papers. |
| No comparable emissions source exists for Indonesian manufacturing; CO₂e constructed from the ground up using physical fuel quantities reported in the SI | Methodological | ✓ | L1100s pipeline: Step 1 physical quantity → GJ, Step 2 GJ → CO₂e; L29 of doc echoes "bottom-up approach". |
| Applies the IPCC 2006 Tier 1 approach at the firm level | Methodological | ✓ | L1106 "IPCC (2006) Tier-1 default emission factors"; L1110 "IPCC 2006 Tier-1 defaults are the accepted standard for Indonesia". Applied per firm-year on reported physical quantities. |
| Distinguishes the measure from Imbruno and Ketterer (2018), which proxies energy performance with energy expenditure data from the SI | Citation claim | ✓ | QMD L122, L2914, L2923, L2936, L2948 confirm Imbruno & Ketterer (2018) use SI energy *expenditure* (monetary intensity); L2948 "who use the survey's total fuel expenditure variable directly." |
| Domestic fuel prices were heavily administered throughout the sample period under the fuel subsidy regime; expenditure conflates price variation with consumption | Methodological | ✓ | L836+ price-variability discussion; L3105 energy subsidy reform policies; L111 (doc) and QMD §7-intensity discussion confirm subsidy-driven price distortion of expenditure measures. |
| Zain, Patunru, and Hartono (2025) also build emissions from physical SI fuel quantities via a direct gigajoule pathway | Citation claim | ✓ | L1112 "This approach is used by Zain, Patunru & Hartono (2025) (Hybrid Energy IO framework)"; L1110 "Prior studies (Zain et al. 2025 ...) use the ESDM HEES as their NCV source." |
| Pipeline routes combusted fuels through fuel-specific calorific values and IPCC combustion factors (Scope 1) and converts purchased electricity with a time-varying grid emission factor (Scope 2) | Methodological | ✓ | L1106 two-step pipeline; L80–82 Scope 1 NCV source + Scope 2 time-varying grid EF; L816 "time-varying grid EF from BPS Neraca Energi stored in `co2_scope2_s1`". |
| Adopts BPS Neraca Energi net calorific values as the primary specification rather than the ESDM HEES values Zain et al. employ | Methodological / Citation | ✓ | L1110 "This pipeline introduces BPS Neraca Energi NCV values as the primary specification (Spec 1) ... retains ESDM HEES as a robustness check (Spec 2)"; L795 same. |
| HEES gross-to-net calorific basis mismatch inflates HEES-based estimates for fuels such as LPG | Methodological | ✓ | L1110 "the ESDM HEES value (52.145 GJ/ton) is on a GCV basis while IPCC 2006 ... require NCV"; L1264 "the ~14.6% gap ... consistent with a GCV convention for LPG". |
| Main fuel categories: diesel, gasoline, kerosene, coal, LPG, city gas, plus sparse fuels including coal briquettes and other gas | Methodological | ✓ | L35–44 fuel table: diesel, petrol, kerosene, coal, LPG, city gas, other gas, fuel oil, coke, coal briquettes. (Doc omits fuel oil/coke from the "main" list — acceptable as both are flagged sparse in QMD.) |
| Questionnaire changed across waves; fuel items harmonised using survey questionnaires for each year (BPS, 2000–2014) into canonical variables | Methodological | ✓ | L189 "SI questionnaire changed substantially across survey waves"; L193+ year-by-year mapping; harmonisation do-file `06_harmonize_si_energy.do`. |
| Purchased electricity recorded separately for the state grid (PLN) and non-PLN sources | Methodological | ✓ | L50–51 `eplkhu`/`elec_pln_kwh` (PLN state grid) and `enpkhu`/`elec_nonpln_kwh` (Non-PLN purchased). |
| LPG and city gas are structurally absent from the 2001–2005 questionnaires; treated as missing not zero | Methodological | ~ | **Discrepancy.** QMD: city gas absent 2001–2005 (L634), LPG absent 2001–2005 as a gap (L635) — but LPG and city gas *were* collected in 2000 (L40, L438–439, L257, L263; LPG 2000 had expenditure only, no physical-quantity column). QMD also describes the structural gap as "2001–2005" in §5/§7 (L1094 "For 2001–2005, gas and LPG are structurally absent"). The doc statement "absent from the 2001–2005 questionnaires" matches QMD §5/§7 wording and is correct. Note: the QMD fuel-status table (L39) labels LPG "Absent 2000–2005" because 2000 lacks the *physical-quantity* column — the doc's 2001–2005 framing is consistent with the harmonised-panel usability statement. No correction needed; flagged for awareness. |
| Completeness indicator records number of fuel types with valid observations | Methodological | ✓ | L1091 "`co2_scope1_nfuels` records how many of the 9 fuel types contributed to the Scope 1 sum (range 0–9) ... filter on completeness". |
| Full harmonisation map reported in Annex A | Methodological | ✗ | QMD has no "Annex A"; the harmonisation map lives in QMD §5 / the fuel tables (L35–44, L193+). "Annex A" is a forward reference to a paper annex that does not yet exist — verify the paper will include it, or repoint the cross-reference. |
| Physical quantities converted to GJ using net calorific values from the Indonesian Energy Balance (Neraca Energi Indonesia), published by the Ministry of Energy and BPS — this is Specification 1 | Methodological | ✓ | L1204 "Spec 1 (primary) draws from BPS Neraca Energi — Indonesia's official national energy balance"; L795 "Spec 1 (BPS Neraca Energi NCV)". (Doc attributes publication to "Ministry of Energy and BPS" — QMD attributes Neraca Energi to BPS; the ESDM/Ministry attribution applies to HEES. Minor — see external-verification note.) |
| Scope 1 computed by multiplying GJ by fuel-specific emission factors in IPCC (2006), Table 2.3, for the manufacturing sector | Methodological | ✓ | L81 "IPCC 2006 Table 2.3, manufacturing sector"; L1297 "IPCC (2006) Table 2.3 — Default emission factors for stationary combustion in Manufacturing Industries". |
| For coal, apply the sub-bituminous emission factor, corresponding to the dominant coal type in Indonesian manufacturing | Methodological | ✗ | **Discrepancy.** QMD L1312 states the opposite: "Both Spec 1 and Spec 2 use the IPCC 2006 **Other Bituminous Coal EF** (95.28 tCO₂e/TJ) — the difference across specs is entirely in the NCV assumption ... The sub-bituminous EF (96.78) is only 1.6% higher than the bituminous default; this marginal difference is within measurement uncertainty and **is not separately tested**." The QMD does note Indonesian coal is predominantly sub-bituminous, but the pipeline applies the **bituminous** EF, not the sub-bituminous EF. The doc sentence should be corrected to: coal uses the IPCC bituminous default EF (the sub-bituminous EF is reported only as a sensitivity, ~1.6% higher). |
| Specification 2 (Appendix B sensitivity) substitutes net calorific values from the Ministry of Energy HEES energy statistics | Methodological | ~ | QMD confirms Spec 2 = ESDM HEES NCV (L795, L1110, L1568) and that HEES is robustness, not primary. QMD does not label any section "Appendix B" — "Appendix B" is a forward reference to a paper appendix; verify the paper structure. |
| Spec 2 sensitivity uses the bituminous coal emission factor in place of sub-bituminous | Methodological | ✗ | **Discrepancy / reversed.** Per QMD L1312, the *baseline* (both specs) already uses the bituminous EF, and the *sub-bituminous* EF is the alternative noted as untested. The doc has the sensitivity direction reversed. Should read: a sub-bituminous EF sensitivity exists conceptually (~+1.6%) but is not separately estimated; the baseline already uses bituminous. Recommend rewriting both coal-EF sentences for consistency with the QMD. |
| Scope 2 captures indirect emissions embodied in purchased electricity; electricity converted from kWh to GJ and multiplied by a year-specific grid emission factor | Methodological | ✓ | L816 Scope 2 = electricity × grid EF; L1171 pipeline "× Grid EF"; time-varying for Spec 1. (Note: QMD grid EF is expressed in tCO₂/kWh and applied directly to kWh; the doc's "convert kWh to GJ" framing is presentational — see L1324 which says the 3.6 MJ/kWh constant does not appear as an explicit step.) |
| Grid emission factor constructed from annual national generation-mix data (PLN and IEA) combined with IPCC (2006) fuel-specific emission factors | Methodological | ✓ | L82 "constructed from Neraca Energi PLN fuel consumption × IPCC EF ÷ total kWh generated"; L1347 "Time-varying (Neraca Energi)". QMD attributes generation data to BPS Neraca Energi/PLN; the explicit "IEA" source is **not named in the QMD** — verify the IEA input externally. |
| Grid emission factor rises from 0.000599 to 0.000914 tonnes CO₂ per kWh over the sample | Quantitative | ✓ | L82, L1330, L1347 "Time-varying, 0.000599–0.000914 tCO₂/kWh"; L1382 (2010 = 0.000599), L1386/L1469 (2014 = 0.000914). |
| Total emissions for each firm-year are the sum of Scope 1 and Scope 2 | Methodological | ✓ | L1992 "'Total CO₂e' = Scope 1 + Scope 2"; doc L109 echoes "Total emissions ... are the sum of Scope 1 and Scope 2". |
| Value added measured directly from the survey | Methodological | ✓ | QMD uses `vtlvcu` (value added) directly from `data8514_SI.dta` (L2319). |
| Value added deflated to constant prices using "[DEFLATOR — to be confirmed]" | Placeholder | [PLACEHOLDER] | Bracketed; deflation specification to be verified by co-authors. QMD §EI / L2996 uses WPI indices (base 2000=100) from BPS IHPB — likely the intended deflator, but doc leaves it open. |
| Outcome variables: VA/GJ = real value added per GJ; VA/CO₂ = real value added per tonne CO₂e; both in natural logs; higher = greater efficiency | Methodological | ✓ | Consistent with QMD intensity framing (L117 firm-level energy-intensity measures; L2936 deflation of denominator; doc L13 defines VA/GJ and VA/CO₂). Productivity (value-per-input) orientation matches QMD §EI. |
| Measures built from physical quantities rather than expenditure because fuel subsidies distorted monetary energy spending | Methodological | ✓ | L1100s + L2936 + L836; QMD repeatedly contrasts physical-quantity (subsidy-immune) vs. expenditure (subsidy-distorted). |

## 3.4 Descriptive statistics

| Claim | Category | Status | QMD evidence / note |
|---|---|---|---|
| Entire subsection bracketed "[Placeholder — summary statistics table and descriptive figures to be added.]" | Placeholder | [PLACEHOLDER] | Intentionally unverified — QMD §D (descriptive statistics, L1932+) contains the source tables/figures for later insertion. |

---

## Summary

- **Total distinct claims checked:** 37 (3.1: 10 · 3.2: 1 placeholder · 3.3: 24 · 3.4: 1 placeholder)
- **✓ Confirmed:** 26
- **~ Approximately confirmed (minor discrepancy):** 5
- **✗ Not found / contradicted:** 3
- **[PLACEHOLDER]:** 3
- **Citation claim — verify externally:** 1 (regulatory-data characterisation of prior studies)

### Issues requiring attention (✗ and ~)

| # | Claim | Issue |
|---|---|---|
| 1 | "For coal, we apply the sub-bituminous emission factor" (3.3) | ✗ **Contradicted.** QMD L1312: both Spec 1 and Spec 2 apply the IPCC **bituminous** ("Other Bituminous Coal") EF. The sub-bituminous EF is ~1.6% higher and noted as *not separately tested*. Rewrite the sentence. |
| 2 | "Spec 2 ... using the bituminous coal emission factor in place of sub-bituminous" (3.3) | ✗ **Reversed.** Per QMD the baseline is already bituminous; the sub-bituminous figure is the (untested) alternative. The sensitivity direction is backwards. Rewrite to match QMD §7.5 footnote. |
| 3 | "The full harmonisation map is reported in Annex A" (3.3) | ✗ **Annex A does not exist in the QMD.** It is a forward reference to a paper annex; confirm the paper will include such an annex or repoint the cross-reference. |
| 4 | "twenty or more workers" size threshold (3.1) | ~ Correct as a BPS fact but **not documented in the QMD** — verify against BPS SI/IBS methodology. |
| 5 | "3.6 percent of the matched panel" (3.1) | ~ QMD gives **3.62%**. "3.6 percent" is correct rounding; keep or state "3.62%". |
| 6 | Neraca Energi "published by the Ministry of Energy and BPS" (3.3) | ~ QMD attributes Neraca Energi to **BPS**; the Ministry of Energy (ESDM) is the publisher of **HEES**. Consider attributing Neraca Energi to BPS only, or "BPS in cooperation with the Ministry of Energy" if confirmed. |
| 7 | "Appendix B" Spec 2 sensitivity location (3.3) | ~ QMD has no "Appendix B"; forward reference to a paper appendix — verify paper structure. |
| 8 | LPG/city gas "structurally absent from the 2001–2005 questionnaires" (3.3) | ~ Consistent with QMD §5/§7 wording (L1094) but the QMD fuel-status table labels LPG "absent 2000–2005" (2000 had expenditure only, no physical-quantity column). No correction needed; awareness flag. |

### Items requiring external verification

1. **Prior-study data sources (3.3 opening sentence).** The characterisation of Holladay (2016), Cherniwchan (2017), Shapiro and Walker (2018) as using US regulatory air-pollution records, Rodrigue et al. (2024) as using China enforcement surveys, and Forslid et al. (2018) as using Swedish CO₂ administrative registers is **not verifiable from the QMD**. It is consistent with the paper's own Literature Review (Sections 2.3–2.4). Verify against the cited papers themselves.
2. **IEA as a grid-EF data source (3.3).** The document states the grid emission factor is built from "national generation-mix data (PLN and IEA)". The QMD documents PLN / BPS Neraca Energi inputs but **does not name the IEA**. Confirm whether IEA generation data actually entered the grid-EF construction, or remove the IEA attribution.
3. **"Twenty or more workers" SI size threshold (3.1).** Standard BPS definition but absent from the QMD — verify against BPS Statistik Industri methodology documentation.
4. **Neraca Energi publisher attribution (3.3).** Confirm whether the Indonesian Energy Balance is published by BPS alone, or jointly with the Ministry of Energy (ESDM).
5. **"Annex A" and "Appendix B" cross-references (3.3).** Both refer to paper sections that do not yet exist. Confirm with co-authors that the paper will contain a harmonisation annex and a Spec-2 sensitivity appendix, or repoint the references.
6. **Value-added deflator (3.3).** Left as "[DEFLATOR — to be confirmed]". QMD uses a WPI/IHPB deflator (base 2000=100) for energy-intensity figures — likely the intended choice; co-authors to confirm.
