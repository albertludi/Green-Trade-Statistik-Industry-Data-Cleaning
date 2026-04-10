* ============================================================
* Script: 12_descriptive_stats.do
* Purpose: Chapter 9 — Descriptive statistics for CO2 emission estimates
*          Produces tables (CSV) and figures (PNG) for all groupings:
*          (1) Aggregate by year — full vs. cleaned sample, Spec 1 vs Spec 2
*          (2) By ISIC2 industry
*          (3) By province (dprovi)
*          (4) By ISIC2 × province (top cells)
*          (5) Per-fuel emission totals: Spec 1 vs Spec 2
*          (6) Correlation with value added (vtlvcu) and labor (ltlnou)
* Input:   output/si_energy_emissions.dta
* Output:  output/tables/desc_*.csv
*          output/figures/figD*.png
* Author:  Albert Ludi
* Date:    March 2026
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
global data    "$handoff/output"
global tables  "$handoff/output/tables"
global figures "$handoff/output/figures"

capture log close
log using "$logs/12_descriptive_stats.log", replace

* ============================================================
* LOAD DATA
* ============================================================

use "$data/si_energy_emissions.dta", clear

di as txt "=== 12_descriptive_stats.do ==="
di as txt "  Obs loaded: " _N
count if !missing(co2_total_s1)
di as txt "  co2_total_s1 non-missing: " r(N)

* ── Derive isic2 if not already present ─────────────────────────────────────
cap confirm var isic2
if _rc != 0 {
    gen isic2 = int(isic5_raw / 1000) if !missing(isic5_raw)
    label define isic2lbl ///
        15 "15 Food & beverages" ///
        16 "16 Tobacco" ///
        17 "17 Textiles" ///
        18 "18 Wearing apparel" ///
        19 "19 Leather & footwear" ///
        20 "20 Wood products" ///
        21 "21 Paper & paper products" ///
        22 "22 Printing & publishing" ///
        23 "23 Coke & refined petroleum" ///
        24 "24 Chemicals" ///
        25 "25 Rubber & plastics" ///
        26 "26 Non-metallic minerals" ///
        27 "27 Basic metals" ///
        28 "28 Fabricated metals" ///
        29 "29 Machinery & equipment" ///
        30 "30 Office machinery" ///
        31 "31 Electrical machinery" ///
        32 "32 Radio, TV & comm equip" ///
        33 "33 Medical instruments" ///
        34 "34 Motor vehicles" ///
        35 "35 Other transport equip" ///
        36 "36 Furniture & other" ///
        37 "37 Recycling", replace
    label values isic2 isic2lbl
    di as txt "  isic2 derived from isic5_raw"
}

* ── Province name mapping ────────────────────────────────────────────────────
* BPS province codes for 2000-2014 (before 2008 splits; 33 provinces)
cap drop prov_name
gen prov_name = ""
replace prov_name = "Nanggroe Aceh Darussalam"   if dprovi == 11
replace prov_name = "Sumatera Utara"              if dprovi == 12
replace prov_name = "Sumatera Barat"              if dprovi == 13
replace prov_name = "Riau"                        if dprovi == 14
replace prov_name = "Jambi"                       if dprovi == 15
replace prov_name = "Sumatera Selatan"            if dprovi == 16
replace prov_name = "Bengkulu"                    if dprovi == 17
replace prov_name = "Lampung"                     if dprovi == 18
replace prov_name = "Bangka Belitung"             if dprovi == 19
replace prov_name = "Kepulauan Riau"              if dprovi == 21
replace prov_name = "DKI Jakarta"                 if dprovi == 31
replace prov_name = "Jawa Barat"                  if dprovi == 32
replace prov_name = "Jawa Tengah"                 if dprovi == 33
replace prov_name = "D.I. Yogyakarta"             if dprovi == 34
replace prov_name = "Jawa Timur"                  if dprovi == 35
replace prov_name = "Banten"                      if dprovi == 36
replace prov_name = "Bali"                        if dprovi == 51
replace prov_name = "Nusa Tenggara Barat"         if dprovi == 52
replace prov_name = "Nusa Tenggara Timur"         if dprovi == 53
replace prov_name = "Kalimantan Barat"            if dprovi == 61
replace prov_name = "Kalimantan Tengah"           if dprovi == 62
replace prov_name = "Kalimantan Selatan"          if dprovi == 63
replace prov_name = "Kalimantan Timur"            if dprovi == 64
replace prov_name = "Sulawesi Utara"              if dprovi == 71
replace prov_name = "Sulawesi Tengah"             if dprovi == 72
replace prov_name = "Sulawesi Selatan"            if dprovi == 73
replace prov_name = "Sulawesi Tenggara"           if dprovi == 74
replace prov_name = "Gorontalo"                   if dprovi == 75
replace prov_name = "Sulawesi Barat"              if dprovi == 76
replace prov_name = "Maluku"                      if dprovi == 81
replace prov_name = "Maluku Utara"                if dprovi == 82
replace prov_name = "Papua Barat"                 if dprovi == 91
replace prov_name = "Papua"                       if dprovi == 94
* Handle any missing codes
replace prov_name = "Unknown (code " + string(dprovi) + ")" if missing(prov_name) & !missing(dprovi)

di as txt "  Province codes mapped. Check unmatched:"
count if missing(prov_name)
di as txt "  Obs with missing prov_name: " r(N)

* ── Sample flags ─────────────────────────────────────────────────────────────
* Full sample: all 314,576 obs in si_energy_emissions.dta (already cleaned)
* The flagged dataset (352,485) is not loaded here; si_energy_emissions.dta = cleaned
gen byte in_cleaned = 1   // all obs here are the cleaned sample
di as txt "  All obs in this dataset are the cleaned sample (N=314,576)"
di as txt "  Full flagged sample stats will be noted from 08/09 logs where needed"

