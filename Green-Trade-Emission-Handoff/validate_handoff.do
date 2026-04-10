* ============================================================
* Script:  validate_handoff.do
* Purpose: Smoke-test every data file in the handoff package.
*          Checks obs counts, variable presence, value ranges,
*          and step-to-step consistency.  Does NOT re-run the
*          pipeline — reads files as-is.
*
* How to run:
*   1. Open Stata, cd to this folder (Green-Trade-Emission-Handoff/)
*   2. do validate_handoff.do
*   3. Look for "FAIL" lines — a clean run prints only PASS + SUMMARY.
*
* Author:  Albert Ludi (validation script)
* Date:    2026-04-08
* ============================================================

clear all
set more off
capture log close

* ── Handoff root: uses current working directory ────────────────────────────
* Run this script with Stata's working directory set to this folder:
*   cd "/path/to/Green-Trade-Emission-Handoff"
*   do validate_handoff.do
* OR set global handoff manually if you prefer an absolute path:
*   global handoff "/path/to/Green-Trade-Emission-Handoff"
*   do "$handoff/validate_handoff.do"

if "$handoff" == "" {
    * Use current working directory if global not already set
    global handoff "`c(pwd)'"
}
di as txt "Handoff path: $handoff"

log using "$handoff/validate_handoff.log", replace text

local pass  = 0
local fail  = 0
local warn  = 0

* ── Helper macros ───────────────────────────────────────────────────────────
* Usage: `check_var varname'  (must be run while dataset is loaded)
* We will inline the checks rather than use programs for readability.

di as txt _n "{hline 70}"
di as txt "  HANDOFF VALIDATION — $(c(current_date)) $(c(current_time))"
di as txt "{hline 70}"


* ============================================================
* BLOCK 1 — Raw data
* ============================================================
di as txt _n "--- BLOCK 1: data/raw/data8514_SI.dta ---"

capture use "$handoff/data/raw/data8514_SI.dta", clear
if _rc {
    di as error "FAIL [B1-01]: Cannot open raw data — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)

    * B1-01: should cover multiple years
    if _N < 200000 {
        di as error "  FAIL [B1-01]: obs count suspiciously low (_N=" _N ")"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B1-01]: obs count OK"
        local pass = `pass' + 1
    }

    * B1-02: key identifiers exist
    foreach v in psid year {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B1-02]: variable `v' missing from raw data"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B1-02]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B1-03: year range
    qui su year
    if r(min) > 2000 | r(max) < 2014 {
        di as error "  FAIL [B1-03]: year range [" r(min) "," r(max) "] — expected to span 2000–2014"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B1-03]: year range " r(min) "–" r(max)
        local pass = `pass' + 1
    }
}


* ============================================================
* BLOCK 2 — Step 01: appended panel 2000–2014
* ============================================================
di as txt _n "--- BLOCK 2: data/steps/step01_si_panel_2000_2014.dta ---"

