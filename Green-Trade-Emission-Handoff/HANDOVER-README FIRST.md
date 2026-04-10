# Dataset Handover: `si_energy_emissions.dta` + `si_energy_intensity.dta`

> **Prepared:** 2026-04-09 | **Version:** v2 | **Prepared by:** Albert Ludi
> **For:** Mba Deasy (and her research assistant)
> **Purpose:** Analysis-ready datasets for DiD / event-study on firm internationalization and carbon intensity

---

## Reproduce the Pipeline from Scratch

If you want to regenerate all outputs from the raw data, three steps:

**Step 1 — Edit one line in `dofiles/00_config.do`**

Open `dofiles/00_config.do` and replace the placeholder path with the actual path to this folder on your machine:

```stata
* Before (placeholder):
global handoff "/path/to/Green-Trade-Emission-Handoff"

* After (your actual path, e.g.):
global handoff "/Users/deasy/Documents/Green-Trade-Emission-Handoff"
```

**Step 2 — Run the config to set globals**

In Stata:
```stata
do "/Users/deasy/Documents/Green-Trade-Emission-Handoff/dofiles/00_config.do"
```

**Step 3 — Run the full pipeline**

```stata
do "$dofiles/00b_run_all_pipeline.do"
```

This runs all 24 do-files in order and produces:
- `output/si_energy_emissions.dta` (314,576 obs)
- `output/wpio_extended.dta` (131 obs)
- `output/si_energy_intensity.dta` (314,574 obs)
- `output/si_energy_emission_and_intensity.dta` (primary final dataset, 314,576 obs, 227 vars)
- 25 summary tables in `output/tables/`
- 40 figures in `output/figures/`
- Individual step logs in `logs/` (one per do-file)

**Pre-requisites — raw input files that must be present:**

| File | Location | Description |
|------|----------|-------------|
| `data8514_SI.dta` | `data/raw/` | Raw SI/IBS panel 1985–2014 (~344 MB) |
| `wpio.dta` | `data/raw/` | WPI deflator 1983–2012 |
| `si2000.dta` – `si2014.dta` | `data/si_annual/` | 15 annual SI files |
| Two BPS IHPB Excel files | `data/ihpb/` | See `dofiles/00c_extract_ihpb.do` header for filenames |
| `ihpb_isic4_concordance.csv` | `data/concordance/` | ISIC4-to-IHPB sub-sector mapping |

Full methodology for every decision: `docs_source/data_industry_emission.qmd`

---

## Quick Orientation

One file to work with:

```
output/si_energy_emission_and_intensity.dta    ← PRIMARY FINAL DATASET
```

- **314,576 firm-years** · **227 variables** · Indonesian Industrial Survey (SI/IBS) 2000–2014
- Emissions (Scope 1 + 2, Spec 1 & 2, 5 sensitivity variants) + energy intensity measures in one file
- Ready for regression — load and go

Component files (for reference / incremental rebuild only):
```
output/si_energy_emissions.dta    ← emissions only (205 vars) — input to step 16
output/si_energy_intensity.dta    ← intensity only (35 vars)  — intermediate output of step 16
```

Full methodology: `docs_source/data_industry_emission.qmd` (long technical memo, read if you need to justify a number)

---

## Research Context

**Mba Deasy's question:** Do firms that first internationalize (begin exporting or importing) subsequently reduce their carbon intensity?

**Identification strategy:** DiD / event-study around the year a firm first appears as an exporter or importer. The SI panel has `psid` as the plant identifier and `year` covers 2000–2014.

**Your role with this dataset:** Use it as the outcome panel. The treatment variable (export/import entry indicator) must come from Mba Deasy's trade linkage — it is NOT in this file.

---

## Load the Data

```stata
* ── After running 00_config.do (see "Reproduce" section above) ────────────
use "$output/si_energy_emission_and_intensity.dta", clear
di "Obs: " _N   // should print 314,576
di "Vars: " c(k)  // should print 227
```

---

## Primary Outcomes — What to Put on the Left-Hand Side