* ── FDI status: merge dasing from data8514_SI.dta ───────────────────────────
* dasing = foreign ownership share (%). IMF FDI threshold: >= 10%
* Exploratory only — dasing not currently in si_energy_emissions.dta pipeline.
* Merge in here just for Chapter 9 descriptive FDI section.
di as txt _n "=== MERGE FDI STATUS (dasing from data8514_SI.dta) ==="

tempfile main_with_fdi fdi_tmp
local fdi_ok = 0

* Save current working data to tempfile
save `main_with_fdi'

* Load dasing from data8514_SI.dta
capture {
    use psid year dasing using "$rawdata/data8514_SI.dta", clear
    sort psid year
    save `fdi_tmp'
}
if _rc == 0 {
    local fdi_ok = 1
    di as txt "  dasing loaded from data8514_SI.dta"
}
else {
    di as txt "  [WARNING: dasing not found in data8514_SI.dta — FDI sections skipped]"
}

* Reload main data and merge
use `main_with_fdi', clear
if `fdi_ok' {
    merge 1:1 psid year using `fdi_tmp', keep(1 3) nogen
    gen byte fdi_firm = (dasing >= 10 & !missing(dasing))
    label var dasing   "Foreign ownership share (%)"
    label var fdi_firm "FDI firm dummy (foreign ownership >= 10%; IMF threshold)"
    count if fdi_firm == 1 & !missing(co2_total_s1)
    di as txt "  FDI firm-years (dasing >= 10, non-missing CO2): " r(N)
    count if fdi_firm == 0 & !missing(co2_total_s1)
    di as txt "  Domestic firm-years (dasing < 10): " r(N)
    count if missing(dasing) & !missing(co2_total_s1)
    di as txt "  Missing dasing (with CO2 data): " r(N)
}
else {
    gen byte fdi_firm = .
    gen double dasing = .
    label var fdi_firm "FDI dummy — MISSING (dasing merge failed)"
}

* ============================================================
* TABLE D1 — AGGREGATE BY YEAR: Spec 1 vs Spec 2
* ============================================================

di as txt _n "=== TABLE D1: Aggregate CO2 by year ==="

preserve
    * Using co2_total_s1 (Spec 1) for consistency with D2–D5; time-varying EF comparison is in 11_sensitivity_variants.do
    collapse (sum) co2_total_s1_sum      = co2_total_s1   ///
                   co2_total_s2_sum      = co2_total_s2   ///
                   co2_scope1_s1_sum     = co2_scope1_s1  ///
                   co2_scope2_s1_sum     = co2_scope2_s1  ///
             (median) co2_total_s1_med   = co2_total_s1   ///
                      co2_total_s2_med   = co2_total_s2   ///
             (mean)   co2_total_s1_mean  = co2_total_s1   ///
                      co2_total_s2_mean  = co2_total_s2   ///
             (p95)    co2_total_s1_p95   = co2_total_s1   ///
             (count)  n_firms            = co2_total_s1   ///
             if !missing(co2_total_s1), by(year)

    * Convert sum to thousand tCO2e for readability
    foreach v in co2_total_s1_sum co2_total_s2_sum co2_scope1_s1_sum co2_scope2_s1_sum {
        replace `v' = `v' / 1000   // thousand tCO2e
    }

    label var co2_total_s1_sum   "Total CO2e (000 tCO2e) — Spec 1"
    label var co2_total_s2_sum   "Total CO2e (000 tCO2e) — Spec 2"
    label var co2_scope1_s1_sum  "Scope 1 CO2e (000 tCO2e) — Spec 1"
    label var co2_scope2_s1_sum  "Scope 2 CO2e (000 tCO2e) — Spec 1"
    label var co2_total_s1_med   "Median total CO2e per firm (tCO2e) — Spec 1"
    label var co2_total_s2_med   "Median total CO2e per firm (tCO2e) — Spec 2"
    label var co2_total_s1_mean  "Mean total CO2e per firm (tCO2e) — Spec 1"
    label var co2_total_s2_mean  "Mean total CO2e per firm (tCO2e) — Spec 2"
    label var co2_total_s1_p95   "P95 total CO2e per firm (tCO2e) — Spec 1"
    label var n_firms            "N firm-years with non-missing total CO2e"

    list year n_firms co2_total_s1_sum co2_total_s2_sum co2_total_s1_med co2_total_s1_mean, noobs sep(0)
    export delimited using "$tables/desc_aggregate_by_year.csv", replace
    di as txt "  → output/tables/desc_aggregate_by_year.csv"
restore

* ============================================================
* TABLE D2 — BY ISIC2: Emissions summary
* ============================================================

di as txt _n "=== TABLE D2: CO2 by ISIC2 ==="

preserve
    keep if !missing(co2_total_s1) & !missing(isic2)
    collapse (sum)    co2_total_s1_sum  = co2_total_s1   ///
                      co2_scope1_s1_sum = co2_scope1_s1  ///
                      co2_scope2_s1_sum = co2_scope2_s1  ///
             (median) co2_total_med     = co2_total_s1   ///
             (mean)   co2_total_mean    = co2_total_s1   ///
             (p25)    co2_total_p25     = co2_total_s1   ///
             (p75)    co2_total_p75     = co2_total_s1   ///
             (p95)    co2_total_p95     = co2_total_s1   ///
             (count)  n_firmyears       = co2_total_s1   ///
             (sum)    vtlvcu_sum        = vtlvcu         ///
             (median) ltlnou_med        = ltlnou         ///
             , by(isic2)
    gsort -co2_total_s1_sum

    * Convert sums to thousand tCO2e
    foreach v in co2_total_s1_sum co2_scope1_s1_sum co2_scope2_s1_sum {
        replace `v' = `v' / 1000
    }

    list isic2 n_firmyears co2_total_s1_sum co2_total_med co2_total_mean co2_total_p95, noobs sep(0)
    export delimited using "$tables/desc_by_isic2.csv", replace
    di as txt "  → output/tables/desc_by_isic2.csv"
restore

