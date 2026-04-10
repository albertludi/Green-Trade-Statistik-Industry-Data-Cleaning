* ============================================================
* Script: 18_fig_unit_price.do
* Purpose: Unit price heterogeneity across industries and provinces.
*   Panel A: Diesel unit price by ISIC2 (sorted by median, descending)
*   Panel B: Diesel unit price by province (sorted West→East, then price)
*   Panel C: PLN electricity unit price by ISIC2
*   Panel D: PLN electricity unit price by province
*
* Unit prices: expenditure (Rp000) ÷ physical quantity, winsorised p1–p99.
*   Diesel     : fuel_diesel_rp  / fuel_diesel_ltr  → Rp000/litre
*   Electricity: elec_pln_rp     / elec_pln_kwh     → Rp000/kWh
*
* Input:   output/si_energy_emissions.dta
* Output:  output/figures/fig_unit_price_heterogeneity.png
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
log using "$logs/18_fig_unit_price.log", replace text

use "$output/si_energy_emissions.dta", clear

di as txt "=== 18_fig_unit_price.do: Unit price heterogeneity ==="
di as txt "  N = " _N

* ── Unit prices ──────────────────────────────────────────────────────────────
gen double p_diesel = fuel_diesel_rp / fuel_diesel_ltr ///
    if fuel_diesel_ltr > 0 & fuel_diesel_rp > 0 & !missing(fuel_diesel_ltr, fuel_diesel_rp)
label var p_diesel "Diesel unit price (Rp000/litre)"

gen double p_elec = elec_pln_rp / elec_pln_kwh ///
    if elec_pln_kwh > 0 & elec_pln_rp > 0 & !missing(elec_pln_kwh, elec_pln_rp)
label var p_elec "PLN electricity unit price (Rp000/kWh)"

