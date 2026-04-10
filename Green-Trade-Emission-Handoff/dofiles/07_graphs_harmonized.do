* ============================================================
* Script: 07_graphs_harmonized.do
* Purpose: Diagnostic charts from si_energy_harmonized.dta to:
*          (1) Show coal quantity distribution by year (as-reported; no correction)
*          (2) Show median & mean trends for all usable fuel and
*              electricity variables (sense-check of the cleaned data)
*          (3) Disaggregate key variables by ISIC 2-digit industry
*              (isic5_raw built into panel from 01_append_si_energy.do)
*
* Input:   output/si_energy_harmonized.dta  (has isic5_raw, dkabup, dprovi,
*                                            ltlnou, vtlvcu, output, iinput)
* Output:  output/figures/fig03_coal_distribution.png
*          output/figures/fig04_fuel_trends.png
*          output/figures/fig05_elec_trends.png
*          output/figures/fig06_diesel_by_isic2.png
*          output/figures/fig06b_diesel_trend_by_isic2.png
*          output/figures/fig07_elec_by_isic2.png
*          output/figures/fig07b_elec_trend_by_isic2.png
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

capture mkdir "$figures"
log using "$logs/07_graphs_harmonized.log", replace text

* ── Load harmonized panel ────────────────────────────────────────────────────
use "$output/si_energy_harmonized.dta", clear
di as txt "Harmonized obs loaded: " _N

* ── Derive isic2 from isic5_raw (now in base panel from 01_append_si_energy) ─
* isic5_raw is 5-digit KBLI/ISIC → isic2 = first 2 digits = int(isic5_raw/1000)
cap confirm variable isic5_raw
if _rc == 0 {
    gen isic2 = int(isic5_raw / 1000) if !missing(isic5_raw)
    di as txt "  isic2 derived from isic5_raw (panel variable)"
}
else {
    di as txt "  WARNING: isic5_raw not found — isic2 will be missing."
    di as txt "  Re-run 01_append_si_energy.do to rebuild si_panel_2000_2014.dta"
    gen isic2 = .
}

di as txt "  isic2 non-missing: "
count if !missing(isic2)

* ── ISIC 2-digit labels (Indonesian manufacturing ISIC Rev 3 / KBLI 2005) ──
label define isic2lbl ///
    15 "15 - Food & beverages" ///
    16 "16 - Tobacco" ///
    17 "17 - Textiles" ///
    18 "18 - Wearing apparel" ///
    19 "19 - Leather & footwear" ///
    20 "20 - Wood products" ///
    21 "21 - Paper & paper products" ///
    22 "22 - Printing & publishing" ///
    23 "23 - Coke & refined petroleum" ///
    24 "24 - Chemicals" ///
    25 "25 - Rubber & plastics" ///
    26 "26 - Non-metallic minerals" ///
    27 "27 - Basic metals" ///
    28 "28 - Fabricated metals" ///
    29 "29 - Machinery & equipment" ///
    30 "30 - Office machinery" ///
    31 "31 - Electrical machinery" ///
    32 "32 - Radio, TV & comm equip" ///
    33 "33 - Medical instruments" ///
    34 "34 - Motor vehicles" ///
    35 "35 - Other transport equip" ///
    36 "36 - Furniture & other" ///
    37 "37 - Recycling" ///
    , replace
label values isic2 isic2lbl

* ============================================================
* FIGURE 3 — COAL UNIT DIAGNOSTIC: RAW vs HARMONIZED
* ============================================================
* Left panel:  raw eclkgu from si_panel_2000_2014.dta (mixed units; Ton suspected in 2004-05)
* Right panel: fuel_coal_kg from si_energy_harmonized.dta (as-reported; diagnostic confirmed Kg throughout — no correction applied)
* Red shading marks 2004-2005 in both panels.

di as txt _n "=== FIGURE 3: Coal unit diagnostic — raw vs harmonized (no correction applied) ==="

