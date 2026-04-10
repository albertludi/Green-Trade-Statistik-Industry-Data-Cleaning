* ============================================================
* 15_extend_wpio_ihpb.do
* Extend WPI deflator (wpio.dta) from 1983–2012 to 1983–2014
* using BPS IHPB chain-linking at 4-digit ISIC level.
*
* INPUT  : data/raw/wpio.dta                          ($rawdata)
*          data/concordance/ihpb_isic4_concordance.csv ($concord)
*          data/concordance/ihpb_annual_averages.csv   ($concord) ← extracted from BPS Excel by 00b_extract_ihpb.do
* OUTPUT : output/wpio_extended.dta                   ($output)
*
* Methodology
* -----------
* Stage 1 (1983–2012): unchanged from wpio.dta (Imbruno & Ketterer 2018 style)
*
* Stage 2 (2013–2014): chain-link from 2010 base using BPS IHPB annual
* averages (Indeks Harga Perdagangan Besar, base 2010=100):
*
*   wpi_t = wpi2010 × (IHPB_t / 100),   t ∈ {2013, 2014}
*
* where IHPB_t is the annual average of the corresponding BPS manufacturing
* sub-sector (sub 1–50). When two IHPB sub-sectors jointly represent an
* ISIC4 code (ihpb_sub2 non-missing), the arithmetic mean is used.
*
* ISIC 3710, 3720 (Recycling) have no IHPB sub-sector; for these two codes
* 2013–2014 are extrapolated via 2010–2012 CAGR (same as prior approach).
*
* Source: BPS, Indeks Harga Perdagangan Besar Indonesia 2013 & 2014
*         (2010=100). Annual averages extracted from Table 1 of each publication
*         via scripts/extract_ihpb_from_excel.py → ihpb_annual_averages.csv.
* Concordance: data8514_SI/ihpb_isic4_concordance.csv
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

cap log close
log using "$logs/15_extend_wpio_ihpb.log", replace text

di as txt "======================================================"
di as txt " 15_extend_wpio_ihpb.do — started: " c(current_date) " " c(current_time)
di as txt "======================================================"


* ============================================================
* SECTION 1 — IHPB ANNUAL AVERAGES (base 2010=100)
* Source: BPS IHPB publications 2013 & 2014, Table 1 ("Rata2/Average" column)
* Extracted by scripts/extract_ihpb_from_excel.py from original BPS Excel files:
*   - indeks-harga-perdagangan-besar-indonesia-2013-2-29-34.xlsx
*   - indeks-harga-perdagangan-besar-indonesia-2014 - -2010-100-2-27-32.xlsx
* Output: data8514_SI/ihpb_annual_averages.csv
* ============================================================

di as txt _n "=== SECTION 1: Load IHPB lookup from CSV ==="

import delimited "$concord/ihpb_annual_averages.csv", ///
    varnames(1) encoding("UTF-8") clear

* Keep only the columns needed downstream
keep ihpb_sub ihpb2013 ihpb2014
* Force numeric (trailing empty row from export delimited may cause string import)
cap destring ihpb_sub ihpb2013 ihpb2014, replace force
drop if missing(ihpb_sub)   // drop trailing empty row

label var ihpb_sub  "BPS IHPB manufacturing sub-sector number (1–50)"
label var ihpb2013  "IHPB annual average 2013 (base 2010=100)"
label var ihpb2014  "IHPB annual average 2014 (base 2010=100)"

qui count
di as txt "  IHPB lookup loaded: " r(N) " sub-sectors × 2 years"
assert r(N) == 50

tempfile ihpb_lookup
save `ihpb_lookup'


* ============================================================
* SECTION 2 — LOAD CONCORDANCE
* Maps each ISIC4 to ihpb_sub (primary), ihpb_sub2 (secondary, if any),
* or "CAGR" for codes with no IHPB sub-sector.
* ============================================================

di as txt _n "=== SECTION 2: Load concordance ==="

import delimited "$concord/ihpb_isic4_concordance.csv", ///
    varnames(1) stringcols(_all) clear

rename isic4    isic4_str
destring isic4_str, gen(isic4)
drop isic4_str

* Flag CAGR codes (ISIC 3710, 3720)
gen cagr_flag = (ihpb_sub == "CAGR")

* Convert ihpb_sub to numeric (CAGR → missing)
destring ihpb_sub,  gen(ihpb_sub1)  force
destring ihpb_sub2, gen(ihpb_sub2n) force

keep isic4 ihpb_sub1 ihpb_sub2n cagr_flag notes

tempfile concordance
save `concordance'
qui count
di as txt "  Concordance loaded: " r(N) " ISIC4 codes"
qui count if cagr_flag
di as txt "  CAGR codes (ISIC 37): " r(N)