capture use "$handoff/data/steps/step01_si_panel_2000_2014.dta", clear
if _rc {
    di as error "FAIL [B2-01]: Cannot open step01 file — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)
    scalar step01_N = _N

    * B2-01: year restricted to 2000–2014
    qui su year
    if r(min) < 2000 | r(max) > 2014 {
        di as error "  FAIL [B2-01]: year range outside 2000–2014 [" r(min) "," r(max) "]"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B2-01]: year range " r(min) "–" r(max)
        local pass = `pass' + 1
    }

    * B2-02: psid and year present
    foreach v in psid year {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B2-02]: `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B2-02]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B2-03: should have raw energy vars (E-prefix pattern)
    capture confirm variable eclkgu
    if _rc {
        di as error "  FAIL [B2-03]: eclkgu (coal kg) missing — raw E* vars not present"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B2-03]: eclkgu (raw coal var) present"
        local pass = `pass' + 1
    }
}


* ============================================================
* BLOCK 3 — Step 01b: full append (all years)
* ============================================================
di as txt _n "--- BLOCK 3: data/steps/step01b_si_panel_full_2000_2014.dta ---"

capture use "$handoff/data/steps/step01b_si_panel_full_2000_2014.dta", clear
if _rc {
    di as error "FAIL [B3-01]: Cannot open step01b file — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)

    * B3-01: obs should be >= step01 (it's the superset)
    if _N < scalar(step01_N) {
        di as error "  FAIL [B3-01]: step01b has fewer obs than step01 — " _N " vs " scalar(step01_N)
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B3-01]: step01b obs (" _N ") >= step01 (" scalar(step01_N) ")"
        local pass = `pass' + 1
    }

    * B3-02: psid and year present
    foreach v in psid year {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B3-02]: `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B3-02]: `v' present"
            local pass = `pass' + 1
        }
    }
}


* ============================================================
* BLOCK 4 — Step 06: harmonized energy variables
* ============================================================
di as txt _n "--- BLOCK 4: data/steps/step06_si_energy_harmonized.dta ---"

capture use "$handoff/data/steps/step06_si_energy_harmonized.dta", clear
if _rc {
    di as error "FAIL [B4-01]: Cannot open step06 file — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)
    scalar step06_N = _N

    * B4-01: canonical fuel variables present
    local canon_vars "fuel_diesel_ltr fuel_petrol_ltr fuel_coal_kg fuel_lpg_kg elec_pln_kwh elec_purchased_kwh_strict"
    foreach v of local canon_vars {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B4-01]: canonical variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B4-01]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B4-02: no raw eclkgu (should have been renamed)
    capture confirm variable eclkgu
    if !_rc {
        di as txt "  WARN [B4-02]: eclkgu (raw name) still present after harmonize — check renaming"
        local warn = `warn' + 1
    }
    else {
        di as txt "  PASS [B4-02]: eclkgu (raw name) correctly absent — renamed to fuel_coal_kg"
        local pass = `pass' + 1
    }

    * B4-03: energy vars non-negative where non-missing
    foreach v in fuel_diesel_ltr elec_pln_kwh {
        qui su `v'
        if r(min) < 0 {
            di as error "  FAIL [B4-03]: `v' has negative values (min=" r(min) ")"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B4-03]: `v' non-negative (min=" r(min) ")"
            local pass = `pass' + 1
        }
    }
}


* ============================================================
* BLOCK 5 — Step 08: outlier flags
* ============================================================
di as txt _n "--- BLOCK 5: data/steps/step08_si_energy_flagged.dta ---"