* ============================================================
* TABLE D3 — BY PROVINCE: Emissions summary
* ============================================================

di as txt _n "=== TABLE D3: CO2 by province ==="

preserve
    keep if !missing(co2_total_s1) & !missing(dprovi)
    collapse (sum)    co2_total_s1_sum  = co2_total_s1   ///
                      co2_scope1_s1_sum = co2_scope1_s1  ///
                      co2_scope2_s1_sum = co2_scope2_s1  ///
             (median) co2_total_med     = co2_total_s1   ///
             (mean)   co2_total_mean    = co2_total_s1   ///
             (count)  n_firmyears       = co2_total_s1   ///
             (sum)    vtlvcu_sum        = vtlvcu         ///
             , by(dprovi prov_name)
    gsort -co2_total_s1_sum

    foreach v in co2_total_s1_sum co2_scope1_s1_sum co2_scope2_s1_sum {
        replace `v' = `v' / 1000
    }

    list dprovi prov_name n_firmyears co2_total_s1_sum co2_total_med, noobs sep(0)
    export delimited using "$tables/desc_by_province.csv", replace
    di as txt "  → output/tables/desc_by_province.csv"
restore

* ============================================================
* TABLE D4 — BY ISIC2 × PROVINCE: Top 20 cells
* ============================================================

di as txt _n "=== TABLE D4: CO2 by ISIC2 × province (top 20) ==="

preserve
    keep if !missing(co2_total_s1) & !missing(isic2) & !missing(dprovi)
    collapse (sum)  co2_total_s1_sum = co2_total_s1 ///
             (count) n_firmyears     = co2_total_s1 ///
             , by(isic2 dprovi prov_name)
    replace co2_total_s1_sum = co2_total_s1_sum / 1000
    gsort -co2_total_s1_sum
    keep if _n <= 20
    list isic2 prov_name n_firmyears co2_total_s1_sum, noobs sep(0)
    export delimited using "$tables/desc_by_isic2_province.csv", replace
    di as txt "  → output/tables/desc_by_isic2_province.csv"
restore

* ============================================================
* TABLE D5 — PER-FUEL TOTALS: Spec 1 vs Spec 2
* ============================================================

di as txt _n "=== TABLE D5: Per-fuel emission totals Spec 1 vs Spec 2 ==="

preserve
    * Sum each fuel CO2 variable across all firm-years
    local fuels    diesel petrol kerosene coal lpg gas
    local scope2   scope2

    * Spec 1
    foreach f in `fuels' {
        quietly sum co2_`f'_s1 if !missing(co2_`f'_s1)
        local s1_`f'_sum = r(sum) / 1000       // 000 tCO2e
        local s1_`f'_n   = r(N)
        di as txt "  co2_`f'_s1: N=" r(N) "  sum=" %15.1fc r(sum)/1000 " (000 tCO2e)"
    }
    quietly sum co2_scope2_s1 if !missing(co2_scope2_s1)
    local s1_scope2_sum = r(sum) / 1000
    local s1_scope2_n   = r(N)

    * Spec 2
    foreach f in `fuels' {
        cap quietly sum co2_`f'_s2 if !missing(co2_`f'_s2)
        if _rc == 0 {
            local s2_`f'_sum = r(sum) / 1000
            local s2_`f'_n   = r(N)
        }
        else {
            local s2_`f'_sum = .
            local s2_`f'_n   = .
        }
    }
    cap quietly sum co2_scope2_s2 if !missing(co2_scope2_s2)
    if _rc == 0 {
        local s2_scope2_sum = r(sum) / 1000
        local s2_scope2_n   = r(N)
    }

    * Build a small dataset for export
    clear
    set obs 7
    gen str15 fuel     = ""
    gen str30 variable = ""
    gen double n_firmyears_s1 = .
    gen double total_s1       = .
    gen double total_s2       = .
    gen double pct_diff       = .

    local row = 1
    foreach f in diesel petrol kerosene coal lpg gas {
        replace fuel     = "`f'"                     in `row'
        replace variable = "co2_`f'_s[12]"           in `row'
        replace n_firmyears_s1 = `s1_`f'_n'          in `row'
        replace total_s1 = `s1_`f'_sum'              in `row'
        cap replace total_s2 = `s2_`f'_sum'          in `row'
        replace pct_diff = 100*(total_s2/total_s1 - 1) in `row' if !missing(total_s2) & !missing(total_s1)
        local ++row
    }
    replace fuel     = "electricity"                 in 7
    replace variable = "co2_scope2_s[12]"            in 7
    replace n_firmyears_s1 = `s1_scope2_n'           in 7
    replace total_s1 = `s1_scope2_sum'               in 7
    replace total_s2 = `s2_scope2_sum'               in 7
    replace pct_diff = 100*(total_s2/total_s1 - 1)   in 7 if !missing(total_s2)

    label var fuel          "Fuel type"
    label var n_firmyears_s1 "N firm-years with positive emissions (Spec 1)"
    label var total_s1      "Total CO2e (000 tCO2e) — Spec 1"
    label var total_s2      "Total CO2e (000 tCO2e) — Spec 2"
    label var pct_diff      "Spec 2 vs Spec 1 (% difference)"

    list, noobs sep(0)
    export delimited using "$tables/desc_perfuel_spec1_vs_spec2.csv", replace
    di as txt "  → output/tables/desc_perfuel_spec1_vs_spec2.csv"
restore

* ============================================================
* TABLE D6 — CORRELATION: CO2 vs value added and labor
* ============================================================

di as txt _n "=== TABLE D6: Correlations — ln CO2 vs ln vtlvcu / ln ltlnou ==="

preserve
    keep if !missing(ln_co2_total_s1) & !missing(vtlvcu) & !missing(ltlnou) ///
          & vtlvcu > 0 & ltlnou > 0

    gen ln_vtlvcu = ln(vtlvcu)
    gen ln_ltlnou = ln(ltlnou)

    label var ln_vtlvcu "Log value added (vtlvcu)"
    label var ln_ltlnou "Log total workers (ltlnou)"

    * Pooled correlations
    di as txt "  --- Pooled correlations ---"
    corr ln_co2_total_s1 ln_co2_total_s2 ln_vtlvcu ln_ltlnou

    * Save pooled correlation matrix manually
    matrix C = r(C)
    local n_corr = r(N)
    di as txt "  N observations for correlation: " `n_corr'

    * Build correlation table for export
    local varlist ln_co2_total_s1 ln_co2_total_s2 ln_vtlvcu ln_ltlnou
    local k = 4
    matrix rownames C = "ln_co2_s1" "ln_co2_s2" "ln_va" "ln_workers"
    matrix colnames C = "ln_co2_s1" "ln_co2_s2" "ln_va" "ln_workers"

    clear
    svmat double C, names(col)
    gen str20 variable = ""
    replace variable = "ln_co2_total_s1" in 1
    replace variable = "ln_co2_total_s2" in 2
    replace variable = "ln_vtlvcu"       in 3
    replace variable = "ln_ltlnou"       in 4
    order variable
    export delimited using "$tables/desc_correlation_pooled.csv", replace
    di as txt "  → output/tables/desc_correlation_pooled.csv (N=" `n_corr' ")"
restore

* Within-year correlations — use postfile to avoid nested preserve
preserve
    keep if !missing(ln_co2_total_s1) & !missing(vtlvcu) & !missing(ltlnou) ///
          & vtlvcu > 0 & ltlnou > 0
    gen ln_vtlvcu = ln(vtlvcu)
    gen ln_ltlnou = ln(ltlnou)

    tempname corr_hdl
    tempfile  corr_by_year
    postfile `corr_hdl' int year_val int n_obs double corr_va double corr_lab ///
        using `corr_by_year', replace

    levelsof year, local(years)
    foreach y of local years {
        qui count if year == `y'
        local N_y = r(N)
        if `N_y' > 5 {
            qui corr ln_co2_total_s1 ln_vtlvcu ln_ltlnou if year == `y'
            local r_va  = r(C)[1,2]
            local r_lab = r(C)[1,3]
        }
        else {
            local r_va  = .
            local r_lab = .
        }
        post `corr_hdl' (`y') (`N_y') (`r_va') (`r_lab')
    }
    postclose `corr_hdl'

    use `corr_by_year', clear
    sort year_val
    label var year_val          "Year"
    label var n_obs             "N obs (non-missing ln CO2 + ln VA + ln labor)"
    label var corr_va           "Corr(ln CO2, ln value added)"
    label var corr_lab          "Corr(ln CO2, ln workers)"
    list, noobs sep(0)
    export delimited using "$tables/desc_correlation_by_year.csv", replace
    di as txt "  → output/tables/desc_correlation_by_year.csv"
