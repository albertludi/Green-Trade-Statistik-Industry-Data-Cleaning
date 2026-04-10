* ============================================================
* Script: 19_fig_subsidy_context.do
* Purpose: Indonesian energy subsidy expenditure (1998–2013)
*          overlaid with firm-level median unit energy prices
*          from the SI panel (2000–2013).
*
* Left axis  — Government subsidy expenditure (Dartanto 2013,
*              billion USD, constant 2005 prices).
* Right axis — Median unit price paid by SI-panel firms:
*              Diesel (Rp000/litre) and PLN electricity (Rp000/kWh).
*
* Key events annotated:
*   Oct 2005 — IDO raised to full international market price
*   May 2008 — Large industrial electricity → full cost recovery
*
* Input:   output/si_energy_emissions.dta
* Output:  output/figures/fig_subsidy_context.png
* Author:  Albert Ludi
* Date:    2026-04-09
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
log using "$logs/19_fig_subsidy_context.log", replace text

di as txt "=== 19_fig_subsidy_context.do: Subsidy context figure ==="

* ── Step 1: Build subsidy dataset (Dartanto 2013, Table 3) ───────────────────
* Billion USD, constant 2005 prices
input float year float fuel float elec
1998  5.6  0.4
1999  8.5  0.9
2000  9.5  0.6
2001  9.4  0.0
2002  4.3  0.5
2003  4.1  0.5
2004  8.6  0.3
2005  9.9  0.4
2006  6.2  2.9
2007  7.6  3.0
2008 10.8  6.5
2009  3.1  3.4
2010  6.2  4.4
2011 12.3  6.7
2012  9.1  4.3
2013 12.1  5.1
end

label var year "Year"
label var fuel "Fuel subsidies (billion USD, 2005 prices)"
label var elec "Electricity subsidies (billion USD, 2005 prices)"

tempfile subsidy
save `subsidy'

* ── Step 2: Compute firm median unit prices from SI panel ────────────────────
use "$output/si_energy_emissions.dta", clear

gen double p_diesel = fuel_diesel_rp / fuel_diesel_ltr ///
    if fuel_diesel_ltr > 0 & fuel_diesel_rp > 0 & !missing(fuel_diesel_ltr, fuel_diesel_rp)

gen double p_elec = elec_pln_rp / elec_pln_kwh ///
    if elec_pln_kwh > 0 & elec_pln_rp > 0 & !missing(elec_pln_kwh, elec_pln_rp)

* Winsorise p1–p99
foreach v in p_diesel p_elec {
    quietly su `v', detail
    replace `v' = r(p1)  if `v' < r(p1)  & !missing(`v')
    replace `v' = r(p99) if `v' > r(p99) & !missing(`v')
}

* Year-level medians
collapse (median) p_diesel p_elec (count) n_diesel = p_diesel n_elec = p_elec, by(year)
keep if inrange(year, 1998, 2013)

label var p_diesel "Diesel — firm median (Rp000/litre)"
label var p_elec   "Electricity — firm median (Rp000/kWh)"

* ── Step 3: Merge subsidy + firm prices ──────────────────────────────────────
merge 1:1 year using `subsidy', nogen

sort year

* ── Step 4: Figure — dual axis ───────────────────────────────────────────────
* Left  axis (yaxis 1): fuel and electricity subsidy expenditure
* Right axis (yaxis 2): firm unit prices

* Shading band: 2005–2008 (IDO desubsidisation + global oil surge)
* Approximated with rarea using invisible fill

gen shade_lo = 0
gen shade_hi = 15
gen in_band  = inrange(year, 2005, 2008)

twoway ///
    (rarea shade_hi shade_lo year if in_band, ///
        fcolor("230 126 34%12") lwidth(none) yaxis(1)) ///
    (line fuel year, ///
        lcolor("192 57 43") lwidth(medthick) yaxis(1)) ///
    (scatter fuel year, ///
        mcolor("192 57 43") msymbol(circle) msize(medium) yaxis(1)) ///
    (line elec year, ///
        lcolor("36 113 163") lwidth(medthick) lpattern(dash) yaxis(1)) ///
    (scatter elec year, ///
        mcolor("36 113 163") msymbol(square) msize(medium) yaxis(1)) ///
    (line p_diesel year if !missing(p_diesel), ///
        lcolor("192 57 43%70") lwidth(medium) lpattern(shortdash) yaxis(2)) ///
    (scatter p_diesel year if !missing(p_diesel), ///
        mcolor("192 57 43%70") msymbol(triangle) msize(medsmall) yaxis(2)) ///
    (line p_elec year if !missing(p_elec), ///
        lcolor("36 113 163%70") lwidth(medium) lpattern(shortdash) yaxis(2)) ///
    (scatter p_elec year if !missing(p_elec), ///
        mcolor("36 113 163%70") msymbol(diamond) msize(medsmall) yaxis(2)), ///
    ///
    ylabel(0(2)14, axis(1) labsize(small) angle(0))             ///
    ytitle("Billion USD (constant 2005 prices)", axis(1) size(small)) ///
    ylabel(0(2)10, axis(2) labsize(small) angle(0))             ///
    ytitle("Firm median unit price (Rp000/unit)", axis(2) size(small)) ///
    ///
    xlabel(1998(1)2013, angle(45) labsize(small))               ///
    xtitle("Year", size(small))                                  ///
    ///
    xline(2005, lcolor("192 57 43%40") lwidth(thick))           ///
    xline(2008, lcolor("36 113 163%40") lwidth(thick))          ///
    ///
    legend(order(2 "Fuel subsidies (left)"                      ///
                 4 "Electricity subsidies (left)"                ///
                 7 "Diesel price — firm median (right)"          ///
                 9 "Electricity price — firm median (right)")    ///
           cols(1) size(small) pos(11) ring(0) region(lwidth(none))) ///
    ///
    title("Indonesian Energy Subsidy Expenditure and"            ///
          "Firm-Level Unit Energy Prices, 1998–2013",            ///
          size(medsmall) color(black))                           ///
    note("Left axis: Dartanto (2013) Table 3 — constant 2005 USD."      ///
         "Fuel = gasoline, kerosene, ADO, IDO, fuel oil; IDO removed Oct 2005." ///
         "Right axis: SI panel (si_energy_emissions.dta) — median unit price"   ///
         "paid by firms; expenditure ÷ quantity, p1–p99 winsorised."     ///
         "Vertical lines: Oct 2005 (IDO removal) and May 2008 (elec reform).", ///
         size(vsmall))                                           ///
    scheme(s1color) xsize(13) ysize(7)

graph export "$figures/fig_subsidy_context.png", replace width(2400)
di as txt "Saved: $figures/fig_subsidy_context.png"

di as txt _n "======================================================"
di as txt " 19_fig_subsidy_context.do — done: " c(current_date) " " c(current_time)
di as txt "======================================================"

log close
