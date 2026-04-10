* ============================================================
* 16_energy_intensity.do
* Construct energy intensity measures: monetary (Imbruno 2018)
* and physical (CO2-based), then compare the two.
*
* INPUT : output/si_energy_emissions.dta
* OUTPUT: output/si_energy_intensity.dta
*
* Two intensity measures:
*   (A) Monetary  — (fuel_rp + elec_rp) / output  [Imbruno 2018]
*         Main spec  : elec_purchased_rp_zero   (structural missing → 0)
*         Robustness : elec_purchased_rp_strict  (missing if either missing)
*   (B) Physical  — co2_total / output  [proxy for GJ/output]
*         Spec 1 (time-varying grid EF) and Spec 2 (static EF)
*
* NOTE on deflation: both numerator and denominator are in nominal Rp.
*   Using the same deflator for both would cancel out (Rp/Rp ratio).
*   Year FE + industry FE in the regression absorb aggregate and
*   industry-level price trends — no separate deflation needed.
*   See Imbruno & Ketterer (2018) fn. 32 for same approach.
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
log using "$logs/16_energy_intensity.log", replace text

di as txt "======================================================"
di as txt " 16_energy_intensity.do — started: " c(current_date) " " c(current_time)
di as txt "======================================================"


* ============================================================
* SECTION 1 — LOAD
* ============================================================

use "$output/si_energy_emissions.dta", clear
di as txt _n "Loaded si_energy_emissions.dta: " _N " obs, " c(k) " vars"

* Derive isic3 from isic5_raw (needed for 3-digit WPI merge in Section 5)
* Note: isic5_raw in early survey years (mainly 2000–2004) was coded at 4 digits
*   (e.g. 1511 instead of 15110), so int(isic5_raw/100) gives a 2-digit result (15).
*   Fix: for 4-digit codes (isic5_raw < 10000) use int(isic5_raw/10) → correct 3-digit (151).
* Residual missing WPI after merge (229 obs):
*   - isic5_raw = 93091 (227 obs, KBLI "Jasa Penunjang Industri", 2010–2014):
*     not a manufacturing ISIC, present in raw data8514_SI.dta — no fix possible.
*   - isic5_raw = 10200 (2 obs, coal mining): clearly miscoded in source data.
cap drop isic3
gen isic3 = int(isic5_raw / 100) if !missing(isic5_raw)
replace isic3 = int(isic5_raw / 10) if isic5_raw < 10000 & !missing(isic5_raw)
label var isic3 "ISIC/KBLI 3-digit industry code (= int(isic5_raw/100), 4-digit codes corrected)"
qui count if !missing(isic3)
di as txt "  isic3 derived: " r(N) " non-missing"
qui count if isic5_raw < 10000 & !missing(isic5_raw)
di as txt "  4-digit isic5_raw corrected (int/10): " r(N) " obs"


* ============================================================
* SECTION 2 — DROP INVALID DENOMINATORS
* ============================================================

* Drop 2 obs with missing output (cannot compute intensity)
drop if missing(output)
di as txt "After dropping missing output: " _N " obs"

* Note: zero-output would also break ratio but confirmed none exist (Section 1 audit)


* ============================================================
* SECTION 3 — MONETARY ENERGY INTENSITY (IMBRUNO APPROACH)
* ============================================================

di as txt _n "=== SECTION 3: Monetary energy intensity ==="

* --- Main spec: elec_zero (structural missing treated as 0) ---
gen double energy_exp_zero = fuel_total_reported_rp + elec_purchased_rp_zero
label var energy_exp_zero "Total energy expenditure Rp000 (fuel + elec_zero)"

gen double ei_monetary_zero = energy_exp_zero / output
label var ei_monetary_zero "Energy intensity: monetary (zero), Rp/Rp"

gen double ln_ei_monetary_zero = ln(ei_monetary_zero)
label var ln_ei_monetary_zero "Log energy intensity: monetary (zero)"

* --- Robustness spec: elec_strict (missing if either component missing) ---
gen double energy_exp_strict = fuel_total_reported_rp + elec_purchased_rp_strict
label var energy_exp_strict "Total energy expenditure Rp000 (fuel + elec_strict)"

gen double ei_monetary_strict = energy_exp_strict / output
label var ei_monetary_strict "Energy intensity: monetary (strict), Rp/Rp"

gen double ln_ei_monetary_strict = ln(ei_monetary_strict)
label var ln_ei_monetary_strict "Log energy intensity: monetary (strict)"

