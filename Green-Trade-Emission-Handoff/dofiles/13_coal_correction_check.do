* ============================================================
* Script: 13_coal_correction_check.do
* Purpose: Diagnose whether the ×1000 coal unit correction for
*          2004–2005 was correct or over-applied.
*
*          Method: Compare implied unit price (Rp000 per kg)
*          of coal across years, both PRE and POST correction.
*          If the correction is correct, post-correction price
*          should be consistent across years. If data was already
*          in kg, post-correction price will be ~1/1000 of adjacent.
*
*          Also: scatter expenditure vs quantity before/after
*          to check whether the relationship is internally consistent.
*
* Input:   output/si_panel_2000_2014.dta  (raw, pre-correction)
*          output/si_energy_harmonized.dta (post-correction)
* Output:  output/tables/coal_correction_check.csv
*          output/figures/figC1_coal_unitprice_raw.png
*          output/figures/figC2_coal_unitprice_corrected.png
*          output/figures/figC3_coal_expend_vs_qty.png
* Author:  Albert Ludi
* Date:    2026-03-22
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

log using "$logs/13_coal_correction_check.log", replace text

* ── create output folders if needed ────────────────────────────────────────
cap mkdir "$output/tables"
cap mkdir "$output/figures"

* ============================================================
* PART A: RAW DATA — unit price BEFORE correction
* ============================================================
* In raw data: eclkgu = coal kg (all years except 2004-2005 which is Tons)
* eclvcu = coal expenditure in Rp000

di as txt _n "=== PART A: Raw data — pre-correction unit price ==="

use "$output/si_panel_2000_2014.dta", clear
di as txt "Raw obs loaded: " _N

* Only keep observations with both coal quantity and expenditure positive
keep if !missing(eclkgu) & eclkgu > 0 & !missing(eclvcu) & eclvcu > 0

di as txt "Coal reporters (qty & exp positive): " _N

* Implied unit price (Rp000 per raw unit of eclkgu)
* In 2003,2006+ this is Rp000/kg
* In 2004-2005 this is Rp000/Ton (since qty is in Ton in raw data)
gen double unit_price_raw = eclvcu / eclkgu
label variable unit_price_raw "Implied price: Rp000 per raw unit (Ton in 2004-5, Kg otherwise)"

* Also compute what unit price WOULD BE if we treat raw 2004-2005 as already in Kg
* (i.e., the correction was WRONG and no conversion was needed)
* For years != 2004-2005, this is the same as unit_price_raw
* For 2004-2005, this is the same as unit_price_raw (raw already in "kg")
* Post-correction would divide by 1000 more → Rp000/1000kg

di as txt _n "--- Median unit price by year (raw data, Rp000 per raw eclkgu unit) ---"
di as txt "(2004-2005 unit is Ton; other years unit is Kg — not directly comparable)"

* Compute by-year medians
tempfile raw_summary
tempname hdl_raw
postfile `hdl_raw' int year double n_obs double p25 double p50 double p75 double mean_price ///
    using `raw_summary', replace

