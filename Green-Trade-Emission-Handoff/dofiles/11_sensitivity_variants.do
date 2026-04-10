* ============================================================
* Script: 11_sensitivity_variants.do
* Purpose: Compute alternative emission specifications as
*          robustness checks for the primary outcome (ln_co2_total_s1).
*          All variants append to si_energy_emissions.dta — the
*          baseline emission variables (Spec 1 and Spec 2) are
*          produced by 10_carbon_convert.do.
*
*          Variants implemented here:
*            alt_lpg_neraca       — LPG NCV: 52.145 → 45.544 GJ/ton (NCV-consistent; HIGH priority)
*            alt_coal_kalimantan  — Coal NCV: HEES 25.691 → Kalimantan thermal 26.2 GJ/ton (base: Spec 2)
*            alt_elec_rosita      — Grid EF: 0.000867 → 0.000904 tCO2/kWh (Rosita 2020)
*            alt_coal_exclude2004 — Exclude coal observations 2004–2005 rather than apply ×1000 correction
*            alt_gas_towngas      — Gas EF: natural gas → gas works gas (56.15 → 44.45 kg CO2/GJ)
*
*          NOTE (2026-03-25): alt_elec_tvef has been REMOVED. After the update
*          to 10_carbon_convert.do, Spec 1 now uses the time-varying Neraca Energi
*          grid EF as its primary co2_scope2_s1. alt_elec_tvef was therefore
*          identical to Spec 1 and is no longer a meaningful sensitivity variant.
*
*          For each variant a full ln_co2_total_{variant} is produced.
*          All other inputs (Scope 2, other fuels) remain at Spec 1 values
*          unless the variant specifically targets those components.
*
*          NOTE on aggregation: co2_total_{variant} = co2_scope1_{variant} + co2_scope2_s1
*          uses direct addition (not rowtotal). This is intentional: a firm missing
*          either Scope 1 or Scope 2 gets missing co2_total, not a partial sum.
*          This mirrors the co2_total_s1 construction in 10_carbon_convert.do (see §4).
*          To recover partial reporters, use rowtotal(co2_scope1_* co2_scope2_s1).
*
*          See §7.8 and §7.9 of data_industry_emission.qmd for rationale.
*
* Input:   output/si_energy_emissions.dta (produced by 10_carbon_convert.do)
* Output:  output/si_energy_emissions.dta (in-place update; adds variant vars)
* Author:  Albert Ludi
* Date:    2026-03-19
* Updated: 2026-03-25 — removed alt_elec_tvef (now redundant with Spec 1)
* Updated: 2026-03-26 — replaced direct addition with rowtotal(..., missing) for all variant Scope 1 aggregates
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

log using "$logs/11_sensitivity_variants.log", replace text

use "$output/si_energy_emissions.dta", clear
di as txt "Obs loaded: " _N

* Drop any variant variables from previous runs (makes do-file idempotent)
capture drop co2_lpg_alt_lpg co2_scope1_alt_lpg co2_total_alt_lpg ln_co2_total_alt_lpg
capture drop co2_coal_alt_kali co2_scope1_alt_kali co2_total_alt_kali ln_co2_total_alt_kali
capture drop co2_scope2_alt_rosita co2_total_alt_rosita ln_co2_total_alt_rosita
capture drop co2_coal_alt_exc2004 co2_scope1_alt_exc2004 co2_total_alt_exc2004 ln_co2_total_alt_exc2004
capture drop co2_gas_alt_towngas co2_scope1_alt_towngas co2_total_alt_towngas ln_co2_total_alt_towngas

