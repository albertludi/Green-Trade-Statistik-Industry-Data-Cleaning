* ============================================================
* Script: 14_finalize_variable_order.do
* Purpose: Finalize variable ordering in si_energy_emissions.dta.
*
*          Order:
*            1. Identifiers   — year, psid, isic5_raw, dprovi, dkabup
*            2. Firm vars     — ltlnou, vtlvcu, output, iinput
*            3. Fuel vars     — fuel_*_ltr / _kg / _m3 (physical quantities)
*            4. Electricity   — elec_*
*            5. Outlier flags — flag_D1_*, flag_D2_*, flag_D3_*, composites
*                               (flag_D4_* and flag_D5_* dropped — not in methods)
*            6. Scope 1 per-fuel emissions, Spec 1 (co2_*_s1)
*            7. Scope 1 total + Scope 2 + Total, Spec 1
*               (co2_scope1_s1, co2_scope1_nfuels, co2_scope2_s1,
*                co2_total_s1, ln_co2_scope1_s1, ln_co2_total_s1)
*            8. Intensity measures, Spec 1
*               (co2_intensity_worker_s1, co2_intensity_output_s1,
*                ln_co2_intensity_worker_s1)
*            9. Scope 1 per-fuel emissions, Spec 2 (co2_*_s2)
*           10. Scope 1 total + Scope 2 + Total, Spec 2
*               (co2_scope1_s2, co2_scope2_s2, co2_total_s2,
*                ln_co2_total_s2, co2_intensity_worker_s2,
*                ln_co2_intensity_worker_s2)
*           11. Sensitivity / alternative specs
*               (co2_*_alt_*, ln_co2_total_alt_*)
*
* Input:   output/si_energy_emissions.dta
* Output:  output/si_energy_emissions.dta (in-place; variable order only)
* Author:  Albert Ludi
* Date:    2026-03-25
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

log using "$logs/14_finalize_variable_order.log", replace text

use "$output/si_energy_emissions.dta", clear
di as txt "Obs loaded: " _N
di as txt "Vars before reorder: " c(k)

* ============================================================
* STEP 1 — DROP UNUSED VARIABLES
* ============================================================
* elec_owngene_nsets, encliu0, explca: raw survey pass-throughs,
* not used in any emission calculation or analysis pipeline.

capture drop elec_owngene_nsets encliu0 explca
di as txt "  Dropped (if present): elec_owngene_nsets encliu0 explca"

* ── DROP D4 / D5 FLAG VARIABLES (not in methods) ───────────────────────────
* These were an early diagnostic dimension (generator > total electricity)
* that was removed from the cleaning methodology. Drop any remnants.

di as txt _n "=== Dropping D4/D5 flag variables (if present) ==="

capture drop flag_D4_*
capture drop flag_D5_*
capture drop flag_any_hard   // ghost variable from a prior exploratory run — never produced by current pipeline
di as txt "  capture drop flag_D4_* flag_D5_* flag_any_hard — done (no error if absent)"
di as txt "  Vars after drop: " c(k)

* ============================================================
* STEP 2 — VARIABLE ORDERING
* ============================================================
* Uses -order- with -last- / -after()- to avoid errors when a variable
* is absent (capture wraps each block so the do-file is idempotent).
*
* Block 1: Identifiers

di as txt _n "=== Ordering variables ==="

capture order year psid isic2 isic5_raw dprovi dkabup

* Block 2: Core firm-level variables
capture order ltlnou vtlvcu output iinput, after(dkabup)

* Block 3: Fuel physical quantities
capture order ///
    fuel_diesel_ltr    ///
    fuel_petrol_ltr    ///
    fuel_kerosene_ltr  ///
    fuel_coal_kg       ///
    fuel_lpg_kg        ///
    fuel_citygas_m3    ///
    fuel_othergas_m3   ///
    fuel_coalbriq_kg   ///
    fuel_coke_kg       ///
    , after(iinput)

* Block 4: Electricity variables
capture order ///
    elec_pln_kwh              ///
    elec_nonpln_kwh           ///
    elec_owngene_kwh          ///
    elec_purchased_kwh_strict ///
    , after(fuel_coke_kg)