* ============================================================
* SECTION 3 — LOAD WPIO AND MERGE CONCORDANCE
* ============================================================

di as txt _n "=== SECTION 3: Load wpio.dta ==="

use "$rawdata/wpio.dta", clear
rename isic isic4

merge 1:1 isic4 using `concordance', nogen
di as txt "  wpio merged with concordance"


* ============================================================
* SECTION 4 — MERGE PRIMARY IHPB VALUES
* ============================================================

di as txt _n "=== SECTION 4: Merge IHPB values ==="

* Primary IHPB sub-sector
rename ihpb_sub1 ihpb_sub
merge m:1 ihpb_sub using `ihpb_lookup', keep(master match) nogen
rename ihpb_sub  ihpb_sub1
rename ihpb2013  ihpb2013_1
rename ihpb2014  ihpb2014_1

qui count if !missing(ihpb2013_1) & !cagr_flag
di as txt "  Primary IHPB matched: " r(N) " codes"

* Secondary IHPB sub-sector (for average-of-two cases)
rename ihpb_sub2n ihpb_sub
merge m:1 ihpb_sub using `ihpb_lookup', keep(master match) nogen
rename ihpb_sub  ihpb_sub2n
rename ihpb2013  ihpb2013_2
rename ihpb2014  ihpb2014_2

qui count if !missing(ihpb2013_2)
di as txt "  Secondary IHPB matched (avg-of-two cases): " r(N) " codes"


* ============================================================
* SECTION 5 — COMPUTE EFFECTIVE IHPB RATES
* ============================================================

di as txt _n "=== SECTION 5: Compute effective IHPB rates ==="

* Default: use primary only
gen ihpb_eff_2013 = ihpb2013_1
gen ihpb_eff_2014 = ihpb2014_1

* Average when secondary exists
replace ihpb_eff_2013 = (ihpb2013_1 + ihpb2013_2) / 2 if !missing(ihpb_sub2n)
replace ihpb_eff_2014 = (ihpb2014_1 + ihpb2014_2) / 2 if !missing(ihpb_sub2n)

qui count if !missing(ihpb_eff_2013) & !cagr_flag
di as txt "  Effective IHPB rate computed for: " r(N) " codes (IHPB path)"


* ============================================================
* SECTION 6 — CHAIN-LINK: EXTEND WPI TO 2013–2014
* ============================================================

di as txt _n "=== SECTION 6: Chain-link extension ==="

* IHPB path: wpi_t = wpi2010 × (IHPB_t / 100)
gen double wpi2013 = wpi2010 * (ihpb_eff_2013 / 100) if !cagr_flag
gen double wpi2014 = wpi2010 * (ihpb_eff_2014 / 100) if !cagr_flag

* CAGR fallback for ISIC 37 (Recycling)
gen double _g = (wpi2012 / wpi2010)^0.5 if cagr_flag
replace    wpi2013 = wpi2012 * _g        if cagr_flag
replace    wpi2014 = wpi2013 * _g        if cagr_flag
drop _g

qui count if missing(wpi2013)
di as txt "  Missing wpi2013 after extension: " r(N) " (should be 0)"

* Spot check: ISIC 37 used CAGR
di as txt "  ISIC 37 CAGR check (wpi2012 → wpi2013 → wpi2014):"
list isic4 wpi2010 wpi2012 wpi2013 wpi2014 if inlist(isic4, 3710, 3720), ///
    noobs clean


* ============================================================
* SECTION 7 — CLEAN UP AND SAVE
* ============================================================

di as txt _n "=== SECTION 7: Save wpio_extended.dta ==="

* Drop working variables
drop ihpb_sub1 ihpb_sub2n ihpb2013_1 ihpb2014_1 ihpb2013_2 ihpb2014_2 ///
     ihpb_eff_2013 ihpb_eff_2014 cagr_flag notes

* Restore original variable name
rename isic4 isic

* Labels
label var wpi2013 "WPI 2013 (base 2000=100, chain-linked from IHPB 2013)"
label var wpi2014 "WPI 2014 (base 2000=100, chain-linked from IHPB 2014)"
label data "wpio extended to 2014: IHPB chain-link (2013-14) + original (1983-2012)"

order isic wpi1983-wpi2012 wpi2013 wpi2014

compress
save "$output/wpio_extended.dta", replace

di as txt "  Saved: $output/wpio_extended.dta"
di as txt "  Variables: isic + wpi1983–wpi2014 (32 WPI columns)"
qui des
di as txt "  Obs: " r(N) ", Vars: " r(k)

di as txt _n "======================================================"
di as txt " 15_extend_wpio_ihpb.do — completed: " c(current_date) " " c(current_time)
di as txt "======================================================"

log close
