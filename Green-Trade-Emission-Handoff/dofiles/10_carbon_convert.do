* ============================================================
* Script: 10_carbon_convert.do
* Purpose: Convert harmonised SI energy variables to CO₂-equivalent
*          emissions for Specification 1 (IPCC 2006 + BPS Neraca Energi, PRIMARY)
*          and Specification 2 (IPCC 2006 + ESDM HEES, robustness).
*
*          Steps:
*            1. Scope 1 — per-fuel emission variables (Spec 1 & 2)
*            2. Scope 1 aggregate + fuel-count diagnostic
*            3. Scope 2 — purchased electricity (Spec 1: time-varying EF; Spec 2: static 0.000867)
*            4. Total Scope 1+2
*            5. Intensity measures (per worker; per nominal output)
*            6. Log outcomes for DiD regression
*            7. Variable labels
*            8. Summary statistics
*            9. Save output/si_energy_emissions.dta
*
*          Conversion factors (Spec 1 — IPCC 2006 + BPS Neraca Energi, PRIMARY):
*            diesel   : 0.002654 tCO2e/litre
*            petrol   : 0.002310 tCO2e/litre
*            kerosene : 0.002494 tCO2e/litre
*            coal     : 0.002496 tCO2e/kg   (Kalimantan thermal NCV)
*            LPG      : 0.002876 tCO2e/kg
*            city gas : 0.002695 tCO2e/m3
*            coke     : 0.002840 tCO2e/kg   (Neraca 2011-2015: 26.377 GJ/ton)
*            coalbriq : 0.002877 tCO2e/kg   (Neraca 2011-2015: 29.308 GJ/ton)
*            elec     : time-varying 0.000599–0.000914 tCO2e/kWh  (Spec 1: Neraca Energi × IPCC 2006)
*                       static 0.000867 tCO2e/kWh             (Spec 2: PLN RUPTL 2015; robustness)
*
*          Conversion factors (Spec 2 — IPCC 2006 + ESDM HEES, robustness):
*            diesel   : 0.002978 tCO2e/litre
*            petrol   : 0.002479 tCO2e/litre
*            kerosene : 0.002616 tCO2e/litre
*            coal     : 0.002448 tCO2e/kg
*            LPG      : 0.003293 tCO2e/kg   (NOTE: HEES likely uses GCV; see §7.9 QMD)
*            city gas : 0.002190 tCO2e/m3
*            coalbriq : 0.002032 tCO2e/kg   (IPCC 2006 default; no HEES value available)
*            coke     : 0.002907 tCO2e/kg   (HEES = 0.027 GJ/kg × 107.68)
*            elec     : 0.000867 tCO2e/kWh  (static PLN RUPTL 2015; distinct from Spec 1)
*
*          See §7 of data_industry_emission.qmd for full derivation,
*          NCV sources, and IPCC 2006 Table 2.3 EF values.
*
* Input:   output/si_energy_harmonized_cleaned.dta
*          (produced by 09_clean_apply.do; 314,576 firm-years — 96.38% of matched panel)
* Output:  output/si_energy_emissions.dta
* Author:  Albert Ludi
* Date:    2026-03-19
* ============================================================

clear all
set more off
capture log close

* ── Paths (all derived from $handoff — set via dofiles/00_config.do) ──────────────
if "$handoff" == "" {
    di as error "ERROR: global 'handoff' is not set."
    di as error "       Run: do {path_to_handoff}/dofiles/00_config.do"
    exit 1
}
global root    "$handoff"
global sidata  "$handoff/data/si_annual"
global output  "$handoff/output"
global logs    "$handoff/logs"
global rawdata "$handoff/data/raw"
global concord "$handoff/data/concordance"
global dofiles "$handoff/dofiles"

log using "$logs/10_carbon_convert.log", replace text

use "$output/si_energy_harmonized_cleaned.dta", clear
di as txt "Obs loaded: " _N