* Block 5: Outlier flag variables — D1, D2, D3 only (D4/D5 dropped above)
* Place composite flags first, then per-fuel detail flags
capture order ///
    flag_any_sev   ///
    flag_any_mod   ///
    flag_n_dims    ///
    , after(elec_purchased_kwh_strict)

* Per-fuel D1 flags
capture order flag_D1_fuel_diesel_ltr_sev    flag_D1_fuel_diesel_ltr_mod    ///
              flag_D1_fuel_petrol_ltr_sev    flag_D1_fuel_petrol_ltr_mod    ///
              flag_D1_fuel_kerosene_ltr_sev  flag_D1_fuel_kerosene_ltr_mod  ///
              flag_D1_fuel_coal_kg_sev       flag_D1_fuel_coal_kg_mod       ///
              flag_D1_fuel_lpg_kg_sev        flag_D1_fuel_lpg_kg_mod        ///
              flag_D1_fuel_citygas_m3_sev    flag_D1_fuel_citygas_m3_mod    ///
              flag_D1_fuel_coalbriq_kg_sev   flag_D1_fuel_coalbriq_kg_mod   ///
              flag_D1_fuel_othergas_m3_sev   flag_D1_fuel_othergas_m3_mod   ///
              flag_D1_fuel_coke_kg_sev       flag_D1_fuel_coke_kg_mod       ///
              flag_D1_elec_pln_kwh_sev       flag_D1_elec_pln_kwh_mod       ///
              flag_D1_elec_nonpln_kwh_sev    flag_D1_elec_nonpln_kwh_mod    ///
              , after(flag_n_dims)

* Per-fuel D2 flags
capture order flag_D2_fuel_diesel_ltr_sev    flag_D2_fuel_diesel_ltr_mod    ///
              flag_D2_fuel_petrol_ltr_sev    flag_D2_fuel_petrol_ltr_mod    ///
              flag_D2_fuel_kerosene_ltr_sev  flag_D2_fuel_kerosene_ltr_mod  ///
              flag_D2_fuel_coal_kg_sev       flag_D2_fuel_coal_kg_mod       ///
              flag_D2_fuel_lpg_kg_sev        flag_D2_fuel_lpg_kg_mod        ///
              flag_D2_fuel_citygas_m3_sev    flag_D2_fuel_citygas_m3_mod    ///
              flag_D2_fuel_coalbriq_kg_sev   flag_D2_fuel_coalbriq_kg_mod   ///
              flag_D2_fuel_othergas_m3_sev   flag_D2_fuel_othergas_m3_mod   ///
              flag_D2_fuel_coke_kg_sev       flag_D2_fuel_coke_kg_mod       ///
              flag_D2_elec_pln_kwh_sev       flag_D2_elec_pln_kwh_mod       ///
              flag_D2_elec_nonpln_kwh_sev    flag_D2_elec_nonpln_kwh_mod    ///
              , after(flag_D1_elec_nonpln_kwh_mod)

* Per-fuel D3 flags
capture order flag_D3_fuel_diesel_ltr_sev    flag_D3_fuel_diesel_ltr_mod    ///
              flag_D3_fuel_petrol_ltr_sev    flag_D3_fuel_petrol_ltr_mod    ///
              flag_D3_fuel_kerosene_ltr_sev  flag_D3_fuel_kerosene_ltr_mod  ///
              flag_D3_fuel_coal_kg_sev       flag_D3_fuel_coal_kg_mod       ///
              flag_D3_fuel_lpg_kg_sev        flag_D3_fuel_lpg_kg_mod        ///
              flag_D3_fuel_citygas_m3_sev    flag_D3_fuel_citygas_m3_mod    ///
              flag_D3_fuel_coalbriq_kg_sev   flag_D3_fuel_coalbriq_kg_mod   ///
              flag_D3_fuel_othergas_m3_sev   flag_D3_fuel_othergas_m3_mod   ///
              flag_D3_fuel_coke_kg_sev       flag_D3_fuel_coke_kg_mod       ///
              flag_D3_elec_pln_kwh_sev       flag_D3_elec_pln_kwh_mod       ///
              flag_D3_elec_nonpln_kwh_sev    flag_D3_elec_nonpln_kwh_mod    ///
              , after(flag_D2_elec_nonpln_kwh_mod)