capture use "$handoff/data/steps/step08_si_energy_flagged.dta", clear
if _rc {
    di as error "FAIL [B5-01]: Cannot open step08 file — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)
    scalar step08_N = _N

    * B5-01: should have same obs as step06 (flags are additive, no drops)
    if _N != scalar(step06_N) {
        di as error "  FAIL [B5-01]: obs changed between step06 and step08 (" scalar(step06_N) " → " _N ") — outlier step should NOT drop rows"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B5-01]: obs unchanged from step06 (" _N ")"
        local pass = `pass' + 1
    }

    * B5-02: composite flag variables present
    foreach v in flag_any_sev flag_any_mod flag_n_dims {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B5-02]: composite flag `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B5-02]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B5-03: flag_any_sev is binary (0/1 only)
    qui tab flag_any_sev
    if r(r) > 2 {
        di as error "  FAIL [B5-03]: flag_any_sev has more than 2 values — not binary"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B5-03]: flag_any_sev is binary (" r(r) " value(s))"
        local pass = `pass' + 1
    }

    * B5-04: some severe flags should exist (otherwise flagging did nothing)
    qui count if flag_any_sev == 1
    local nsev = r(N)
    if `nsev' == 0 {
        di as txt "  WARN [B5-04]: no severe flags found — either very clean data or flagging failed"
        local warn = `warn' + 1
    }
    else {
        di as txt "  PASS [B5-04]: `nsev' severe-flag obs found (will be dropped in step09)"
        local pass = `pass' + 1
    }
}


* ============================================================
* BLOCK 6 — Step 09: cleaned (severe flags dropped)
* ============================================================
di as txt _n "--- BLOCK 6: data/steps/step09_si_energy_harmonized_cleaned.dta ---"

capture use "$handoff/data/steps/step09_si_energy_harmonized_cleaned.dta", clear
if _rc {
    di as error "FAIL [B6-01]: Cannot open step09 file — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)
    scalar step09_N = _N

    * B6-01: obs should be LESS than step08 (severe flags dropped)
    if _N >= scalar(step08_N) {
        di as error "  FAIL [B6-01]: step09 has same or more obs than step08 (" _N " vs " scalar(step08_N) ") — severe-flag drop may not have run"
        local fail = `fail' + 1
    }
    else {
        local dropped = scalar(step08_N) - _N
        di as txt "  PASS [B6-01]: obs reduced from " scalar(step08_N) " to " _N " (dropped `dropped' severe-flag obs)"
        local pass = `pass' + 1
    }

    * B6-02: NO severe flags remain
    capture confirm variable flag_any_sev
    if !_rc {
        qui count if flag_any_sev == 1
        if r(N) > 0 {
            di as error "  FAIL [B6-02]: " r(N) " obs still have flag_any_sev==1 after cleaning"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B6-02]: flag_any_sev==0 for all obs"
            local pass = `pass' + 1
        }
    }
    else {
        di as txt "  WARN [B6-02]: flag_any_sev not found in step09 — cannot verify"
        local warn = `warn' + 1
    }

    * B6-03: canonical fuel vars still present
    foreach v in fuel_diesel_ltr elec_pln_kwh {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B6-03]: `v' missing after cleaning step"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B6-03]: `v' preserved through cleaning"
            local pass = `pass' + 1
        }
    }
}


* ============================================================
* BLOCK 7 — Final dataset: si_energy_emissions.dta
* ============================================================
di as txt _n "--- BLOCK 7: si_energy_emissions.dta (FINAL) ---"

capture use "$handoff/si_energy_emissions.dta", clear
if _rc {
    di as error "FATAL [B7-01]: Cannot open final dataset — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)

    * B7-01: expected obs count (from documentation: 314,576)
    if _N != 314576 {
        di as error "  FAIL [B7-01]: obs count = " _N " — expected 314,576"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-01]: obs = 314,576 — matches documentation"
        local pass = `pass' + 1
    }

    * B7-02: step09 → final: obs should match
    if _N != scalar(step09_N) {
        di as txt "  WARN [B7-02]: final obs (" _N ") != step09 obs (" scalar(step09_N) ") — check if extra drops happened in 10–14"
        local warn = `warn' + 1
    }
    else {
        di as txt "  PASS [B7-02]: final obs matches step09 (" _N ")"
        local pass = `pass' + 1
    }

    * B7-03: variable count (documented: 205 — includes isic3 added in step08)
    if c(k) != 205 {
        di as error "  FAIL [B7-03]: var count = " c(k) " — expected 205"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-03]: var count = 205"
        local pass = `pass' + 1
    }

    * B7-04: key identifier variables
    foreach v in psid year isic2 dprovi {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B7-04]: identifier variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B7-04]: identifier `v' present"
            local pass = `pass' + 1
        }
    }

    * B7-05: primary emission outcomes (Spec 1)
    local s1_vars "co2_total_s1 co2_scope1_s1 co2_scope2_s1 ln_co2_total_s1 ln_co2_scope1_s1"
    foreach v of local s1_vars {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B7-05]: Spec 1 variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B7-05]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B7-06: Spec 2 robustness variables
    local s2_vars "co2_total_s2 ln_co2_total_s2 co2_intensity_worker_s2 ln_co2_intensity_worker_s2"
    foreach v of local s2_vars {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B7-06]: Spec 2 variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B7-06]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B7-07: sensitivity variants
    local alt_vars "ln_co2_total_alt_lpg ln_co2_total_alt_kali ln_co2_total_alt_rosita ln_co2_total_alt_exc2004 ln_co2_total_alt_towngas"
    foreach v of local alt_vars {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B7-07]: sensitivity variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B7-07]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B7-08: intensity variables
    foreach v in co2_intensity_worker_s1 co2_intensity_output_s1 ln_co2_intensity_worker_s1 {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B7-08]: intensity variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B7-08]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B7-09: CRITICAL — no severe flags in final dataset
    capture confirm variable flag_any_sev
    if _rc {
        di as error "  FAIL [B7-09]: flag_any_sev missing from final dataset"
        local fail = `fail' + 1
    }
    else {
        qui count if flag_any_sev == 1
        if r(N) > 0 {
            di as error "  FAIL [B7-09]: " r(N) " obs have flag_any_sev==1 in final dataset — should be zero"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B7-09]: flag_any_sev==0 for all 314,576 obs (assert will pass)"
            local pass = `pass' + 1
        }
    }

    * B7-10: co2_total_s1 is non-negative where non-missing
    qui su co2_total_s1
    if r(min) < 0 {
        di as error "  FAIL [B7-10]: co2_total_s1 has negative values (min=" r(min) ") — check emission calc"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-10]: co2_total_s1 non-negative (min=" r(min) ", max=" r(max) ")"
        local pass = `pass' + 1
    }

    * B7-11: ln_co2_total_s1 — plausible range (log tCO2e: roughly -5 to 15)
    qui su ln_co2_total_s1
    di as txt "  INFO [B7-11]: ln_co2_total_s1 — mean=" %6.3f r(mean) "  sd=" %6.3f r(sd) "  min=" %6.3f r(min) "  max=" %6.3f r(max)
    if r(mean) < 0 | r(mean) > 15 {
        di as error "  FAIL [B7-11]: ln_co2_total_s1 mean=" r(mean) " — outside plausible range [0,15]"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-11]: ln_co2_total_s1 mean in plausible range"
        local pass = `pass' + 1
    }

    * B7-12: year coverage (2000–2014)
    qui su year
    if r(min) != 2000 | r(max) != 2014 {
        di as error "  FAIL [B7-12]: year range [" r(min) "," r(max) "] — expected 2000–2014"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-12]: year range 2000–2014"
        local pass = `pass' + 1
    }

    * B7-13: psid uniqueness within psid-year (no duplicates)
    qui duplicates report psid year
    if r(unique_value) < _N {
        local ndups = _N - r(unique_value)
        di as error "  FAIL [B7-13]: " `ndups' " duplicate psid-year pairs in final dataset"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-13]: no duplicate psid-year pairs"
        local pass = `pass' + 1
    }

    * B7-14: co2_scope1_nfuels in 0–9 range
    qui su co2_scope1_nfuels
    if r(min) < 0 | r(max) > 9 {
        di as error "  FAIL [B7-14]: co2_scope1_nfuels outside [0,9]: min=" r(min) " max=" r(max)
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-14]: co2_scope1_nfuels in [0,9] (min=" r(min) " max=" r(max) ")"
        local pass = `pass' + 1
    }

    * B7-15: assert macro for Mba Deasy's use
    di as txt "  INFO [B7-15]: Running assert checks from HANDOVER.md..."
    capture assert flag_any_sev == 0
    if _rc {
        di as error "  FAIL [B7-15]: assert flag_any_sev==0 FAILED"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B7-15]: assert flag_any_sev==0 passed"
        local pass = `pass' + 1
    }
}