* ============================================================
* SECTION 1 — SCOPE 1: PER-FUEL EMISSION VARIABLES
* ============================================================
* Spec 1 composite factors: NCV (BPS Neraca Energi) × EF (IPCC 2006) ÷ 1000  [PRIMARY]
* Spec 2 composite factors: NCV (ESDM HEES) × EF (IPCC 2006) ÷ 1000          [robustness]
* Units throughout: tCO2e per physical unit (litre / kg / m3)
*
* Missing physical units remain missing (.) — not set to zero.
* A firm that did not report a fuel is distinguishable from one
* reporting zero only by context; we do not assume structural zero.
* The co2_scope1_nfuels companion variable records coverage.

di as txt _n "=== SECTION 1: Scope 1 — per-fuel emission variables ==="

* -- Diesel / Solar (HSD) --
* Composite factors = NCV × IPCC_EF / 1000 (see §7 of QMD for full derivation).
* All factors rounded to 6 decimal places; rounding error < 0.05% per fuel.
gen double co2_diesel_s1   = fuel_diesel_ltr   * 0.002654   // IPCC+Neraca [Spec 1, PRIMARY]
gen double co2_diesel_s2   = fuel_diesel_ltr   * 0.002978   // IPCC+HEES   [Spec 2, robustness]
label var co2_diesel_s1   "Diesel emissions, tCO2e (Spec 1: IPCC+Neraca, PRIMARY)"
label var co2_diesel_s2   "Diesel emissions, tCO2e (Spec 2: IPCC+HEES, robustness)"

* -- Gasoline / Bensin --
gen double co2_petrol_s1   = fuel_petrol_ltr   * 0.002310   // IPCC+Neraca
gen double co2_petrol_s2   = fuel_petrol_ltr   * 0.002479   // IPCC+HEES
label var co2_petrol_s1   "Petrol emissions, tCO2e (Spec 1: IPCC+Neraca, PRIMARY)"
label var co2_petrol_s2   "Petrol emissions, tCO2e (Spec 2: IPCC+HEES, robustness)"

* -- Kerosene / Minyak Tanah --
gen double co2_kerosene_s1 = fuel_kerosene_ltr * 0.002494   // IPCC+Neraca
gen double co2_kerosene_s2 = fuel_kerosene_ltr * 0.002616   // IPCC+HEES
label var co2_kerosene_s1 "Kerosene emissions, tCO2e (Spec 1: IPCC+Neraca, PRIMARY)"
label var co2_kerosene_s2 "Kerosene emissions, tCO2e (Spec 2: IPCC+HEES, robustness)"

* -- Coal / Batubara — taken as-reported for all years (no unit correction; see QMD §4.1) --
gen double co2_coal_s1     = fuel_coal_kg      * 0.002496   // Kalimantan thermal NCV (Neraca) [Spec 1]
gen double co2_coal_s2     = fuel_coal_kg      * 0.002448   // Other bituminous coal (IPCC 2006) [Spec 2/HEES]
label var co2_coal_s1     "Coal emissions, tCO2e (Spec 1: IPCC+Neraca, Kalimantan thermal NCV)"
label var co2_coal_s2     "Coal emissions, tCO2e (Spec 2: IPCC+HEES, bituminous EF)"

* -- LPG --
gen double co2_lpg_s1      = fuel_lpg_kg       * 0.002876   // Neraca NCV (NCV-consistent) [Spec 1]
gen double co2_lpg_s2      = fuel_lpg_kg       * 0.003293   // NOTE: HEES likely GCV; see §7.9 [Spec 2]
label var co2_lpg_s1      "LPG emissions, tCO2e (Spec 1: IPCC+Neraca; NCV-consistent)"
label var co2_lpg_s2      "LPG emissions, tCO2e (Spec 2: IPCC+HEES; GCV/NCV flag — see §7.9)"

* -- City gas / PGN (egam3u) --
gen double co2_gas_s1      = fuel_citygas_m3   * 0.002695   // 0.048 GJ/m3 × 56.15 / 1000 [Neraca]
gen double co2_gas_s2      = fuel_citygas_m3   * 0.002190   // 0.039 GJ/m3 × 56.15 / 1000 [HEES]
label var co2_gas_s1      "City gas emissions, tCO2e (Spec 1: IPCC+Neraca, 0.048 GJ/m3)"
label var co2_gas_s2      "City gas emissions, tCO2e (Spec 2: IPCC+HEES, 0.039 GJ/m3)"

