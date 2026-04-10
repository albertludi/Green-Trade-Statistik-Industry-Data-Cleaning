* ============================================================
* Script: 09b_clean_diagnostics.do
* Purpose: Visualizations for §6 Data Cleaning Decision:
*
*   Figure 8 — Before/After kernel density (log scale)
*              Panel A: fuel_diesel_ltr
*              Panel B: elec_pln_kwh
*              Shows tail-trimming effect of severe-flag cleaning
*
*   Figure 9 — Flag distribution by year
*              Line chart: N severely flagged obs by year
*              Shows whether flagging is uniform or year-clustered
*
*   Figure 10 — Literature retention comparison
*              Bar chart: Armundito-Kaneko vs Amiti-Konings vs ours
*
* Input:   output/si_energy_flagged.dta
* Output:  output/figures/fig08_kde_before_after.png
*          output/figures/fig09_flags_by_year.png
*          output/figures/fig10_literature_comparison.png
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
global figures "$handoff/output/figures"

capture mkdir "$figures"
log using "$logs/09b_clean_diagnostics.log", replace text

use "$output/si_energy_flagged.dta", clear
di as txt "Obs loaded: " _N

* ============================================================
* FIGURE 8 — BEFORE / AFTER KERNEL DENSITY
* ============================================================
* Compare log-distribution of two key variables before and after
* applying the severe-flag cleaning rule.
* "Before" = all positive reporters; "After" = positive + not severely flagged.

di as txt _n "=== FIGURE 8: Before/After KDE ==="

* ── Panel A: fuel_diesel_ltr ──────────────────────────────────────────────
preserve
    keep if fuel_diesel_ltr > 0 & !missing(fuel_diesel_ltr)
    gen double log_diesel = log(fuel_diesel_ltr)

    * Before: all positive obs
    kdensity log_diesel, generate(x_d_bef d_bef) nograph n(300)

    * After: positive + not severely flagged
    kdensity log_diesel if flag_any_sev == 0, ///
        generate(x_d_aft d_aft) nograph n(300)

    twoway ///
        (line d_bef x_d_bef, lcolor(navy%60)  lwidth(medium) lpattern(solid)) ///
        (line d_aft x_d_aft, lcolor(maroon)   lwidth(medthick) lpattern(solid)), ///
        legend(order(1 "Before cleaning (N = full)" 2 "After cleaning (N = severe-flag dropped)") ///
               size(small) position(1) ring(0)) ///
        xtitle("log(Diesel liters)") ///
        ytitle("Density") ///
        title("(A) Diesel — fuel_diesel_ltr", size(medsmall)) ///
        note("Kernel density of log positive values. Cleaning drops flag_any_sev=1." ///
             "Tails trimmed; core distribution unchanged.") ///
        scheme(s1color) name(g_kde_a, replace)
restore

* ── Panel B: elec_pln_kwh ─────────────────────────────────────────────────
preserve
    keep if elec_pln_kwh > 0 & !missing(elec_pln_kwh)
    gen double log_elec = log(elec_pln_kwh)

    kdensity log_elec, generate(x_e_bef e_bef) nograph n(300)

    kdensity log_elec if flag_any_sev == 0, ///
        generate(x_e_aft e_aft) nograph n(300)

    twoway ///
        (line e_bef x_e_bef, lcolor(navy%60)  lwidth(medium) lpattern(solid)) ///
        (line e_aft x_e_aft, lcolor(maroon)   lwidth(medthick) lpattern(solid)), ///
        legend(order(1 "Before cleaning" 2 "After cleaning") ///
               size(small) position(1) ring(0)) ///
        xtitle("log(PLN electricity kWh)") ///
        ytitle("Density") ///
        title("(B) PLN electricity — elec_pln_kwh", size(medsmall)) ///
        note("elec_pln_kwh had the highest severe D2 flag count (6,829 obs)." ///
             "Cleaning removes the right-tail spikes without affecting the main distribution.") ///
        scheme(s1color) name(g_kde_b, replace)
restore

graph combine g_kde_a g_kde_b, ///
    rows(1) ///
    title("Figure 8. Distribution Before and After Severe-Flag Cleaning", size(medsmall)) ///
    note("Severe flags: D1 k=5 IQR outlier; D2 |Δlog|>log(50); D3 intensity k=5; D4 gen>total." ///
         "Source: si_energy_flagged.dta | Do-file: 09b_clean_diagnostics.do") ///
    xsize(14) ysize(6)

graph export "$figures/fig08_kde_before_after.png", replace width(2800)
di as txt "Saved: $figures/fig08_kde_before_after.png"

* ============================================================
* FIGURE 9 — FLAG DISTRIBUTION BY YEAR
* ============================================================
di as txt _n "=== FIGURE 9: Flag distribution by year ==="