* ============================================================
* BLOCK 8 — Do-file portability check
* ============================================================
di as txt _n "--- BLOCK 8: Do-file portability check ---"

* Check that 00_config.do exists at handoff root (Opsi B — portable setup)
capture confirm file "$handoff/dofiles/00_config.do"
if _rc {
    di as error "  FAIL [B8-00]: 00_config.do missing from dofiles/"
    local fail = `fail' + 1
}
else {
    di as txt "  PASS [B8-00]: 00_config.do present (Opsi B — portable)"
    local pass = `pass' + 1
}

* Check that all do-files exist in dofiles/ (00–19 core pipeline)
local dofiles "00b_run_all_pipeline 00c_extract_ihpb 01_append_si_energy 06_harmonize_si_energy 08_outlier_flags 09_clean_apply 10_carbon_convert 11_sensitivity_variants 12_descriptive_stats 14_finalize_variable_order 15_extend_wpio_ihpb 16_energy_intensity 17_ei_figures 18_fig_unit_price 19_fig_subsidy_context"
foreach f of local dofiles {
    capture confirm file "$handoff/dofiles/`f'.do"
    if _rc {
        di as error "  FAIL [B8-01]: do-file `f'.do missing from dofiles/"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B8-01]: dofiles/`f'.do present"
        local pass = `pass' + 1
    }
}

