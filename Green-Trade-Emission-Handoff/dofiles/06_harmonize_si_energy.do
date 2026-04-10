* ============================================================
* Script: 06_harmonize_si_energy.do
* Purpose: Apply corrections identified in §4 of the QMD and
*          rename all raw SI energy variables to canonical names
*          that are stable across the 2000–2014 panel.
*
*          Steps:
*            1. Coal unit correction: eclkgu × 1000 for 2004–2005
*            2. Rename all E* variables to canonical names
*            3. Create purchased electricity aggregates
*               - strict variant: missing if any component missing
*               - zerofill variant: treat structural missing as 0
*            4. Own-generated electricity kept as standalone variable
*               (not in Scope 2 aggregate — already counted via fuel)
*            5. Lubricants kept as standalone (non-combustion)
*            6. efuvcu kept as fuel_total_reported_rp (flagged unreliable)
*
*          Decisions from prior research (Natanael, Jan–Feb 2026):
*            - Canonical naming follows prior pipeline convention
*            - strict/zerofill pattern matches prior missingness policy
*            - Own-gen excluded from purchased elec aggregate
*
* Input:   output/si_panel_2000_2014.dta
* Output:  output/si_energy_harmonized.dta
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

log using "$logs/06_harmonize_si_energy.log", replace text

use "$output/si_panel_2000_2014.dta", clear

di as txt "Obs loaded: " _N

* ============================================================
* SECTION 1 — COAL UNIT: NO CORRECTION APPLIED
* ============================================================
* Initial assessment: questionnaire 2004-2005 labels coal unit as "Ton",
*   quantity distribution shows 98% median drop vs. 2003 → appeared to
*   require × 1,000 correction.
*
* Expenditure-based diagnostic (13_coal_correction_check.do) overturns this:
*   Pre-correction implied price (Rp000/unit) in 2004-2005 = 0.750,
*   matching 2003 exactly (0.751). Post-correction price = 0.00075,
*   which is 1/1,000 of adjacent years (ratio = 0.0006).
*   Data was already in Kg; correction would inflate by 1,000x.
*
* Resolution: NO correction applied. eclkgu taken as-reported for all years.
* See §4.1 of data_industry_emission.qmd for full diagnostic.

di as txt _n "=== SECTION 1: Coal unit — NO correction (data already in Kg) ==="

count if year == 2004 & !missing(eclkgu) & eclkgu > 0
di as txt "  2004 coal obs (positive): " r(N)
count if year == 2005 & !missing(eclkgu) & eclkgu > 0
di as txt "  2005 coal obs (positive): " r(N)

* NO correction: lines below intentionally omitted
* replace eclkgu = eclkgu * 1000 if (year == 2004 | year == 2005) & !missing(eclkgu)
* replace eclkge = eclkge * 1000 if (year == 2004 | year == 2005) & !missing(eclkge)

di as txt "  Coal correction NOT applied: data taken as-reported in Kg for all years"

* Verify: median should be consistent across adjacent years (no artificial drop expected)
quietly summarize eclkgu if year == 2003 & eclkgu > 0, detail
di as txt "  eclkgu median 2003 (Kg): " r(p50)
quietly summarize eclkgu if year == 2004 & eclkgu > 0, detail
di as txt "  eclkgu median 2004 (Kg, as-reported): " r(p50)
quietly summarize eclkgu if year == 2006 & eclkgu > 0, detail
di as txt "  eclkgu median 2006 (Kg): " r(p50)

* ============================================================
* SECTION 2 — RENAME: FUEL QUANTITY VARIABLES
* ============================================================
* Naming convention: fuel_{type}_{unit}
*   ltr = liters | kg = kilograms | m3 = cubic metres
* _gen suffix = sub-item for electricity generator use only

di as txt _n "=== SECTION 2: Rename fuel quantity variables ==="