* ============================================================
* BASELINE REFERENCE
* ============================================================
* The following variables from 10_carbon_convert.do serve as the
* Spec 1 (PRIMARY: IPCC 2006 + BPS Neraca Energi) baseline:
*   co2_diesel_s1, co2_petrol_s1, co2_kerosene_s1
*   co2_coal_s1  (Kalimantan thermal NCV, 26.2 GJ/ton × 95.28 = 0.002496)
*   co2_lpg_s1   (Neraca NCV, 45.544 GJ/ton × 63.15 = 0.002876)
*   co2_gas_s1   (Neraca NCV, 0.048 GJ/m3 × 56.15 = 0.002695)
*   co2_scope2_s1 (electricity; time-varying Neraca Energi grid EF — see 10_carbon_convert.do)
*   co2_total_s1  (Scope 1 + Scope 2 baseline total)
*
* Each variant replaces ONE component and recomputes the total.
* This isolates the marginal effect of each factor assumption.
*
* NOTE: After the naming correction in 10_carbon_convert.do (2026-03-24),
*   _s1 = Spec 1 (Neraca, PRIMARY) and _s2 = Spec 2 (HEES, robustness).
*   alt_lpg_neraca produces results identical to the Spec 1 baseline
*   (confirming Spec 1 already uses Neraca LPG NCV); it is retained for
*   verification purposes.
*   alt_coal_kalimantan uses Spec 2 as its base (HEES NCV) and replaces
*   only the coal component with the Kalimantan thermal factor — this is
*   the meaningful comparison (HEES NCV vs. Kalimantan NCV for coal).