restore

* ============================================================
* FIGURE D1 — Total CO2e by year, Spec 1 vs Spec 2
* ============================================================

di as txt _n "=== FIGURE D1: Total CO2 by year, Spec 1 vs Spec 2 ==="

preserve
    keep if !missing(co2_total_s1)
    collapse (sum) s1 = co2_total_s1 s2 = co2_total_s2, by(year)
    replace s1 = s1 / 1e6   // million tCO2e
    replace s2 = s2 / 1e6

    twoway (connected s1 year, lcolor(navy) mcolor(navy) msymbol(circle)) ///
           (connected s2 year, lcolor(cranberry) mcolor(cranberry) msymbol(diamond) lpattern(dash)), ///
        xlabel(2000(2)2014) ///
        ylabel(, format(%9.1f) labsize(small)) ///
        xtitle("Year") ytitle("Million tCO{sub:2}e", size(small)) ///
        yscale(titlegap(5)) ///
        title("Total Manufacturing CO{sub:2}e — SI Panel (Cleaned Sample, N=314,576)", size(medsmall)) ///
        subtitle("Scope 1 + Scope 2; positive reporters only", size(small)) ///
        legend(order(1 "Spec 1 (IPCC + BPS Neraca, primary)" 2 "Spec 2 (IPCC + ESDM HEES, robustness)") ///
               position(6) rows(1) size(small)) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD1_total_co2_by_year.png", replace width(1200) height(700)
    di as txt "  → output/figures/figD1_total_co2_by_year.png"
restore

* ============================================================
* FIGURE D2 — Median CO2e by ISIC2 (horizontal bar)
* ============================================================

di as txt _n "=== FIGURE D2: Median CO2 by ISIC2 ==="

preserve
    keep if !missing(co2_total_s1) & !missing(isic2)
    collapse (median) med_co2 = co2_total_s1 ///
             (count)  n_fy    = co2_total_s1, by(isic2)
    keep if n_fy >= 100   // keep only industries with ≥100 firm-years
    gen log_med_co2 = log(med_co2)

    * Sort ascending so the highest bar appears at the top in a horizontal chart
    gsort log_med_co2
    gen order = _n
    local n_isic = _N

    * Build ylabel list dynamically from the data (maps order → ISIC label)
    local ylabs ""
    forval i = 1/`n_isic' {
        local code = isic2[`i']
        local lname : label isic2lbl `code'
        local ylabs `"`ylabs' `i' "`lname'""'
    }

    twoway (bar log_med_co2 order, horizontal barwidth(0.7) ///
            color(navy%70) lcolor(navy%30)), ///
        ylabel(`ylabs', angle(0) labsize(vsmall) nogrid) ///
        xtitle("Log median tCO{sub:2}e") ytitle("") ///
        title("Median Total CO{sub:2}e by ISIC2 Industry", size(medium)) ///
        subtitle("Cleaned sample; industries with {&ge}100 firm-years; Spec 1", size(small)) ///
        scheme(s2color) graphregion(color(white)) plotregion(margin(l=2))
    graph export "$figures/figD2_median_co2_by_isic2.png", replace width(1400) height(900)
    di as txt "  → output/figures/figD2_median_co2_by_isic2.png"