* -- Continuous fuels (2000–2014, no structural gap) --
rename esoliu  fuel_diesel_ltr        // Solar / HSD
rename epeliu  fuel_petrol_ltr        // Bensin / Premium
rename eluliu  fuel_lubricant_ltr     // Pelumas (non-combustion; kept for reference)

* -- Fuels with short gaps (2001–2002 absent) --
rename eoiliu  fuel_kerosene_ltr      // Minyak Tanah
rename eclkgu  fuel_coal_kg           // Batubara (unit-corrected above)

* -- Fuels with long gaps (2001–2005 absent) --
rename egam3u  fuel_citygas_m3        // Gas Kota / PGN
rename elpkgu  fuel_lpg_kg            // LPG

* -- Fuels: late introduction (2012–2014 only) --
rename ecbkgu  fuel_coalbriq_kg       // Briket Batubara
rename egom3u  fuel_othergas_m3       // Gas dari sumber lain (non-PGN)

* -- Fuels: sparse (mostly absent by survey design) --
rename eckkgu  fuel_coke_kg           // Kokas (2000, 2006 only)
rename ecakgu  fuel_charcoal_kg       // Arang / Kayu Bakar (2006 only)
rename ewokgu  fuel_firewood_kg       // Kayu Bakar (2006 only)
rename ediliu  fuel_dieseloil_ltr     // Minyak Diesel / IDO (2000–2001, 2006 only)
rename efoliu  fuel_fueloil_ltr       // Minyak Bakar / Bunker C (2000–2001, 2006 only)

* -- Generator sub-items (fuel consumed for own electricity generation) --
rename esolie  fuel_diesel_ltr_gen
rename epelie  fuel_petrol_ltr_gen
rename eoilie  fuel_kerosene_ltr_gen
rename eclkge  fuel_coal_kg_gen
rename eckkge  fuel_coke_kg_gen
rename ecakge  fuel_charcoal_kg_gen
rename ewokge  fuel_firewood_kg_gen
rename edilie  fuel_dieseloil_ltr_gen
rename efolie  fuel_fueloil_ltr_gen
rename elulie  fuel_lubricant_ltr_gen
rename egam3e  fuel_citygas_m3_gen
rename elpkge  fuel_lpg_kg_gen
rename ecbkge  fuel_coalbriq_kg_gen
rename egom3e  fuel_othergas_m3_gen

* ============================================================
* SECTION 3 — RENAME: FUEL EXPENDITURE VARIABLES (Rp000)
* ============================================================
* Naming convention: fuel_{type}_rp
* _gen suffix = generator sub-item expenditure

di as txt _n "=== SECTION 3: Rename fuel expenditure variables ==="

* -- Main use expenditure --
rename esovcu  fuel_diesel_rp
rename epevcu  fuel_petrol_rp
rename eluvcu  fuel_lubricant_rp
rename eoivcu  fuel_kerosene_rp
rename eclvcu  fuel_coal_rp
rename egavcu  fuel_citygas_rp
rename elpvcu  fuel_lpg_rp
rename ecbvcu  fuel_coalbriq_rp
rename egovcu  fuel_othergas_rp
rename eckvcu  fuel_coke_rp
rename ecavcu  fuel_charcoal_rp
rename ewovcu  fuel_firewood_rp
rename edivcu  fuel_dieseloil_rp
rename efovcu  fuel_fueloil_rp
rename encvcu  fuel_other_rp          // Bahan bakar lainnya (catch-all)
rename efuvcu  fuel_total_reported_rp // Survey total row — independently filled by respondent;
                                       // EXCEEDS component sum by 5–39% across years (ratio 1.05–1.39).
                                       // This confirms it captures fuels without individual survey columns.
                                       // Appropriate for Imbruno-style monetary intensity. See 06_efuvcu_check.do.