preserve
    collapse ///
        (sum)   n_sev   = flag_any_sev  ///
                n_mod   = flag_any_mod  ///
        (count) n_obs   = psid, by(year)

    gen pct_sev  = 100 * n_sev  / n_obs
    gen pct_mod  = 100 * n_mod  / n_obs

    label variable pct_sev  "% severe flagged"
    label variable pct_mod  "% moderate flagged"
    label variable n_obs    "Total firm-years"

    twoway ///
        (bar  n_obs  year, barwidth(0.7) fcolor(gs12) lcolor(gs10)) ///
        (connected pct_mod year, ///
            lcolor(orange) mcolor(orange) msymbol(circle) lwidth(medium) ///
            yaxis(2)) ///
        (connected pct_sev year, ///
            lcolor(maroon) mcolor(maroon) msymbol(diamond) lwidth(medthick) ///
            yaxis(2)), ///
        xlabel(2000(1)2014, angle(45) labsize(small)) ///
        xtitle("Survey year") ///
        ytitle("Firm-years (N)", axis(1)) ///
        ytitle("% flagged", axis(2)) ///
        legend(order(2 "Moderate flag %" 3 "Severe flag %") ///
               size(small) position(11) ring(0)) ///
        title("Figure 9. Data-Quality Flag Rates by Year", size(medsmall)) ///
        note("Bars = total firm-years (left axis). Lines = % flagged (right axis)." ///
             "2006 spike in N reflects the census expansion wave (SE06)." ///
             "Source: si_energy_flagged.dta | Do-file: 09b_clean_diagnostics.do") ///
        scheme(s1color) ///
        xsize(12) ysize(6)

    graph export "$figures/fig09_flags_by_year.png", replace width(2400)
    di as txt "Saved: $figures/fig09_flags_by_year.png"
restore

* ============================================================
* FIGURE 10 — LITERATURE RETENTION COMPARISON
* ============================================================
di as txt _n "=== FIGURE 10: Literature retention comparison ==="

* ── Compute retention counts from the loaded dataset ──────────────────────────
use "$output/si_energy_flagged.dta", clear

quietly count
local n_full = r(N)

quietly count if flag_any_sev == 0
local n_sev_clean = r(N)

quietly count if flag_any_mod == 0
local n_mod_clean = r(N)

local pct_sev_clean = 100 * `n_sev_clean' / `n_full'
local pct_mod_clean = 100 * `n_mod_clean' / `n_full'

di as txt "Full sample N          : `n_full'"
di as txt "Severe-clean N         : `n_sev_clean' (`pct_sev_clean'%)"
di as txt "Moderate-clean N       : `n_mod_clean' (`pct_mod_clean'%)"

* ── Build comparison dataset ──────────────────────────────────────────────────
clear
input str40 label float pct_retained float n_obs
"Armundito-Kaneko (2014)"       4.38    19926
"Amiti-Konings (2007) est."    97.80  167000
"Our full sample"             100.00  `n_full'
"Our cleaned sample (§6)"   `pct_sev_clean'  `n_sev_clean'
"Our moderate clean"         `pct_mod_clean'  `n_mod_clean'
end

* Encode label as numeric for bar chart
encode label, gen(study)

* Color: highlight our severe-cleaned sample
gen byte highlight = (label == "Our cleaned sample (§6)")

twoway ///
    (bar pct_retained study if highlight == 0, ///
        barwidth(0.6) fcolor(gs11) lcolor(gs9)) ///
    (bar pct_retained study if highlight == 1, ///
        barwidth(0.6) fcolor(maroon) lcolor(maroon%80)), ///
    xlabel(1(1)5, valuelabel angle(30) labsize(small)) ///
    ytitle("% of raw observations retained") ///
    ylabel(0(10)100, angle(0)) ///
    yline(100, lcolor(gs12) lpattern(dash)) ///
    legend(off) ///
    title("Figure 10. Sample Retention: Literature Comparison", size(medsmall)) ///
    note("Armundito-Kaneko: balanced panel, mode×500 intensity rule, drop problem years." ///
         "Amiti-Konings: 1st/99th pct growth trim (estimated)." ///
         "Our cleaned sample: drop flag_any_sev=1 (highlighted). N computed from si_energy_flagged.dta." ///
         "Source: do-file 09b_clean_diagnostics.do") ///
    scheme(s1color) ///
    xsize(11) ysize(7)

graph export "$figures/fig10_literature_comparison.png", replace width(2200)
di as txt "Saved: $figures/fig10_literature_comparison.png"

* ============================================================
* SUMMARY
* ============================================================
di as txt _n "=== OUTPUT SUMMARY ==="
di as txt "  $figures/fig08_kde_before_after.png"
di as txt "  $figures/fig09_flags_by_year.png"
di as txt "  $figures/fig10_literature_comparison.png"

log close