* ── Before: raw eclkgu from unharmonized panel ──────────────────────────────
preserve
    use "$output/si_panel_2000_2014.dta", clear
    keep if !missing(eclkgu) & eclkgu > 0
    collapse (median) med_raw = eclkgu ///
             (count)  n_raw   = eclkgu, by(year)
    tempfile coal_before
    save `coal_before'
restore

* ── After: as-reported fuel_coal_kg from harmonized panel (no correction applied) ───────────
preserve
    keep if !missing(fuel_coal_kg) & fuel_coal_kg > 0
    collapse (median) med_corr = fuel_coal_kg ///
             (count)  n_corr   = fuel_coal_kg, by(year)
    tempfile coal_after
    save `coal_after'
restore

* ── Plot: before ─────────────────────────────────────────────────────────────
use `coal_before', clear

* Add shading bounds for rarea (covers full y-range on log scale)
gen shade_lo = 50
gen shade_hi = 2e7

twoway ///
    (rarea shade_lo shade_hi year if inrange(year, 2004, 2005), ///
        color(red%12) lwidth(none)) ///
    (connected med_raw year, lcolor(maroon) mcolor(maroon) msymbol(circle) lwidth(medthick)), ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Median (Kg or Ton, log scale)", size(small)) ///
    yscale(log range(50 2e7)) ///
    ylabel(100 1000 10000 100000 1000000 10000000, ///
        format(%10.0gc) labsize(vsmall) angle(0)) ///
    title("Before correction", size(medsmall) color(maroon)) ///
    subtitle("Raw {it:eclkgu} — Ton in 2004–2005", size(small)) ///
    legend(off) ///
    scheme(s1color) name(g_before, replace)

drop shade_lo shade_hi

* ── Plot: after ──────────────────────────────────────────────────────────────
use `coal_after', clear

gen shade_lo = 50
gen shade_hi = 2e7

twoway ///
    (rarea shade_lo shade_hi year if inrange(year, 2004, 2005), ///
        color(red%12) lwidth(none)) ///
    (connected med_corr year, lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medthick)), ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Median (Kg, log scale)", size(small)) ///
    yscale(log range(50 2e7)) ///
    ylabel(100 1000 10000 100000 1000000 10000000, ///
        format(%10.0gc) labsize(vsmall) angle(0)) ///
    title("Harmonized (as-reported)", size(medsmall) color(navy)) ///
    subtitle("As-reported {it:fuel_coal_kg} — confirmed Kg throughout (no correction needed)", size(small)) ///
    legend(off) ///
    scheme(s1color) name(g_after, replace)

drop shade_lo shade_hi

* ── Combine ──────────────────────────────────────────────────────────────────
graph combine g_before g_after, ///
    title("Coal Quantity (eclkgu / fuel_coal_kg): Raw vs. Harmonized (diagnostic — no correction applied)", ///
        size(small)) ///
    note("Red shading: 2004-2005 (suspected unit anomaly). Diagnostic confirmed data already in Kg — no ×1,000 correction applied." ///
         "Source: si_panel_2000_2014.dta (raw) · si_energy_harmonized.dta (harmonized).", ///
         size(vsmall)) ///
    rows(1) imargin(medium) ///
    scheme(s1color) xsize(14) ysize(6)

graph export "$figures/fig03_coal_distribution.png", replace width(2800)
di as txt "Saved: fig03_coal_distribution.png"

use "$output/si_energy_harmonized.dta", clear
cap gen isic2 = int(isic5_raw / 1000) if !missing(isic5_raw)
label values isic2 isic2lbl

* ============================================================
* FIGURE 4 — FUEL VARIABLES: MEDIAN TRENDS (2000–2014)
* ============================================================
* Two-panel combined figure:
*   Panel A — liquid & gas fuels (liters / m³ / kg-gas)
*   Panel B — coal (kg) shown separately because as-reported values
*             (median ~2–6 million Kg) are orders of
*             magnitude larger than liquid fuel medians in liters

di as txt _n "=== FIGURE 4: Fuel variable trends ==="

use "$output/si_energy_harmonized.dta", clear