* -- Generator sub-item expenditure --
rename esovce  fuel_diesel_rp_gen
rename epevce  fuel_petrol_rp_gen
rename eoivce  fuel_kerosene_rp_gen
rename eclvce  fuel_coal_rp_gen
rename eckvce  fuel_coke_rp_gen
rename ecavce  fuel_charcoal_rp_gen
rename ewovce  fuel_firewood_rp_gen
rename edivce  fuel_dieseloil_rp_gen
rename efovce  fuel_fueloil_rp_gen
rename eluvce  fuel_lubricant_rp_gen
rename egavce  fuel_citygas_rp_gen
rename elpvce  fuel_lpg_rp_gen
rename ecbvce  fuel_coalbriq_rp_gen
rename egovce  fuel_othergas_rp_gen
rename encvce  fuel_other_rp_gen
rename efuvce  fuel_total_reported_rp_gen

* ============================================================
* SECTION 4 — RENAME: ELECTRICITY VARIABLES
* ============================================================
* Naming convention:
*   elec_pln_kwh / elec_pln_rp         = PLN (state grid)
*   elec_nonpln_kwh / elec_nonpln_rp   = non-PLN purchased
*   elec_owngene_kwh                   = own-generated (standalone; NOT in Scope 2)
*   elec_owngene_rp                    = (if available)

di as txt _n "=== SECTION 4: Rename electricity variables ==="

rename eplkhu  elec_pln_kwh
rename eplvcu  elec_pln_rp
rename enpkhu  elec_nonpln_kwh
rename enpvcu  elec_nonpln_rp
rename esgkhu  elec_owngene_kwh       // Own-generated; kept standalone — not in Scope 2 aggregate

* esgans: likely number of generating sets; keep with descriptive name
cap rename esgans elec_owngene_nsets

* ============================================================
* SECTION 5 — PURCHASED ELECTRICITY AGGREGATES
* ============================================================
* Two variants, clearly labelled:
*
* STRICT: aggregate is missing (.) if EITHER component is missing.
*   Use when you want to be conservative — if the questionnaire
*   collected both PLN and non-PLN but one is absent, the total
*   is unknown and should not be treated as zero.
*
* ZEROFILL: structural missing treated as 0.
*   Use for balanced-panel regressions. Flag counts how many
*   components were zero-filled so transparency is maintained.
*
* Own-generated electricity (elec_owngene_kwh) is NOT included
* in either aggregate — it would double-count with Scope 1 fuel
* combustion used to run the generator.

di as txt _n "=== SECTION 5: Purchased electricity aggregates ==="

* -- KwH aggregates --
gen double elec_purchased_kwh_strict = elec_pln_kwh + elec_nonpln_kwh
label variable elec_purchased_kwh_strict "Purchased elec (KwH): PLN+non-PLN; missing if either component missing"

egen double elec_purchased_kwh_zero = rowtotal(elec_pln_kwh elec_nonpln_kwh)
label variable elec_purchased_kwh_zero   "Purchased elec (KwH): PLN+non-PLN; structural missing → 0"

gen byte elec_purchased_kwh_nfilled = missing(elec_pln_kwh) + missing(elec_nonpln_kwh)
label variable elec_purchased_kwh_nfilled "N components zero-filled in elec_purchased_kwh_zero (0/1/2)"

* -- Rp aggregates --
gen double elec_purchased_rp_strict = elec_pln_rp + elec_nonpln_rp
label variable elec_purchased_rp_strict "Purchased elec (Rp000): PLN+non-PLN; missing if either missing"

egen double elec_purchased_rp_zero = rowtotal(elec_pln_rp elec_nonpln_rp)
label variable elec_purchased_rp_zero   "Purchased elec (Rp000): PLN+non-PLN; structural missing → 0"

gen byte elec_purchased_rp_nfilled = missing(elec_pln_rp) + missing(elec_nonpln_rp)
label variable elec_purchased_rp_nfilled "N components zero-filled in elec_purchased_rp_zero (0/1/2)"

* Summary check
di as txt "  elec_purchased_kwh_strict — non-missing obs: "
count if !missing(elec_purchased_kwh_strict)
di as txt "  elec_purchased_kwh_zero   — non-missing obs: " _N