* ── Winsorise at p1–p99 ──────────────────────────────────────────────────────
foreach v in p_diesel p_elec {
    quietly su `v', detail
    replace `v' = r(p1)  if `v' < r(p1)  & !missing(`v')
    replace `v' = r(p99) if `v' > r(p99) & !missing(`v')
}

* ── ISIC 2-digit labels ───────────────────────────────────────────────────────
cap confirm var isic2
if _rc != 0 gen isic2 = int(isic5_raw / 1000)

cap label drop isic2lbl
label define isic2lbl ///
     1  "1 — Agriculture"        ///
     2  "2 — Forestry"           ///
     3  "3 — Fishing"            ///
    15  "15 — Food & Bev."       ///
    16  "16 — Tobacco"           ///
    17  "17 — Textiles"          ///
    18  "18 — Apparel"           ///
    19  "19 — Leather"           ///
    20  "20 — Wood"              ///
    21  "21 — Paper"             ///
    22  "22 — Publishing"        ///
    23  "23 — Coke & Petrol."    ///
    24  "24 — Chemicals"         ///
    25  "25 — Rubber & Plast."   ///
    26  "26 — Non-met. Min."     ///
    27  "27 — Basic Metals"      ///
    28  "28 — Fab. Metals"       ///
    29  "29 — Machinery"         ///
    30  "30 — Office Mach."      ///
    31  "31 — Elec. Mach."       ///
    32  "32 — Electronics"       ///
    33  "33 — Instruments"       ///
    34  "34 — Motor Veh."        ///
    35  "35 — Othr. Transport"   ///
    36  "36 — Furniture"         ///
    37  "37 — Recycling"         ///
    93  "93 — Other Svcs."
label values isic2 isic2lbl

* ── Province labels and island-group sort key ────────────────────────────────
* Island rank (higher = more West = higher on chart):
* Sumatera=6, Jawa=5, Bali+NT=4, Kalimantan=3, Sulawesi=2, Maluku=1, Papua=0
cap drop island_rank
gen island_rank = .
replace island_rank = 6 if inrange(dprovi, 11, 21)   // Sumatera
replace island_rank = 5 if inrange(dprovi, 31, 36)   // Jawa
replace island_rank = 4 if inrange(dprovi, 51, 53)   // Bali + Nusa Tenggara
replace island_rank = 3 if inrange(dprovi, 61, 65)   // Kalimantan
replace island_rank = 2 if inrange(dprovi, 71, 76)   // Sulawesi
replace island_rank = 1 if inrange(dprovi, 81, 82)   // Maluku
replace island_rank = 0 if inrange(dprovi, 91, 94)   // Papua

cap label drop provlbl
label define provlbl ///
    11 "Aceh"              12 "Sumatera Utara"     13 "Sumatera Barat"  ///
    14 "Riau"              15 "Jambi"              16 "Sumatera Selatan" ///
    17 "Bengkulu"          18 "Lampung"            19 "Bangka-Belitung" ///
    20 "Kep. Riau (lama)"  21 "Kepulauan Riau"    ///
    31 "DKI Jakarta"       32 "Jawa Barat"         33 "Jawa Tengah"     ///
    34 "Yogyakarta"        35 "Jawa Timur"          36 "Banten"          ///
    51 "Bali"              52 "NTB"                53 "NTT"             ///
    61 "Kalimantan Barat"  62 "Kalimantan Tengah"  63 "Kalimantan Selatan" ///
    64 "Kalimantan Timur"  65 "Kalimantan Utara"  ///
    71 "Sulawesi Utara"    72 "Sulawesi Tengah"    73 "Sulawesi Selatan" ///
    74 "Sulawesi Tenggara" 75 "Gorontalo"          76 "Sulawesi Barat"  ///
    81 "Maluku"            82 "Maluku Utara"       ///
    91 "Papua Barat"       92 "Papua (lama)"       93 "Papua Tengah"    ///
    94 "Papua"
label values dprovi provlbl

* Province sort key: within each island group, sort by median price ascending
* (lower price = lower position on chart within that group)
* Composite: island_rank * 1000 + rank_within_island (higher island_rank = top)
foreach price in p_diesel p_elec {
    quietly {
        bysort dprovi: egen med_`price'_prov = median(`price')
        bysort island_rank (med_`price'_prov): gen rank_`price'_prov = _n
        gen sort_`price'_prov = island_rank * 1000 + rank_`price'_prov
    }
}

* ── Panel A: Diesel by ISIC2 ──────────────────────────────────────────────────
preserve
    keep if !missing(p_diesel) & !missing(isic2)
    * Filter to at least 20 obs per ISIC for reliable boxplot
    bysort isic2: gen n_isic = _N
    keep if n_isic >= 20

    graph hbox p_diesel,                                        ///
        over(isic2, sort(1) descending                         ///
            label(labsize(tiny) angle(0)))                     ///
        box(1, fcolor("67 93 142%60") lcolor("46 74 126"))     ///
        marker(1, msize(tiny) mcolor("46 74 126%40"))          ///
        medtype(cline) medline(lcolor(white) lwidth(medthick)) ///
        ytitle("Rp000 / litre", size(small))                   ///
        title("Diesel — by Industry", size(medsmall)           ///
              color(black) margin(b=2))                        ///
        note("Sorted by median (descending). Min. 20 obs per group.", ///
             size(tiny))                                       ///
        graphregion(margin(l=35))                              ///
        scheme(s1color) name(pA, replace)
restore

* ── Panel B: Diesel by Province (West → East, then price) ────────────────────
preserve
    keep if !missing(p_diesel) & !missing(dprovi) & !missing(island_rank)
    bysort dprovi: gen n_prov = _N
    keep if n_prov >= 20

    graph hbox p_diesel,                                        ///
        over(dprovi, sort(sort_p_diesel_prov)                  ///
            label(labsize(tiny) angle(0)))                     ///
        box(1, fcolor("67 93 142%60") lcolor("46 74 126"))     ///
        marker(1, msize(tiny) mcolor("46 74 126%40"))          ///
        medtype(cline) medline(lcolor(white) lwidth(medthick)) ///
        ytitle("Rp000 / litre", size(small))                   ///
        title("Diesel — by Province", size(medsmall)           ///
              color(black) margin(b=2))                        ///
        note("Sorted by island group (W→E), then price. Min. 20 obs.", ///
             size(tiny))                                       ///
        graphregion(margin(l=45))                              ///
        scheme(s1color) name(pB, replace)
restore

* ── Panel C: PLN Electricity by ISIC2 ────────────────────────────────────────
preserve
    keep if !missing(p_elec) & !missing(isic2)
    bysort isic2: gen n_isic = _N
    keep if n_isic >= 20

    graph hbox p_elec,                                          ///
        over(isic2, sort(1) descending                         ///
            label(labsize(tiny) angle(0)))                     ///
        box(1, fcolor("42 125 111%60") lcolor("30 100 89"))    ///
        marker(1, msize(tiny) mcolor("30 100 89%40"))          ///
        medtype(cline) medline(lcolor(white) lwidth(medthick)) ///
        ytitle("Rp000 / kWh", size(small))                     ///
        title("PLN Electricity — by Industry", size(medsmall)  ///
              color(black) margin(b=2))                        ///
        note("Sorted by median (descending). Min. 20 obs per group.", ///
             size(tiny))                                       ///
        graphregion(margin(l=35))                              ///
        scheme(s1color) name(pC, replace)
restore

* ── Panel D: PLN Electricity by Province ─────────────────────────────────────
preserve
    keep if !missing(p_elec) & !missing(dprovi) & !missing(island_rank)
    bysort dprovi: gen n_prov = _N
    keep if n_prov >= 20

    graph hbox p_elec,                                          ///
        over(dprovi, sort(sort_p_elec_prov)                    ///
            label(labsize(tiny) angle(0)))                     ///
        box(1, fcolor("42 125 111%60") lcolor("30 100 89"))    ///
        marker(1, msize(tiny) mcolor("30 100 89%40"))          ///
        medtype(cline) medline(lcolor(white) lwidth(medthick)) ///
        ytitle("Rp000 / kWh", size(small))                     ///
        title("PLN Electricity — by Province", size(medsmall)  ///
              color(black) margin(b=2))                        ///
        note("Sorted by island group (W→E), then price. Min. 20 obs.", ///
             size(tiny))                                       ///
        graphregion(margin(l=45))                              ///
        scheme(s1color) name(pD, replace)
restore

* ── Combine 4 panels ─────────────────────────────────────────────────────────
graph combine pA pB pC pD,                                         ///
    cols(2)                                                         ///
    title("Price Variation by Industry and Geography"               ///
          "{it:Median unit price (IQR), SI panel 2000–2014}",       ///
          size(medsmall) margin(b=2))                               ///
    note("Source: si_energy_emissions.dta · Do-file: 18_fig_unit_price.do" ///
         "Unit prices = expenditure (Rp000) ÷ physical quantity, winsorised p1–p99." ///
         "Province order: Sumatera (West) → Jawa → Bali+NT → Kalimantan → Sulawesi → Maluku → Papua (East).", ///
         size(vsmall))                                              ///
    xsize(16) ysize(20)

graph export "$figures/fig_unit_price_heterogeneity.png", replace width(2400)
di as txt "Saved: $figures/fig_unit_price_heterogeneity.png"

graph drop pA pB pC pD

di as txt _n "======================================================"
di as txt " 18_fig_unit_price.do — done: " c(current_date) " " c(current_time)
di as txt "======================================================"

log close
