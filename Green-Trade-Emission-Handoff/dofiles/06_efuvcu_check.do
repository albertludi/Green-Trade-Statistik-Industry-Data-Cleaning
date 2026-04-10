* ============================================================
* Script: 06_efuvcu_check.do
* Purpose: Confirm whether efuvcu is a reliable aggregate total
*          using si_panel_2000_2014.dta (annual SI files panel).
*          Compares efuvcu to encvcu (other fuels) and to the
*          sum of individual fuel expenditure components.
*          Produces ratio table and firm-level scatter for 2007.
* Input:   output/si_panel_2000_2014.dta
* Output:  output/figures/fig_efuvcu_check.png
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

cap mkdir "$figures"
log using "$logs/06_efuvcu_check.log", replace text

use "$output/si_panel_2000_2014.dta", clear

* ── Confirm key variables exist ─────────────────────────────────────────────
di as txt "=== efuvcu DECOMPOSITION CHECK ==="
di as txt "Source: si_panel_2000_2014.dta  (N = " _N ")"

foreach v in efuvcu esovcu epevcu eoivcu eclvcu egavcu elpvcu encvcu {
    cap confirm variable `v'
    if _rc == 0 di as txt "  FOUND: `v'"
    else        di as txt "  MISSING: `v'"
}

* ── Build sum of individual fuel expenditure components ─────────────────────
* esovcu = diesel, epevcu = petrol, eoivcu = kerosene, eclvcu = coal,
* egavcu = city gas, elpvcu = LPG, encvcu = other fuels
* Use rowtotal approach: treat missing component as 0 only when others present

egen fuel_sum = rowtotal(esovcu epevcu eoivcu eclvcu egavcu elpvcu encvcu), missing
label var fuel_sum "Sum of individual fuel components (Rp000)"

* ── Diagnostic A: Year-level means ─────────────────────────────────────────
* Also save to tempfile for Panel A line chart
di as txt _n "=== DIAGNOSTIC A: Year means (Rp000) ==="
di as txt "  " %-6s "Year" %15s "mean(efuvcu)" %15s "mean(comp.sum)" %12s "Ratio" %10s "N_equal"
di as txt "  {hline 65}"

postfile yr_handle int yr float m_efu m_sum ratio using `"$output/tables/__efuvcu_ratio_tmp.dta"', replace

forval y = 2000/2014 {
    quietly sum efuvcu   if year == `y' & !missing(efuvcu)
    local m_efu = r(mean)
    quietly sum fuel_sum if year == `y' & !missing(fuel_sum)
    local m_sum = r(mean)
    quietly count if year == `y' & !missing(efuvcu) & !missing(fuel_sum) ///
                     & abs(efuvcu - fuel_sum) <= 1
    local n_eq = r(N)

    if missing(`m_sum') | `m_sum' == 0 {
        di as txt "  " %-6s "`y'" %15.0fc `m_efu' %15s "N/A" %12s "N/A" %10.0fc `n_eq'
        post yr_handle (`y') (`m_efu') (.) (.)
    }
    else {
        local ratio = `m_efu' / `m_sum'
        di as txt "  " %-6s "`y'" %15.0fc `m_efu' %15.0fc `m_sum' %12.3f `ratio' %10.0fc `n_eq'
        post yr_handle (`y') (`m_efu') (`m_sum') (`ratio')
    }
}

postclose yr_handle

* ── Panel A: by-year ratio line chart ───────────────────────────────────────
* Shows mean(efuvcu) / mean(component sum) for each year 2000–2014.
* Ratio > 1 in every year confirms efuvcu is independently filled (not computed).

preserve
    use `"$output/tables/__efuvcu_ratio_tmp.dta"', clear

    twoway ///
        (connected ratio yr, lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medthick)) ///
        (function y=1, range(2000 2014) lcolor(red) lpattern(dash) lwidth(thin)) ///
        , ///
        xlabel(2000(1)2014, angle(45) labsize(small)) ///
        xtitle("Survey year", size(small)) ///
        ytitle("mean(efuvcu) / mean(component sum)", size(small)) ///
        title("(A) efuvcu excess ratio by year", size(medsmall)) ///
        subtitle("Ratio > 1: reported total exceeds sum of sub-components", size(small)) ///
        yline(1, lcolor(red) lpattern(dash)) ///
        legend(off) ///
        note("Red dashed line = 1.0 (efuvcu equals component sum). Values above line → efuvcu independently filled." ///
             "Source: si_panel_2000_2014.dta | do-file: 06_efuvcu_check.do") ///
        scheme(s1color) name(g_ratio, replace)
restore

* ── Diagnostic B: Firm-level scatter for 2007 ───────────────────────────────
di as txt _n "=== DIAGNOSTIC B: Scatter efuvcu vs component sum — 2007 ==="

preserve
keep if year == 2007
keep efuvcu fuel_sum
drop if missing(efuvcu) | missing(fuel_sum)
count
if r(N) < 10 {
    di as txt "  Too few obs for scatter in 2007."
}
else {
    replace efuvcu   = efuvcu   / 1000
    replace fuel_sum = fuel_sum / 1000

    quietly sum efuvcu
    local xmax = r(max)
    quietly sum fuel_sum
    local ymax = r(max)
    local axmax = max(`xmax', `ymax')

    set scheme s1color
    twoway ///
        (scatter efuvcu fuel_sum, mcolor(navy%40) msize(tiny)) ///
        (function y=x, range(0 `axmax') lcolor(red) lpattern(dash) lwidth(thin)) ///
        , ///
        title("(B) efuvcu vs. component sum — 2007 (firm level)", size(medsmall)) ///
        subtitle("Points above 45° line → efuvcu > arithmetic sum", size(small)) ///
        xtitle("Sum of components (Rp million)", size(small)) ///
        ytitle("efuvcu (Rp million)", size(small)) ///
        note("Source: si_panel_2000_2014.dta", size(vsmall)) ///
        legend(order(1 "Firms" 2 "45° line") size(small)) ///
        graphregion(color(white)) ///
        name(g_scatter, replace)
}
restore

* ── Combine and export ───────────────────────────────────────────────────────
capture confirm name g_ratio
if _rc == 0 {
    capture confirm name g_scatter
    if _rc == 0 {
        graph combine g_ratio g_scatter, ///
            cols(2) ///
            title("efuvcu vs. Fuel Component Sum: By Year and Firm Level", size(medium)) ///
            xsize(14) ysize(6)
        graph export "$figures/fig_efuvcu_check.png", replace width(2400)
        di as txt "  Combined figure saved: $figures/fig_efuvcu_check.png"
    }
    else {
        * Scatter not available — export ratio chart alone
        graph use g_ratio
        graph export "$figures/fig_efuvcu_check.png", replace width(1600)
        di as txt "  Ratio-only figure saved (2007 scatter had <10 obs)."
    }
}

* Clean up temp file
cap erase `"$output/tables/__efuvcu_ratio_tmp.dta"'

di as txt _n "=== END ==="
log close
