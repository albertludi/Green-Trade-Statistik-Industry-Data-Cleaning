* ============================================================
* Script: 03_psid_merge_check.do
* Purpose: Document the linkage between two data sources:
*            (A) si{year}.dta  — annual SI files with energy vars
*            (B) data8514_SI.dta — pre-built long panel (no fuel vars)
*          For each year 2000–2014, checks whether psid is unique
*          within each source and reports match rates.
*          Results feed QMD Section 2 (Data Sources).
* Input:   data8514_SI/data8514_SI.dta
*          [sidata]/si{year}.dta  (2000–2014)
* Output:  output/tables/psid_merge_check.csv
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
global data8514 "$rawdata/data8514_SI.dta"

log using "$logs/03_psid_merge_check.log", replace text

local years "2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014"

* ── Write CSV header ────────────────────────────────────────────────────────
file open res using "$tables/psid_merge_check.csv", write replace
file write res "year,n_si,n_8514,n_matched,n_only_si,n_only_8514,pct_matched_si,pct_matched_8514" _n

* ── Log header ──────────────────────────────────────────────────────────────
di as txt _n "=== PSID MERGE CHECK: si{year}.dta vs data8514_SI.dta ==="
di as txt "  psid is the merge key. Merge is 1:1 within year."
di as txt _n "  " %-6s "Year" %10s "N_si" %10s "N_8514" %12s "Matched" %12s "Only_si" %12s "Only_8514" %10s "%_si" %10s "%_8514"
di as txt "  {hline 85}"

* ── Loop over years ─────────────────────────────────────────────────────────
foreach y of local years {

    * Check si file exists
    capture confirm file "$sidata/si`y'.dta"
    if _rc != 0 {
        di as txt "  `y'  [si`y'.dta NOT FOUND — skipped]"
        continue
    }

    * --- Source A: si{year}.dta ---
    use "$sidata/si`y'.dta", clear
    keep psid

    * Confirm psid is unique
    quietly duplicates report psid
    local dup_si = r(unique_value)   // should equal _N if no dups
    local n_si = _N

    sort psid
    tempfile si_ids
    save `si_ids'

    * --- Source B: data8514_SI year y ---
    use "$data8514" if year == `y', clear
    keep psid

    quietly duplicates report psid
    local n_8514 = _N

    sort psid

    * --- Merge ---
    merge 1:1 psid using `si_ids'

    quietly count if _merge == 3
    local n_matched = r(N)
    quietly count if _merge == 1
    local n_only_8514 = r(N)
    quietly count if _merge == 2
    local n_only_si = r(N)

    * Match rates
    local pct_si   = round(`n_matched' / `n_si'   * 100, 0.1)
    local pct_8514 = round(`n_matched' / `n_8514' * 100, 0.1)

    di as txt "  " %-6s "`y'" %10.0fc `n_si' %10.0fc `n_8514' %12.0fc `n_matched' %12.0fc `n_only_si' %12.0fc `n_only_8514' %9.1fc `pct_si' "%"  %9.1fc `pct_8514' "%"

    file write res "`y',`n_si',`n_8514',`n_matched',`n_only_si',`n_only_8514',`pct_si',`pct_8514'" _n
}

di as txt "  {hline 85}"

file close res
di as txt _n "Saved: $tables/psid_merge_check.csv"

* ── Summary note ────────────────────────────────────────────────────────────
di as txt _n "=== INTERPRETATION ==="
di as txt "  n_only_si    = firms in si{year} with NO match in data8514_SI"
di as txt "                 (energy data available, no panel covariates)"
di as txt "  n_only_8514  = firms in data8514_SI with NO match in si{year}"
di as txt "                 (panel covariates available, no energy data)"
di as txt "  Matched      = firms present in BOTH — full merge possible"
di as txt "  A 1:1 merge by psid+year retains matched obs and drops unmatched"
di as txt "  unless force-merged. Researcher must decide how to handle gaps."

log close
