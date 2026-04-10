* ============================================================
* 17_ei_figures.do
* Energy intensity figures for Appendix C of data_industry_emission.qmd
*
* Figures produced (replaces Python scripts in scripts/fig_ei_*.py):
*   fig_ei_composition.png      — EI-1: fuel vs electricity share by year
*   fig_ei_trend_comparison.png — EI-2: trend comparison indexed to 2000=0
*   fig_ei_components.png       — EI-3: component decomposition indexed to 2000=0
*   fig_ei_industry_gj.png      — EI-4: GJ intensity by ISIC (boxplot + spaghetti)
*   fig_ei_industry_monetary.png — EI-5: monetary intensity by ISIC (boxplot + spaghetti)
*
* INPUT : output/si_energy_intensity.dta
* OUTPUT: output/figures/fig_ei_*.png
*
* AUTHOR: Albert Ludi
* ============================================================

clear all
set more off

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
global out     "$handoff/output"
global fig     "$handoff/output/figures"

cap log close
log using "$logs/17_ei_figures.log", replace text

di as txt "======================================================"
di as txt " 17_ei_figures.do — started: " c(current_date) " " c(current_time)
di as txt "======================================================"

* ── Load ───────────────────────────────────────────────────────────────────
cap restore, not   // discard any lingering preserve from a prior failed run
use "$out/si_energy_intensity.dta", clear
di as txt _n "Loaded: " _N " obs, " c(k) " vars"

* ── ISIC 2-digit value labels ───────────────────────────────────────────────
cap label drop isic2lbl
label define isic2lbl           ///
    15 "15 Food & Beverages"    ///
    16 "16 Tobacco"             ///
    17 "17 Textiles"            ///
    18 "18 Wearing Apparel"     ///
    19 "19 Leather"             ///
    20 "20 Wood Products"       ///
    21 "21 Paper"               ///
    22 "22 Publishing"          ///
    23 "23 Coke & Petroleum"    ///
    24 "24 Chemicals"           ///
    25 "25 Rubber & Plastics"   ///
    26 "26 Non-metallic Min."   ///
    27 "27 Basic Metals"        ///
    28 "28 Fabricated Metals"   ///
    29 "29 Machinery"           ///
    30 "30 Office Machinery"    ///
    31 "31 Elec. Machinery"     ///
    32 "32 Electronics"         ///
    33 "33 Instruments"         ///
    34 "34 Motor Vehicles"      ///
    35 "35 Other Transport"     ///
    36 "36 Furniture"           ///
    37 "37 Recycling"
cap label values isic2 isic2lbl

* ── Set graph scheme ────────────────────────────────────────────────────────
set scheme s2color


* ============================================================
* FIGURE EI-1 — Fuel vs electricity composition by year
* Stacked bar: Panel A = GJ mix, Panel B = monetary mix
* ============================================================
di as txt _n "=== Figure EI-1: composition stacked bars ==="

preserve
    collapse (sum) gj_fuel_s1 gj_elec_s1 ///
                   fuel_total_reported_rp elec_purchased_rp_zero energy_exp_zero, ///
                   by(year)

    * Percentage shares
    gen share_fuel_gj  = gj_fuel_s1 / (gj_fuel_s1 + gj_elec_s1) * 100
    gen share_elec_gj  = gj_elec_s1 / (gj_fuel_s1 + gj_elec_s1) * 100
    gen share_fuel_mon = fuel_total_reported_rp / energy_exp_zero * 100
    gen share_elec_mon = elec_purchased_rp_zero / energy_exp_zero * 100

    * Panel A — GJ
    graph bar share_fuel_gj share_elec_gj, over(year, label(angle(45) labsize(vsmall))) ///
        stack                                                                             ///
        bar(1, fcolor(midblue) lcolor(none))                                             ///
        bar(2, fcolor(ltblue)  lcolor(none))                                             ///
        legend(order(1 "Fuel combustion (Scope 1)" 2 "Purchased electricity (Scope 2)") ///
               position(6) rows(1) size(small))                                          ///
        ytitle("Share of total GJ (%)", size(small))                                     ///
        ylabel(0(25)100, format(%3.0f) labsize(small))                                   ///
        title("Panel A — Physical Energy Mix (GJ)", size(medsmall) margin(b=2))          ///
        subtitle("Fuel combustion vs purchased electricity share of total energy", size(vsmall) color(gs7)) ///
        xsize(7) ysize(5)
    graph save "$fig/tmp_ei1_pA.gph", replace

    * Panel B — Monetary
    graph bar share_fuel_mon share_elec_mon, over(year, label(angle(45) labsize(vsmall))) ///
        stack                                                                               ///
        bar(1, fcolor(cranberry) lcolor(none))                                             ///
        bar(2, fcolor(orange)    lcolor(none))                                             ///
        legend(order(1 "Fuel expenditure" 2 "Electricity purchase cost")                  ///
               position(6) rows(1) size(small))                                            ///
        ytitle("Share of total energy cost (%)", size(small))                              ///
        ylabel(0(25)100, format(%3.0f) labsize(small))                                     ///
        title("Panel B — Monetary Energy Mix (nominal Rp)", size(medsmall) margin(b=2))    ///
        subtitle("Fuel cost vs electricity cost share of total energy expenditure", size(vsmall) color(gs7)) ///
        xsize(7) ysize(5)
    graph save "$fig/tmp_ei1_pB.gph", replace

    graph combine "$fig/tmp_ei1_pA.gph" "$fig/tmp_ei1_pB.gph", ///
        rows(1)                                                   ///
        title("Fuel vs Electricity Composition of Energy Use, 2000–2014", size(medsmall)) ///
        note("Source: si_energy_intensity.dta · dofiles/17_ei_figures.do", size(vsmall))  ///
        xsize(14) ysize(5)
    graph export "$fig/fig_ei_composition.png", replace width(2100)
    di as txt "  Saved: fig_ei_composition.png"