* ============================================================
* VARIANT 1: alt_lpg_neraca
* ============================================================
* LPG NCV: ESDM HEES 52.145 GJ/ton → BPS Neraca Energi 45.544 GJ/ton
*   New composite factor: 45.544 × 63.15 / 1000 / 1000 = 0.002876 tCO2/kg
*   (This is identical to Spec 1's LPG factor — confirming Spec 1 already uses Neraca LPG)
*
* Rationale: HEES LPG value appears to be on a GCV basis; IPCC 2006
*   emission factors are defined on an NCV basis. Using GCV overstates
*   LPG energy content by ~12.7%, inflating LPG emissions proportionally.
*   BPS Neraca Energi (45.544 GJ/ton) is NCV-consistent.
*   This is the highest-priority sensitivity (§7.9 priority note).
*
* 0.045544 GJ/kg × 63.15 kg CO2/GJ / 1000 = 0.002876 tCO2/kg

di as txt _n "=== VARIANT 1: alt_lpg_neraca (LPG NCV GCV→NCV) ==="

gen double co2_lpg_alt_lpg        = fuel_lpg_kg * 0.002876
label var co2_lpg_alt_lpg         "LPG emissions, tCO2e (alt_lpg_neraca: NCV 45.544 GJ/ton)"

egen double co2_scope1_alt_lpg    = rowtotal(co2_diesel_s1 co2_petrol_s1 co2_kerosene_s1 ///
                                             co2_coal_s1 co2_lpg_alt_lpg co2_gas_s1      ///
                                             co2_othergas_s1 co2_coalbriq_s1 co2_coke_s1), missing
label var co2_scope1_alt_lpg      "Scope 1 total, tCO2e (alt_lpg_neraca)"

gen double co2_total_alt_lpg      = co2_scope1_alt_lpg + co2_scope2_s1
label var co2_total_alt_lpg       "Total Scope 1+2, tCO2e (alt_lpg_neraca)"

gen double ln_co2_total_alt_lpg   = ln(co2_total_alt_lpg)
label var ln_co2_total_alt_lpg    "Log total emissions (alt_lpg_neraca) — robustness"

* Diagnose change magnitude at LPG-reporting firms
quietly summarize co2_lpg_s1      if !missing(co2_lpg_s1) & co2_lpg_s1 > 0, detail
local lpg_med_s1 = r(p50)
quietly summarize co2_lpg_alt_lpg if !missing(co2_lpg_alt_lpg) & co2_lpg_alt_lpg > 0, detail
local lpg_med_alt = r(p50)
di as txt "  LPG median Spec1: " %10.4f `lpg_med_s1' " tCO2e"
di as txt "  LPG median alt:   " %10.4f `lpg_med_alt'  " tCO2e"
di as txt "  Ratio (alt/Spec1): " %6.4f `lpg_med_alt'/`lpg_med_s1' " (expected ~0.873)"

* ============================================================
* VARIANT 2: alt_coal_kalimantan
* ============================================================
* Base: Spec 2 (HEES NCV); coal NCV replaced with Kalimantan thermal
*   (26.200 GJ/ton). Tests whether using the dominant supply-region NCV
*   instead of HEES changes total emissions.
*
*   Spec 2 coal factor (HEES NCV): 0.025691 × 95.28 / 1000 = 0.002448 tCO2/kg
*   Alt coal factor (Kalimantan):  0.026200 × 95.28 / 1000 = 0.002496 tCO2/kg
*   Source: HEES regional table (1 BOE = 6.117 GJ basis)
*
* Rationale: Kalimantan produces the majority of coal consumed by SI
*   manufacturing firms. This variant tests whether the 2% higher
*   Kalimantan NCV (vs. HEES generic 25.691) meaningfully changes coal
*   emissions relative to the HEES-based Spec 2 baseline.
*   This has negligible aggregate impact (coal is 5% of firm-years) but
*   is the methodologically correct choice for heavy-industry sectors.

di as txt _n "=== VARIANT 2: alt_coal_kalimantan (Coal NCV: HEES 25.691 → Kalimantan 26.200 GJ/ton; base Spec 2) ==="

gen double co2_coal_alt_kali      = fuel_coal_kg * 0.002496
label var co2_coal_alt_kali       "Coal emissions, tCO2e (alt_coal_kalimantan: NCV 26.2 GJ/ton)"

* Build Scope 1 from Spec 2 base, swapping only the coal component
egen double co2_scope1_alt_kali   = rowtotal(co2_diesel_s2 co2_petrol_s2 co2_kerosene_s2 ///
                                             co2_coal_alt_kali co2_lpg_s2 co2_gas_s2     ///
                                             co2_othergas_s2 co2_coalbriq_s2 co2_coke_s2), missing
label var co2_scope1_alt_kali     "Scope 1 total, tCO2e (alt_coal_kalimantan; base: Spec 2)"

gen double co2_total_alt_kali     = co2_scope1_alt_kali + co2_scope2_s2
label var co2_total_alt_kali      "Total Scope 1+2, tCO2e (alt_coal_kalimantan; base: Spec 2)"

gen double ln_co2_total_alt_kali  = ln(co2_total_alt_kali)
label var ln_co2_total_alt_kali   "Log total emissions (alt_coal_kalimantan) — robustness"

di as txt "  Coal EF change (vs Spec 2): 0.002448 → 0.002496 (+2.0%); ~coal-using firms only (5% coverage)"

* ============================================================
* VARIANT 3: alt_elec_rosita
* ============================================================
* Grid emission factor: PLN RUPTL 2015 0.000867 → Rosita et al. (2020) 0.000904
*   Rosita et al. (2020) estimates the grid EF for the 2010–2014 period at
*   approximately 0.000904 tCO2/kWh on an IPCC-consistent basis.
*   The Rosita factor reflects a more coal-intensive grid mix (~2010–2014)
*   and therefore overstates emissions slightly for earlier years.
*
* Rationale: tests whether results are sensitive to the grid EF source.
*   Both factors are static across 2000–2014 (limitation: see §7.7 warning).
*   The ~4.3% higher Rosita factor has a larger aggregate effect than coal
*   EF variants because electricity covers 88% of firm-years.

di as txt _n "=== VARIANT 3: alt_elec_rosita (Grid EF 0.000867 → 0.000904) ==="

gen double co2_scope2_alt_rosita   = elec_purchased_kwh_strict * 0.000904
label var co2_scope2_alt_rosita    "Scope 2 emissions, tCO2e (alt_elec_rosita: 0.000904 tCO2/kWh)"

gen double co2_total_alt_rosita    = co2_scope1_s1 + co2_scope2_alt_rosita
label var co2_total_alt_rosita     "Total Scope 1+2, tCO2e (alt_elec_rosita)"

gen double ln_co2_total_alt_rosita = ln(co2_total_alt_rosita)
label var ln_co2_total_alt_rosita  "Log total emissions (alt_elec_rosita) — robustness"

quietly summarize co2_scope2_s1 if !missing(co2_scope2_s1) & co2_scope2_s1 > 0, detail
local s2_med_s1 = r(p50)
quietly summarize co2_scope2_alt_rosita if !missing(co2_scope2_alt_rosita) & co2_scope2_alt_rosita > 0, detail
local s2_med_alt = r(p50)
di as txt "  Scope2 median baseline: " %10.4f `s2_med_s1' " tCO2e"
di as txt "  Scope2 median alt:      " %10.4f `s2_med_alt'  " tCO2e"
di as txt "  Ratio (alt/baseline):   " %6.4f `s2_med_alt'/`s2_med_s1' " (expected ~1.043 avg; varies by year since Spec 1 now uses time-varying EF)"

* ============================================================
* VARIANT 5: alt_coal_exclude2004
* ============================================================
* Exclude coal observations 2004–2005 rather than apply a ×1000 unit correction.
*   No correction was applied upstream — the 2004–2005 coal data are used as-is
*   in the baseline (Spec 1). This variant instead sets coal emissions to missing
*   for 2004–2005 to test sensitivity to the Ton-label years, regardless of
*   whether a unit correction is needed.
*
* Rationale: The 2004–2005 questionnaires label the coal unit as "Ton"
*   while surrounding years use "Kg"; it is unclear whether all firms
*   converted correctly. Excluding these two years is a conservative
*   alternative that avoids any unit-ambiguity assumption.
*   Expected outcome: co2_total_alt_exc2004 is missing (treated as zero
*   in aggregation) for coal-using firms in 2004–2005 — a lower bound.
*
* Implementation note: co2_coal_s1 is copied and 2004–2005 values are
*   nulled out. All other fuel components remain at Spec 1 values.

di as txt _n "=== VARIANT 5: alt_coal_exclude2004 (exclude coal 2004–2005) ==="

gen double co2_coal_alt_exc2004 = co2_coal_s1
* Null out coal emissions for 2004–2005 (treat as missing rather than corrected)
replace co2_coal_alt_exc2004 = . if (year == 2004 | year == 2005)
label var co2_coal_alt_exc2004     "Coal emissions, tCO2e (alt_coal_exclude2004: 2004–2005 set missing)"

egen double co2_scope1_alt_exc2004 = rowtotal(co2_diesel_s1 co2_petrol_s1 co2_kerosene_s1   ///
                                              co2_coal_alt_exc2004 co2_lpg_s1 co2_gas_s1    ///
                                              co2_othergas_s1 co2_coalbriq_s1 co2_coke_s1), missing
label var co2_scope1_alt_exc2004   "Scope 1 total, tCO2e (alt_coal_exclude2004)"

gen double co2_total_alt_exc2004   = co2_scope1_alt_exc2004 + co2_scope2_s1
label var co2_total_alt_exc2004    "Total Scope 1+2, tCO2e (alt_coal_exclude2004)"

gen double ln_co2_total_alt_exc2004 = ln(co2_total_alt_exc2004)
label var ln_co2_total_alt_exc2004  "Log total emissions (alt_coal_exclude2004) — robustness"

count if (year == 2004 | year == 2005) & !missing(co2_coal_s1) & co2_coal_s1 > 0
di as txt "  Coal obs set to missing in 2004–2005: " r(N)

* ============================================================
* VARIANT 6: alt_gas_towngas
* ============================================================
* Gas EF: natural gas (56.15 kg CO2/GJ) → gas works gas (44.45 kg CO2/GJ)
*   IPCC 2006 Table 2.3, Manufacturing Industries and Construction:
*     Natural Gas:   56.15 kg CO2e/GJ
*     Gas Works Gas: 44.45 kg CO2e/GJ (manufactured gas, lower carbon content)
*   NCV unchanged at 0.039 GJ/m3
*   New composite factor: 0.039 × 44.45 / 1000 = 0.001733 tCO2/m3
*
* Rationale: PGN distributes natural gas, not manufactured gas; natural gas
*   is the correct IPCC category. This variant tests the lower bound from using
*   the wrong IPCC category. Priority: LOW (city gas covers only 4% of firm-years).

di as txt _n "=== VARIANT 6: alt_gas_towngas (Gas EF: natural → gas works) ==="

gen double co2_gas_alt_towngas     = fuel_citygas_m3 * 0.001733
label var co2_gas_alt_towngas      "City gas emissions, tCO2e (alt_gas_towngas: gas works 44.45 kg CO2/GJ)"

egen double co2_scope1_alt_towngas = rowtotal(co2_diesel_s1 co2_petrol_s1 co2_kerosene_s1 ///
                                              co2_coal_s1 co2_lpg_s1 co2_gas_alt_towngas  ///
                                              co2_othergas_s1 co2_coalbriq_s1 co2_coke_s1), missing
label var co2_scope1_alt_towngas   "Scope 1 total, tCO2e (alt_gas_towngas)"

gen double co2_total_alt_towngas   = co2_scope1_alt_towngas + co2_scope2_s1
label var co2_total_alt_towngas    "Total Scope 1+2, tCO2e (alt_gas_towngas)"

gen double ln_co2_total_alt_towngas = ln(co2_total_alt_towngas)
label var ln_co2_total_alt_towngas  "Log total emissions (alt_gas_towngas) — robustness"

di as txt "  Gas EF change: 56.15 → 44.45 kg CO2/GJ (−20.9%); low-coverage fuel (4% of firm-years)"

* ============================================================
* SECTION — COMPARISON TABLE
* ============================================================
* Report median co2_total and ln_co2_total across all specifications.
* This allows visual confirmation that variants produce plausible
* and interpretable deviations from the baseline.

di as txt _n "=== COMPARISON: Median co2_total across specifications ==="
di as txt "  " %-35s "Specification" %12s "N_pos" %14s "Median tCO2e" %14s "Median ln"

foreach vname in s1 s2 alt_lpg alt_kali alt_rosita alt_exc2004 alt_towngas {
    local v "co2_total_`vname'"
    capture confirm variable `v'
    if _rc == 0 {
        quietly count if !missing(`v') & `v' > 0
        local n_pos = r(N)
        quietly summarize `v' if !missing(`v') & `v' > 0, detail
        local med = r(p50)
        quietly summarize ln_co2_total_`vname', detail
        local medln = r(p50)
        di as txt "  " %-35s "`v'" %12.0fc `n_pos' %14.2fc `med' %14.4f `medln'
    }
}