* Check that logs exist
local logfiles "01_append_si_energy 06_harmonize_si_energy 08_outlier_flags 09_clean_apply 10_carbon_convert 14_finalize_variable_order 15_extend_wpio_ihpb 16_energy_intensity 17_ei_figures"
foreach f of local logfiles {
    capture confirm file "$handoff/dofiles/logs/`f'.log"
    if _rc {
        di as error "  FAIL [B8-02]: log `f'.log missing from dofiles/logs/"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B8-02]: logs/`f'.log present"
        local pass = `pass' + 1
    }
}

* Check concordance data files (new in v2)
foreach f in "data/concordance/ihpb_isic4_concordance.csv" "data/concordance/ihpb_annual_averages.csv" "data/steps/step15_wpio_extended.dta" {
    capture confirm file "$handoff/`f'"
    if _rc {
        di as error "  FAIL [B8-03]: concordance/WPI file missing: `f'"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B8-03]: `f' present"
        local pass = `pass' + 1
    }
}


* ============================================================
* BLOCK 9 — xtset compatibility check on final dataset
* ============================================================
di as txt _n "--- BLOCK 9: Panel structure (xtset) check ---"

use "$handoff/si_energy_emissions.dta", clear

capture xtset psid year
if _rc {
    di as error "  FAIL [B9-01]: xtset psid year failed — panel not uniquely identified (rc=" _rc ")"
    local fail = `fail' + 1
}
else {
    di as txt "  PASS [B9-01]: xtset psid year succeeded — panel uniquely identified"
    local pass = `pass' + 1
}

* B9-02: check panel is strongly balanced or note gaps
qui xtsum year
di as txt "  INFO [B9-02]: panel — N=" r(N) " n=" r(n) " T-bar=" %5.2f r(Tbar)
if r(Tbar) < 5 {
    di as txt "  WARN [B9-02]: T-bar=" %5.2f r(Tbar) " — panel is short; note for Mba Deasy"
    local warn = `warn' + 1
}
else {
    di as txt "  PASS [B9-02]: T-bar=" %5.2f r(Tbar) " — reasonable panel depth"
    local pass = `pass' + 1
}


* ============================================================
* BLOCK 10 — si_energy_intensity.dta (component file)
* ============================================================
di as txt _n "--- BLOCK 10: si_energy_intensity.dta (v2 new) ---"

