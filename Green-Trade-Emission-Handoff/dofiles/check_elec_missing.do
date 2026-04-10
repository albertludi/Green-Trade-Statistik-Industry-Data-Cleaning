* ============================================================
* Script: check_elec_missing.do
* Purpose: Check % missing by year for eplkhu and enpkhu
* ============================================================

clear all
set more off
capture log close

* ── Paths (all derived from $handoff — set via 00_config.do) ──────────────
if "$handoff" == "" {
    di as error "ERROR: global 'handoff' is not set."
    di as error "       Run: do {path_to_handoff}/00_config.do"
    exit 1
}
global root    "$handoff"
global sidata  "$handoff/data/si_annual"
global output  "$handoff/output"
global logs    "$handoff/logs"
global rawdata "$handoff/data/raw"
global concord "$handoff/data/concordance"
global dofiles "$handoff/dofiles"

use "$output/si_panel_2000_2014.dta", clear

di "=== % MISSING BY YEAR: eplkhu (PLN electricity kWh) ==="
forvalues y = 2000/2014 {
    quietly count if year == `y'
    local n = r(N)
    quietly count if year == `y' & missing(eplkhu)
    local m = r(N)
    local pct = round(`m'/`n'*100, 0.1)
    di "  `y': `pct'% missing  (N=`n', missing=`m')"
}

di ""
di "=== % MISSING BY YEAR: enpkhu (Non-PLN electricity kWh) ==="
forvalues y = 2000/2014 {
    quietly count if year == `y'
    local n = r(N)
    quietly count if year == `y' & missing(enpkhu)
    local m = r(N)
    local pct = round(`m'/`n'*100, 0.1)
    di "  `y': `pct'% missing  (N=`n', missing=`m')"
}
