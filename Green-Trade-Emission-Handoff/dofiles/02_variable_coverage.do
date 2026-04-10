* ============================================================
* Script: 02_variable_coverage.do
* Purpose: Produce variable availability documentation from the
*          appended SI energy panel. No data modification here —
*          only description and tabulation.
*          Feeds QMD Chapter 2 (Data Panel Structure) and
*          Chapter 3 (Data Gaps).
* Input:   output/si_panel_2000_2014.dta  (from 01_append_si_energy.do)
* Output:  output/tables/var_coverage_matrix.csv
*          output/tables/var_list.csv
*          output/tables/obs_by_year.csv
*          log: structural gap summary
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

* Create tables subfolder if needed
cap mkdir "$tables"

log using "$logs/02_variable_coverage.log", replace text

use "$output/si_panel_2000_2014.dta", clear

di as txt _n "=== DATASET OVERVIEW ==="
di as txt "  Obs: " _N "   Vars: " c(k)

* ============================================================
* SECTION 1 — OBS PER YEAR
* ============================================================

di as txt _n "=== OBSERVATIONS PER YEAR ==="
tab year

* Export obs-by-year to CSV
preserve
    collapse (count) n_obs = psid, by(year)
    export delimited using "$tables/obs_by_year.csv", replace
    di as txt "  Saved: obs_by_year.csv"
restore

* ============================================================
* SECTION 2 — VARIABLE LIST WITH LABELS
* ============================================================
* Produce a tidy variable inventory: name, label, storage type
* Excludes psid and year (ID vars)

di as txt _n "=== VARIABLE INVENTORY ==="
di as txt "  " %-22s "Variable" %-12s "Type" "Label"
di as txt "  {hline 90}"

* Write CSV header
file open vlist using "$tables/var_list.csv", write replace
file write vlist "variable,storage_type,label" _n

foreach v of varlist _all {
    if "`v'" == "psid" | "`v'" == "year" continue

    local vtype : type `v'
    local vlab  : variable label `v'

    di as txt "  " %-22s "`v'" %-12s "`vtype'" "`vlab'"
    file write vlist `"`v',`vtype',"`vlab'""' _n
}
di as txt "  {hline 90}"
file close vlist
di as txt "  Saved: var_list.csv  (" c(k) " vars total)"

* ============================================================
* SECTION 3 — COVERAGE MATRIX: N non-missing by year
* ============================================================
* For each variable × year: count of non-missing observations.
* This is the raw number — allows distinction between:
*   0   = variable exists in dataset but ALL obs are missing that year
*   N   = variable present and reported

di as txt _n "=== VARIABLE COVERAGE MATRIX (N non-missing per year) ==="

* Write CSV
file open cov using "$tables/var_coverage_matrix.csv", write replace
file write cov "variable"
forval y = 2000/2014 {
    file write cov ",`y'"
}
file write cov _n

* Header line to log
di as txt "  " %-26s "Variable" _continue
forval y = 2000/2014 {
    di as txt %6s "`y'" _continue
}
di as txt ""
di as txt "  {hline 120}"

foreach v of varlist _all {
    if "`v'" == "psid" | "`v'" == "year" continue

    di as txt "  " %-26s "`v'" _continue
    file write cov "`v'"

    forval y = 2000/2014 {
        quietly count if year == `y' & !missing(`v')
        local n = r(N)
        di as txt %6.0fc `n' _continue
        file write cov ",`n'"
    }
    di as txt ""
    file write cov _n
}
di as txt "  {hline 120}"
file close cov
di as txt "  Saved: var_coverage_matrix.csv"

* ============================================================
* SECTION 4 — BINARY PRESENCE MATRIX (1/0 by year)
* ============================================================
* Collapse to: variable present in that year = 1, absent = 0
* "Present" = at least 1 non-missing obs in that year
* This is what QMD Ch 2-3 tables will display

di as txt _n "=== BINARY PRESENCE BY YEAR (1=present, 0=structurally absent) ==="