restore

cap erase "$fig/tmp_ei1_pA.gph"
cap erase "$fig/tmp_ei1_pB.gph"


* ============================================================
* FIGURE EI-2 — Trend comparison (all 3 measures, indexed to 2000=0)
* ============================================================
di as txt _n "=== Figure EI-2: trend comparison ==="

preserve
    * Annual means (firm-level mean collapsed to year)
    collapse (mean) m_gj  = ln_ei_gj_real       ///
                    m_mon = ln_ei_monetary_zero  ///
                    m_co2 = ln_ei_co2_real, by(year)
    sort year

    * Index to 2000 = 0
    foreach v in m_gj m_mon m_co2 {
        quietly sum `v' if year == 2000, meanonly
        gen idx_`v' = `v' - r(mean)
    }

    twoway                                                                   ///
        (connected idx_m_gj  year,                                          ///
            msymbol(O) mcolor(midblue)    lcolor(midblue)    lwidth(medthick) msize(small)) ///
        (connected idx_m_mon year,                                          ///
            msymbol(S) mcolor(cranberry)  lcolor(cranberry)  lwidth(medthick) msize(small)) ///
        (connected idx_m_co2 year,                                          ///
            msymbol(T) mcolor(dkgreen)    lcolor(dkgreen)    lwidth(medthick) msize(small)) ///
        ,                                                                    ///
        yline(0, lcolor(gs10) lwidth(thin) lpattern(dash))                  ///
        xline(2005, lcolor(orange) lwidth(thin) lpattern(shortdash))        ///
        xline(2008, lcolor(orange) lwidth(thin) lpattern(shortdash))        ///
        legend(order(1 "GJ intensity (WPI-deflated output)"                 ///
                     2 "Monetary intensity (nominal Rp)"                    ///
                     3 "CO{sub:2} intensity (WPI-deflated output)")          ///
               position(6) rows(1) size(small))                             ///
        xlabel(2000(2)2014, angle(45) labsize(small))                       ///
        ylabel(, format(%4.2f) labsize(small))                              ///
        ytitle("Change in log intensity since 2000", size(small))           ///
        xtitle("Year", size(small))                                         ///
        title("Energy Intensity Trends Relative to 2000, All Manufacturing", size(medsmall)) ///
        subtitle("Indexed to 2000 = 0 (log-point deviation from 2000 mean)", size(vsmall) color(gs7)) ///
        note("Dashed vertical lines: 2005 IDO desubsidization; 2008 global oil price peak." ///
             "Source: si_energy_intensity.dta · dofiles/17_ei_figures.do", size(vsmall))    ///
        xsize(10) ysize(6)
    graph export "$fig/fig_ei_trend_comparison.png", replace width(1500)
    di as txt "  Saved: fig_ei_trend_comparison.png"
restore


* ============================================================
* FIGURE EI-3 — Component decomposition (fuel vs electricity, indexed)
* ============================================================
di as txt _n "=== Figure EI-3: component decomposition ==="

* Compute component intensities at firm level
gen double ln_ei_gj_fuel = ln(gj_fuel_s1 / output_real)        ///
    if gj_fuel_s1  > 0 & !missing(gj_fuel_s1)                  ///
    & output_real  > 0 & !missing(output_real)
