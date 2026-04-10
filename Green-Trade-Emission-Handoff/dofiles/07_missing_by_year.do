* ============================================================
* Script: 07_missing_by_year.do
* Purpose: Compute % missing by year for key energy variables
*          in si_panel_2000_2014.dta. Replaces binary presence
*          table with informative missingness rates.
* Input:   output/si_panel_2000_2014.dta
* Output:  output/tables/pct_missing_by_year.csv
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
global tables  "$handoff/output/tables"

cap mkdir "$tables"
log using "$logs/07_missing_by_year.log", replace text

use "$output/si_panel_2000_2014.dta", clear

* Key variables to check (grouped logically)
local varlist ///
    eplvcu enpvcu esgkhu ///
    epevcu epeliu ///
    esovcu esoliu ///
    eluvcu eluliu ///
    eoivcu eoiliu ///
    eclvcu eclkgu ///
    egavcu egam3u ///
    elpvcu elpkgu ///
    encvcu efuvcu ///
    edivcu ediliu ///
    efovcu efoliu ///
    ecbvcu ecbkgu ///
    egovcu egom3u

* ── Build output dataset ─────────────────────────────────────────────────────
* For each variable × year: count total obs and missing obs → % missing

* First get total obs per year
tempfile base
preserve
    contract year, freq(n_total)
    save `base'
restore

* Collect results into a matrix-like structure
postfile handle str12 varname int yr float pct_miss using "$tables/pct_missing_by_year_raw.dta", replace

foreach v of local varlist {
    cap confirm variable `v'
    if _rc != 0 {
        di as txt "SKIP (not found): `v'"
        continue
    }
    forval y = 2000/2014 {
        quietly count if year == `y'
        local n_total = r(N)
        quietly count if year == `y' & missing(`v')
        local n_miss = r(N)
        if `n_total' > 0 {
            local pct = 100 * `n_miss' / `n_total'
        }
        else {
            local pct = .
        }
        post handle ("`v'") (`y') (`pct')
    }
}

postclose handle

* ── Reshape and export ────────────────────────────────────────────────────────
use "$tables/pct_missing_by_year_raw.dta", clear

* Round to 1 decimal
replace pct_miss = round(pct_miss, 0.1)

* Reshape wide: one row per variable, columns = years
reshape wide pct_miss, i(varname) j(yr)

* Rename year columns to short labels
foreach y of numlist 2000/2014 {
    local yshort = substr("`y'", 3, 2)
    rename pct_miss`y' y`yshort'
}

* Display in log
di as txt _n "=== % MISSING BY YEAR (rounded to 0.1%) ==="
di as txt "  " %-15s "Variable" %6s "00" %6s "01" %6s "02" %6s "03" %6s "04" %6s "05" %6s "06" %6s "07" %6s "08" %6s "09" %6s "10" %6s "11" %6s "12" %6s "13" %6s "14"
di as txt "  {hline 105}"

forval i = 1/`=_N' {
    local vn = varname[`i']
    di as txt "  " %-15s "`vn'" ///
        %6.1f y00[`i'] %6.1f y01[`i'] %6.1f y02[`i'] %6.1f y03[`i'] %6.1f y04[`i'] ///
        %6.1f y05[`i'] %6.1f y06[`i'] %6.1f y07[`i'] %6.1f y08[`i'] %6.1f y09[`i'] ///
        %6.1f y10[`i'] %6.1f y11[`i'] %6.1f y12[`i'] %6.1f y13[`i'] %6.1f y14[`i']
}

* Export CSV
export delimited using "$tables/pct_missing_by_year.csv", replace
di as txt _n "Saved: $tables/pct_missing_by_year.csv"

di as txt _n "=== END ==="
log close
