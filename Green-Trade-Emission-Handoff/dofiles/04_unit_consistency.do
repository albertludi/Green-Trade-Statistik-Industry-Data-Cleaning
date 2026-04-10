* ============================================================
* Script: 04_unit_consistency.do
* Purpose: Document unit and scale inconsistencies across survey
*          years in si_panel_2000_2014.dta. Shows distribution
*          statistics (median, P75, P99, max) per physical quantity
*          variable × year. Flags years where the median jumps
*          implausibly — evidence of a unit change.
*          Key focus: coal (eclkgu) Ton vs Kg change in 2004–2005.
*          Results feed QMD Chapter 4 (Unit Consistency & Data Gaps).
* Input:   output/si_panel_2000_2014.dta
* Output:  output/tables/unit_consistency.csv
*          output/tables/structural_gaps.csv
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

log using "$logs/04_unit_consistency.log", replace text

use "$output/si_panel_2000_2014.dta", clear

* Physical quantity variables to inspect
* (monetary *vcu excluded — unit is always Rp000)
local phys_vars "esoliu epeliu eoiliu eclkgu eckkgu egam3u elpkgu eluliu ecbkgu egom3u ediliu efoliu ecakgu ewokgu esolie epelie eoilie eclkge eplkhu enpkhu esgkhu"

* ============================================================
* SECTION 1 — DISTRIBUTION BY YEAR (physical qty vars)
* ============================================================

di as txt _n "=== PHYSICAL QUANTITY DISTRIBUTIONS BY YEAR ==="
di as txt "  Positive obs only. Values in reported units."
di as txt "  Flag: ratio of adjacent-year medians > 5 or < 0.2 → possible unit change"

* Write CSV header
file open uc using "$tables/unit_consistency.csv", write replace
file write uc "variable,year,n_pos,median,p75,p99,max,ratio_prev_median" _n

foreach v of local phys_vars {
    cap confirm variable `v'
    if _rc != 0 continue

    di as txt _n "  --- `v' ---"
    di as txt "  " %-6s "Year" %10s "N_pos" %15s "Median" %15s "P75" %15s "P99" %15s "Max" %10s "Ratio_prev"
    di as txt "  {hline 80}"

    local prev_med = .

    forval y = 2000/2014 {
        quietly count if year == `y' & `v' > 0 & !missing(`v')
        local npos = r(N)

        if `npos' >= 10 {
            quietly summarize `v' if year == `y' & `v' > 0, detail
            local med  = r(p50)
            local p75  = r(p75)
            local p99  = r(p99)
            local vmax = r(max)

            * Ratio to previous year median
            local ratio = .
            if `prev_med' != . & `prev_med' > 0 {
                local ratio = round(`med' / `prev_med', 0.01)
            }

            * Flag implausible jumps
            local flag ""
            if `ratio' != . {
                if `ratio' > 5 | `ratio' < 0.2 {
                    local flag "  *** UNIT CHANGE?"
                }
            }

            di as txt "  " %-6s "`y'" %10.0fc `npos' %15.0fc `med' %15.0fc `p75' %15.0fc `p99' %15.0fc `vmax' %10.2fc `ratio' "`flag'"

            * Write to CSV (ratio as string to handle missing)
            if `ratio' == . {
                file write uc "`v',`y',`npos',`med',`p75',`p99',`vmax',." _n
            }
            else {
                file write uc "`v',`y',`npos',`med',`p75',`p99',`vmax',`ratio'" _n
            }

            local prev_med = `med'
        }
        else if `npos' > 0 {
            di as txt "  " %-6s "`y'" %10.0fc `npos' "  (< 10 positive obs — skipped)"
            local prev_med = .
        }
        else {
            * Absent year — reset ratio chain
            local prev_med = .
        }
    }
    di as txt "  {hline 80}"
}

file close uc
di as txt _n "Saved: $tables/unit_consistency.csv"

* ============================================================
* SECTION 2 — COAL UNIT DEEP DIVE (eclkgu)
* ============================================================
* Coal is the primary concern: questionnaire shows Ton in 2004–2005,
* Kg in other years. If so, 2004–2005 medians should be ~1000x smaller
* than adjacent years (since 1 Ton = 1000 Kg).

di as txt _n "=== COAL (eclkgu) UNIT DEEP DIVE ==="
di as txt "  If 2004–2005 are in Ton, their median should be ~1/1000 of 2003 or 2006."
di as txt _n "  " %-6s "Year" %10s "N_pos" %15s "Median (raw)" %15s "P25" %15s "P75" %15s "Max"
di as txt "  {hline 70}"

cap confirm variable eclkgu
if _rc == 0 {
    forval y = 2000/2014 {
        quietly count if year == `y' & eclkgu > 0 & !missing(eclkgu)
        if r(N) >= 5 {
            quietly summarize eclkgu if year == `y' & eclkgu > 0, detail
            di as txt "  " %-6s "`y'" %10.0fc r(N) %15.0fc r(p50) %15.0fc r(p25) %15.0fc r(p75) %15.0fc r(max)
        }
        else {
            quietly count if year == `y' & eclkgu > 0 & !missing(eclkgu)
            di as txt "  " %-6s "`y'" %10.0fc r(N) "  (too few)"
        }
    }
    di as txt "  {hline 70}"
    di as txt "  Interpretation: if 2004–2005 median << 2003 and 2006 median → Ton confirmed"
    di as txt "                  if 2004–2005 median ≈ 2003 and 2006 median → already in Kg"
}

* ============================================================
* SECTION 3 — STRUCTURAL GAP SUMMARY
* ============================================================
* For each physical var: list years where N_pos == 0 but year exists in panel

di as txt _n "=== STRUCTURAL GAPS (years with zero positive obs) ==="

file open sg using "$tables/structural_gaps.csv", write replace
file write sg "variable,gap_years,n_years_present,n_years_absent,gap_type" _n

di as txt "  " %-22s "Variable" %-40s "Gap years" "Gap type"
di as txt "  {hline 80}"

foreach v of local phys_vars {
    cap confirm variable `v'
    if _rc != 0 continue

    local gap_years ""
    local n_present = 0
    local n_absent  = 0

    forval y = 2000/2014 {
        quietly count if year == `y'
        if r(N) > 0 {
            quietly count if year == `y' & `v' > 0 & !missing(`v')
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
        local gtype ""
        if `n_present' == 0       local gtype "never collected"
        else if `n_absent' >= 10  local gtype "mostly absent"
        else if `n_absent' <= 2   local gtype "short gap"
        else                      local gtype "long gap"

        di as txt "  " %-22s "`v'" %-40s "`gap_years'" "`gtype'"
        file write sg `"`v',"`gap_years'",`n_present',`n_absent',`gtype'"' _n
    }
}
di as txt "  {hline 80}"

file close sg
di as txt _n "Saved: $tables/structural_gaps.csv"

log close