restore

* ============================================================
* FIGURE D3 — Total CO2e by province (top 15)
* ============================================================

di as txt _n "=== FIGURE D3: Total CO2e by province ==="

preserve
    keep if !missing(co2_total_s1) & !missing(dprovi)
    collapse (sum) total_co2 = co2_total_s1 ///
             (count) n_fy    = co2_total_s1 ///
             , by(dprovi prov_name)
    replace total_co2 = total_co2 / 1000   // 000 tCO2e
    gsort -total_co2
    keep if _n <= 15
    gen province_label = prov_name

    gen order_var = _n
    gen log_total = log(total_co2)

    twoway (bar total_co2 order_var, horizontal barwidth(0.7) ///
            color(teal%70) lcolor(teal%20)), ///
        ylabel(1/15, valuelabel angle(0) labsize(small)) ///
        ytick(1/15, grid) ///
        xtitle("000 tCO₂e (pooled 2000–2014)") ytitle("") ///
        title("Total CO₂e by Province — Top 15") ///
        subtitle("Cleaned sample; Spec 1; pooled 2000–2014") ///
        scheme(s2color) graphregion(color(white))
    * Note: ylabel by number requires manually replacing with names
    * We export the data with prov_name for QMD table instead
    graph export "$figures/figD3_total_co2_by_province.png", replace width(1200) height(700)
    di as txt "  → output/figures/figD3_total_co2_by_province.png"
restore

* ============================================================
* FIGURE D4 — Scatter: ln CO2 vs ln value added (pooled)
* ============================================================

di as txt _n "=== FIGURE D4: Scatter ln_co2 vs ln_vtlvcu ==="

preserve
    keep if !missing(ln_co2_total_s1) & !missing(vtlvcu) & vtlvcu > 0
    gen ln_vtlvcu = ln(vtlvcu)
    * Thin to 10% sample for scatter readability
    set seed 42
    sample 10
    twoway (scatter ln_co2_total_s1 ln_vtlvcu, ///
                msize(tiny) mcolor(navy%50) msymbol(smcircle)) ///
           (lfit ln_co2_total_s1 ln_vtlvcu, lcolor(cranberry) lwidth(medthick)), ///
        xtitle("Log value added (ln vtlvcu)") ///
        ytitle("Log total CO₂e (ln co2_total_s1)") ///
        title("CO₂e vs. Value Added") ///
        subtitle("10% random sample of cleaned firm-years; OLS fit line") ///
        legend(off) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD4_co2_vs_va.png", replace width(900) height(700)
    di as txt "  → output/figures/figD4_co2_vs_va.png"
restore

* ============================================================
* FIGURE D5 — Scatter: ln CO2 vs ln labor (ltlnou)
* ============================================================

di as txt _n "=== FIGURE D5: Scatter ln_co2 vs ln_ltlnou ==="

preserve
    keep if !missing(ln_co2_total_s1) & !missing(ltlnou) & ltlnou > 0
    gen ln_ltlnou = ln(ltlnou)
    set seed 42
    sample 10
    twoway (scatter ln_co2_total_s1 ln_ltlnou, ///
                msize(tiny) mcolor(teal%50) msymbol(smcircle)) ///
           (lfit ln_co2_total_s1 ln_ltlnou, lcolor(cranberry) lwidth(medthick)), ///
        xtitle("Log total workers (ln ltlnou)") ///
        ytitle("Log total CO₂e (ln co2_total_s1)") ///
        title("CO₂e vs. Employment") ///
        subtitle("10% random sample of cleaned firm-years; OLS fit line") ///
        legend(off) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD5_co2_vs_labor.png", replace width(900) height(700)
    di as txt "  → output/figures/figD5_co2_vs_labor.png"
restore

* ============================================================
* FIGURE D1b — Scope 1 vs Scope 2 decomposition by year (Spec 1)
* ============================================================

di as txt _n "=== FIGURE D1b: Scope 1 vs Scope 2 decomposition by year ==="

preserve
    keep if !missing(co2_scope1_s1) | !missing(co2_scope2_s1)
    collapse (sum) s1_scope1 = co2_scope1_s1 ///
                   s1_scope2 = co2_scope2_s1 ///
                   s1_total  = co2_total_s1  ///
             , by(year)
    foreach v in s1_scope1 s1_scope2 s1_total {
        replace `v' = `v' / 1e6   // million tCO2e
    }

    export delimited using "$tables/desc_scope_decomp_by_year.csv", replace
    di as txt "  → output/tables/desc_scope_decomp_by_year.csv"

    twoway (connected s1_total  year, lcolor(navy)     mcolor(navy)     msymbol(circle)   lwidth(medthick)) ///
           (connected s1_scope1 year, lcolor(dkorange)  mcolor(dkorange) msymbol(square)   lpattern(dash)) ///
           (connected s1_scope2 year, lcolor(teal)      mcolor(teal)     msymbol(triangle) lpattern(shortdash)), ///
        xlabel(2000(2)2014, labsize(small)) ///
        ylabel(, format(%9.2f) labsize(small)) ///
        xtitle("Year") ytitle("Million tCO{sub:2}e", size(small)) ///
        title("Scope 1 vs. Scope 2 Decomposition — Spec 1", size(medsmall)) ///
        subtitle("Direct fuel combustion (Scope 1) vs. purchased electricity (Scope 2)", size(small)) ///
        legend(order(1 "Total (Scope 1+2)" 2 "Scope 1 — Direct fuels" 3 "Scope 2 — Electricity") ///
               position(6) rows(1) size(small)) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD1b_scope_decomp_by_year.png", replace width(1200) height(700)
    di as txt "  → output/figures/figD1b_scope_decomp_by_year.png"
restore

* ============================================================
* FIGURE D1c — Per-fuel Scope 1 time series
* ============================================================