* ── Panel A: liquid & gas fuels ──────────────────────────────────────────────
local liq_vars  "fuel_diesel_ltr fuel_petrol_ltr fuel_kerosene_ltr fuel_citygas_m3 fuel_lpg_kg"
local liq_labels `""Diesel (ltr)" "Petrol (ltr)" "Kerosene (ltr)" "City gas (m³)" "LPG (kg)""'
local liq_colors "navy maroon dkgreen orange teal"
local liq_symbols "circle square diamond triangle smcircle"

tempfile liq_trends

* First variable: save baseline
preserve
    keep if !missing(fuel_diesel_ltr) & fuel_diesel_ltr > 0
    collapse (median) med = fuel_diesel_ltr, by(year)
    gen varname = "fuel_diesel_ltr"
    save `liq_trends'
restore

* Remaining variables: append
foreach v in fuel_petrol_ltr fuel_kerosene_ltr fuel_citygas_m3 fuel_lpg_kg {
    preserve
        keep if !missing(`v') & `v' > 0
        collapse (median) med = `v', by(year)
        gen varname = "`v'"
        append using `liq_trends'
        save `liq_trends', replace
    restore
}

use `liq_trends', clear
keep year varname med
reshape wide med, i(year) j(varname) string

local i = 1
local plotcmd_a ""
local legord_a ""
foreach v of local liq_vars {
    local col : word `i' of `liq_colors'
    local sym : word `i' of `liq_symbols'
    local lbl : word `i' of `liq_labels'
    local plotcmd_a `"`plotcmd_a' (connected med`v' year, lcolor(`col') mcolor(`col') msymbol(`sym') lwidth(medium))"'
    local legord_a `"`legord_a' `i' "`lbl'""'
    local i = `i' + 1
}

twoway `plotcmd_a', ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Median (liters / m³ / kg, log scale)", size(small)) ///
    yscale(log) ///
    ylabel(100 1000 10000 100000 1000000, format(%10.0gc) labsize(vsmall) angle(0)) ///
    title("(A) Liquid & Gas Fuels", size(small)) ///
    subtitle("Line breaks = structural survey gaps", size(vsmall)) ///
    legend(order(`legord_a') cols(3) size(vsmall)) ///
    scheme(s1color) name(g_liq, replace)

* ── Panel B: coal ─────────────────────────────────────────────────────────────
use "$output/si_energy_harmonized.dta", clear

preserve
    keep if !missing(fuel_coal_kg) & fuel_coal_kg > 0
    collapse (median) med_coal = fuel_coal_kg ///
             (count)  n_coal   = fuel_coal_kg, by(year)
    tempfile coal_trend
    save `coal_trend'
restore

use `coal_trend', clear

twoway ///
    (connected med_coal year, lcolor(sienna) mcolor(sienna) msymbol(circle) lwidth(medthick)), ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Median (kg, log scale)", size(small)) ///
    yscale(log) ///
    ylabel(1000 10000 100000 1000000 10000000, format(%10.0gc) labsize(vsmall) angle(0)) ///
    title("(B) Coal — fuel_coal_kg", size(small)) ///
    subtitle("As-reported Kg (no correction applied — see §4.1). Gap = 2001–2002.", size(vsmall)) ///
    legend(order(1 "Coal (kg)") size(vsmall)) ///
    scheme(s1color) name(g_coal, replace)

* ── Combine ───────────────────────────────────────────────────────────────────
graph combine g_liq g_coal, ///
    title("Fuel Variables: Median by Year (positive reporters)", size(medsmall)) ///
    note("Coal shown separately: as-reported medians (~2–6M Kg) are orders of magnitude larger than liquid fuel medians (liters)." ///
         "Log scale. Source: si_energy_harmonized.dta | do-file: 07_graphs_harmonized.do", size(vsmall)) ///
    rows(1) imargin(small) ///
    scheme(s1color) xsize(14) ysize(6)

graph export "$figures/fig04_fuel_trends.png", replace width(2800)
di as txt "Saved: fig04_fuel_trends.png"

* ============================================================
* FIGURE 5 — ELECTRICITY VARIABLES: MEDIAN TRENDS (2000–2014)
* ============================================================
* Two-panel combined figure:
*   Panel A — All four kWh series on one log-scale axis so the
*             order-of-magnitude gap between PLN (dominant) and
*             non-PLN/own-gen (marginal) is immediately visible.
*             N positive reporters shown in each legend label.
*   Panel B — Share of electricity expenditure (Rp000) by source
*             (PLN vs. non-PLN) as a stacked area chart, using
*             elec_pln_rp and elec_nonpln_rp.  Quantifies PLN
*             dominance (>90% of total spend throughout).

di as txt _n "=== FIGURE 5: Electricity variable trends ==="

use "$output/si_energy_harmonized.dta", clear

* ── Count N positive reporters for legend labels ─────────────────────────────
foreach v in elec_pln_kwh elec_nonpln_kwh elec_owngene_kwh elec_purchased_kwh_strict {
    quietly count if `v' > 0 & !missing(`v')
    local n_`v'     = r(N)
    local n_`v'_lbl = string(round(`n_`v'' / 1000, 0.1)) + "k"
}