* Group labels for readable log output
local grp_elec    "eplkhu eplvcu enpkhu enpvcu esgkhu"
local grp_diesel  "esoliu esovcu esolie esovce ediliu edivcu edilie edivce"
local grp_gasoline "epeliu epevcu epelie epevce"
local grp_kerosene "eoiliu eoivcu eoilie eoivce"
local grp_fueloil  "efoliu efovcu efolie efovce"
local grp_coal     "eclkgu eclvcu eclkge eclvce"
local grp_coke     "eckkgu eckvcu eckkge eckvce"
local grp_gas      "egam3u egavcu egam3e egavce egom3u egovcu egom3e egovce"
local grp_lpg      "elpkgu elpvcu elpkge elpvce"
local grp_other    "encvcu encvce eluliu eluvcu elulie eluvce efuvcu efuvce"
local grp_biomass  "ecakgu ecavcu ecakge ecavce ewokgu ewovcu ewokge ewovce"
local grp_coalbriq "ecbkgu ecbvcu ecbkge ecbvce"

foreach grp in elec diesel gasoline kerosene fueloil coal coke gas lpg other biomass coalbriq {
    di as txt _n "  -- `grp' --"
    di as txt "  " %-26s "Variable" _continue
    forval y = 2000/2014 {
        local yy = substr(string(`y'),3,2)
        di as txt %5s "`yy'" _continue
    }
    di as txt ""

    foreach v of local grp_`grp' {
        cap confirm variable `v'
        if _rc != 0 continue

        di as txt "  " %-26s "`v'" _continue
        forval y = 2000/2014 {
            quietly count if year == `y' & !missing(`v')
            if r(N) > 0 {
                di as txt %5s "1" _continue
            }
            else {
                quietly count if year == `y'
                if r(N) > 0 {
                    di as txt %5s "0" _continue
                }
                else {
                    di as txt %5s "." _continue
                }
            }
        }
        di as txt ""
    }
}

* ============================================================
* SECTION 5 — STRUCTURAL GAP SUMMARY (for QMD Ch 3)
* ============================================================
* Identify variables with year gaps and classify the gap type

di as txt _n "=== STRUCTURAL GAP SUMMARY ==="
di as txt "  Variables with at least one absent year:"
di as txt "  " %-26s "Variable" %-35s "Gap years" "Gap type"
di as txt "  {hline 90}"

foreach v of varlist _all {
    if "`v'" == "psid" | "`v'" == "year" continue

    local gap_years ""
    local n_present 0
    local n_absent  0

    forval y = 2000/2014 {
        quietly count if year == `y'
        local yr_exists = (r(N) > 0)
        if `yr_exists' {
            quietly count if year == `y' & !missing(`v')
            if r(N) == 0 {
                local gap_years "`gap_years' `y'"
                local n_absent = `n_absent' + 1
            }
            else {
                local n_present = `n_present' + 1
            }
        }
    }

    if `n_absent' > 0 {
        * Classify gap type
        local gtype ""
        if `n_present' == 0       local gtype "never collected"
        else if `n_absent' >= 10  local gtype "mostly absent (sparse)"
        else if `n_absent' <= 2   local gtype "short gap"
        else                      local gtype "long gap"

        di as txt "  " %-26s "`v'" %-35s "`gap_years'" "`gtype'"
    }
}
di as txt "  {hline 90}"

* ============================================================
* SECTION 6 — EKSPOR (export status) COVERAGE CHECK
* ============================================================
* ekspor is the treatment variable for Mba Deasy's research —
* check its availability separately

cap confirm variable ekspor
if _rc == 0 {
    di as txt _n "=== EKSPOR (EXPORT STATUS) COVERAGE ==="
    di as txt "  " %-6s "Year" %12s "N total" %12s "N non-miss" %12s "% non-miss"
    di as txt "  {hline 45}"
    forval y = 2000/2014 {
        quietly count if year == `y'
        local ntot = r(N)
        quietly count if year == `y' & !missing(ekspor)
        local nval = r(N)
        if `ntot' > 0 {
            local pct = round(`nval' / `ntot' * 100, 0.1)
            di as txt "  " %-6s "`y'" %12.0fc `ntot' %12.0fc `nval' %12.1fc `pct'
        }
    }
    di as txt "  {hline 45}"
}

log close