* -- Other gas / non-PGN (egom3u) --
* Same NCV and EF as city gas: both are natural gas distributed through different networks.
* Coverage: 2012–2014 only (~1,352 obs, 0.4%). Low coverage but firms that report it
* should have their emissions counted — exclusion would systematically underreport.
gen double co2_othergas_s1 = fuel_othergas_m3  * 0.002695   // same as city gas, Neraca [Spec 1]
gen double co2_othergas_s2 = fuel_othergas_m3  * 0.002190   // same as city gas, HEES   [Spec 2]
label var co2_othergas_s1 "Other gas emissions, tCO2e (Spec 1: IPCC+Neraca, 0.048 GJ/m3)"
label var co2_othergas_s2 "Other gas emissions, tCO2e (Spec 2: IPCC+HEES, 0.039 GJ/m3)"

* -- Coal briquettes / Briket batubara (ecbkgu) --
* NCV Spec 1 (Neraca): BPS Neraca Energi 2011-2015 "Briket" = 29.308 GJ/ton.
*   Composite (s1=Neraca): 29.308 × 98.18 / 1000 = 0.002877 tCO2/kg.
* NCV Spec 2 (HEES): No HEES value available; use IPCC 2006 default = 20.700 GJ/ton.
*   Composite (s2=HEES): 20.700 × 98.18 / 1000 = 0.002032 tCO2/kg.
* Note: Neraca 2016-2020 revised Briket to 30.209 GJ/ton; we use 2011-2015 (within sample period).
* EF: IPCC 2006 Table 2.3 brown coal briquettes = 98.18 kg CO2e/GJ.
* Coverage: 2012-2014 only (~894 obs, 0.3%). Include: exclude would undercount reporting firms.
gen double co2_coalbriq_s1 = fuel_coalbriq_kg  * 0.002877   // IPCC+Neraca 2011-2015 (29.308 GJ/ton) [Spec 1]
gen double co2_coalbriq_s2 = fuel_coalbriq_kg  * 0.002032   // IPCC 2006 default, no HEES NCV [Spec 2]
label var co2_coalbriq_s1 "Coal briquette emissions, tCO2e (Spec 1/Neraca: Neraca 2011-2015 29.308 GJ/ton)"
label var co2_coalbriq_s2 "Coal briquette emissions, tCO2e (Spec 2/HEES: IPCC 2006 default 20.700 GJ/ton)"

* -- Coke / Kokas (eckkgu) --
* NCV Spec 1 (Neraca): BPS Neraca Energi 2011-2015 "Kokas" = 26.377 GJ/ton.
*   Composite (s1=Neraca): 26.377 × 107.68 / 1000 = 0.002840 tCO2/kg.
* NCV Spec 2 (HEES): HEES = 27.000 GJ/ton = 0.027 GJ/kg.
*   Composite (s2=HEES): 0.027 × 107.68 / 1000 = 0.002907 tCO2/kg.
* Note: Neraca 2016-2020 revised Kokas to 20.195 GJ/ton; we use 2011-2015 (within sample period).
* EF: IPCC 2006 Table 2.3 coke oven coke = 107.68 kg CO2e/GJ.
* Coverage: sparse across panel (<0.1%). Include: firms using coke should not be
* systematically underreported; missing = not reported, not zero.
gen double co2_coke_s1     = fuel_coke_kg      * 0.002840   // IPCC+Neraca 2011-2015 (26.377 GJ/ton) [Spec 1]
gen double co2_coke_s2     = fuel_coke_kg      * 0.002907   // IPCC+HEES (0.027 GJ/kg × 107.68) [Spec 2]
label var co2_coke_s1     "Coke emissions, tCO2e (Spec 1/Neraca: Neraca 2011-2015 26.377 GJ/ton)"
label var co2_coke_s2     "Coke emissions, tCO2e (Spec 2/HEES: 0.027 GJ/kg × 107.68 kg CO2/GJ)"