di as txt _n "=== FIGURE D1c: Per-fuel Scope 1 emissions by year ==="

preserve
    collapse (sum) diesel   = co2_diesel_s1   ///
                   coal     = co2_coal_s1     ///
                   petrol   = co2_petrol_s1   ///
                   kerosene = co2_kerosene_s1 ///
                   lpg      = co2_lpg_s1      ///
                   gas      = co2_gas_s1      ///
             , by(year)
    foreach v in diesel coal petrol kerosene lpg gas {
        replace `v' = `v' / 1000   // 000 tCO2e
    }

    export delimited using "$tables/desc_perfuel_s1_by_year.csv", replace
    di as txt "  → output/tables/desc_perfuel_s1_by_year.csv"

    twoway (connected coal     year, lcolor(gs6)      mcolor(gs6)      msymbol(circle)   lwidth(medthick)) ///
           (connected diesel   year, lcolor(dkorange)  mcolor(dkorange) msymbol(square)   lwidth(medthick)) ///
           (connected petrol   year, lcolor(cranberry) mcolor(cranberry) msymbol(diamond) lpattern(dash)) ///
           (connected kerosene year, lcolor(green)     mcolor(green)    msymbol(triangle) lpattern(dash)) ///
           (connected gas      year, lcolor(teal)      mcolor(teal)     msymbol(plus)     lpattern(shortdash)) ///
           (connected lpg      year, lcolor(purple)    mcolor(purple)   msymbol(smcircle) lpattern(shortdash_dot)), ///
        xlabel(2000(2)2014, labsize(small)) ///
        ylabel(, format(%9.0fc) labsize(small)) ///
        xtitle("Year") ytitle("000 tCO{sub:2}e", size(small)) ///
        title("Per-Fuel Scope 1 Emissions — Spec 1", size(medsmall)) ///
        subtitle("Direct combustion only; positive reporters; 000 tCO2e by year", size(small)) ///
        note("Gas and LPG available from 2006 only (survey design)", size(vsmall)) ///
        legend(order(1 "Coal" 2 "Diesel" 3 "Petrol" 4 "Kerosene" 5 "City gas" 6 "LPG") ///
               position(6) rows(1) size(small)) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD1c_perfuel_s1_by_year.png", replace width(1200) height(700)
    di as txt "  → output/figures/figD1c_perfuel_s1_by_year.png"
restore

* ============================================================
* FIGURE D2b — Top-sector ISIC time series (Scope 1 & 2 share)
* ============================================================

di as txt _n "=== FIGURE D2b: ISIC Scope 1 vs Scope 2 share (cross-section) ==="

* Panel A: Scope share by ISIC2 (cross-sectional bar)
preserve
    keep if !missing(co2_total_s1) & !missing(isic2) & co2_total_s1 > 0
    collapse (sum) scope1_sum = co2_scope1_s1 scope2_sum = co2_scope2_s1 ///
                   total_sum  = co2_total_s1 (count) n_fy = co2_total_s1 ///
             , by(isic2)
    keep if n_fy >= 500   // ISIC groups with enough observations
    gen scope2_share = scope2_sum / total_sum * 100
    gsort -scope2_share
    gen order = _n
    local n_isic = _N

    local ylabs ""
    forval i = 1/`n_isic' {
        local code = isic2[`i']
        local lname : label isic2lbl `code'
        local ylabs `"`ylabs' `i' "`lname'""'
    }

    twoway (bar scope2_share order, horizontal barwidth(0.7) color(teal%70) lcolor(teal%20)), ///
        ylabel(`ylabs', angle(0) labsize(vsmall) nogrid) ///
        xline(50, lcolor(red) lpattern(dash) lwidth(thin)) ///
        xtitle("Scope 2 share of total CO{sub:2}e (%)") ytitle("") ///
        title("Electricity (Scope 2) Share by ISIC2", size(medium)) ///
        subtitle("Pooled 2000–2014; industries with {&ge}500 firm-years; Spec 1", size(small)) ///
        note("Red dashed line = 50% threshold", size(vsmall)) ///
        scheme(s2color) graphregion(color(white)) plotregion(margin(l=2))
    export delimited using "$tables/desc_scope_share_by_isic2.csv", replace
    graph export "$figures/figD2b_scope_share_by_isic2.png", replace width(1400) height(900)
    di as txt "  → output/figures/figD2b_scope_share_by_isic2.png"
    di as txt "  → output/tables/desc_scope_share_by_isic2.csv"
restore

* Panel B: Top 5 ISIC by total CO2, time series
di as txt "  --- Top-5 ISIC time series ---"

preserve
    * Top 5 ISIC by total pooled CO2: Textiles (17), Food & bev (15),
    * Basic metals (27), Chemicals (24), Rubber & plastics (25)
    keep if inlist(isic2, 15, 17, 24, 25, 27) & !missing(co2_total_s1)
    collapse (sum) total = co2_total_s1, by(year isic2)
    replace total = total / 1000   // 000 tCO2e
    reshape wide total, i(year) j(isic2)
    rename total15 isic15
    rename total17 isic17
    rename total24 isic24
    rename total25 isic25
    rename total27 isic27

    export delimited using "$tables/desc_top5isic_by_year.csv", replace
    di as txt "  → output/tables/desc_top5isic_by_year.csv"

    twoway (connected isic17 year, lcolor(navy)    mcolor(navy)    msymbol(circle)) ///
           (connected isic15 year, lcolor(dkorange) mcolor(dkorange) msymbol(square)) ///
           (connected isic25 year, lcolor(teal)     mcolor(teal)    msymbol(triangle)) ///
           (connected isic24 year, lcolor(cranberry) mcolor(cranberry) msymbol(diamond) lpattern(dash)) ///
           (connected isic27 year, lcolor(purple)   mcolor(purple)  msymbol(smcircle) lpattern(shortdash)), ///
        xlabel(2000(2)2014, labsize(small)) ///
        ylabel(, format(%9.0fc) labsize(small)) ///
        xtitle("Year") ytitle("000 tCO{sub:2}e", size(small)) ///
        title("Total CO{sub:2}e by Year — Top 5 ISIC Sectors", size(medsmall)) ///
        subtitle("Scope 1 + Scope 2; Spec 1; 000 tCO2e", size(small)) ///
        legend(order(1 "17 Textiles" 2 "15 Food & bev" 3 "25 Rubber & plastics" ///
                     4 "24 Chemicals" 5 "27 Basic metals") ///
               position(6) rows(2) size(small)) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD2c_top5isic_trend.png", replace width(1200) height(700)
    di as txt "  → output/figures/figD2c_top5isic_trend.png"