levelsof year, local(years)
foreach y of local years {
    qui count if year == `y'
    local N = r(N)
    if `N' > 0 {
        qui summarize unit_price_raw if year == `y', detail
        post `hdl_raw' (`y') (`N') (r(p25)) (r(p50)) (r(p75)) (r(mean))
        di as txt "  Year `y': N=" %6.0f `N' "  median=" %12.4f r(p50) "  mean=" %12.2f r(mean)
    }
}
postclose `hdl_raw'

* Save raw summary
use `raw_summary', clear
gen source = "raw_pre_correction"
tempfile raw_part
save `raw_part'

* Figure: median unit price by year (raw) — this will look like a jump if correction needed
use "$output/si_panel_2000_2014.dta", clear
keep if !missing(eclkgu) & eclkgu > 0 & !missing(eclvcu) & eclvcu > 0
gen double unit_price_raw = eclvcu / eclkgu

* Annual medians for graph
preserve
    collapse (p50) med_price = unit_price_raw (count) n = unit_price_raw, by(year)
    twoway (connected med_price year, mcolor(navy) lcolor(navy) msymbol(circle)) ///
        , xtitle("Year") ytitle("Rp000 per raw unit") ///
          title("Coal unit price — RAW data (pre-correction)") ///
          subtitle("2004-2005: qty in Ton; other years: qty in Kg") ///
          note("If correction needed: 2004-2005 price should be ~1000× adjacent years") ///
          xlabel(2000(2)2014, angle(45)) ///
          graphregion(color(white)) bgcolor(white)
    graph export "$output/figures/figC1_coal_unitprice_raw.png", replace width(1200)
    di as txt "figC1 saved"
restore

* ============================================================
* PART B: HARMONIZED DATA — unit price (no correction applied)
* ============================================================
* Conclusion from Part A: coal quantities were already reported in Kg for all
* years including 2004-2005. NO × 1000 correction was applied in
* 06_harmonize_si_energy.do. This part confirms the conclusion: if unit
* prices are flat across years in the harmonized data, the data was already
* in Kg and no correction was needed.

di as txt _n "=== PART B: Harmonized data — as-reported unit price (no correction) ==="

use "$output/si_energy_harmonized.dta", clear
di as txt "Harmonized obs loaded: " _N

keep if !missing(fuel_coal_kg) & fuel_coal_kg > 0 & !missing(fuel_coal_rp) & fuel_coal_rp > 0

di as txt "Coal reporters (qty & exp positive): " _N

* As-reported unit price (flat across years = data was already in Kg; no correction needed)
gen double unit_price_post = fuel_coal_rp / fuel_coal_kg
label variable unit_price_post "Implied price: Rp000 per kg (as-reported, no correction)"

di as txt _n "--- Median unit price by year (as-reported, Rp000 per kg) ---"
di as txt "(Flat prices across 2004-2005 confirm no correction was needed)"

tempfile post_summary
tempname hdl_post
postfile `hdl_post' int year double n_obs double p25 double p50 double p75 double mean_price ///
    using `post_summary', replace

levelsof year, local(years)
foreach y of local years {
    qui count if year == `y'
    local N = r(N)
    if `N' > 0 {
        qui summarize unit_price_post if year == `y', detail
        post `hdl_post' (`y') (`N') (r(p25)) (r(p50)) (r(p75)) (r(mean))
        di as txt "  Year `y': N=" %6.0f `N' "  median=" %12.6f r(p50) "  mean=" %12.6f r(mean)
    }
}
postclose `hdl_post'

* Save post summary
use `post_summary', clear
gen source = "post_correction"
tempfile post_part
save `post_part'

* Combined CSV
use `raw_part', clear
append using `post_part'
order year source n_obs p25 p50 p75 mean_price
sort source year
export delimited using "$output/tables/coal_correction_check.csv", replace
di as txt "Saved: coal_correction_check.csv"

* Figure: median unit price by year (post-correction)
use "$output/si_energy_harmonized.dta", clear
keep if !missing(fuel_coal_kg) & fuel_coal_kg > 0 & !missing(fuel_coal_rp) & fuel_coal_rp > 0
gen double unit_price_post = fuel_coal_rp / fuel_coal_kg

preserve
    collapse (p50) med_price = unit_price_post (count) n = unit_price_post, by(year)
    twoway (connected med_price year, mcolor(maroon) lcolor(maroon) msymbol(diamond)) ///
        , xtitle("Year") ytitle("Rp000 per kg") ///
          title("Coal unit price — HARMONIZED data (post-correction)") ///
          subtitle("All years in Rp000/kg — should be consistent if correction correct") ///
          note("2004-2005 price ≈ adjacent → correction OK" ///
               "2004-2005 price << adjacent → data was already in kg (over-corrected)") ///
          xlabel(2000(2)2014, angle(45)) ///
          graphregion(color(white)) bgcolor(white)
    graph export "$output/figures/figC2_coal_unitprice_corrected.png", replace width(1200)
    di as txt "figC2 saved"
restore

* ============================================================
* PART C: SCATTER — expenditure vs quantity, by year group
* ============================================================
* If correction is correct: 2004-2005 scatter should align with other years
* If over-corrected: 2004-2005 will be shifted right (quantity too large)

di as txt _n "=== PART C: Scatter — expenditure vs quantity ==="

use "$output/si_energy_harmonized.dta", clear
keep if !missing(fuel_coal_kg) & fuel_coal_kg > 0 & !missing(fuel_coal_rp) & fuel_coal_rp > 0