| Use case | Variable | Notes |
|---|---|---|
| **DiD / event-study (main spec)** | `ln_co2_total_s1` | Log total CO₂e, Spec 1. Year FE absorb grid EF variation — use this. |
| **Carbon intensity (main spec)** | `ln_co2_intensity_worker_s1` | Log CO₂e per worker. Useful as a size-neutral intensity measure. |
| **Carbon intensity by output** | `co2_intensity_output_s1` | tCO₂e per 000 Rp value added. Not logged — trim before using. |
| **Robustness: different NCV** | `ln_co2_total_s2` | Spec 2 (ESDM HEES NCV). Compare to Spec 1 — if treatment coefficient barely moves, NCV choice doesn't drive results. |
| **Robustness: Scope 1 only** | `ln_co2_scope1_s1` | Direct fuel combustion only (no electricity). Tests whether result is driven by grid EF assumption. |
| **Descriptive levels / trends** | `co2_total_s1` | Levels in tCO₂e. Use for graphs, summary stats, not regression. |

**One-sentence rule:** Use `ln_co2_total_s1` as your primary outcome. Report `ln_co2_intensity_worker_s1` as a secondary. Put `ln_co2_total_s2` in the robustness table.

---

## Key Identifiers

| Variable | Description |
|---|---|
| `psid` | Plant identifier (consistent across years — use this for `xtset`) |
| `year` | Survey year (2000–2014, integer) |
| `isic2` | ISIC/KBLI 2-digit industry code |
| `isic5_raw` | Raw 5-digit KBLI code from the survey |
| `dprovi` | Province code (BPS 2-digit) |
| `dkabup` | District/kabupaten code |

```stata
xtset psid year
```

---

## Panel Setup for DiD

```stata
use "$output/si_energy_emission_and_intensity.dta", clear

* Merge in Mba Deasy's treatment variable here
* merge 1:1 psid year using "$output/treatment_panel.dta", keep(3) nogen

xtset psid year

* Basic DiD
reghdfe ln_co2_total_s1 treated_post controls, ///
    absorb(psid year) cluster(psid)

* Event study (replace with your event-year variable)
reghdfe ln_co2_total_s1 ib(-1).event_time controls, ///
    absorb(psid year) cluster(psid)
```

---

## Firm-Level Controls Available in This File

| Variable | Description |
|---|---|
| `ltlnou` | Total workers (persons) — use `ln(ltlnou)` as a control |
| `vtlvcu` | Total output value (Rp 000) |
| `output` | Output / sales (alternative measure) |
| `iinput` | Intermediate inputs (Rp 000) |

All monetary variables are **nominal Rp 000**. The WPI deflator (BPS IHPB, base 2000=100) is applied in `si_energy_intensity.dta` — see the Energy Intensity Variables section below.

---

## Fuel Variables (Physical Quantities)

These are the cleaned inputs to the emission calculation. Useful for mechanism analysis.

| Variable | Unit | Coverage |
|---|---|---|
| `fuel_diesel_ltr` | litres | Near-continuous (2000–2014) |
| `fuel_petrol_ltr` | litres | Near-continuous |
| `fuel_kerosene_ltr` | litres | Absent 2001–2002 |
| `fuel_coal_kg` | kg | Absent 2001–2002 |
| `fuel_lpg_kg` | kg | Absent 2001–2005 |
| `fuel_citygas_m3` | m³ | Absent 2001–2005 |
| `fuel_othergas_m3` | m³ | Absent 2001–2005 |
| `fuel_coalbriq_kg` | kg | Sparse (<1,500 obs) |
| `fuel_coke_kg` | kg | Sparse (<1,500 obs) |
| `elec_pln_kwh` | kWh | PLN grid electricity (dominant source) |
| `elec_nonpln_kwh` | kWh | Non-PLN purchased |
| `elec_owngene_kwh` | kWh | Own-generated (not used in Scope 2) |
| `elec_purchased_kwh_strict` | kWh | Strict aggregate used in emission calc: PLN + non-PLN only |

---

## Emission Variables: What Exists and What It Means

### Spec 1 (PRIMARY — use this)
> IPCC 2006 EF × BPS Neraca Energi NCV + **time-varying** grid EF (0.000599–0.000914 tCO₂/kWh by year)

| Variable | Description |
|---|---|
| `co2_diesel_s1` … `co2_coke_s1` | Per-fuel Scope 1 emissions (9 fuels), tCO₂e |
| `co2_scope1_s1` | Total Scope 1 (direct fuel combustion), tCO₂e |
| `co2_scope2_s1` | Scope 2 (purchased electricity, time-varying EF), tCO₂e |
| `co2_total_s1` | Scope 1 + Scope 2 total, tCO₂e — **primary level variable** |
| `ln_co2_total_s1` | Log total — **primary regression outcome** |
| `ln_co2_scope1_s1` | Log Scope 1 only |
| `co2_scope1_nfuels` | Count of fuels with non-missing emissions (0–9) |
| `co2_intensity_worker_s1` | tCO₂e per worker |
| `co2_intensity_output_s1` | tCO₂e per 000 Rp output |
| `ln_co2_intensity_worker_s1` | Log intensity per worker |

