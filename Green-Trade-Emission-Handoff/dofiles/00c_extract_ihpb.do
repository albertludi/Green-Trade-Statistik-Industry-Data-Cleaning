* ============================================================
* 00c_extract_ihpb.do
* Extract IHPB annual averages (2013 & 2014) from BPS Excel files.
* Stata replacement for scripts/extract_ihpb_from_excel.py.
*
* INPUT  : data/ihpb/indeks-harga-perdagangan-besar-indonesia-2013-2-29-34.xlsx
*          data/ihpb/indeks-harga-perdagangan-besar-indonesia-2014 - -2010-100-2-27-32.xlsx
* OUTPUT : data/concordance/ihpb_annual_averages.csv
*
* Excel structure (confirmed from BPS Table 1):
*   Sheet  : "Table 1"
*   Range  : A1:R123 (18 cols, 123 rows incl. header)
*   Col A  : Sub-sector identifier
*             → Sub  1 (Industri Besar dan Sedang aggregate): numeric cell = 1
*             → Subs 2–50 (manufacturing sub-sectors): starts with "N."
*   Col P  : Rata2/Average — annual average WPI index (base 2010=100)
*
* Output columns: ihpb_sub, ihpb_sub_name, ihpb2013, ihpb2014,
*                 base_year, source_2013, source_2014
*
* AUTHOR: Albert Ludi  (replaces scripts/extract_ihpb_from_excel.py)
* DATE  : 2026-04-09
* ============================================================

* ── Paths ───────────────────────────────────────────────────────────────────
if "$handoff" == "" {
    di as error "ERROR: global 'handoff' is not set."
    di as error "       Run: do {path_to_handoff}/00_config.do"
    exit 1
}
global ihpbdir "$handoff/data/ihpb"
global concord "$handoff/data/concordance"
global logs    "$handoff/logs"

cap log close
cap mkdir "$logs"
log using "$logs/00c_extract_ihpb.log", replace text

di as txt "======================================================"
di as txt " 00c_extract_ihpb.do — started: " c(current_date) " " c(current_time)
di as txt "======================================================"

* ── Excel file paths ────────────────────────────────────────────────────────
local xlsx2013 `"$ihpbdir/indeks-harga-perdagangan-besar-indonesia-2013-2-29-34.xlsx"'
local xlsx2014 `"$ihpbdir/indeks-harga-perdagangan-besar-indonesia-2014 - -2010-100-2-27-32.xlsx"'
local source2013 "indeks-harga-perdagangan-besar-indonesia-2013-2-29-34.xlsx"
local source2014 "indeks-harga-perdagangan-besar-indonesia-2014 - -2010-100-2-27-32.xlsx"

foreach yr in 2013 2014 {
    cap confirm file "`xlsx`yr''"
    if _rc != 0 {
        di as error "ERROR: IHPB Excel not found: `xlsx`yr''"
        di as error "       Copy both BPS Excel files to: $ihpbdir"
        log close
        exit 1
    }
}
di as txt "  Both IHPB Excel files confirmed."


* ============================================================
* SECTION 1 — EXTRACT 2013 AVERAGES
* ============================================================
di as txt _n "=== SECTION 1: Extract 2013 IHPB averages ==="

import excel using `"`xlsx2013'"', ///
    sheet("Table 1") cellrange(A1:R123) allstring clear

* import excel without firstrow names variables by Excel column letter: A, B, ..., P, ..., R
rename A col_a
rename P col_p

* Identify sub-sector rows:
*   Sub 1 (aggregate): col_a is a short numeric string (the number "1")
*   Subs 2–50        : col_a starts with "N."
gen byte subsec = 0
replace subsec = 1 if real(col_a) < . & real(col_a) >= 1     // sub 1 (numeric)
replace subsec = 1 if regexm(strtrim(col_a), "^[0-9]+\.")     // subs 2–50 (e.g. "2.   Industri...")