gen double ln_ei_gj_elec = ln(gj_elec_s1 / output_real)        ///
    if gj_elec_s1  > 0 & !missing(gj_elec_s1)                  ///
    & output_real  > 0 & !missing(output_real)
gen double ln_ei_mon_fuel = ln(fuel_total_reported_rp / output) ///
    if fuel_total_reported_rp > 0 & !missing(fuel_total_reported_rp) ///
    & output > 0 & !missing(output)
gen double ln_ei_mon_elec = ln(elec_purchased_rp_zero / output) ///
    if elec_purchased_rp_zero > 0 & !missing(elec_purchased_rp_zero) ///
    & output > 0 & !missing(output)

preserve
    collapse (mean) m_gj_fuel  = ln_ei_gj_fuel  ///
                    m_gj_elec  = ln_ei_gj_elec  ///
                    m_mon_fuel = ln_ei_mon_fuel  ///
                    m_mon_elec = ln_ei_mon_elec, by(year)
    sort year

    * Index to 2000 = 0
    foreach v in m_gj_fuel m_gj_elec m_mon_fuel m_mon_elec {
        quietly sum `v' if year == 2000, meanonly
        gen idx_`v' = `v' - r(mean)
    }

    * Panel A — GJ components
    twoway                                                                    ///
        (connected idx_m_gj_fuel year,                                       ///
            msymbol(O) mcolor(midblue) lcolor(midblue)  lwidth(medthick) msize(small)) ///
        (connected idx_m_gj_elec year,                                       ///
            msymbol(S) mcolor(ltblue)  lcolor(ltblue)   lwidth(medthick) msize(small)) ///
        ,                                                                     ///
        yline(0, lcolor(gs10) lwidth(thin) lpattern(dash))                   ///
        xline(2005, lcolor(orange) lwidth(thin) lpattern(shortdash))         ///
        xline(2008, lcolor(orange) lwidth(thin) lpattern(shortdash))         ///
        legend(order(1 "Fuel combustion (GJ / real output)"                  ///
                     2 "Electricity (GJ / real output)")                      ///
               position(6) rows(1) size(small))                              ///
        xlabel(2000(2)2014, angle(45) labsize(small))                        ///
        ylabel(, format(%4.2f) labsize(small))                               ///
        ytitle("Change in log intensity since 2000", size(small))            ///
        xtitle("Year", size(small))                                          ///
        title("Panel A — Physical GJ Intensity Components", size(medsmall))  ///
        xsize(7) ysize(5)
    graph save "$fig/tmp_ei3_pA.gph", replace

    * Panel B — Monetary components
    twoway                                                                      ///
        (connected idx_m_mon_fuel year,                                        ///
            msymbol(O) mcolor(cranberry) lcolor(cranberry) lwidth(medthick) msize(small)) ///
        (connected idx_m_mon_elec year,                                        ///
            msymbol(S) mcolor(orange)    lcolor(orange)    lwidth(medthick) msize(small)) ///
        ,                                                                       ///
        yline(0, lcolor(gs10) lwidth(thin) lpattern(dash))                     ///
        xline(2005, lcolor(orange) lwidth(thin) lpattern(shortdash))           ///
        xline(2008, lcolor(orange) lwidth(thin) lpattern(shortdash))           ///
        legend(order(1 "Fuel cost (Rp / nominal output)"                       ///
                     2 "Electricity cost (Rp / nominal output)")                ///
               position(6) rows(1) size(small))                                ///
        xlabel(2000(2)2014, angle(45) labsize(small))                          ///
        ylabel(, format(%4.2f) labsize(small))                                 ///
        ytitle("Change in log intensity since 2000", size(small))              ///
        xtitle("Year", size(small))                                            ///
        title("Panel B — Monetary Intensity Components", size(medsmall))       ///
        xsize(7) ysize(5)
    graph save "$fig/tmp_ei3_pB.gph", replace

    graph combine "$fig/tmp_ei3_pA.gph" "$fig/tmp_ei3_pB.gph",                ///
        rows(1)                                                                 ///
        title("Fuel vs Electricity Intensity: Decomposing GJ and Monetary Trends, 2000–2014", ///
              size(medsmall))                                                   ///
        note("Dashed vertical lines: 2005 and 2008 energy price shocks." ///
             "Source: si_energy_intensity.dta · dofiles/17_ei_figures.do", size(vsmall)) ///
        xsize(14) ysize(5)
    graph export "$fig/fig_ei_components.png", replace width(2100)
    di as txt "  Saved: fig_ei_components.png"