### Spec 2 (ROBUSTNESS)
> IPCC 2006 EF × ESDM HEES NCV + **static** grid EF (0.000867 tCO₂/kWh)

| Variable | Description |
|---|---|
| `co2_diesel_s2` … `co2_coke_s2` | Per-fuel Scope 1 emissions, tCO₂e |
| `co2_scope1_s2` | Total Scope 1, tCO₂e |
| `co2_scope2_s2` | Scope 2 (static EF), tCO₂e |
| `co2_total_s2` | Total Scope 1 + Scope 2, tCO₂e |
| `ln_co2_total_s2` | Log total — robustness regression outcome |
| `co2_intensity_worker_s2` | tCO₂e per worker (Spec 2) |
| `ln_co2_intensity_worker_s2` | Log intensity per worker (Spec 2) |

### Sensitivity Variants
Each variant changes ONE assumption and recomputes the total; all others remain at Spec 1.

| Variable | What it tests |
|---|---|
| `ln_co2_total_alt_lpg` | LPG NCV: GCV→NCV (HIGH priority; ~−12.7% for LPG-heavy firms) |
| `ln_co2_total_alt_kali` | Coal NCV: HEES→Kalimantan thermal (base: Spec 2; +2% on coal) |
| `ln_co2_total_alt_rosita` | Grid EF: 0.000867→0.000904 tCO₂/kWh (Rosita 2020) |
| `ln_co2_total_alt_exc2004` | Exclude coal 2004–2005 (unit-label ambiguity robustness) |
| `ln_co2_total_alt_towngas` | Gas EF: natural gas→gas works gas (LOW priority; ~4% of firm-years) |

---

## Energy Intensity Variables (`si_energy_intensity.dta`) *(new in v2)*

Built by `16_energy_intensity.do` from `si_energy_emissions.dta`. Contains 314,574 obs (2 dropped for missing `output`).

### Monetary Energy Intensity (Imbruno 2018 approach)

> (fuel expenditure + electricity expenditure) / gross output — both numerator and denominator in nominal Rp, so the ratio is unit-free. Year + industry FE in the regression absorb price trends — no separate WPI deflation needed for the *monetary* measure.

| Variable | Description |
|---|---|
| `energy_exp_zero` | Total energy expenditure Rp000 (fuel + elec, structural missing→0) |
| `ei_monetary_zero` | Energy intensity: monetary (main spec), Rp/Rp |
| `ln_ei_monetary_zero` | Log — **primary Imbruno-style outcome** |
| `energy_exp_strict` | Total energy expenditure Rp000 (strict: missing if either missing) |
| `ei_monetary_strict` | Energy intensity: monetary (robustness), Rp/Rp |
| `ln_ei_monetary_strict` | Log — robustness |
| `flag_ei_gt1_zero` | Flag: monetary EI > 1 (energy cost exceeds output; keep but flag) |

### Physical Energy Intensity (GJ-based)

| Variable | Description |
|---|---|
| `total_gj_s1` | Total energy GJ: Scope 1 fuels + purchased electricity (Spec 1 NCV) |
| `gj_fuel_s1` | Fuel combustion GJ only (Scope 1) |
| `gj_elec_s1` | Electricity GJ (Scope 2) |
| `ei_gj_s1` | Nominal GJ intensity: GJ / nominal output Rp000 |
| `ln_ei_gj_s1` | Log nominal GJ intensity |
| `output_real` | Real output Rp000 in 2000 prices (WPI deflated) |
| `wpi` | WPI deflator (base 2000=100, 3-digit ISIC mean, from `wpio_extended.dta`) |
| `ei_gj_real` | **Real GJ intensity**: GJ / real output — primary physical outcome |
| `ln_ei_gj_real` | Log real GJ intensity — **use this for physical intensity regression** |
| `ei_co2_real` | CO₂ intensity: tCO₂e per real Rp000 output (Spec 1, WPI-deflated) |
| `ln_ei_co2_real` | Log CO₂ intensity (WPI-deflated) |

