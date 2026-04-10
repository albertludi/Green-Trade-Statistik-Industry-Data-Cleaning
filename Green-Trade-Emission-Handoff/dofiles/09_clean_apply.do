* ============================================================
* Script: 09_clean_apply.do
* Purpose: Apply the cleaning rule from §6 of data_industry_emission.qmd
*          to produce the primary analysis-ready cleaned dataset.
*
*          Cleaning rule (one filter):
*            Drop flag_any_sev == 1
*                      Any severe flag across D1/D2/D3 dimensions
*                      (11,420 observations)
*
*          Rationale (§6 of QMD):
*            - Severe thresholds (k=5 IQR; |Δlog|>log(50)) are conservative
*              and very unlikely to flag genuine firm behaviour
*            - Moderate flags (12.5% of sample) include real variation in
*              energy-intensive industries — not deleted
*            - D4 (generator > total) removed: inconsistencies are common in
*              survey data and do not warrant unconditional deletion
*            - Dropping the full Armundito-Kaneko balanced panel (4.4% retained)
*              would eliminate most treatment events for the event study design
*
*          Reference:
*            Armundito & Kaneko (2014, IDEC DP2-14-9): mode×500 rule
*            Amiti & Konings (2007, AER): 1st/99th pct growth trim
*            Griliches & Hausman (1986, JoE): FE amplifies measurement error
*
* Input:   output/si_energy_flagged.dta
* Output:  output/si_energy_harmonized_cleaned.dta
*
* Author:  Albert Ludi
* Date:    2026-03-20
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

log using "$logs/09_clean_apply.log", replace text

use "$output/si_energy_flagged.dta", clear
di as txt "Obs loaded (si_energy_flagged): " _N

* ============================================================
* SECTION 1 — VERIFY FLAG VARIABLES PRESENT
* ============================================================
di as txt _n "=== Verifying flag variables ==="

foreach v in flag_any_sev flag_any_mod flag_n_dims {
    cap confirm variable `v'
    if _rc != 0 {
        di as error "ERROR: `v' not found — re-run 08_outlier_flags.do first."
        exit 1
    }
}
di as txt "  All composite flag variables confirmed present."

* ============================================================
* SECTION 2 — DOCUMENT PRE-CLEAN COUNTS
* ============================================================
di as txt _n "=== Pre-clean sample summary ==="

quietly count
di as txt "  Full sample:               " r(N)
quietly count if flag_any_sev == 1
di as txt "  To be dropped (severe):    " r(N)

* ============================================================
* SECTION 3 — APPLY CLEANING RULE
* ============================================================
di as txt _n "=== Applying cleaning rule ==="

drop if flag_any_sev == 1
di as txt "  After dropping D1/D2/D3 severe: " _N " obs remain"

* ============================================================
* SECTION 4 — POST-CLEAN DIAGNOSTICS
* ============================================================
di as txt _n "=== Post-clean diagnostics ==="

di as txt "  Final cleaned N: " _N
di as txt "  Retention rate: " %5.2f `=100*_N/326382' "%  (matched panel N = 326,382)"
di as txt ""

* Year distribution
di as txt "  --- Obs per year (post-clean) ---"
tab year

* Remaining moderate flags (present but not dropped)
quietly count if flag_any_mod == 1
di as txt "  Moderate flags retained (not cleaned): " r(N) " obs (" %5.2f `=100*r(N)/_N' "%)"
di as txt "  These are available for sensitivity analysis via flag_any_mod variable."

* flag_n_dims distribution post-clean
di as txt _n "  --- flag_n_dims distribution (post-clean) ---"
tab flag_n_dims

* ============================================================
* SECTION 5 — COMPARISON WITH LITERATURE BENCHMARKS
* ============================================================
di as txt _n "=== Comparison with literature benchmarks ==="
di as txt "  Armundito & Kaneko (2014) balanced panel: ~19,926 obs (4.4% of raw)"
di as txt "  Amiti & Konings (2007) growth trim:       ~167,000 obs (est. ~98% of their sample)"
di as txt "  Our cleaned sample:                       " _N " obs (" %5.2f `=100*_N/326382' "% of matched panel)"

* ============================================================
* SECTION 6 — SAVE
* ============================================================
save "$output/si_energy_harmonized_cleaned.dta", replace
di as txt _n "Saved: $output/si_energy_harmonized_cleaned.dta"
di as txt "  Obs: " _N
quietly ds
di as txt "  Vars: `: word count `r(varlist)''"

log close