restore

cap erase "$fig/tmp_ei3_pA.gph"
cap erase "$fig/tmp_ei3_pB.gph"
drop ln_ei_gj_fuel ln_ei_gj_elec ln_ei_mon_fuel ln_ei_mon_elec


* ============================================================
* FIGURES EI-4 and EI-5 — Cross-industry: boxplot + spaghetti
* Figures iterate over GJ (Spec 1) and monetary intensity
* ============================================================
di as txt _n "=== Figures EI-4 and EI-5: cross-industry ==="

local specs      "gj monetary"
local vnames     "ln_ei_gj_real  ln_ei_monetary_zero"
local ylabels    `""ln(GJ / real Rp000 output)"  "ln(energy cost / nominal output)""'
local title_mains `""Physical GJ Intensity by Industry (2000-2014, WPI-deflated)"  "Monetary Energy Intensity by Industry (2000-2014)""'
local title_As   `""Panel A - GJ Intensity Distribution"  "Panel A - Monetary Intensity Distribution""'
local title_Bs   `""Panel B - GJ Intensity Trend by Industry"  "Panel B - Monetary Intensity Trend by Industry""'
local outfiles   "fig_ei_industry_gj  fig_ei_industry_monetary"
local colors     "midblue  cranberry"

local k = 0
foreach spec of local specs {
    local k = `k' + 1
    local varname  : word `k' of `vnames'
    local ylabel   : word `k' of `ylabels'
    local tmain    : word `k' of `title_mains'
    local tA       : word `k' of `title_As'
    local tB       : word `k' of `title_Bs'
    local outfile  : word `k' of `outfiles'
    local c1       : word `k' of `colors'

    di as txt _n "  Processing: `spec' (`varname')"

    * ── Panel A: horizontal box plot by ISIC ─────────────────────────────
    preserve
        keep if inrange(isic2, 15, 37) & !missing(`varname')
        graph hbox `varname',                                               ///
            over(isic2, sort(1) descending                                  ///
                 label(labsize(tiny) angle(0)))                             ///
            box(1, fcolor(`c1'%60) lcolor(`c1'))                           ///
            marker(1, mcolor(`c1'%50) msize(vtiny))                        ///
            ytitle(`ylabel', size(small))                                   ///
            title(`tA', size(small) margin(b=1))                           ///
            note("Box = IQR · whiskers = 10th/90th pctile · sorted by median (high→low)", ///
                 size(vsmall))                                              ///
            xsize(7) ysize(10)
        graph save "$fig/tmp_`spec'_box.gph", replace
    restore

    * ── Industry annual means (tempfile) ─────────────────────────────────
    preserve
        keep if inrange(isic2, 15, 37) & !missing(`varname')
        collapse (mean) ind_mean = `varname', by(year isic2)
        tempfile ind_`spec'
        save `ind_`spec''
    restore

    * ── Panel B: spaghetti trend with spread right-side industry labels ────────────
    preserve
        * Overall aggregate (firm-level mean)
        keep if inrange(isic2, 15, 37) & !missing(`varname')
        collapse (mean) agg = `varname', by(year)

        merge 1:m year using `ind_`spec'', nogen
        sort isic2 year

        * Short industry labels at last available year (right-side annotation)
        bysort isic2 (year): gen is_last = (_n == _N)
        gen str12 isic_short = ""
        replace isic_short = "Food&Bev"   if isic2 == 15 & is_last
        replace isic_short = "Tobacco"    if isic2 == 16 & is_last
        replace isic_short = "Textiles"   if isic2 == 17 & is_last
        replace isic_short = "Apparel"    if isic2 == 18 & is_last
        replace isic_short = "Leather"    if isic2 == 19 & is_last
        replace isic_short = "Wood"       if isic2 == 20 & is_last
        replace isic_short = "Paper"      if isic2 == 21 & is_last
        replace isic_short = "Publish"    if isic2 == 22 & is_last
        replace isic_short = "Coke&Pet"   if isic2 == 23 & is_last
        replace isic_short = "Chemicals"  if isic2 == 24 & is_last
        replace isic_short = "Rubber"     if isic2 == 25 & is_last
        replace isic_short = "NonMetMin"  if isic2 == 26 & is_last
        replace isic_short = "Metals"     if isic2 == 27 & is_last
        replace isic_short = "FabMetal"   if isic2 == 28 & is_last
        replace isic_short = "Machinery"  if isic2 == 29 & is_last
        replace isic_short = "OffMach"    if isic2 == 30 & is_last
        replace isic_short = "ElecMach"   if isic2 == 31 & is_last
        replace isic_short = "Electron"   if isic2 == 32 & is_last
        replace isic_short = "Instrums"   if isic2 == 33 & is_last
        replace isic_short = "MotorVeh"   if isic2 == 34 & is_last
        replace isic_short = "OthrTrsp"   if isic2 == 35 & is_last
        replace isic_short = "Furniture"  if isic2 == 36 & is_last
        replace isic_short = "Recycling"  if isic2 == 37 & is_last

        * ── Spread label y-positions to avoid overlap ───────────────────────
        * Algorithm: temporarily sort is_last obs by value to assign ranks;
        * assign evenly-spaced y-positions across the full y range + padding.
        * Thin pcspike connectors link actual endpoints to spread positions at x=2016.
        * No nested preserve needed — compute in-place, restore sort after.
        gen float _val_last = ind_mean if is_last & isic_short != ""
        sort _val_last isic2            // missings go last in Stata
        qui count if is_last & isic_short != ""
        local n_lab = r(N)
        gen int rank_lab = .
        qui replace rank_lab = _n if is_last & isic_short != ""
        sort isic2 year                 // restore sort order

        qui sum _val_last
        local ylo = r(min)
        local yhi = r(max)
        local pad = max(0.4, (`yhi' - `ylo') * 0.10)
        gen float y_lab = (`ylo' - `pad') + ///
            (rank_lab - 1) / max(1, `n_lab' - 1) * (`yhi' - `ylo' + 2 * `pad')
        drop _val_last

        * Connector endpoints — only set for labelled last-year observations
        gen y_end = ind_mean if is_last & isic_short != ""
        gen x_end = year     if is_last & isic_short != ""
        gen x_lab = 2016     if is_last & isic_short != ""

        * Build twoway command: one line per ISIC, aggregate, connectors, labels
        levelsof isic2, local(isic_list)
        local n_isic: word count `isic_list'

        local sp ""
        foreach i of local isic_list {
            local sp `"`sp' (line ind_mean year if isic2==`i', lcolor(gs13) lwidth(vthin))"'
        }
        local sp `"`sp' (connected agg year, lcolor(`c1') lwidth(medthick) msymbol(O) mcolor(`c1') msize(small))"'
        * Thin connector: actual endpoint (x_end, y_end) → spread label position (x_lab, y_lab)
        local sp `"`sp' (pcspike y_end x_end y_lab x_lab if is_last & isic_short != "", lcolor(gs13) lwidth(vthin))"'
        * Labels at spread y-position, x = 2016
        local sp `"`sp' (scatter y_lab x_lab if is_last & isic_short != "", msize(none) mlabel(isic_short) mlabposition(3) mlabsize(tiny) mlabcolor(gs6))"'
        local leg_num = `n_isic' + 1

        twoway `sp',                                                          ///
            xline(2005, lcolor(orange) lwidth(thin) lpattern(shortdash))      ///
            xline(2008, lcolor(orange) lwidth(thin) lpattern(shortdash))      ///
            legend(order(`leg_num' "All manufacturing (mean)")                 ///
                   position(6) size(small))                                    ///
            xlabel(2000(2)2014, angle(45) labsize(small))                      ///
            xscale(range(1999 2020))                                           ///
            ylabel(, format(%4.1f) labsize(small))                             ///
            ytitle(`ylabel', size(small))                                      ///
            xtitle("Year", size(small))                                        ///
            title(`tB', size(small) margin(b=1))                               ///
            note("Grey lines = individual ISIC 2-digit industries (labelled at right)" ///
                 "Dashed lines = 2005 and 2008 energy price events", size(vsmall)) ///
            xsize(12) ysize(7)
        graph save "$fig/tmp_`spec'_spag.gph", replace
    restore

    * ── Combine and export ────────────────────────────────────────────────
    graph combine "$fig/tmp_`spec'_box.gph" "$fig/tmp_`spec'_spag.gph", ///
        rows(1)                                                            ///
        title(`tmain', size(medsmall))                                     ///
        note("Source: si_energy_intensity.dta · dofiles/17_ei_figures.do", size(vsmall)) ///
        xsize(17) ysize(10)
    graph export "$fig/`outfile'.png", replace width(2550)
    di as txt "  Saved: `outfile'.png"

    cap erase "$fig/tmp_`spec'_box.gph"
    cap erase "$fig/tmp_`spec'_spag.gph"
}


di as txt _n "======================================================"
di as txt " 17_ei_figures.do — done: " c(current_date) " " c(current_time)
di as txt "======================================================"

log close