* ── Collapse medians for all four series ─────────────────────────────────────
foreach v in elec_pln_kwh elec_nonpln_kwh elec_owngene_kwh elec_purchased_kwh_strict {
    preserve
        keep if !missing(`v') & `v' > 0
        collapse (median) med_`v' = `v', by(year)
        tempfile tmp_`v'
        save `tmp_`v''
    restore
}

* Merge into one wide file
use `tmp_elec_pln_kwh', clear
foreach v in elec_nonpln_kwh elec_owngene_kwh elec_purchased_kwh_strict {
    merge 1:1 year using `tmp_`v'', nogen
}
sort year

* ── Panel A: all four kWh series on one log-scale axis ───────────────────────
twoway ///
    (connected med_elec_pln_kwh year, ///
        lcolor(dkgreen) mcolor(dkgreen) msymbol(square) lwidth(medthick)) ///
    (connected med_elec_nonpln_kwh year, ///
        lcolor(maroon) mcolor(maroon) msymbol(circle) lwidth(medium) lpattern(dash)) ///
    (connected med_elec_owngene_kwh year, ///
        lcolor(orange) mcolor(orange) msymbol(diamond) lwidth(medium) lpattern(shortdash)) ///
    (connected med_elec_purchased_kwh_strict year, ///
        lcolor(navy) mcolor(navy) msymbol(plus) lwidth(thin) lpattern(longdash)), ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Median kWh (log scale)", size(small)) ///
    yscale(log range(500 2e8)) ///
    ylabel(1000 10000 100000 1000000 10000000 100000000, ///
        format(%10.0gc) labsize(vsmall) angle(0)) ///
    title("(A) Electricity: Median kWh by Source", size(small)) ///
    subtitle("All series on one axis — gap shows PLN dominance in volume", size(vsmall)) ///
    legend(order(1 "PLN grid (N=`n_elec_pln_kwh_lbl')" ///
                 2 "Non-PLN purchased (N=`n_elec_nonpln_kwh_lbl')" ///
                 3 "Own-generated (N=`n_elec_owngene_kwh_lbl')" ///
                 4 "Purchased strict aggregate (N=`n_elec_purchased_kwh_strict_lbl')") ///
           cols(1) size(vsmall)) ///
    scheme(s1color) name(g_elec_a, replace)

* ── Panel B: stacked area — PLN vs non-PLN share of total expenditure ─────────
use "$output/si_energy_harmonized.dta", clear

* Keep obs where at least PLN expenditure is recorded
keep if elec_pln_rp > 0 & !missing(elec_pln_rp)
* Treat missing non-PLN as zero
replace elec_nonpln_rp = 0 if missing(elec_nonpln_rp)

collapse (sum) sum_pln_rp = elec_pln_rp ///
               sum_nonpln_rp = elec_nonpln_rp, by(year)

gen total_rp    = sum_pln_rp + sum_nonpln_rp
gen share_pln   = sum_pln_rp   / total_rp * 100
gen top_line    = 100
gen zero_line   = 0

twoway ///
    (rarea top_line share_pln year, fcolor(maroon%50) lwidth(none)) ///
    (rarea share_pln zero_line year, fcolor(dkgreen%50) lwidth(none)) ///
    (line share_pln year, lcolor(dkgreen) lwidth(medthick)), ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Share of total electricity spend (%)", size(small)) ///
    ylabel(0(20)100, labsize(vsmall) angle(0)) ///
    title("(B) Electricity Expenditure Share", size(small)) ///
    subtitle("PLN grid vs. non-PLN purchased (Rp000, among PLN reporters)", size(vsmall)) ///
    legend(order(2 "PLN grid (elec_pln_rp)" ///
                 1 "Non-PLN purchased (elec_nonpln_rp)") ///
           cols(1) size(vsmall)) ///
    scheme(s1color) name(g_elec_b, replace)

* ── Combine ───────────────────────────────────────────────────────────────────
graph combine g_elec_a g_elec_b, ///
    title("Electricity Variables: Volume Trends and Expenditure Shares", size(medsmall)) ///
    note("Panel A: median kWh by year (log scale); Panel B: share of total electricity expenditure (Rp000)." ///
         "Source: si_energy_harmonized.dta | do-file: 07_graphs_harmonized.do", size(vsmall)) ///
    rows(1) imargin(small) ///
    scheme(s1color) xsize(14) ysize(6)

graph export "$figures/fig05_elec_trends.png", replace width(2800)
di as txt "Saved: fig05_elec_trends.png"

* ── ISIC 2-digit short names (persist as locals through Figs 6–7) ─────────────
* Used for line chart legends where value labels are unavailable after reshape.
local isic_nm_10 "Other food (10)"
local isic_nm_15 "Food & bev (15)"
local isic_nm_16 "Tobacco (16)"
local isic_nm_17 "Textiles (17)"
local isic_nm_18 "Apparel (18)"
local isic_nm_19 "Leather (19)"
local isic_nm_20 "Wood (20)"
local isic_nm_21 "Paper (21)"
local isic_nm_22 "Printing (22)"
local isic_nm_23 "Petroleum (23)"
local isic_nm_24 "Chemicals (24)"
local isic_nm_25 "Rubber/plastics (25)"
local isic_nm_26 "Non-met minerals (26)"
local isic_nm_27 "Basic metals (27)"
local isic_nm_28 "Fab metals (28)"
local isic_nm_29 "Machinery (29)"
local isic_nm_30 "Office mach (30)"
local isic_nm_31 "Elec machinery (31)"
local isic_nm_32 "Electronics (32)"
local isic_nm_33 "Med instruments (33)"
local isic_nm_34 "Motor vehicles (34)"
local isic_nm_35 "Other transport (35)"
local isic_nm_36 "Furniture/other (36)"
local isic_nm_37 "Recycling (37)"

* ============================================================
* FIGURE 6 — FUEL USE BY ISIC 2-DIGIT: BOX PLOTS (one per fuel)
* Figures: fig06A_diesel, fig06B_petrol, fig06C_kerosene,
*          fig06D_coal, fig06E_lpg, fig06F_citygas
* ============================================================

di as txt _n "=== FIGURE 6: Fuel use by ISIC 2-digit (box plots) ==="

local fvars    "fuel_diesel_ltr fuel_petrol_ltr fuel_kerosene_ltr fuel_coal_kg fuel_lpg_kg fuel_citygas_m3"
local funits   "log(liters) log(liters) log(liters) log(kg) log(kg) log(m3)"
local ftitles  "Diesel/Solar Petrol/Bensin Kerosene Coal/Batubara LPG City_Gas/PGN"
local ffiles   "fig06A_diesel fig06B_petrol fig06C_kerosene fig06D_coal fig06E_lpg fig06F_citygas"
local fletters "A B C D E F"

forvalues i = 1/6 {
    local fvar   : word `i' of `fvars'
    local funit  : word `i' of `funits'
    local ftitle : word `i' of `ftitles'
    local ffile  : word `i' of `ffiles'
    local fltr   : word `i' of `fletters'
    local ftitle_clean = subinstr("`ftitle'", "_", " ", .)

    use "$output/si_energy_harmonized.dta", clear
    cap gen isic2 = int(isic5_raw / 1000) if !missing(isic5_raw)

    * Redefine labels after each use,clear (use,clear wipes label memory)
    label define isic2lbl ///
        15 "15 - Food & beverages" 16 "16 - Tobacco" 17 "17 - Textiles" ///
        18 "18 - Wearing apparel" 19 "19 - Leather & footwear" ///
        20 "20 - Wood products" 21 "21 - Paper & paper products" ///
        22 "22 - Printing & publishing" 23 "23 - Coke & refined petroleum" ///
        24 "24 - Chemicals" 25 "25 - Rubber & plastics" ///
        26 "26 - Non-metallic minerals" 27 "27 - Basic metals" ///
        28 "28 - Fabricated metals" 29 "29 - Machinery & equipment" ///
        30 "30 - Office machinery" 31 "31 - Electrical machinery" ///
        32 "32 - Radio, TV & comm equip" 33 "33 - Medical instruments" ///
        34 "34 - Motor vehicles" 35 "35 - Other transport equip" ///
        36 "36 - Furniture & other" 37 "37 - Recycling" ///
        , replace
    label values isic2 isic2lbl

    quietly {
        keep if !missing(`fvar') & `fvar' > 0 & !missing(isic2)
        quietly count
        if r(N) < 10 {
            di as txt "  Skipping `ffile' — too few obs"
            continue
        }
        bysort isic2: gen n_isic = _N
        preserve
            bysort isic2: keep if _n == 1
            gsort -n_isic
            keep if _n <= 10
            levelsof isic2, local(top_g_`i')
        restore
        gen top_ind = 0
        foreach g of local top_g_`i' {
            replace top_ind = 1 if isic2 == `g'
        }
        keep if top_ind == 1
    }

    decode isic2, gen(isic2_name)
    gen log_val = log(`fvar')

    graph hbox log_val, ///
        over(isic2_name, sort(1) label(angle(0) labsize(small))) ///
        title("(`fltr') `ftitle_clean' Use by ISIC 2-digit", size(medsmall)) ///
        subtitle("Distribution of `funit' pooled 2000–2014, top 10 industries by N", size(small)) ///
        ytitle("`funit'", size(small)) ///
        note("Sorted by median (descending). Horizontal lines = median; box = IQR; whiskers = 1.5×IQR." ///
             "Positive reporters only. Source: si_energy_harmonized.dta · Do-file: 07_graphs_harmonized.do", ///
             size(vsmall)) ///
        graphregion(margin(l=35)) ///
        scheme(s1color) xsize(14) ysize(8)
    graph export "$figures/`ffile'_by_isic2.png", replace width(2400)
    di as txt "Saved: `ffile'_by_isic2.png"
}

* ============================================================
* FIGURE 7 — PLN ELECTRICITY BY ISIC 2-DIGIT: BOX PLOT + LINE CHART
* ============================================================

di as txt _n "=== FIGURE 7: PLN electricity by ISIC 2-digit (box + line) ==="

use "$output/si_energy_harmonized.dta", clear
cap gen isic2 = int(isic5_raw / 1000) if !missing(isic5_raw)

* Identify top 10 ISIC 2-digit groups by N positive PLN obs
quietly {
    keep if !missing(elec_pln_kwh) & elec_pln_kwh > 0 & !missing(isic2)
    bysort isic2: gen n_isic = _N
    preserve
        bysort isic2: keep if _n == 1
        gsort -n_isic
        keep if _n <= 10
        levelsof isic2, local(top_isic2_e)
    restore
    gen top_ind = 0
    foreach g of local top_isic2_e {
        replace top_ind = 1 if isic2 == `g'
    }
    keep if top_ind == 1
}

label define isic2lbl ///
    15 "15 - Food & beverages" 16 "16 - Tobacco" 17 "17 - Textiles" ///
    18 "18 - Wearing apparel" 19 "19 - Leather & footwear" ///
    20 "20 - Wood products" 21 "21 - Paper & paper products" ///
    22 "22 - Printing & publishing" 23 "23 - Coke & refined petroleum" ///
    24 "24 - Chemicals" 25 "25 - Rubber & plastics" ///
    26 "26 - Non-metallic minerals" 27 "27 - Basic metals" ///
    28 "28 - Fabricated metals" 29 "29 - Machinery & equipment" ///
    30 "30 - Office machinery" 31 "31 - Electrical machinery" ///
    32 "32 - Radio, TV & comm equip" 33 "33 - Medical instruments" ///
    34 "34 - Motor vehicles" 35 "35 - Other transport equip" ///
    36 "36 - Furniture & other" 37 "37 - Recycling" ///
    , replace
label values isic2 isic2lbl
decode isic2, gen(isic2_name)

* ── 7A: Box plot ─────────────────────────────────────────────────────────────
gen log_pln = log(elec_pln_kwh)

graph hbox log_pln, over(isic2_name, sort(1) label(angle(0) labsize(small))) ///
    title("(A) PLN Electricity by ISIC 2-digit", size(medsmall)) ///
    subtitle("Distribution of log kWh pooled 2000–2014, top 10 industries by N", size(small)) ///
    ytitle("log(elec_pln_kwh)", size(small)) ///
    note("Sorted by median (descending). Horizontal lines = median; box = IQR; whiskers = 1.5×IQR." ///
         "Positive reporters only. Source: si_energy_harmonized.dta · Do-file: 07_graphs_harmonized.do", ///
         size(vsmall)) ///
    graphregion(margin(l=35)) ///
    scheme(s1color) xsize(14) ysize(8)
graph export "$figures/fig07_elec_by_isic2.png", replace width(2400)
di as txt "Saved: fig07_elec_by_isic2.png"

* ── 7B: Line chart — median PLN kWh by year per industry ─────────────────────
tempfile elec_yrind
preserve
    keep year isic2 elec_pln_kwh top_ind
    collapse (median) med_pln = elec_pln_kwh ///
             (count)  n_pln   = elec_pln_kwh, by(year isic2)
    save `elec_yrind'
restore

use `elec_yrind', clear
reshape wide med_pln n_pln, i(year) j(isic2)

local i = 1
local plotcmd_7b ""
local legord_7b ""
foreach g of local top_isic2_e {
    local col : word `i' of `colors'
    local lbl "`isic_nm_`g''"
    if "`lbl'" == "" local lbl "ISIC `g'"
    local plotcmd_7b `"`plotcmd_7b' (connected med_pln`g' year if med_pln`g' > 0, lcolor(`col') mcolor(`col') msymbol(circle) lwidth(thin) msize(small))"'
    local legord_7b `"`legord_7b' `i' "`lbl'""'
    local i = `i' + 1
}

twoway `plotcmd_7b', ///
    xlabel(2000(1)2014, angle(45) labsize(vsmall)) ///
    xtitle("Survey year", size(small)) ///
    ytitle("Median PLN kWh (log scale)", size(small)) ///
    yscale(log range(1000 1e8)) ///
    ylabel(1000 10000 100000 1000000 10000000 100000000, format(%10.0gc) labsize(vsmall) angle(0)) ///
    title("(B) PLN Electricity Trend by ISIC 2-digit", size(medsmall)) ///
    subtitle("Median kWh per year by industry (positive reporters only, log scale)", size(small)) ///
    legend(order(`legord_7b') cols(2) size(vsmall)) ///
    note("Source: si_energy_harmonized.dta · Do-file: 07_graphs_harmonized.do", size(vsmall)) ///
    scheme(s1color) xsize(12) ysize(7)
graph export "$figures/fig07b_elec_trend_by_isic2.png", replace width(2400)
di as txt "Saved: fig07b_elec_trend_by_isic2.png"

* ============================================================
* SUMMARY
* ============================================================
di as txt _n "=== OUTPUT SUMMARY ==="
di as txt "  fig03_coal_distribution.png — coal quantity distribution (as-reported)"
di as txt "  fig04_fuel_trends.png       — fuel variable medians by year"
di as txt "  fig05_elec_trends.png       — electricity variable medians by year"
di as txt "  fig06A_diesel_by_isic2.png    — diesel box plot by ISIC 2-digit"
di as txt "  fig06B_petrol_by_isic2.png    — petrol box plot by ISIC 2-digit"
di as txt "  fig06C_kerosene_by_isic2.png  — kerosene box plot by ISIC 2-digit"
di as txt "  fig06D_coal_by_isic2.png      — coal box plot by ISIC 2-digit"
di as txt "  fig06E_lpg_by_isic2.png       — LPG box plot by ISIC 2-digit"
di as txt "  fig06F_citygas_by_isic2.png   — city gas box plot by ISIC 2-digit"
di as txt "  fig07_elec_by_isic2.png       — PLN electricity box plot by ISIC 2-digit"
di as txt "  fig07b_elec_trend_by_isic2.png — PLN electricity trend by ISIC 2-digit"

log close