**WPI coverage note:** 314,345 / 314,574 obs (99.93%) have a valid WPI deflator. The 229 missing are non-manufacturing ISIC codes (mainly code 93091 "Jasa Penunjang Industri" and a few miscoded coal mining obs) — they retain missing for `output_real` and `ei_gj_real`.

**Which intensity outcome to use:**
- Imbruno-style (expenditure-share): use `ln_ei_monetary_zero`
- Physical (GJ, WPI-deflated): use `ln_ei_gj_real`
- CO₂-per-output (WPI-deflated): use `ln_ei_co2_real`
- Log CO₂ total (for level regressions): use `ln_co2_total_s1` — all in the same combined file

---

## Outlier Flags

69 flag variables from `08_outlier_flags.do`. Three key composite flags:

| Variable | Meaning | Action |
|---|---|---|
| `flag_any_sev` | Severe outlier on any of D1/D2/D3 | **Already dropped** — no obs with `flag_any_sev==1` in this file |
| `flag_any_mod` | Moderate outlier on any dimension | Retained. ~9.2% of remaining sample. |
| `flag_n_dims` | How many dimensions flagged (0–3) | Use to construct sensitivity sub-samples |

```stata
* Confirm no severe flags remain
assert flag_any_sev == 0

* Robustness: exclude moderate flags too
reghdfe ln_co2_total_s1 treated_post controls if flag_any_mod == 0, ///
    absorb(psid year) cluster(psid)
```

---

## Data Gotchas

**1. Year 2010 dip is real, not a data error.**
The 2010 SI survey collected only monetary values — physical quantities were not collected that year. This means Scope 1 (fuel combustion) is missing/zero for most firms in 2010. Scope 2 (electricity) is mostly intact. If you include year FE, this is absorbed. If you are doing levels analysis, flag 2010.

**2. Year 2001–2002: coal and kerosene structurally absent.**
These fuels were not collected in the 2001–2002 questionnaire waves. `fuel_coal_kg` and `fuel_kerosene_ltr` are 100% missing for those years — not a quality issue.

**3. Spec 1 vs Spec 2 Scope 2 comparison: pooled difference is ~0%.**
The time-varying Spec 1 EF averages to approximately the static Spec 2 EF over the full 2000–2014 pool. Year-by-year differences are large (Spec 1 is 33–45% lower in 2000–2010; ~5% higher in 2014). With year FE in the regression, both specs give nearly identical treatment coefficients — that's by design.

**4. `co2_total_s1` is missing if ALL energy inputs are missing.**
If a firm reported no fuel and no electricity in a given year, `co2_total_s1` is missing (not zero). The variable `co2_scope1_nfuels` tells you how many fuels contributed. Use `!missing(co2_total_s1)` as the sample restriction.

**5. Monetary variables are nominal.**
`vtlvcu`, `iinput`, `output` are in nominal Rp 000. If you use them as controls or denominators for intensity measures, apply a deflator (not provided in this file — get from BPS).

---

## Data Provenance Chain

```
data8514_SI/data8514_SI.dta          ← Raw SI/IBS panel 1985–2014 (344MB; never modify)
         │
         ↓  dofiles/01_append_si_energy.do
si_energy_harmonized.dta             ← Appended, renamed, gap-filled
         │
         ↓  dofiles/06_harmonize_si_energy.do
si_energy_harmonized.dta             ← Canonical variable names (fuel_*, elec_*)
         │
         ↓  dofiles/08_outlier_flags.do
si_energy_flagged.dta                ← + 72 flag_* variables (D1/D2/D3)
         │
         ↓  dofiles/09_clean_apply.do
si_energy_harmonized_cleaned.dta     ← Drop flag_any_sev==1  (326,382 → 314,576 obs)
         │
         ↓  dofiles/10_carbon_convert.do
si_energy_emissions.dta              ← + Spec 1 and Spec 2 emission variables
         │
         ↓  dofiles/11_sensitivity_variants.do
si_energy_emissions.dta              ← + 5 sensitivity variant columns (in-place)
         │
         ↓  dofiles/12_descriptive_stats.do
output/tables/desc_*.csv             ← Summary tables (read-only; do not regenerate
output/figures/figD*.png                unless you have the full pipeline data)
         │
         ↓  dofiles/14_finalize_variable_order.do
si_energy_emissions.dta              ← FINAL emissions: 204 vars, clean order, all labels
         │
         ↓  dofiles/15_extend_wpio_ihpb.do
output/wpio_extended.dta             ← WPI panel: base 2000=100, 4-digit ISIC, 1983–2014
                                        (BPS IHPB; 2013–14 chain-linked; ISIC 37 via CAGR)
         │
         ↓  dofiles/16_energy_intensity.do
si_energy_intensity.dta              ← intensity only: monetary + GJ (real), 314,574 obs
         │
         ↓  dofiles/16_energy_intensity.do §8 (merge back)
si_energy_emission_and_intensity.dta ← PRIMARY FINAL: 227 vars, 314,576 obs  ← YOU ARE HERE
         │
         ↓  dofiles/17_ei_figures.do
output/figures/fig_ei_*.png          ← Energy intensity trend/distribution figures
         │
         ↓  dofiles/18_fig_unit_price.do + 19_fig_subsidy_context.do
output/figures/fig_unit_price_*.png  ← Unit price heterogeneity + subsidy context figures
         fig_subsidy_context.png
```

