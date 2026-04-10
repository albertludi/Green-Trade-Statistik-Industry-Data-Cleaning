* ============================================================
* Script: 01_append_si_energy.do
* Purpose: Build the 2000–2014 base panel from annual SI files.
*          Keeps psid, year, and all energy-related variables
*          (E* and IF* patterns — excludes ZP*VCU wages and all
*          other non-energy vars).
*          This file is the single source of truth for all
*          downstream do-files. Nothing after 01 touches the
*          raw yearly SI files.
* Input:   [sidata]/si{year}.dta  (annual files, 2000–2014)
* Output:  output/si_panel_2000_2014.dta
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

log using "$logs/01_append_si_energy.log", replace text

* ── Year list (2000–2014 only) ──────────────────────────────────────────────
local years "2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014"

di as txt _n "=== BUILDING SI PANEL 2000–2014 ==="
di as txt "  Source: $sidata"
di as txt "  {hline 80}"
di as txt "  " %-6s "Year" %10s "Obs" %10s "E*_vars" %10s "IF*_vars" %12s "ISIC_var" %10s "Covars"
di as txt "  {hline 80}"

* ============================================================
* SECTION 1 — LOAD, FILTER, SAVE TEMPFILE PER YEAR
* ============================================================
* Keeps:
*   - psid, year (identifiers)
*   - E* and IF* (all energy variables)
*   - isic5_raw (ISIC/KBLI 5-digit; detected from kki5d / disic5 / kkid)
*   - dkabup, dprovi (regional identifiers)
*   - ltlnou (total workers), vtlvcu (total output value, Rp000),
*     output (gross output), iinput (intermediate input)

local saved_list ""

foreach y of local years {

    local fpath "$sidata/si`y'.dta"

    capture confirm file "`fpath'"
    if _rc != 0 {
        di as txt "  `y'  [FILE NOT FOUND — skipped]"
        continue
    }

    use "`fpath'", clear

    foreach id in psid year {
        capture confirm variable `id'
        if _rc != 0 {
            di as txt "  `y'  [WARNING: `id' missing — skipped]"
            continue 2
        }
    }

    * ── Energy variables ────────────────────────────────────────────────────
    local n_e  = 0
    local n_if = 0
    local keep_vars "psid year"

    foreach v of varlist _all {
        local vl = lower("`v'")
        if regexm("`vl'", "^e[a-z]") {
            // Captures energy variables by BPS naming convention (esovcu, eplkhu, etc.)
            // Non-energy vars starting with 'e' (e.g. ekspor) are handled explicitly
            // in the economic covariates block below — any overlap is harmless (Stata
            // deduplicates keep lists).
            local n_e = `n_e' + 1
            local keep_vars "`keep_vars' `v'"
        }
        if regexm("`vl'", "^if[a-z]") {
            local n_if = `n_if' + 1
            local keep_vars "`keep_vars' `v'"
        }
    }

    * ── ISIC/KBLI detection — standardize to isic5_raw ─────────────────────
    * Priority: kki5d (most years) > disic5 (2011–14) > kkid (2005)
    * Actual results (from log): 2000–04 & 2006–10 = kki5d; 2005 = kkid; 2011–14 = disic5
    local isic_found  0
    local isic_source ""
    foreach isic_cand in kki5d disic5 kkid {
        cap confirm variable `isic_cand'
        if _rc == 0 & !`isic_found' {
            rename `isic_cand' isic5_raw
            local keep_vars   "`keep_vars' isic5_raw"
            local isic_found  1
            local isic_source "`isic_cand'"
        }
    }
    if !`isic_found' local isic_source "(none)"

    * ── Economic covariates (cap — not all present in all years) ────────────
    local n_cov 0
    foreach v in dkabup dprovi ltlnou vtlvcu output iinput ekspor {
        cap confirm variable `v'
        if _rc == 0 {
            local keep_vars "`keep_vars' `v'"
            local n_cov = `n_cov' + 1
        }
    }

    keep `keep_vars'

    di as txt "  " %-6s "`y'" %10.0fc _N %10.0fc `n_e' %10.0fc `n_if' %12s "`isic_source'" %10.0fc `n_cov'

    tempfile tmp`y'
    save `tmp`y''
    local saved_list "`saved_list' `y'"
}

di as txt "  {hline 65}"

* ============================================================
* SECTION 2 — APPEND ALL YEARS
* ============================================================

