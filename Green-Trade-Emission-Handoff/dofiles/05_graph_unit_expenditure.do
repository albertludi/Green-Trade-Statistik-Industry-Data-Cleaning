* ============================================================
* Script: 05_graph_unit_expenditure.do
* Purpose: Line charts for key fuel variables showing
*          (1) median physical quantity vs mean expenditure by year
*              for coal — unit change is visible as a dip in (1) but
*              not in (2), confirming the Ton→Kg problem in 2004–2005
*          (2) N_pos coverage by year for variables with structural
*              gaps — shows which absences are survey-design gaps
* Input:   output/si_panel_2000_2014.dta
* Output:  output/figures/fig01_coal_unit_expenditure.png
*          output/figures/fig02_fuel_coverage.png
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
global figures "$handoff/output/figures"

* Create figures directory if needed
capture mkdir "$figures"

log using "$logs/05_graph_unit_expenditure.log", replace text

use "$output/si_panel_2000_2014.dta", clear

* ============================================================
* FIGURE 1 — COAL: Median physical unit vs mean expenditure
* ============================================================
* The unit change (Ton in 2004–2005) will appear as a sharp dip
* in the physical-quantity panel but NOT in the expenditure panel
* (since firms spent more Rp on coal in those years as coal use expanded).
* The contrast between the two panels is the diagnostic.

di as txt _n "=== FIGURE 1: Coal unit vs expenditure ==="

* Panel A: median physical quantity (eclkgu, positive obs only)
preserve
    keep if !missing(eclkgu) & eclkgu > 0
    collapse (median) med_eclkgu = eclkgu ///
             (count)  n_eclkgu   = eclkgu, by(year)
    tempfile coal_unit
    save `coal_unit'
restore

* Panel B: mean expenditure (eclvcu, if it exists)
local has_eclvcu = 0
cap confirm variable eclvcu
if _rc == 0 {
    local has_eclvcu = 1
    preserve
        keep if !missing(eclvcu) & eclvcu > 0
        collapse (mean) mean_eclvcu = eclvcu ///
                 (count) n_eclvcu   = eclvcu, by(year)
        tempfile coal_exp
        save `coal_exp'
    restore
}

* ── Draw Panel A ──
use `coal_unit', clear

twoway ///
    (connected med_eclkgu year, ///
        lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medthick)), ///
    xlabel(2000(1)2014, angle(45) labsize(small)) ///
    xtitle("Survey year") ///
    ytitle("Median quantity (reported units)") ///
    title("(A) Coal: physical quantity — eclkgu", size(medsmall)) ///
    note("Positive obs only. Red bands: questionnaire-confirmed Ton years (2004–2005)." ///
         "Dip confirms Ton reporting: median 97,700 (2003) → 2,175 (2004) → 3,087 (2006).") ///
    xline(3.5 4 4.5 5 5.5, lcolor(red%20) lwidth(vthick)) ///
    yline(0, lcolor(gs12)) ///
    scheme(s1color) name(g_unit, replace)

* ── Draw Panel B (expenditure) if available ──
if `has_eclvcu' == 1 {
    use `coal_exp', clear

    twoway ///
        (connected mean_eclvcu year, ///
            lcolor(maroon) mcolor(maroon) msymbol(circle) lwidth(medthick)), ///
        xlabel(2000(1)2014, angle(45) labsize(small)) ///
        xtitle("Survey year") ///
        ytitle("Mean expenditure (Rp 000)") ///
        title("(B) Coal: expenditure — eclvcu", size(medsmall)) ///
        note("Mean expenditure (Rp 000) among positive reporters." ///
             "No dip in 2004–2005 → consistent with rising coal use; confirms unit problem.") ///
        xline(3.5 4 4.5 5 5.5, lcolor(red%20) lwidth(vthick)) ///
        yline(0, lcolor(gs12)) ///
        scheme(s1color) name(g_exp, replace)

    graph combine g_unit g_exp, ///
        cols(1) ///
        title("Coal: Raw Physical Unit vs. Expenditure Trend", size(medium)) ///
        note("Source: si_panel_2000_2014.dta | do-file: 05_graph_unit_expenditure.do") ///
        xsize(9) ysize(11)
    graph export "$figures/fig01_coal_unit_expenditure.png", replace width(2400)
    di as txt "Saved: $figures/fig01_coal_unit_expenditure.png (combined)"
}
else {
    * No eclvcu — export unit panel alone
    use `coal_unit', clear
    twoway ///
        (connected med_eclkgu year, ///
            lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medthick)), ///
        xlabel(2000(1)2014, angle(45) labsize(small)) ///
        xtitle("Survey year") ///
        ytitle("Median quantity (reported units)") ///
        title("Coal: Physical Quantity by Year — eclkgu", size(medium)) ///
        note("Positive obs only. Red bands: Ton years 2004–2005." ///
             "Source: si_panel_2000_2014.dta") ///
        xline(3.5 4 4.5 5 5.5, lcolor(red%20) lwidth(vthick)) ///
        scheme(s1color)
    graph export "$figures/fig01_coal_unit_expenditure.png", replace width(2400)
    di as txt "Saved: $figures/fig01_coal_unit_expenditure.png (unit only — eclvcu not found)"
}