---

## Minimal Regression Template

```stata
* ── Setup ───────────────────────────────────────────────────────────────────
use "$output/si_energy_emission_and_intensity.dta", clear

* Merge treatment here
* merge 1:1 psid year using "$output/treatment_panel.dta", keep(3) nogen

xtset psid year

* ── Outcome check ────────────────────────────────────────────────────────────
su ln_co2_total_s1, detail              // mean ≈ 5–6 log tCO2e
assert flag_any_sev == 0                // confirms no severe outliers

* ── Main spec: DiD with TWFE ─────────────────────────────────────────────────
* ssc install reghdfe, replace
* ssc install ftools, replace

reghdfe ln_co2_total_s1 c.treated_post c.ln_workers, ///
    absorb(psid year) cluster(psid)
est store main

* ── Robustness 1: Spec 2 ────────────────────────────────────────────────────
reghdfe ln_co2_total_s2 c.treated_post c.ln_workers, ///
    absorb(psid year) cluster(psid)
est store rob_spec2

* ── Robustness 2: exclude moderate flags ────────────────────────────────────
reghdfe ln_co2_total_s1 c.treated_post c.ln_workers if flag_any_mod==0, ///
    absorb(psid year) cluster(psid)
est store rob_noflag

* ── Export ───────────────────────────────────────────────────────────────────
* ssc install esttab, replace
esttab main rob_spec2 rob_noflag using "$output/table_main.tex", ///
    replace booktabs label se star(* 0.10 ** 0.05 *** 0.01) ///
    title("Effect of Internationalization on Log CO2e") ///
    mtitles("Main (S1)" "Spec 2" "No Mod Flags")
```

---

## For Claude Code Sessions

If you're running this with Claude Code, paste this as context at the start of your session:

> **Primary dataset:** `output/si_energy_emission_and_intensity.dta` — 314,576 firm-years, 227 vars, Indonesian Industrial Survey 2000–2014. Panel ID: `psid`. No severe outliers (`flag_any_sev==0`). DiD outcome: `ln_co2_total_s1`. Robustness: `ln_co2_total_s2`. Imbruno intensity: `ln_ei_monetary_zero`. Physical (WPI-deflated): `ln_ei_gj_real`. CO₂-per-output: `ln_ei_co2_real`. WPI deflator (base 2000=100): `wpi`. Full methodology in `docs_source/data_industry_emission.qmd`.

---

## What These Files Do NOT Contain

- Trade linkage / export-import treatment variable → get from Mba Deasy's customs/trade panel
- Deflators for *monetary control variables* (vtlvcu, iinput) → get from BPS
  - Note: WPI deflator for output IS provided in `si_energy_intensity.dta` (variable `wpi`)
- Firm-level trade shares, destination-country controls → get from trade data
- Balanced panel restriction → apply yourself with `egen balanced = min(!missing(co2_total_s1)), by(psid)`

---

## Questions?

Read `docs_source/data_industry_emission.qmd` first — it documents every decision.

If something in the dataset looks wrong (variable missing, unexpected level, structural gap in a year), check the do-files in `dofiles/` — they are numbered 00–19 (plus `check_elec_missing.do` diagnostic) and each has a header comment explaining what it does and why. Run `00b_run_all_pipeline.do` to reproduce the full pipeline from scratch.