* ============================================================
* SECTION 6 — VARIABLE LABELS (key variables)
* ============================================================

di as txt _n "=== SECTION 6: Variable labels ==="

* Fuel quantities
label variable fuel_diesel_ltr        "Diesel (Solar) — liters; 2000–2014"
label variable fuel_petrol_ltr        "Gasoline (Bensin) — liters; 2000–2014"
label variable fuel_lubricant_ltr     "Lubricant — liters; 2000–2014 (non-combustion; not in Scope 1)"
label variable fuel_kerosene_ltr      "Kerosene (Minyak Tanah) — liters; 2001–2002 absent"
label variable fuel_coal_kg           "Coal (Batubara) — kg; taken as-reported for all years (no unit correction); 2001–2002 absent"
label variable fuel_citygas_m3        "City gas / PGN — m³; 2001–2005 absent"
label variable fuel_lpg_kg            "LPG — kg; 2001–2005 absent"
label variable fuel_coalbriq_kg       "Coal briquettes (Briket) — kg; 2000–2011 absent"
label variable fuel_othergas_m3       "Gas from others (non-PGN) — m³; 2000–2011 absent"
label variable fuel_coke_kg           "Coke (Kokas) — kg; mostly absent (2000, 2006)"
label variable fuel_charcoal_kg       "Charcoal/firewood (Arang) — kg; mostly absent (2006)"
label variable fuel_firewood_kg       "Firewood (Kayu Bakar) — kg; mostly absent (2006)"
label variable fuel_dieseloil_ltr     "Diesel Oil (IDO/ADO) — liters; mostly absent"
label variable fuel_fueloil_ltr       "Fuel Oil / Bunker C — liters; mostly absent"

* Electricity
label variable elec_pln_kwh           "PLN grid electricity — KwH; 2000–2014"
label variable elec_pln_rp            "PLN grid electricity — Rp000; 2000–2014"
label variable elec_nonpln_kwh        "Non-PLN purchased electricity — KwH; 2000–2014"
label variable elec_nonpln_rp         "Non-PLN purchased electricity — Rp000; 2000–2014"
label variable elec_owngene_kwh       "Own-generated electricity — KwH; NOT in purchased aggregate"

* Flag
label variable fuel_total_reported_rp "Survey total fuel expenditure (Rp000) — independently filled; exceeds component sum by 5–39% across years; preferred for Imbruno-style monetary intensity; see 06_efuvcu_check.do"

* ============================================================
* SECTION 7 — SUMMARY STATISTICS
* ============================================================

di as txt _n "=== SECTION 7: Summary — N non-missing by variable group ==="

di as txt _n "  --- Core fuels (quantity, positive obs) ---"
foreach v in fuel_diesel_ltr fuel_petrol_ltr fuel_kerosene_ltr fuel_coal_kg ///
             fuel_citygas_m3 fuel_lpg_kg fuel_coalbriq_kg fuel_othergas_m3 {
    quietly count if !missing(`v') & `v' > 0
    di as txt "  %-35s N_pos = " %8.0fc r(N) "`v'"
}

di as txt _n "  --- Electricity ---"
foreach v in elec_pln_kwh elec_nonpln_kwh elec_owngene_kwh ///
             elec_purchased_kwh_strict elec_purchased_kwh_zero {
    quietly count if !missing(`v') & `v' > 0
    di as txt "  %-40s N_pos = " %8.0fc r(N) "`v'"
}

di as txt _n "  --- elec_purchased_kwh_nfilled distribution ---"
tab elec_purchased_kwh_nfilled

* ============================================================
* SECTION 8 — SAVE
* ============================================================

save "$output/si_energy_harmonized.dta", replace
di as txt _n "Saved: $output/si_energy_harmonized.dta"
di as txt "  Obs: " _N
di as txt "  Vars: " c(k)

log close