restore

* ============================================================
* FIGURE D6b + TABLE D6c — Carbon intensity time series
* ============================================================

di as txt _n "=== FIGURE D6b: Carbon intensity time series ==="

preserve
    keep if !missing(co2_total_s1) & vtlvcu > 0 & !missing(vtlvcu)
    * Carbon intensity: tCO2e per million Rp of output
    gen ci_va = co2_total_s1 / (vtlvcu / 1000)   // tCO2e per million Rp
    * Alternative: tCO2e per worker
    gen ci_lbr = co2_total_s1 / ltlnou if ltlnou > 0 & !missing(ltlnou)

    collapse (median) med_ci_va  = ci_va    ///
                      med_ci_lbr = ci_lbr   ///
             (p25)    p25_ci_va  = ci_va    ///
             (p75)    p75_ci_va  = ci_va    ///
             (count)  n_fy       = ci_va    ///
             , by(year)

    export delimited using "$tables/desc_carbon_intensity_by_year.csv", replace
    di as txt "  → output/tables/desc_carbon_intensity_by_year.csv"

    twoway (rarea p25_ci_va p75_ci_va year, color(navy%15) lwidth(none)) ///
           (connected med_ci_va year, lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medthick)), ///
        xlabel(2000(2)2014, labsize(small)) ///
        ylabel(, format(%9.1f) labsize(small)) ///
        xtitle("Year") ytitle("tCO{sub:2}e per million Rp output", size(small)) ///
        title("Median Carbon Intensity by Year", size(medsmall)) ///
        subtitle("tCO{sub:2}e per million Rp gross output; shaded band = IQR (P25–P75); Spec 1", size(small)) ///
        note("Deflated output not used (nominal Rp); interpret trend cautiously re: inflation.", size(vsmall)) ///
        legend(order(1 "IQR (P25–P75)" 2 "Median") position(6) rows(1) size(small)) ///
        scheme(s2color) graphregion(color(white))
    graph export "$figures/figD6b_carbon_intensity_by_year.png", replace width(1200) height(700)
    di as txt "  → output/figures/figD6b_carbon_intensity_by_year.png"
restore

* ============================================================
* TABLE D7 + FIGURE D7 — FDI vs. domestic firm comparison
* ============================================================

di as txt _n "=== TABLE D7 / FIGURE D7: FDI vs. domestic emissions ==="