* Log-log scatter by year group
gen ln_coal_kg = ln(fuel_coal_kg)
gen ln_coal_rp = ln(fuel_coal_rp)
gen group = cond(year == 2004 | year == 2005, 2, cond(year == 2003 | year == 2006, 3, 1))
label define grp 1 "Other years" 3 "Adjacent (2003,2006)" 2 "2004-2005 (corrected)"
label values group grp

* Binscatter-style: sample up to 5000 obs for scatter legibility
set seed 42
sample 5000 if _N > 5000, count

twoway (scatter ln_coal_rp ln_coal_kg if group == 1, ///
            mcolor(gs10) msymbol(oh) msize(tiny) mlwidth(vthin)) ///
       (scatter ln_coal_rp ln_coal_kg if group == 3, ///
            mcolor(navy) msymbol(circle) msize(small)) ///
       (scatter ln_coal_rp ln_coal_kg if group == 2, ///
            mcolor(maroon) msymbol(diamond) msize(small)) ///
       (lfit ln_coal_rp ln_coal_kg, lcolor(black) lwidth(medthin)) ///
    , xtitle("ln(coal quantity, kg)") ytitle("ln(coal expenditure, Rp000)") ///
      title("Coal: expenditure vs. quantity (post-correction)") ///
      subtitle("If 2004-2005 (red) aligns with adjacent (blue) → correction OK") ///
      legend(order(2 "Adjacent years (2003,2006)" 3 "2004-2005 corrected" 1 "Other years") ///
             ring(0) position(5)) ///
      graphregion(color(white)) bgcolor(white)
graph export "$output/figures/figC3_coal_expend_vs_qty.png", replace width(1200)
di as txt "figC3 saved"

* ============================================================
* PART D: QUANTITATIVE SUMMARY — ratio test
* ============================================================
* Key statistic: ratio of median unit price in 2004-2005 vs. average of 2003 and 2006
* If correction correct: ratio ≈ 1
* If over-corrected:     ratio ≈ 0.001 (price 1000× too low per kg)

di as txt _n "=== PART D: Ratio test ==="

use "$output/si_energy_harmonized.dta", clear
keep if !missing(fuel_coal_kg) & fuel_coal_kg > 0 & !missing(fuel_coal_rp) & fuel_coal_rp > 0
gen double unit_price_post = fuel_coal_rp / fuel_coal_kg

qui summarize unit_price_post if year == 2003, detail
local p50_2003 = r(p50)
qui summarize unit_price_post if year == 2006, detail
local p50_2006 = r(p50)
qui summarize unit_price_post if year == 2004, detail
local p50_2004 = r(p50)
qui summarize unit_price_post if year == 2005, detail
local p50_2005 = r(p50)

local adjacent_avg = (`p50_2003' + `p50_2006') / 2
local ratio_2004 = `p50_2004' / `adjacent_avg'
local ratio_2005 = `p50_2005' / `adjacent_avg'

di as txt _n "  Median unit price (Rp000/kg, post-correction):"
di as txt "    Year 2003: " %10.6f `p50_2003'
di as txt "    Year 2004: " %10.6f `p50_2004'
di as txt "    Year 2005: " %10.6f `p50_2005'
di as txt "    Year 2006: " %10.6f `p50_2006'
di as txt "    Adjacent avg (2003+2006)/2: " %10.6f `adjacent_avg'
di as txt _n "  Ratio 2004/adjacent: " %8.4f `ratio_2004'
di as txt "  Ratio 2005/adjacent: " %8.4f `ratio_2005'
di as txt _n "  Interpretation:"
di as txt "    Ratio ≈ 1.0     → correction was correct (data was in Ton, ×1000 appropriate)"
di as txt "    Ratio ≈ 0.001   → data was already in Kg (over-corrected by ×1000)"
di as txt "    Ratio ≈ 1000    → correction insufficient (data still needs conversion)"

* Also check N coal reporters by year
di as txt _n "  N coal reporters by year (post-correction dataset):"
forvalues y = 2000/2014 {
    qui count if year == `y'
    if r(N) > 0 di as txt "    `y': " %6.0fc r(N)
}

log close
di as txt _n "Done. Check output/tables/coal_correction_check.csv and figC1–figC3."