capture use "$handoff/si_energy_intensity.dta", clear
if _rc {
    di as error "FAIL [B10-01]: Cannot open si_energy_intensity.dta — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)

    * B10-01: obs count (documented: 314,574 — 2 dropped for missing output)
    if _N != 314574 {
        di as error "  FAIL [B10-01]: obs = " _N " — expected 314,574"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B10-01]: obs = 314,574 — matches documentation"
        local pass = `pass' + 1
    }

    * B10-02: primary intensity outcomes present
    local ei_vars "ln_ei_monetary_zero ln_ei_gj_real ln_ei_co2_real ei_gj_s1 ei_monetary_zero total_gj_s1 output_real wpi"
    foreach v of local ei_vars {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B10-02]: key variable `v' missing"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B10-02]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B10-03: WPI coverage — should be ~99.93% non-missing
    qui count if !missing(wpi)
    local wpi_n = r(N)
    local wpi_pct = `wpi_n' / _N * 100
    di as txt "  INFO [B10-03]: WPI coverage = `wpi_n' / " _N " (" %5.2f `wpi_pct' "%)"
    if `wpi_pct' < 99 {
        di as error "  FAIL [B10-03]: WPI coverage < 99% — unexpected"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B10-03]: WPI coverage >= 99%"
        local pass = `pass' + 1
    }

    * B10-04: ei_monetary_zero positive where non-missing
    qui su ei_monetary_zero
    if r(min) < 0 {
        di as error "  FAIL [B10-04]: ei_monetary_zero has negative values (min=" r(min) ")"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B10-04]: ei_monetary_zero non-negative (min=" r(min) ")"
        local pass = `pass' + 1
    }

    * B10-05: ln_ei_gj_real plausible range
    qui su ln_ei_gj_real
    di as txt "  INFO [B10-05]: ln_ei_gj_real — mean=" %6.3f r(mean) "  sd=" %6.3f r(sd)
    if r(mean) < -10 | r(mean) > 5 {
        di as error "  FAIL [B10-05]: ln_ei_gj_real mean=" r(mean) " — outside plausible range"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B10-05]: ln_ei_gj_real mean in plausible range"
        local pass = `pass' + 1
    }

    * B10-06: no duplicate psid-year
    qui duplicates report psid year
    if r(unique_value) < _N {
        di as error "  FAIL [B10-06]: duplicate psid-year pairs in si_energy_intensity.dta"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B10-06]: no duplicate psid-year pairs"
        local pass = `pass' + 1
    }
}


* ============================================================
* BLOCK 11 — PRIMARY FINAL: si_energy_emission_and_intensity.dta
* ============================================================
di as txt _n "--- BLOCK 11: si_energy_emission_and_intensity.dta (PRIMARY FINAL) ---"

capture use "$handoff/si_energy_emission_and_intensity.dta", clear
if _rc {
    di as error "FATAL [B11-01]: Cannot open combined final dataset — rc=" _rc
    local fail = `fail' + 1
}
else {
    di as txt "  Obs = " _N "  Vars = " c(k)

    * B11-01: obs count
    if _N != 314576 {
        di as error "  FAIL [B11-01]: obs = " _N " — expected 314,576"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B11-01]: obs = 314,576"
        local pass = `pass' + 1
    }

    * B11-02: var count
    if c(k) != 227 {
        di as error "  FAIL [B11-02]: var count = " c(k) " — expected 227"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B11-02]: var count = 227"
        local pass = `pass' + 1
    }

    * B11-03: key outcomes from BOTH sides present
    local combined_vars "ln_co2_total_s1 ln_co2_total_s2 ln_ei_monetary_zero ln_ei_gj_real ln_ei_co2_real wpi output_real flag_any_sev"
    foreach v of local combined_vars {
        capture confirm variable `v'
        if _rc {
            di as error "  FAIL [B11-03]: key variable `v' missing from combined file"
            local fail = `fail' + 1
        }
        else {
            di as txt "  PASS [B11-03]: `v' present"
            local pass = `pass' + 1
        }
    }

    * B11-04: no severe flags
    qui count if flag_any_sev == 1
    if r(N) > 0 {
        di as error "  FAIL [B11-04]: " r(N) " obs with flag_any_sev==1 in combined file"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B11-04]: flag_any_sev==0 for all obs"
        local pass = `pass' + 1
    }

    * B11-05: xtset
    capture xtset psid year
    if _rc {
        di as error "  FAIL [B11-05]: xtset psid year failed (rc=" _rc ")"
        local fail = `fail' + 1
    }
    else {
        di as txt "  PASS [B11-05]: xtset psid year succeeded"
        local pass = `pass' + 1
    }

    * B11-06: 2 obs with missing intensity vars (those 2 had missing output)
    qui count if missing(ln_ei_monetary_zero) & !missing(ln_co2_total_s1)
    di as txt "  INFO [B11-06]: obs with co2 but missing intensity (should be ~2): " r(N)
}


* ============================================================
* SUMMARY
* ============================================================
di as txt _n "{hline 70}"
di as txt "  VALIDATION SUMMARY"
di as txt "{hline 70}"
di as txt "  PASS : " `pass'
di as txt "  WARN : " `warn'
di as txt "  FAIL : " `fail'
di as txt "{hline 70}"

if `fail' == 0 & `warn' == 0 {
    di as txt "  *** ALL CHECKS PASSED — handoff package is clean ***"
}
else if `fail' == 0 {
    di as txt "  *** No failures — " `warn' " warning(s) to review ***"
}
else {
    di as error "  *** " `fail' " FAILURE(S) — review FAIL lines above ***"
}

di as txt "{hline 70}"
log close