di as txt "  Per-fuel emission variables created: diesel, petrol, kerosene, coal, lpg, gas,"
di as txt "    othergas, coalbriq, coke"
di as txt "  Fuels excluded: lubricant (non-combustion); firewood/charcoal (biogenic — Scope 1 excl.)"
di as txt "  LPG Spec 2 uses HEES value (likely GCV — see §7.9 QMD); Spec 1 uses Neraca NCV (45.544 GJ/ton = 0.002876 tCO2/kg)"

* ============================================================
* SECTION 2 — SCOPE 1 AGGREGATE + FUEL-COUNT DIAGNOSTIC
* ============================================================
* STRICT: missing if ALL nine fuel variables are missing (rowtotal default).
*         For a firm reporting any fuel, the aggregate reflects reported fuels only
*         (partial coverage). This is preferable to zero-filling: a firm not
*         reporting coal does not necessarily have zero coal use.
*
* co2_scope1_nfuels: count of fuel types with non-missing values (0–9).
*         Use to filter on completeness: e.g., keep if co2_scope1_nfuels >= 2.

di as txt _n "=== SECTION 2: Scope 1 aggregate + fuel-count ==="

* Spec 1 — 9 fuel types including sparse fuels (othergas, coalbriq, coke)
* Missing if ALL nine fuel variables are missing (rowtotal option)
* Firms reporting only a subset get a partial Scope 1 — co2_scope1_nfuels records coverage
egen double co2_scope1_s1 = rowtotal(co2_diesel_s1 co2_petrol_s1 co2_kerosene_s1 ///
                                      co2_coal_s1 co2_lpg_s1 co2_gas_s1           ///
                                      co2_othergas_s1 co2_coalbriq_s1 co2_coke_s1), missing
label var co2_scope1_s1 "Scope 1 total, tCO2e (Spec 1: IPCC+Neraca, 9 fuels, PRIMARY); missing if all missing"

* Spec 2
egen double co2_scope1_s2 = rowtotal(co2_diesel_s2 co2_petrol_s2 co2_kerosene_s2 ///
                                      co2_coal_s2 co2_lpg_s2 co2_gas_s2           ///
                                      co2_othergas_s2 co2_coalbriq_s2 co2_coke_s2), missing
label var co2_scope1_s2 "Scope 1 total, tCO2e (Spec 2: IPCC+HEES, 9 fuels, robustness); missing if all missing"