keep if subsec == 1 & col_p != "" & strtrim(col_p) != "."

if _N != 50 {
    di as error "ERROR: Expected 50 IHPB sub-sectors, found " _N
    di as error "       Check Excel file structure."
    log close
    exit 1
}
di as txt "  Sub-sectors identified: " _N " (correct — should be 50)"

* Sequential sub-sector number
gen ihpb_sub = _n

* Sub-sector name: sub 1 gets the standard aggregate name; rest use col_a
gen ihpb_sub_name = strtrim(col_a)
replace ihpb_sub_name = "Industri Besar dan Sedang" if real(col_a) < .

* IHPB annual average 2013
gen double ihpb2013 = real(col_p)

* Spot-check first 5 subs (from prior validation):
di as txt "  Spot-check (sub 1–5 expected: 120.9 126.61 113.74 99.29 111.99):"
list ihpb_sub ihpb2013 in 1/5, noobs clean

local n_missing = 0
qui count if missing(ihpb2013)
local n_missing = r(N)
if `n_missing' > 0 {
    di as error "  WARNING: " `n_missing' " missing ihpb2013 values"
}

keep ihpb_sub ihpb_sub_name ihpb2013

tempfile ihpb2013
save `ihpb2013'


* ============================================================
* SECTION 2 — EXTRACT 2014 AVERAGES
* ============================================================
di as txt _n "=== SECTION 2: Extract 2014 IHPB averages ==="

import excel using `"`xlsx2014'"', ///
    sheet("Table 1") cellrange(A1:R123) allstring clear

rename A col_a
rename P col_p

gen byte subsec = 0
replace subsec = 1 if real(col_a) < . & real(col_a) >= 1
replace subsec = 1 if regexm(strtrim(col_a), "^[0-9]+\.")     // subs 2–50 (e.g. "2.   Industri...")

keep if subsec == 1 & col_p != "" & strtrim(col_p) != "."

if _N != 50 {
    di as error "ERROR: Expected 50 IHPB sub-sectors in 2014, found " _N
    log close
    exit 1
}
di as txt "  Sub-sectors identified: " _N " (correct)"

gen ihpb_sub = _n
gen double ihpb2014 = real(col_p)

di as txt "  Spot-check (sub 1–3, 2014):"
list ihpb_sub ihpb2014 in 1/3, noobs clean

keep ihpb_sub ihpb2014

tempfile ihpb2014
save `ihpb2014'


* ============================================================
* SECTION 3 — MERGE AND EXPORT CSV
* ============================================================
di as txt _n "=== SECTION 3: Merge and export CSV ==="

use `ihpb2013', clear
merge 1:1 ihpb_sub using `ihpb2014', nogen
assert _N == 50

* Add metadata columns (mirrors Python output format)
gen base_year  = 2010
gen source_2013 = "`source2013'"
gen source_2014 = "`source2014'"

label var ihpb_sub      "BPS IHPB manufacturing sub-sector number (1–50)"
label var ihpb_sub_name "Sub-sector name (BPS)"
label var ihpb2013      "IHPB annual average 2013 (base 2010=100)"
label var ihpb2014      "IHPB annual average 2014 (base 2010=100)"
label var base_year     "IHPB base year"

order ihpb_sub ihpb_sub_name ihpb2013 ihpb2014 base_year source_2013 source_2014

export delimited using "$concord/ihpb_annual_averages.csv", replace

di as txt "  Exported: $concord/ihpb_annual_averages.csv"
di as txt "  Obs: " _N "  (should be 50)"

* Final validation: check against expected values from Python extraction
di as txt _n "  Full sub-sector table:"
list ihpb_sub ihpb2013 ihpb2014, noobs clean

di as txt _n "======================================================"
di as txt " 00c_extract_ihpb.do — completed: " c(current_date) " " c(current_time)
di as txt "======================================================"

log close