if !missing(fdi_firm[1]) | (fdi_firm[1] != .) {
    * Check we have usable FDI data
    count if fdi_firm == 1 & !missing(co2_total_s1)
    if r(N) > 0 {

        * --- Table D7a: Summary statistics by FDI status ---
        preserve
            keep if !missing(fdi_firm) & !missing(co2_total_s1)
            gen ci_va = co2_total_s1 / (vtlvcu / 1000) if vtlvcu > 0 & !missing(vtlvcu)
            collapse (count)  n_fy       = co2_total_s1 ///
                     (median) med_total  = co2_total_s1 ///
                     (median) med_scope1 = co2_scope1_s1 ///
                     (median) med_scope2 = co2_scope2_s1 ///
                     (median) med_ci     = ci_va         ///
                     (mean)   mean_total = co2_total_s1  ///
                     (sum)    sum_scope1 = co2_scope1_s1 ///
                     (sum)    sum_scope2 = co2_scope2_s1 ///
                     , by(fdi_firm)
            * Scope 2 share of total
            gen scope2_share = sum_scope2 / (sum_scope1 + sum_scope2) * 100
            export delimited using "$tables/desc_fdi_summary.csv", replace
            di as txt "  → output/tables/desc_fdi_summary.csv"
            list, noobs sep(0)
        restore

        * --- Table D7b: FDI share and emission trend by year ---
        preserve
            keep if !missing(fdi_firm) & !missing(co2_total_s1)
            gen ci_va = co2_total_s1 / (vtlvcu / 1000) if vtlvcu > 0 & !missing(vtlvcu)
            collapse (count)  n_fy      = co2_total_s1 ///
                     (median) med_total = co2_total_s1 ///
                     (median) med_ci    = ci_va        ///
                     , by(year fdi_firm)
            reshape wide n_fy med_total med_ci, i(year) j(fdi_firm)
            rename n_fy0     n_domestic
            rename n_fy1     n_fdi
            rename med_total0 med_total_dom
            rename med_total1 med_total_fdi
            rename med_ci0   med_ci_dom
            rename med_ci1   med_ci_fdi
            gen fdi_share = n_fdi / (n_domestic + n_fdi) * 100
            export delimited using "$tables/desc_fdi_by_year.csv", replace
            di as txt "  → output/tables/desc_fdi_by_year.csv"
        restore

        * --- Figure D7a: FDI share over time ---
        preserve
            keep if !missing(fdi_firm)
            collapse (count) n_total = fdi_firm ///
                     (sum)   n_fdi   = fdi_firm ///
                     , by(year)
            gen fdi_share = n_fdi / n_total * 100
            twoway (connected fdi_share year, lcolor(navy) mcolor(navy) msymbol(circle) lwidth(medthick)), ///
                xlabel(2000(2)2014, labsize(small)) ///
                ylabel(0(5)30, labsize(small)) ///
                xtitle("Year") ytitle("FDI firm share (%)", size(small)) ///
                title("Share of FDI Firms by Year", size(medsmall)) ///
                subtitle("FDI defined as foreign ownership {&ge} 10% (dasing {&ge} 10)", size(small)) ///
                scheme(s2color) graphregion(color(white))
            graph export "$figures/figD7a_fdi_share_by_year.png", replace width(900) height(600)
            di as txt "  → output/figures/figD7a_fdi_share_by_year.png"
        restore

        * --- Figure D7b: Median CO2 total — FDI vs domestic by year ---
        preserve
            keep if !missing(fdi_firm) & !missing(co2_total_s1)
            gen ci_va = co2_total_s1 / (vtlvcu / 1000) if vtlvcu > 0 & !missing(vtlvcu)
            collapse (median) med_total = co2_total_s1 ///
                              med_ci    = ci_va        ///
                     , by(year fdi_firm)

            * Panel 1: Median total CO2
            twoway (connected med_total year if fdi_firm == 1, ///
                        lcolor(cranberry) mcolor(cranberry) msymbol(circle) lwidth(medthick)) ///
                   (connected med_total year if fdi_firm == 0, ///
                        lcolor(navy) mcolor(navy) msymbol(square) lpattern(dash)), ///
                xlabel(2000(2)2014, labsize(small)) ///
                ylabel(, format(%9.0fc) labsize(small)) ///
                xtitle("Year") ytitle("Median tCO{sub:2}e per firm", size(small)) ///
                title("Median Emissions: FDI vs. Domestic Firms", size(medsmall)) ///
                subtitle("Spec 1; positive CO2 reporters; FDI = foreign ownership {&ge} 10%", size(small)) ///
                legend(order(1 "FDI firms" 2 "Domestic firms") position(6) rows(1) size(small)) ///
                scheme(s2color) graphregion(color(white))
            graph export "$figures/figD7b_fdi_vs_domestic_co2.png", replace width(1000) height(650)
            di as txt "  → output/figures/figD7b_fdi_vs_domestic_co2.png"

            * Panel 2: Median carbon intensity — FDI vs domestic
            twoway (connected med_ci year if fdi_firm == 1 & !missing(med_ci), ///
                        lcolor(cranberry) mcolor(cranberry) msymbol(circle) lwidth(medthick)) ///
                   (connected med_ci year if fdi_firm == 0 & !missing(med_ci), ///
                        lcolor(navy) mcolor(navy) msymbol(square) lpattern(dash)), ///
                xlabel(2000(2)2014, labsize(small)) ///
                ylabel(, format(%9.1f) labsize(small)) ///
                xtitle("Year") ytitle("Median tCO{sub:2}e per million Rp output", size(small)) ///
                title("Carbon Intensity: FDI vs. Domestic Firms", size(medsmall)) ///
                subtitle("Spec 1; tCO2e per million Rp gross output; FDI = foreign ownership {&ge} 10%", size(small)) ///
                note("Nominal output — interpret cautiously re: inflation across years.", size(vsmall)) ///
                legend(order(1 "FDI firms" 2 "Domestic firms") position(6) rows(1) size(small)) ///
                scheme(s2color) graphregion(color(white))
            graph export "$figures/figD7c_fdi_vs_domestic_ci.png", replace width(1000) height(650)
            di as txt "  → output/figures/figD7c_fdi_vs_domestic_ci.png"
        restore
    }
    else {
        di as txt "  [SKIP: No FDI firm-years with CO2 data — check dasing variable]"
    }
}
else {
    di as txt "  [SKIP: fdi_firm missing — dasing merge was not successful]"
}

* ============================================================
* FINAL SUMMARY
* ============================================================

di as txt _n "============================================================"
di as txt "  12_descriptive_stats.do COMPLETE"
di as txt "  Tables:"
di as txt "    desc_aggregate_by_year.csv          (§9.1)"
di as txt "    desc_scope_decomp_by_year.csv        (§9.2)"
di as txt "    desc_perfuel_s1_by_year.csv          (§9.3)"
di as txt "    desc_by_isic2.csv                    (§9.4)"
di as txt "    desc_scope_share_by_isic2.csv        (§9.4)"
di as txt "    desc_top5isic_by_year.csv            (§9.5)"
di as txt "    desc_by_province.csv                 (§9.6)"
di as txt "    desc_by_isic2_province.csv           (§9.7)"
di as txt "    desc_carbon_intensity_by_year.csv    (§9.8)"
di as txt "    desc_fdi_summary.csv                 (§9.9 — exploratory)"
di as txt "    desc_fdi_by_year.csv                 (§9.9 — exploratory)"
di as txt "    desc_perfuel_spec1_vs_spec2.csv      (§9.10)"
di as txt "    desc_correlation_pooled.csv          (§9.11)"
di as txt "    desc_correlation_by_year.csv         (§9.11)"
di as txt "  Figures:"
di as txt "    figD1_total_co2_by_year.png          (§9.1)"
di as txt "    figD1b_scope_decomp_by_year.png      (§9.2)"
di as txt "    figD1c_perfuel_s1_by_year.png        (§9.3)"
di as txt "    figD2_median_co2_by_isic2.png        (§9.4)"
di as txt "    figD2b_scope_share_by_isic2.png      (§9.4)"
di as txt "    figD2c_top5isic_trend.png            (§9.5)"
di as txt "    figD3_total_co2_by_province.png      (§9.6)"
di as txt "    figD4_co2_vs_va.png                  (§9.11)"
di as txt "    figD5_co2_vs_labor.png               (§9.11)"
di as txt "    figD6b_carbon_intensity_by_year.png  (§9.8)"
di as txt "    figD7a_fdi_share_by_year.png         (§9.9 — exploratory)"
di as txt "    figD7b_fdi_vs_domestic_co2.png       (§9.9 — exploratory)"
di as txt "    figD7c_fdi_vs_domestic_ci.png        (§9.9 — exploratory)"
di as txt "============================================================"

log close