* Fuel count (same for both specs — coverage doesn't depend on factor)
* Range 0–9; includes sparse fuels so analyst can see completeness per firm-year
gen byte co2_scope1_nfuels = (!missing(fuel_diesel_ltr))    ///
                            + (!missing(fuel_petrol_ltr))    ///
                            + (!missing(fuel_kerosene_ltr))  ///
                            + (!missing(fuel_coal_kg))       ///
                            + (!missing(fuel_lpg_kg))        ///
                            + (!missing(fuel_citygas_m3))    ///
                            + (!missing(fuel_othergas_m3))   ///
                            + (!missing(fuel_coalbriq_kg))   ///
                            + (!missing(fuel_coke_kg))
label var co2_scope1_nfuels "N fuel types with non-missing quantity (0–9); coverage diagnostic"

di as txt "  co2_scope1_s1 non-missing: "
count if !missing(co2_scope1_s1)
di as txt "  co2_scope1_nfuels distribution:"
tab co2_scope1_nfuels

* ============================================================
* SECTION 3 — SCOPE 2: PURCHASED ELECTRICITY
* ============================================================
* Applied to the strict purchased electricity aggregate:
*   elec_purchased_kwh_strict = elec_pln_kwh + elec_nonpln_kwh
*   (missing if either component missing — created in 06_harmonize_si_energy.do)
*
* METHODOLOGICAL NOTE — Spec 1 (time-varying EF) vs. Spec 2 (static EF) (see §7.7–7.8):
*
*   Spec 1 (PRIMARY): year-specific grid EF derived from BPS Neraca Energi
*     "Konsumsi Bahan Bakar Pembangkit Listrik" fuel-mix tables × IPCC 2006 EFs.
*     Covers 2000–2014; pre-2006 values are extrapolated (oil/gas mix stable
*     pre-Fast Track); 2011-2012 are interpolated between 2010 and 2013.
*     Range: 0.000599 (2010) to 0.000914 (2014) tCO2/kWh.
*
*   Spec 2 (robustness): static 0.000867 tCO2/kWh (PLN RUPTL 2015 grid average).
*     Consistent with prior literature using a single national EF.
*
*   For DiD with year FE: because the grid EF is constant WITHIN each calendar year
*   (a single national value applies to all firms in year t), year FE fully absorb
*   any level shift or trend in the EF. The estimated treatment coefficient is
*   NUMERICALLY IDENTICAL under Spec 1 and Spec 2 — the EF choice cancels out of
*   the within-year cross-firm comparison. EF choice affects aggregate totals and
*   trend-based descriptives only, NOT the DiD treatment estimate.
*
* Own-generated electricity (elec_owngene_kwh) is NOT included:
*   it would double-count Scope 1 fuel used to run the generator.
*   Generator fuel sub-items (fuel_*_ltr_gen) are already included in
*   the total fuel quantity variables via the harmonization step.

di as txt _n "=== SECTION 3: Scope 2 — purchased electricity ==="

* -- Step A: Build year-specific grid EF for Spec 1 --
* Source: Neraca Energi "Konsumsi Bahan Bakar Pembangkit Listrik" × IPCC 2006
* 2000-2005 = 2006 value (pre-Fast Track; oil/gas mix similar)
* 2011-2012 = interpolated between 2010 and 2013
gen double gridEF_s1 = .
replace gridEF_s1 = 0.000630 if inrange(year, 2000, 2006)
replace gridEF_s1 = 0.000650 if year == 2007
replace gridEF_s1 = 0.000627 if year == 2008
replace gridEF_s1 = 0.000609 if year == 2009
replace gridEF_s1 = 0.000599 if year == 2010
replace gridEF_s1 = 0.000690 if year == 2011   // interpolated
replace gridEF_s1 = 0.000782 if year == 2012   // interpolated
replace gridEF_s1 = 0.000873 if year == 2013
replace gridEF_s1 = 0.000914 if year == 2014
label var gridEF_s1 "Year-specific grid EF, tCO2/kWh (Spec 1; Neraca Energi × IPCC 2006)"

* -- Step B: Compute Scope 2 for both specs --
* Use strict aggregate (preserves missingness for non-reporters)
gen double co2_scope2_s1 = elec_purchased_kwh_strict * gridEF_s1
label var co2_scope2_s1 "Scope 2 emissions, tCO2e (Spec 1: time-varying grid EF from Neraca Energi)"

gen double co2_scope2_s2 = elec_purchased_kwh_strict * 0.000867
label var co2_scope2_s2 "Scope 2 emissions, tCO2e (Spec 2: static 0.000867 tCO2/kWh, PLN RUPTL 2015)"

drop gridEF_s1   // temp variable; EF was used only to compute co2_scope2_s1

di as txt "  co2_scope2_s1 non-missing: "
count if !missing(co2_scope2_s1)

* ============================================================
* SECTION 4 — TOTAL SCOPE 1 + SCOPE 2
* ============================================================
* NOTE: co2_total uses direct addition — missing if EITHER Scope 1 OR Scope 2 is missing.
* A firm reporting only fuel (no electricity) or only electricity (no fuel)
* will have missing co2_total. This is a known limitation; use co2_scope1_s1
* or co2_scope2_s1 separately for firms with partial energy reporting.
* For partial-reporter analysis downstream, construct: egen co2_total_partial = rowtotal(co2_scope1_s1 co2_scope2_s1), missing

di as txt _n "=== SECTION 4: Total Scope 1+2 ==="

gen double co2_total_s1 = co2_scope1_s1 + co2_scope2_s1
label var co2_total_s1 "Total Scope 1+2 emissions, tCO2e (Spec 1: IPCC+Neraca) — PRIMARY outcome"

gen double co2_total_s2 = co2_scope1_s2 + co2_scope2_s2
label var co2_total_s2 "Total Scope 1+2 emissions, tCO2e (Spec 2: IPCC+HEES) — robustness"

di as txt "  co2_total_s1 non-missing: "
count if !missing(co2_total_s1)
quietly summarize co2_total_s1, detail
di as txt "  co2_total_s1 median: " %12.2fc r(p50) " tCO2e"
di as txt "  co2_total_s1 p95:    " %12.2fc r(p95) " tCO2e"
di as txt "  co2_total_s1 max:    " %12.2fc r(max) " tCO2e"

* ============================================================
* SECTION 5 — INTENSITY MEASURES
* ============================================================
* ltlnou  = total workers (kept from 01_append_si_energy.do; SI raw name unchanged)
* vtlvcu  = total output value (Rp000, NOMINAL). Real deflation requires a
*           sector-year price deflator not yet loaded in this pipeline.
*           co2_intensity_output_s1 is on a NOMINAL basis — interpret cautiously
*           in cross-year comparisons; suitable for within-firm DiD.

di as txt _n "=== SECTION 5: Intensity measures ==="

* Guard: ensure workers variable exists
capture confirm variable ltlnou
if _rc != 0 {
    di as err "WARNING: ltlnou (total workers) not found — intensity per worker skipped"
}
else {
    // Guard: Stata returns missing (.) for x/0, so zero-worker obs get missing automatically.
    // Explicit zero-guard added for transparency.
    gen double co2_intensity_worker_s1  = co2_total_s1  / ltlnou
    gen double co2_intensity_worker_s2  = co2_total_s2  / ltlnou
    replace co2_intensity_worker_s1 = . if ltlnou == 0
    replace co2_intensity_worker_s2 = . if ltlnou == 0
    label var co2_intensity_worker_s1  "Emission intensity per worker, tCO2e (Spec 1); missing if ltlnou = 0"
    label var co2_intensity_worker_s2  "Emission intensity per worker, tCO2e (Spec 2); missing if ltlnou = 0"
    di as txt "  co2_intensity_worker_s1 created (÷ ltlnou)"
}

* Guard: ensure output variable exists
capture confirm variable vtlvcu
if _rc != 0 {
    di as err "WARNING: vtlvcu (total output value) not found — output intensity skipped"
}
else {
    * vtlvcu is in Rp000; divide by 1000 → millions Rp (nominal)
    gen double co2_intensity_output_s1 = co2_total_s1 / (vtlvcu / 1000)
    label var co2_intensity_output_s1 "Emission intensity per M Rp output (NOMINAL), tCO2e (Spec 1)"
    di as txt "  co2_intensity_output_s1 created (÷ vtlvcu/1000; NOMINAL basis)"
    di as txt "  Note: real output deflation requires sector-year CPI — not yet applied"
}

* ============================================================
* SECTION 6 — LOG OUTCOMES FOR DiD REGRESSION
* ============================================================
* Primary DiD outcome: ln_co2_total_s1
* Log is undefined for zero or negative values.
* Firms with co2_total_s1 == 0 are extremely rare (all fuels genuinely zero)
* and will have missing ln_co2_total_s1.
*
* Semi-elasticity interpretation: a 1-unit change in the treatment dummy
* shifts log-emissions by β → co2 multiplied by exp(β) - 1 percent.

di as txt _n "=== SECTION 6: Log outcomes for DiD ==="

gen double ln_co2_total_s1            = ln(co2_total_s1)
gen double ln_co2_total_s2            = ln(co2_total_s2)
gen double ln_co2_scope1_s1           = ln(co2_scope1_s1)
label var ln_co2_total_s1            "Log total Scope 1+2, Spec 1 (IPCC+Neraca) — PRIMARY DiD outcome"
label var ln_co2_total_s2            "Log total Scope 1+2, Spec 2 (IPCC+HEES) — robustness"
label var ln_co2_scope1_s1           "Log Scope 1 (combustion only), Spec 1 (IPCC+Neraca)"

capture confirm variable co2_intensity_worker_s1
if _rc == 0 {
    gen double ln_co2_intensity_worker_s1  = ln(co2_intensity_worker_s1)
    gen double ln_co2_intensity_worker_s2  = ln(co2_intensity_worker_s2)
    label var ln_co2_intensity_worker_s1  "Log emission intensity per worker, Spec 1 — DiD intensity outcome"
    label var ln_co2_intensity_worker_s2  "Log emission intensity per worker, Spec 2 — robustness"
}

* Diagnose zero/negative co2_total (should be very rare)
count if co2_total_s1 <= 0 & !missing(co2_total_s1)
di as txt "  co2_total_s1 <= 0 (not missing): " r(N) " obs — these have missing ln_co2_total_s1"
count if missing(ln_co2_total_s1)
di as txt "  ln_co2_total_s1 missing:          " r(N) " obs"

* ============================================================
* SECTION 7 — SUMMARY STATISTICS
* ============================================================

di as txt _n "=== SECTION 7: Summary statistics ==="

di as txt _n "  --- Per-fuel Scope 1 contributions (N non-missing, Spec 1) ---"
foreach v in co2_diesel_s1 co2_petrol_s1 co2_kerosene_s1 co2_coal_s1 co2_lpg_s1 co2_gas_s1 co2_othergas_s1 co2_coalbriq_s1 co2_coke_s1 {
    quietly count if !missing(`v') & `v' > 0
    di as txt "  %-30s N_pos = " %8.0fc r(N) "  `v'"
}

di as txt _n "  --- Scope totals ---"
foreach v in co2_scope1_s1 co2_scope2_s1 co2_total_s1 co2_total_s2 {
    quietly count if !missing(`v') & `v' > 0
    quietly summarize `v', detail
    di as txt "  `v':"
    di as txt "    N_pos=" %8.0fc r(N) "  median=" %12.2fc r(p50) "  p95=" %12.2fc r(p95)
}

di as txt _n "  --- Log outcome coverage ---"
foreach v in ln_co2_total_s1 ln_co2_total_s2 ln_co2_scope1_s1 {
    quietly count if !missing(`v')
    di as txt "  %-40s N = " %8.0fc r(N) "  `v'"
}

di as txt _n "  --- Spec 1 vs. Spec 2: Scope 1 ratio at median (Spec2/Spec1) ---"
quietly summarize co2_scope1_s1 if !missing(co2_scope1_s1) & co2_scope1_s1 > 0, detail
local med1 = r(p50)
quietly summarize co2_scope1_s2 if !missing(co2_scope1_s2) & co2_scope1_s2 > 0, detail
local med2 = r(p50)
di as txt "  Scope1 median: Spec1 = " %10.2fc `med1' "  Spec2 = " %10.2fc `med2' ///
          "  Ratio S2/S1 = " %6.4f `med2'/`med1'
di as txt "  (Expected ~1.10: Spec 2 HEES uses higher NCV for diesel/petrol than Spec 1 Neraca)"

* ============================================================
* SECTION 8 — SAVE
* ============================================================

save "$output/si_energy_emissions.dta", replace
di as txt _n "Saved: $output/si_energy_emissions.dta"
di as txt "  Obs: " _N
di as txt "  Vars: " c(k)
di as txt _n "KEY EMISSION VARIABLES:"
di as txt "  ln_co2_total_s1           — PRIMARY DiD outcome (Spec 1: IPCC+Neraca)"
di as txt "  ln_co2_total_s2           — Robustness outcome (Spec 2: IPCC+HEES)"
di as txt "  ln_co2_intensity_worker_s1 — Emission intensity DiD outcome"
di as txt "  co2_scope1_nfuels          — Fuel coverage diagnostic (0–9; includes sparse fuels)"
di as txt _n "NEXT STEP: 11_sensitivity_variants.do — alternative EF assumptions"
di as txt "  (alt_lpg_neraca, alt_coal_kalimantan, alt_elec_rosita, alt_coal_exclude2004, alt_gas_towngas)"

log close