* --- Coverage report ---
di as txt _n "  Coverage — monetary intensity:"
foreach v in ei_monetary_zero ei_monetary_strict {
    qui count if `v' > 0 & !missing(`v')
    local pos = r(N)
    qui count if `v' == 0 & !missing(`v')
    local zero = r(N)
    qui count if missing(`v')
    local miss = r(N)
    di as txt "  `v':  positive=`pos'  zero=`zero'  missing=`miss'"
}

* Flag observations where energy expenditure exceeds output (ratio > 1)
* These are suspicious but kept — flagged for transparency
gen byte flag_ei_gt1_zero   = (ei_monetary_zero   > 1 & !missing(ei_monetary_zero))
gen byte flag_ei_gt1_strict = (ei_monetary_strict > 1 & !missing(ei_monetary_strict))
label var flag_ei_gt1_zero   "Flag: monetary energy intensity (zero) > 1"
label var flag_ei_gt1_strict "Flag: monetary energy intensity (strict) > 1"

qui count if flag_ei_gt1_zero == 1
di as txt _n "  Obs with ei_monetary_zero > 1 (energy cost > output): " r(N)
qui count if flag_ei_gt1_strict == 1
di as txt "  Obs with ei_monetary_strict > 1: " r(N)


* ============================================================
* SECTION 4 — PHYSICAL ENERGY INTENSITY (GJ-BASED)
* ============================================================

di as txt _n "=== SECTION 4: Physical energy intensity (GJ/output) ==="

* NCV values: Spec 1 (BPS Neraca Energi) — same source as 10_carbon_convert.do
* References: QMD §7.5 NCV table; liquid fuels in GJ/kL converted to GJ/liter
local ncv_diesel   = 35.697 / 1000   // GJ/kL → GJ/liter
local ncv_petrol   = 33.225 / 1000   // GJ/kL → GJ/liter
local ncv_kerosene = 34.559 / 1000   // GJ/kL → GJ/liter
local ncv_coal     = 26.200 / 1000   // GJ/tonne → GJ/kg (Kalimantan thermal)
local ncv_lpg      = 45.544 / 1000   // GJ/tonne → GJ/kg
local ncv_citygas  = 0.048            // GJ/m3
local ncv_othergas = 0.048            // GJ/m3 (same as city gas)
local ncv_coalbriq = 29.308 / 1000   // GJ/tonne → GJ/kg (Neraca 2011-2015)
local ncv_coke     = 26.377 / 1000   // GJ/tonne → GJ/kg (Neraca 2011-2015)
local ncv_elec     = 0.0036           // GJ/kWh (1 kWh = 3.6 MJ, unit constant)

* Fuel GJ — same Scope 1 boundary as CO2 pipeline (excludes lubricant, firewood, charcoal)
gen double gj_diesel   = fuel_diesel_ltr   * `ncv_diesel'
gen double gj_petrol   = fuel_petrol_ltr   * `ncv_petrol'
gen double gj_kerosene = fuel_kerosene_ltr * `ncv_kerosene'
gen double gj_coal     = fuel_coal_kg      * `ncv_coal'
gen double gj_lpg      = fuel_lpg_kg       * `ncv_lpg'
gen double gj_citygas  = fuel_citygas_m3   * `ncv_citygas'
gen double gj_othergas = fuel_othergas_m3  * `ncv_othergas'
gen double gj_coalbriq = fuel_coalbriq_kg  * `ncv_coalbriq'
gen double gj_coke     = fuel_coke_kg      * `ncv_coke'

* Scope 2: purchased electricity (zero-filled — same logic as monetary numerator)
* NOTE: uses elec_purchased_kwh_zero here (structural missing → 0), while
*       10_carbon_convert.do uses elec_purchased_kwh_strict for co2_scope2.
*       Coverage difference: 1 firm-year. Both choices are documented and deliberate:
*       GJ intensity follows the monetary spec (zero-fill for balanced coverage);
*       CO2 uses strict to avoid imputing zero electricity when data are truly absent.
gen double gj_elec = elec_purchased_kwh_zero * `ncv_elec'

* Total GJ (Scope 1 + 2)
* missing option: return missing (not 0) when ALL fuel components are missing —
* consistent with co2_scope1 rowtotal in 10_carbon_convert.do
egen double total_gj_s1 = rowtotal(gj_diesel gj_petrol gj_kerosene gj_coal ///
                                    gj_lpg gj_citygas gj_othergas            ///
                                    gj_coalbriq gj_coke gj_elec), missing
label var total_gj_s1 "Total energy (GJ): Scope 1 fuels + purchased elec (Spec 1 NCV)"

* Keep fuel and electricity GJ separately for component analysis
gen double gj_elec_s1 = gj_elec
gen double gj_fuel_s1 = total_gj_s1 - gj_elec_s1
label var gj_elec_s1 "Electricity GJ (Scope 2, Spec 1 NCV): kwh × 0.0036"
label var gj_fuel_s1 "Fuel combustion GJ (Scope 1, Spec 1 NCV): total_gj_s1 − gj_elec_s1"

drop gj_diesel gj_petrol gj_kerosene gj_coal gj_lpg gj_citygas ///
     gj_othergas gj_coalbriq gj_coke gj_elec

* ── Reference GJ variables (NOT in total_gj_s1) ─────────────────────────────
* Computed for reference only — excluded from main analysis for the reasons below.
* NCV sources: IPCC 2006 Guidelines Vol. 2, Table 1.4.
*
* Firewood  (fuel_firewood_kg):  NCV = 15.6 GJ/tonne (IPCC 2006: Wood/Wood Waste)
*   Excluded: biogenic carbon (IPCC Scope 1 convention); quantity data 2006 only.
*
* Charcoal  (fuel_charcoal_kg):  NCV = 29.5 GJ/tonne (IPCC 2006: Charcoal)
*   Excluded: biogenic carbon (IPCC Scope 1 convention); quantity data 2006 only.
*
* Lubricant (fuel_lubricant_ltr): potential heat content = 40.2 GJ/tonne × 0.88 kg/ltr
*   = 0.03538 GJ/ltr (IPCC 2006: Lubricants). NOT an energy input — non-combustion use.
*   GJ figure is theoretical potential heat content only, not actual energy use.

gen double gj_firewood_ref  = fuel_firewood_kg  * (15.6  / 1000)
gen double gj_charcoal_ref  = fuel_charcoal_kg  * (29.5  / 1000)
gen double gj_lubricant_ref = fuel_lubricant_ltr * 0.03538

label var gj_firewood_ref  "Firewood GJ ref (IPCC 15.6 GJ/t, 2006 only, biogenic — NOT in total_gj_s1)"
label var gj_charcoal_ref  "Charcoal GJ ref (IPCC 29.5 GJ/t, 2006 only, biogenic — NOT in total_gj_s1)"
label var gj_lubricant_ref "Lubricant GJ ref (IPCC 40.2 GJ/t × 0.88 kg/ltr, non-combustion — NOT in total_gj_s1)"

qui count if gj_firewood_ref > 0 & !missing(gj_firewood_ref)
di as txt "  gj_firewood_ref: " r(N) " obs with positive values (2006 only)"
qui count if gj_charcoal_ref > 0 & !missing(gj_charcoal_ref)
di as txt "  gj_charcoal_ref: " r(N) " obs with positive values (2006 only)"
qui count if gj_lubricant_ref > 0 & !missing(gj_lubricant_ref)
di as txt "  gj_lubricant_ref: " r(N) " obs with positive values"

* GJ intensity
gen double ei_gj_s1    = total_gj_s1 / output
gen double ln_ei_gj_s1 = ln(ei_gj_s1)
label var ei_gj_s1    "Physical energy intensity: GJ per Rp000 output (Spec 1 NCV)"
label var ln_ei_gj_s1 "Log physical energy intensity: GJ/output (Spec 1 NCV)"

di as txt _n "  Coverage — nominal GJ intensity:"
foreach v in ei_gj_s1 {
    qui count if `v' > 0 & !missing(`v')
    local pos = r(N)
    qui count if `v' == 0 & !missing(`v')
    local zero = r(N)
    qui count if missing(`v')
    local miss = r(N)
    di as txt "  `v':  positive=`pos'  zero=`zero'  missing=`miss'"
}


* ============================================================
* SECTION 5 — WPI DEFLATION OF OUTPUT
* ============================================================
*
* Source: wpio_extended.dta (Imbruno-style WPI, base 2000=100, 4-digit ISIC,
*         1983–2014; 2013–2014 extended from BPS IHPB via chain-linking;
*         CAGR used for ISIC 37 only — see scripts/extend_wpio_ihpb.py)
* Method: collapse to 3-digit ISIC → merge on isic3 × year
*         output_real = output / (wpi / 100)  [2000 Rp000]
*         ei_gj_real  = total_gj_s1 / output_real
*
* NOTE: WPI covers ISIC 15–37 (manufacturing) only. Non-manufacturing obs
*       (isic3 < 151 or > 372) retain missing for output_real and ei_gj_real.

di as txt _n "=== SECTION 5: WPI deflation ==="

* ── Prepare WPI lookup (isic3 × year) ──────────────────────────────────────
preserve
    use "$output/wpio_extended.dta", clear
    gen isic3 = floor(isic / 10)
    reshape long wpi, i(isic) j(year)
    collapse (mean) wpi, by(isic3 year)

    keep if inrange(year, 2000, 2014)
    label var wpi "WPI (base 2000=100, 3-digit ISIC mean, 2013-14 from IHPB (CAGR for ISIC 37))"
    tempfile wpi_lookup
    save `wpi_lookup'
restore

* ── Merge and deflate ────────────────────────────────────────────────────────
merge m:1 isic3 year using `wpi_lookup', keep(master match) nogen

qui count if !missing(wpi)
di as txt "  WPI matched: " r(N) " obs (unmatched = non-mfg ISIC, retain missing)"

gen double output_real   = output / (wpi / 100)
gen double ei_gj_real    = total_gj_s1 / output_real
gen double ln_ei_gj_real = ln(ei_gj_real)

label var wpi           "WPI deflator (base 2000=100, 3-digit ISIC, from wpio_extended.dta)"
label var isic3         "ISIC/KBLI 3-digit industry code (= int(isic5_raw/100))"
label var output_real   "Real output Rp000, 2000 prices (WPI deflated)"
label var ei_gj_real    "Physical energy intensity: GJ per real Rp000 output"
label var ln_ei_gj_real "Log physical energy intensity (WPI deflated)"

* CO2 intensity — WPI-deflated (same logic as GJ: physical numerator, real denominator)
gen double ei_co2_real    = co2_total_s1 / output_real
gen double ln_ei_co2_real = ln(ei_co2_real)
label var ei_co2_real    "CO2 intensity: tCO2e per real Rp000 output (Spec 1, WPI-deflated)"
label var ln_ei_co2_real "Log CO2 intensity (Spec 1, WPI-deflated)"

di as txt _n "  Coverage — real intensity vars:"
foreach v in ei_gj_real ei_co2_real {
    qui count if `v' > 0 & !missing(`v')
    local pos = r(N)
    qui count if `v' == 0 & !missing(`v')
    local zero = r(N)
    qui count if missing(`v')
    local miss = r(N)
    di as txt "  `v':  positive=`pos'  zero=`zero'  missing=`miss'"
}

di as txt _n "  Nominal vs real GJ intensity (mean, median):"
tabstat ln_ei_gj_s1 ln_ei_gj_real, stats(n mean sd p50) col(stats) format(%9.3f)


* ============================================================
* SECTION 6 — COMPARISON: MONETARY vs PHYSICAL (GJ)
* ============================================================

di as txt _n "=== SECTION 6: Comparison ==="

* --- Summary statistics ---
di as txt _n "  Summary: log intensity measures (positive obs only)"
tabstat ln_ei_monetary_zero ln_ei_monetary_strict ln_ei_gj_s1 ln_ei_gj_real ln_ei_co2_real, ///
    stats(n mean sd p10 p50 p90) col(stats) format(%9.3f)

* --- Correlation ---
di as txt _n "  Pairwise correlations:"
pwcorr ln_ei_monetary_zero ln_ei_gj_real ln_ei_co2_real, obs sig

* --- Annual means (levels comparison) ---
di as txt _n "  Annual mean of log intensity measures:"
tabstat ln_ei_monetary_zero ln_ei_gj_s1, by(year) stats(mean) format(%9.3f)

* --- Check divergence: do monetary and physical move together? ---
preserve
    collapse (mean) ln_ei_monetary_zero ln_ei_gj_s1 (count) n=psid, by(year)
    sort year
    gen d_monetary = ln_ei_monetary_zero - ln_ei_monetary_zero[_n-1]
    gen d_gj       = ln_ei_gj_s1        - ln_ei_gj_s1[_n-1]
    gen diverge    = (d_monetary > 0 & d_gj < 0) | (d_monetary < 0 & d_gj > 0)
    di as txt _n "  Year-on-year divergence (monetary and GJ moving in opposite directions):"
    list year d_monetary d_gj diverge if !missing(d_monetary), noobs sep(0)
restore


* ============================================================
* SECTION 7 — SAVE
* ============================================================

di as txt _n "=== SECTION 7: Save ==="

* Keep core id vars + all intensity vars
keep psid year isic2 isic3 isic5_raw dprovi output output_real wpi ///
     energy_exp_zero energy_exp_strict ///
     ei_monetary_zero ei_monetary_strict ///
     ln_ei_monetary_zero ln_ei_monetary_strict ///
     flag_ei_gt1_zero flag_ei_gt1_strict ///
     total_gj_s1 gj_fuel_s1 gj_elec_s1 ///
     ei_gj_s1 ln_ei_gj_s1 ///
     ei_gj_real ln_ei_gj_real ///
     co2_total_s1 ei_co2_real ln_ei_co2_real ///
     fuel_total_reported_rp elec_purchased_rp_zero elec_purchased_rp_strict ///
     gj_firewood_ref gj_charcoal_ref gj_lubricant_ref ///
     vtlvcu ekspor

order psid year isic2 isic3 isic5_raw dprovi output output_real wpi vtlvcu ekspor ///
      energy_exp_zero energy_exp_strict ///
      ei_monetary_zero ln_ei_monetary_zero ///
      ei_monetary_strict ln_ei_monetary_strict ///
      flag_ei_gt1_zero flag_ei_gt1_strict ///
      total_gj_s1 gj_fuel_s1 gj_elec_s1 ///
      ei_gj_s1 ln_ei_gj_s1 ///
      ei_gj_real ln_ei_gj_real ///
      co2_total_s1 ei_co2_real ln_ei_co2_real ///
      gj_firewood_ref gj_charcoal_ref gj_lubricant_ref

sort psid year
compress
save "$output/si_energy_intensity.dta", replace

di as txt _n "Saved: $output/si_energy_intensity.dta"
di as txt "Obs: " _N "  |  Vars: " c(k)


* ============================================================
* SECTION 8 — COMBINED FILE: si_energy_emission_and_intensity.dta
* ============================================================
* Merge the new intensity variables (those not already in si_energy_emissions.dta)
* into the full emissions file to produce a single analysis-ready dataset.
*
* Shared id/covariate vars already in emissions: psid year isic2 isic3 isic5_raw
*   dprovi output vtlvcu ekspor co2_total_s1
* New vars brought in from intensity: output_real wpi energy_exp_* ei_* ln_ei_*
*   flag_ei_* total_gj_s1 gj_fuel_s1 gj_elec_s1 fuel_*_rp elec_*_rp gj_*_ref
*
* The 2 obs in si_energy_emissions.dta with missing output are kept (all intensity
* vars will be missing for those 2 obs — deliberate).

di as txt _n "=== SECTION 8: Build combined file ==="

local intensity_new ///
    output_real wpi ///
    energy_exp_zero energy_exp_strict ///
    ei_monetary_zero ei_monetary_strict ///
    ln_ei_monetary_zero ln_ei_monetary_strict ///
    flag_ei_gt1_zero flag_ei_gt1_strict ///
    total_gj_s1 gj_fuel_s1 gj_elec_s1 ///
    ei_gj_s1 ln_ei_gj_s1 ///
    ei_gj_real ln_ei_gj_real ///
    ei_co2_real ln_ei_co2_real ///
    fuel_total_reported_rp elec_purchased_rp_zero elec_purchased_rp_strict ///
    gj_firewood_ref gj_charcoal_ref gj_lubricant_ref

use "$output/si_energy_emissions.dta", clear
merge 1:1 psid year using "$output/si_energy_intensity.dta", ///
    keepusing(`intensity_new') keep(1 3) nogen

* Place new vars after the existing intensity vars in emissions (after ln_co2_intensity_worker_s2)
order `intensity_new', after(ln_co2_intensity_worker_s2)

compress
save "$output/si_energy_emission_and_intensity.dta", replace

di as txt _n "Saved: $output/si_energy_emission_and_intensity.dta"
di as txt "Obs: " _N "  |  Vars: " c(k)
di as txt "(Primary final dataset — emissions + intensity in one file)"


di as txt _n "======================================================"
di as txt " 16_energy_intensity.do — done: " c(current_date) " " c(current_time)
di as txt "======================================================"

log close