* Block 6: Spec 1 — per-fuel emission variables
capture order ///
    co2_diesel_s1    ///
    co2_petrol_s1    ///
    co2_kerosene_s1  ///
    co2_coal_s1      ///
    co2_lpg_s1       ///
    co2_gas_s1       ///
    co2_othergas_s1  ///
    co2_coalbriq_s1  ///
    co2_coke_s1      ///
    , after(flag_D3_elec_nonpln_kwh_mod)

* Block 7: Spec 1 — aggregate + total + log outcomes
capture order ///
    co2_scope1_s1          ///
    co2_scope1_nfuels      ///
    co2_scope2_s1          ///
    co2_total_s1           ///
    ln_co2_scope1_s1       ///
    ln_co2_total_s1        ///
    , after(co2_coke_s1)

* Block 8: Spec 1 — intensity outcomes
capture order ///
    co2_intensity_worker_s1   ///
    co2_intensity_output_s1   ///
    ln_co2_intensity_worker_s1 ///
    , after(ln_co2_total_s1)

* Block 9: Spec 2 — per-fuel emission variables
capture order ///
    co2_diesel_s2    ///
    co2_petrol_s2    ///
    co2_kerosene_s2  ///
    co2_coal_s2      ///
    co2_lpg_s2       ///
    co2_gas_s2       ///
    co2_othergas_s2  ///
    co2_coalbriq_s2  ///
    co2_coke_s2      ///
    , after(ln_co2_intensity_worker_s1)

* Block 10: Spec 2 — aggregate + total + intensity
capture order ///
    co2_scope1_s2              ///
    co2_scope2_s2              ///
    co2_total_s2               ///
    ln_co2_total_s2            ///
    co2_intensity_worker_s2    ///
    ln_co2_intensity_worker_s2 ///
    , after(co2_coke_s2)

* Block 11: Sensitivity / alternative specifications
* Order by priority (HIGH → MEDIUM → LOW; see §7.9 of QMD)
capture order ///
    co2_lpg_alt_lpg            ///
    co2_scope1_alt_lpg         ///
    co2_total_alt_lpg          ///
    ln_co2_total_alt_lpg       ///
    , after(ln_co2_intensity_worker_s2)

capture order ///
    co2_coal_alt_kali          ///
    co2_scope1_alt_kali        ///
    co2_total_alt_kali         ///
    ln_co2_total_alt_kali      ///
    , after(ln_co2_total_alt_lpg)

capture order ///
    co2_scope2_alt_rosita      ///
    co2_total_alt_rosita       ///
    ln_co2_total_alt_rosita    ///
    , after(ln_co2_total_alt_kali)

capture order ///
    co2_coal_alt_exc2004       ///
    co2_scope1_alt_exc2004     ///
    co2_total_alt_exc2004      ///
    ln_co2_total_alt_exc2004   ///
    , after(ln_co2_total_alt_rosita)

capture order ///
    co2_gas_alt_towngas        ///
    co2_scope1_alt_towngas     ///
    co2_total_alt_towngas      ///
    ln_co2_total_alt_towngas   ///
    , after(ln_co2_total_alt_exc2004)

* ============================================================
* STEP 3 — LABEL UNLABELED VARIABLES
* ============================================================
* Variables that passed through the pipeline without a label assigned.

label var isic2             "ISIC/KBLI 2-digit industry code (= int(isic5_raw/1000))"

di as txt _n "=== Labels added to previously unlabeled variables ==="
foreach v in isic2 {
    local lbl : variable label `v'
    di as txt "  `v': `lbl'"
}

* ============================================================
* STEP 4 — VERIFY AND SAVE
* ============================================================

di as txt _n "=== Final variable order (first 30 variables) ==="
describe, short
ds
local allvars "`r(varlist)'"
local i = 0
foreach v of local allvars {
    local ++i
    if `i' <= 30 di as txt "  " %3.0f `i' "  `v'"
}
if `i' > 30 di as txt "  ... (total `i' variables)"

save "$output/si_energy_emissions.dta", replace
di as txt _n "Saved: $output/si_energy_emissions.dta"
di as txt "  Obs: " _N
di as txt "  Vars: " c(k)

log close