* ============================================================
* FIGURE 2 — COVERAGE: N positive obs by year per variable
* ============================================================
* Variables selected to show the structural-gap story:
*   - esoliu  : diesel liters    (reference — no gap)
*   - elpkhu  : PLN elec KwH     (reference — no gap)
*   - eclkgu  : coal Kg          (gap 2001–2002)
*   - egam3u  : city gas m3      (gap 2001–2005)
*   - elpkgu  : LPG Kg           (gap 2001–2005)
*   - ecbkgu  : coal briquettes  (only 2012–2014)
*   - egom3u  : gas from others  (only 2012–2014)

di as txt _n "=== FIGURE 2: N_pos coverage by year ==="

use "$output/si_panel_2000_2014.dta", clear

local gap_vars "esoliu eplkhu eclkgu egam3u elpkgu ecbkgu egom3u"

* Build a wide dataset: one row per year, one column per variable
tempfile cov_wide
quietly {
    * Start with year skeleton
    preserve
        keep year
        duplicates drop year, force
        sort year
        save `cov_wide'
    restore

    foreach v of local gap_vars {
        cap confirm variable `v'
        if _rc != 0 continue

        preserve
            gen byte pos = (`v' > 0 & !missing(`v'))
            collapse (sum) n_`v' = pos, by(year)
            merge 1:1 year using `cov_wide', nogen
            sort year
            save `cov_wide', replace
        restore
    }
}

use `cov_wide', clear

* Replace missing with 0 (structural gap = reported zero)
foreach v of local gap_vars {
    cap confirm variable n_`v'
    if _rc == 0 replace n_`v' = 0 if missing(n_`v')
}

* Label variables for legend
label variable n_esoliu "Diesel (esoliu)"
label variable n_eplkhu "PLN elec (eplkhu)"
cap label variable n_eclkgu "Coal (eclkgu)"
cap label variable n_egam3u "City gas (egam3u)"
cap label variable n_elpkgu "LPG (elpkgu)"
cap label variable n_ecbkgu "Coal briquettes (ecbkgu)"
cap label variable n_egom3u "Gas-other (egom3u)"

* ── Build twoway command dynamically ──
* Colors: diesel=navy, PLN=dkgreen, coal=maroon, gas=orange, lpg=purple, briq=sienna, gother=teal

twoway ///
    (connected n_esoliu year,  lcolor(navy)    mcolor(navy)    msymbol(circle)   lwidth(medthick) lpattern(solid)) ///
    (connected n_eplkhu year,  lcolor(dkgreen) mcolor(dkgreen) msymbol(square)   lwidth(medthick) lpattern(solid)) ///
    (connected n_eclkgu year,  lcolor(maroon)  mcolor(maroon)  msymbol(diamond)  lwidth(medium)   lpattern(dash)) ///
    (connected n_egam3u year,  lcolor(orange)  mcolor(orange)  msymbol(triangle) lwidth(medium)   lpattern(dash)) ///
    (connected n_elpkgu year,  lcolor(purple)  mcolor(purple)  msymbol(plus)     lwidth(medium)   lpattern(dash)) ///
    (connected n_ecbkgu year,  lcolor(sienna)  mcolor(sienna)  msymbol(x)        lwidth(thin)     lpattern(shortdash)) ///
    (connected n_egom3u year,  lcolor(teal)    mcolor(teal)    msymbol(smcircle) lwidth(thin)     lpattern(shortdash)), ///
    xlabel(2000(1)2014, angle(45) labsize(small)) ///
    ylabel(0(5000)25000, labsize(small) angle(0)) ///
    yscale(titlegap(8)) ///
    xtitle("Survey year") ///
    ytitle("Number of firms with positive values", size(small)) ///
    title("Fuel Variable Coverage by Year", size(medium)) ///
    subtitle("Solid lines: continuously collected; dashed lines: structural gaps") ///
    legend(order(1 "Diesel (esoliu)" 2 "PLN elec (eplkhu)" ///
                 3 "Coal (eclkgu)" 4 "City gas (egam3u)" ///
                 5 "LPG (elpkgu)" 6 "Coal briquettes (ecbkgu)" ///
                 7 "Gas-other (egom3u)") ///
           cols(2) size(small)) ///
    note("N_pos = firms reporting positive values; zero = structural gap or no collection." ///
         "Source: si_panel_2000_2014.dta | do-file: 05_graph_unit_expenditure.do") ///
    plotregion(margin(l=5)) ///
    scheme(s1color) ///
    xsize(11) ysize(7)

graph export "$figures/fig02_fuel_coverage.png", replace width(2400)
di as txt "Saved: $figures/fig02_fuel_coverage.png"

* ============================================================
* SUMMARY
* ============================================================
di as txt _n "=== OUTPUT SUMMARY ==="
di as txt "  $figures/fig01_coal_unit_expenditure.png"
di as txt "  $figures/fig02_fuel_coverage.png"

log close
