/*
00_produce_tables.do
Green-Trade Project — Produce the data-backed tables in data_memo.pdf
Tables 1, 3, and 6 are derived from data.
Tables 2, 4, and 5 are reference/documentation tables (not data-derived).

Run:  do dofiles/00_produce_tables.do
*/

* ── Paths ─────────────────────────────────────────────────────────────────────
gl data    "/Users/albertludi/Library/CloudStorage/GoogleDrive-albertludi@gmail.com/My Drive/Cursor database/Mba Deasy-Green Project/data8514_SI"
gl dofiles "/Users/albertludi/Library/CloudStorage/GoogleDrive-albertludi@gmail.com/My Drive/Cursor database/Mba Deasy-Green Project/dofiles"
gl output  "/Users/albertludi/Library/CloudStorage/GoogleDrive-albertludi@gmail.com/My Drive/Cursor database/Mba Deasy-Green Project/dofiles/output-stata"


* ══════════════════════════════════════════════════════════════════════════════
* TABLE 1: Dataset Summary
* ══════════════════════════════════════════════════════════════════════════════

use "$data/data8514_SI.dta", clear

cap log close
log using "$output/table1_dataset_summary.log", replace text

di as txt _n "{hline 60}"
di as txt "TABLE 1: DATASET SUMMARY"
di as txt "{hline 60}"

count
local N_total = r(N)
di as txt "Total obs (firm-years):  " %15.0fc `N_total'

su year, meanonly
di as txt "Year range:              " r(min) "–" r(max)

tempvar tag
bys psid: gen `tag' = (_n == 1)
count if `tag'
di as txt "Unique establishments:   " r(N) " *"

tempvar tag2
bys dprovi: gen `tag2' = (_n == 1)
count if `tag2'
di as txt "Provinces:               " r(N) " *"

ds
local nvars : word count `r(varlist)'
di as txt "Variables in file:       " `nvars'
di as txt "  (* = verify with codebook / tabulate before finalising)"

log close


* ══════════════════════════════════════════════════════════════════════════════
* TABLE 3: Energy Variable Coverage
* ══════════════════════════════════════════════════════════════════════════════

* (data still loaded — full 579,533 obs; N_total still in memory)

cap log close
log using "$output/table3_coverage.log", replace text

di as txt _n "{hline 60}"
di as txt "TABLE 3: ENERGY VARIABLE COVERAGE"
di as txt "  Coverage = share of " %15.0fc `N_total' " total firm-year obs"
di as txt "  with a non-zero, non-missing value."
di as txt "{hline 60}"

* helper: print one row
cap program drop _cov_row
program _cov_row
    args v N_total
    count if `v' > 0 & !missing(`v')
    local nz    = r(N)
    local pct   = `nz' / `N_total' * 100
    su year if `v' > 0 & !missing(`v'), meanonly
    local y0    = r(min)
    local y1    = r(max)
    di as txt "  " %-12s "`v'"  %12.0fc `nz'  "  (" %4.1f `pct' "%)  " `y0' "–" `y1'
end

* ── Panel A: Electricity
di as txt _n "  A. Electricity"
di as txt "  " %-12s "Variable"  %12s "Non-zero obs"  "  (%)"  "   Years"
di as txt "  " "{hline 52}"
foreach v in efuvcu eplvcu enpvcu {
    _cov_row `v' `N_total'
}

* ── Panel B: Fuel — monetary value (vcu)
di as txt _n "  B. Fuel — monetary value (vcu)"
di as txt "  " %-12s "Variable"  %12s "Non-zero obs"  "  (%)"  "   Years"
di as txt "  " "{hline 52}"
foreach v in zpdvcu zndvcu zpsvcu znsvcu zpovcu znovcu ///
             zpivcu znivcu zpzvcu znzvcu zpxvcu znxvcu {
    _cov_row `v' `N_total'
}

* ── Panel C: Fuel — physical quantity (kcu)
di as txt _n "  C. Fuel — physical quantity (kcu)"
di as txt "  " %-12s "Variable"  %12s "Non-zero obs"  "  (%)"  "   Years"
di as txt "  " "{hline 52}"
foreach v in zpdkcu zndkcu zpskcu znskcu zpokcu znokcu zpikcu znikcu {
    _cov_row `v' `N_total'
}

log close


* ══════════════════════════════════════════════════════════════════════════════
* TABLE 6: Year-by-Year Availability (2000–2014)
* ══════════════════════════════════════════════════════════════════════════════

use "$data/data8514_SI.dta", clear
keep if year >= 2000 & year <= 2014

cap log close
log using "$output/table6_availability.log", replace text

di as txt _n "{hline 72}"
di as txt "TABLE 6: YEAR-BY-YEAR AVAILABILITY, 2000–2014"
di as txt "  Y = at least one non-zero obs in that year"
di as txt "  - = all zero or missing"
di as txt "{hline 72}"

local elec_vars  efuvcu eplvcu enpvcu
local zp_vars    zpdvcu zpsvcu zpovcu zpivcu zpzvcu zpxvcu
local zn_vars    zndvcu znsvcu znovcu znivcu znzvcu znxvcu

* Header row
di as txt _n "  " %-12s "Variable" _continue
forval y = 2000/2014 {
    local yy = substr(string(`y'), 3, 2)
    di as txt "  `yy'" _continue
}
di as txt ""
di as txt "  {hline 72}"

* Rows
foreach group in "Electricity" "Fuel zp*vcu (production)" "Fuel zn*vcu (non-production)" {
    di as txt _n "  [`group']"

    if "`group'" == "Electricity"                   local varlist `elec_vars'
    if "`group'" == "Fuel zp*vcu (production)"      local varlist `zp_vars'
    if "`group'" == "Fuel zn*vcu (non-production)"  local varlist `zn_vars'

    foreach v of local varlist {
        di as txt "  " %-12s "`v'" _continue
        forval y = 2000/2014 {
            count if year == `y' & `v' > 0 & !missing(`v')
            if r(N) > 0   di as txt "   Y" _continue
            else          di as txt "   -" _continue
        }
        di as txt ""
    }
}

di as txt _n "{hline 72}"
di as txt "Done."

log close