* ============================================================
* SAVE
* ============================================================

save "$output/si_energy_emissions.dta", replace
di as txt _n "Saved: $output/si_energy_emissions.dta"
di as txt "  Obs: " _N
di as txt "  Vars: " c(k)
di as txt _n "SENSITIVITY VARIABLES ADDED:"
di as txt "  ln_co2_total_alt_lpg       (HIGH priority — LPG GCV/NCV convention)"
di as txt "  ln_co2_total_alt_kali      (Medium — coal Kalimantan NCV)"
di as txt "  ln_co2_total_alt_rosita    (Medium — grid EF Rosita 2020)"
di as txt "  ln_co2_total_alt_exc2004   (Low — coal 2004–2005 exclusion)"
di as txt "  ln_co2_total_alt_towngas   (Low — gas works EF)"
di as txt _n "PIPELINE COMPLETE: si_energy_emissions.dta is the analysis-ready dataset."
di as txt "  Primary DiD outcome:    ln_co2_total_s1"
di as txt "  Note: co2_scope2_s1 now uses time-varying Neraca Energi grid EF (not static PLN RUPTL 2015)"
di as txt "  Intensity outcome:      ln_co2_intensity_worker_s1"
di as txt "  Robustness:             ln_co2_total_s2, ln_co2_total_alt_*"

log close