local saved_count : word count `saved_list'
if `saved_count' == 0 {
    di as error "ERROR: No SI files found. Check global sidata path."
    log close
    exit 1
}

local first_year : word 1 of `saved_list'
use `tmp`first_year'', clear

local rest : list saved_list - first_year
foreach y of local rest {
    append using `tmp`y'', force
}

* ============================================================
* SECTION 3 — FULL PANEL SUMMARY (before merge restriction)
* ============================================================

di as txt _n "=== FULL ANNUAL PANEL (pre-merge) ==="
di as txt "  Obs: " _N "   Vars: " c(k) "   Years: " "`saved_list'"
tab year

* Save full panel as reference (documents who is in the annual SI files)
compress
save "$output/si_panel_full_2000_2014.dta", replace
di as txt _n "Saved (full, pre-merge): $output/si_panel_full_2000_2014.dta"
di as txt "NOTE: This file is for documentation only. All cleaning do-files"
di as txt "      use si_panel_2000_2014.dta (the merged/restricted panel below)."

* ============================================================
* SECTION 4 — MERGE 1:1 WITH data8514_SI.dta (DECISION: matched firms only)
* ============================================================
*
* Decision (March 2026): Restrict to firms present in BOTH the annual SI files
*   AND the long panel (data8514_SI.dta). This ensures:
*   (a) ISIC codes come from data8514_SI.dta (already standardized by BPS)
*   (b) The emission dataset is directly linkable to trade status and wages
*       from data8514_SI.dta without losing any observations at the regression stage.
*
*   Unmatched annual SI firms (5–18% per year; see 03_psid_merge_check.do) are
*   dropped here. They have energy data but no trade status → cannot contribute
*   to the DiD regression.
*
* Variables pulled from data8514_SI.dta: ISIC code + all available covariates.
*   The ISIC variable name is detected automatically (checked in priority order).

global data8514 "$rawdata/data8514_SI.dta"

di as txt _n "=== SECTION 4: Merging 1:1 with data8514_SI.dta ==="
di as txt "  Key: psid + year.  Keeping only _merge==3 (matched firms)."
di as txt "  Unmatched annual-SI firms (5–18%/year) dropped — no trade status."

* ── ISIC variable in data8514_SI.dta ────────────────────────────────────────
* Confirmed via: describe using data8514_SI.dta (March 2026)
* Variable: disic5 (float) — 5-digit ISIC/KBLI code, present in all years
* (Previous detection loop was buggy: loaded only psid+year before checking,
*  so confirm variable always failed. Hardcoded now that variable is confirmed.)

tempfile panel8514
local isic8514 "disic5"
di as txt "  data8514_SI.dta ISIC variable: `isic8514' (confirmed)"

* Reload data8514_SI keeping only the variables we need for the base panel:
*   - psid year (merge keys)
*   - ISIC code (replaces annual-file isic5_raw)
*   - key economic covariates that are absent from annual SI files or cleaner here
if "`isic8514'" != "(none)" {
    use psid year `isic8514' using "$data8514", clear
    rename `isic8514' isic5_raw   // standardize to isic5_raw (same name, better source)
    label var isic5_raw "ISIC/KBLI 5-digit code — sourced from data8514_SI.dta"
}
else {
    use psid year using "$data8514", clear
}

sort psid year
save `panel8514'

* ── Load full annual panel and merge ────────────────────────────────────────
use "$output/si_panel_full_2000_2014.dta", clear

* Drop the annual-file ISIC (will be replaced from data8514_SI.dta if available)
if "`isic8514'" != "(none)" {
    cap drop isic5_raw
}

* 1:1 merge on psid year
merge 1:1 psid year using `panel8514', keepusing(isic5_raw) keep(3) nogen
* keep(3) = matched only; nogen = no _merge variable

di as txt _n "=== MERGED PANEL SUMMARY (matched firms only) ==="
di as txt "  Obs retained: " _N
di as txt "  Dropped: annual-SI-only firms (no trade status in data8514_SI)"
tab year

* ============================================================
* SECTION 5 — SAVE MERGED BASE FILE
* ============================================================

compress
save "$output/si_panel_2000_2014.dta", replace

di as txt _n "Saved (matched panel): $output/si_panel_2000_2014.dta"
di as txt "This is the base file for all downstream do-files (02 onwards)."
di as txt "ISIC source: " "`isic8514'" " from data8514_SI.dta."
if "`isic8514'" == "(none)" di as error "WARNING: ISIC from annual files (no match found in data8514_SI.dta)"

log close
