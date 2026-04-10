* ============================================================
* 00b_run_all_pipeline.do
* Master script — runs the full Green-Trade SI energy pipeline
* from raw data to final energy-intensity dataset and all figures.
*
* PRE-REQUISITES
* --------------
*   1. 00_config.do configured with correct $handoff path (edit ONE line)
*   2. data/raw/data8514_SI.dta            (raw SI panel, ~344 MB)
*   3. data/raw/wpio.dta                   (WPI deflator 1983–2012)
*   4. data/concordance/ihpb_isic4_concordance.csv
*   5. data/ihpb/  — two BPS IHPB Excel files (see Step 0 below)
*   6. data/si_annual/  — SI annual .dta files (si2000.dta–si2014.dta)
*
* PIPELINE OVERVIEW
* -----------------
* CORE PIPELINE (produces emission datasets):
*   Step 0   [Stata]  Extract IHPB annual averages from BPS Excel → CSV
*   Step 1   [Stata]  Append SI annual files → base panel
*   Step 2   [Stata]  Harmonise energy variables across survey years
*   Step 3   [Stata]  Flag outliers
*   Step 4   [Stata]  Apply cleaning rules
*   Step 5   [Stata]  Convert energy to CO₂-equivalent (Spec 1 & 2)
*   Step 6   [Stata]  Sensitivity / robustness variants
*   Step 7   [Stata]  Descriptive statistics & figures
*   Step 8   [Stata]  Finalize variable order in si_energy_emissions.dta
*   Step 9   [Stata]  Extend WPI deflator to 2013–2014 via IHPB chain-link
*   Step 10  [Stata]  Construct energy intensity measures
*   Step 11  [Stata]  Energy-intensity figures
*
* DOCUMENTATION & DIAGNOSTIC SCRIPTS
* (run after relevant core step; produce QMD tables/figures):
*   Step 1a  [Stata]  Variable coverage documentation
*   Step 1b  [Stata]  PSID merge diagnostics
*   Step 1c  [Stata]  Unit consistency and structural-gap documentation
*   Step 1d  [Stata]  Missing-by-year rates
*   Step 1e  [Stata]  Coal unit-correction diagnostic (Appendix C)
*   Step 1f  [Stata]  Unit expenditure diagnostic figures
*   Step 1g  [Stata]  efuvcu expenditure aggregate check
*   Step 2a  [Stata]  Harmonised fuel/electricity trend and by-ISIC figures
*   Step 4a  [Stata]  Cleaning diagnostics (KDE, flag distributions)
*   Step 11a [Python] Unit price heterogeneity figure
*   Step 11b [Python] Subsidy context figure (with firm unit prices overlay)
*
* OUTPUTS (all in output/ unless noted)
* ------
*   si_energy_emissions.dta        — main clean emission panel (Steps 1–8)
*   wpio_extended.dta              — WPI extended to 2014 (Step 9)
*   si_energy_intensity.dta        — intensity measures (Step 10)
*   tables/*.csv                   — documentation tables (Steps 1a–1d, 7)
*   figures/fig_ei_*.png           — intensity figures (Step 11)
*   figures/fig[01-10]_*.png       — diagnostic/coverage figures (Steps 1f–2a, 4a)
*   figures/figC*.png              — coal correction appendix (Step 1e)
*   figures/figD*.png              — descriptive figures (Step 7)
*   figures/fig_unit_price_*.png   — unit price heterogeneity (Step 11a)
*   figures/fig_subsidy_context.png — subsidy context (Step 11b)
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
cap mkdir "$logs"
log using "$logs/00b_run_all_pipeline.log", replace text

di as txt "======================================================"
di as txt " 00b_run_all_pipeline.do — started: " c(current_date) " " c(current_time)
di as txt "======================================================"


* ── Step 0: Extract IHPB annual averages from BPS Excel files ─────────────────
* This MUST run before Step 9 (15_extend_wpio_ihpb.do).
* Reads two BPS Excel publications and writes ihpb_annual_averages.csv.
*
* Script : dofiles/00c_extract_ihpb.do  (Stata — no Python needed)
* Input  : data/ihpb/indeks-harga-perdagangan-besar-indonesia-2013-2-29-34.xlsx
*          data/ihpb/indeks-harga-perdagangan-besar-indonesia-2014 - -2010-100-2-27-32.xlsx
* Output : data/concordance/ihpb_annual_averages.csv

di as txt _n "=== Step 0: Extract IHPB from BPS Excel ==="
do "$dofiles/00c_extract_ihpb.do"

cap confirm file "$concord/ihpb_annual_averages.csv"
if _rc != 0 {
    di as error "ERROR: ihpb_annual_averages.csv not found — 00c_extract_ihpb.do failed."
    exit 1
}
di as txt "  ihpb_annual_averages.csv confirmed."


* ── Step 1: Append SI annual files → base panel ───────────────────────────────
* Output: output/si_panel_2000_2014.dta

di as txt _n "=== Step 1: Append SI energy ==="
do "$dofiles/01_append_si_energy.do"


* ── Step 1a: Variable coverage documentation ──────────────────────────────────
* Runs on si_panel_2000_2014.dta.
* Output: output/tables/var_list.csv
*         output/tables/var_coverage_matrix.csv
*         output/tables/obs_by_year.csv

di as txt _n "=== Step 1a: Variable coverage ==="
do "$dofiles/02_variable_coverage.do"


* ── Step 1b: PSID merge diagnostics ──────────────────────────────────────────
* Checks SI annual ↔ data8514_SI.dta merge quality.
* Output: output/tables/psid_merge_check.csv

di as txt _n "=== Step 1b: PSID merge diagnostics ==="
do "$dofiles/03_psid_merge_check.do"


* ── Step 1c: Unit consistency and structural-gap documentation ────────────────
* Runs on si_panel_2000_2014.dta.
* Output: output/tables/unit_consistency.csv
*         output/tables/structural_gaps.csv

di as txt _n "=== Step 1c: Unit consistency ==="
do "$dofiles/04_unit_consistency.do"


* ── Step 1d: Missing-by-year rates ───────────────────────────────────────────
* Runs on si_panel_2000_2014.dta.
* Output: output/tables/pct_missing_by_year.csv

di as txt _n "=== Step 1d: Missing by year ==="
do "$dofiles/07_missing_by_year.do"


* ── Step 1e: Coal unit-correction diagnostic (Appendix C) ────────────────────
* Runs on si_panel_2000_2014.dta (raw, pre-correction).
* Confirms data were already in Kg — no correction applied.
* Output: output/tables/coal_correction_check.csv
*         output/figures/figC1_coal_unitprice_raw.png
*         output/figures/figC2_coal_unitprice_corrected.png
*         output/figures/figC3_coal_expend_vs_qty.png

di as txt _n "=== Step 1e: Coal correction check ==="
do "$dofiles/13_coal_correction_check.do"


* ── Step 1f: Unit expenditure diagnostic figures ─────────────────────────────
* Runs on si_panel_2000_2014.dta.
* Output: output/figures/fig01_coal_unit_expenditure.png
*         output/figures/fig02_fuel_coverage.png

di as txt _n "=== Step 1f: Unit expenditure figures ==="
do "$dofiles/05_graph_unit_expenditure.do"


* ── Step 1g: efuvcu expenditure aggregate check ──────────────────────────────
* Runs on si_panel_2000_2014.dta.
* Output: output/figures/fig_efuvcu_check.png

di as txt _n "=== Step 1g: efuvcu check ==="
do "$dofiles/06_efuvcu_check.do"


* ── Step 2: Harmonise energy variables across survey years ────────────────────
* Output: output/si_energy_harmonized.dta

di as txt _n "=== Step 2: Harmonise energy ==="
do "$dofiles/06_harmonize_si_energy.do"


* ── Step 2a: Harmonised fuel/electricity trend and by-ISIC figures ────────────
* Runs on si_energy_harmonized.dta.
* Output: output/figures/fig03_coal_distribution.png
*         output/figures/fig04_fuel_trends.png
*         output/figures/fig05_elec_trends.png
*         output/figures/fig06A-F_*_by_isic2.png
*         output/figures/fig07_elec_by_isic2.png
*         output/figures/fig07b_elec_trend_by_isic2.png

di as txt _n "=== Step 2a: Harmonised figures ==="
do "$dofiles/07_graphs_harmonized.do"


* ── Step 3: Flag outliers ─────────────────────────────────────────────────────
* Output: output/si_energy_flagged.dta
*         output/tables/flag_summary_by_year.csv
*         output/tables/flag_summary_by_isic2.csv

di as txt _n "=== Step 3: Outlier flags ==="
do "$dofiles/08_outlier_flags.do"


* ── Step 4: Apply cleaning rules ──────────────────────────────────────────────
* Output: output/si_energy_harmonized_cleaned.dta

di as txt _n "=== Step 4: Apply cleaning ==="
do "$dofiles/09_clean_apply.do"


* ── Step 4a: Cleaning diagnostics ────────────────────────────────────────────
* Compares distributions before/after cleaning; literature comparison.
* Output: output/figures/fig08_kde_before_after.png
*         output/figures/fig09_flags_by_year.png
*         output/figures/fig10_literature_comparison.png

di as txt _n "=== Step 4a: Cleaning diagnostics ==="
do "$dofiles/09b_clean_diagnostics.do"


* ── Step 5: Convert energy to CO₂-equivalent ──────────────────────────────────
* Output: output/si_energy_emissions.dta

di as txt _n "=== Step 5: Carbon conversion ==="
do "$dofiles/10_carbon_convert.do"


* ── Step 6: Sensitivity variants ──────────────────────────────────────────────
* Updates: output/si_energy_emissions.dta (adds sensitivity columns)

di as txt _n "=== Step 6: Sensitivity variants ==="
do "$dofiles/11_sensitivity_variants.do"


* ── Step 7: Descriptive statistics ───────────────────────────────────────────
* Output: output/tables/desc_*.csv
*         output/figures/figD*.png

di as txt _n "=== Step 7: Descriptive statistics ==="
do "$dofiles/12_descriptive_stats.do"


* ── Step 8: Finalize variable order in si_energy_emissions.dta ───────────────

di as txt _n "=== Step 8: Finalize variable order ==="
do "$dofiles/14_finalize_variable_order.do"


* ── Step 9: Extend WPI deflator to 2013–2014 ─────────────────────────────────
* Reads ihpb_annual_averages.csv (produced in Step 0).
* Output: output/wpio_extended.dta

di as txt _n "=== Step 9: Extend WPI via IHPB ==="
do "$dofiles/15_extend_wpio_ihpb.do"


* ── Step 10: Construct energy-intensity measures ──────────────────────────────
* Reads si_energy_emissions.dta + wpio_extended.dta.
* Output: output/si_energy_intensity.dta

di as txt _n "=== Step 10: Energy intensity ==="
do "$dofiles/16_energy_intensity.do"


* ── Step 11: Energy-intensity figures ────────────────────────────────────────
* Output: output/figures/fig_ei_*.png

di as txt _n "=== Step 11: EI figures ==="
do "$dofiles/17_ei_figures.do"


* ── Step 11a: Unit price heterogeneity figure ────────────────────────────────
* Reads si_energy_emissions.dta.
* Output: output/figures/fig_unit_price_heterogeneity.png

di as txt _n "=== Step 11a: Unit price figure ==="
do "$dofiles/18_fig_unit_price.do"


* ── Step 11b: Subsidy context figure ─────────────────────────────────────────
* Reads si_energy_emissions.dta (firm unit prices) + hardcoded Dartanto (2013).
* Output: output/figures/fig_subsidy_context.png

di as txt _n "=== Step 11b: Subsidy context figure ==="
do "$dofiles/19_fig_subsidy_context.do"


* ── Done ──────────────────────────────────────────────────────────────────────
di as txt _n "======================================================"
di as txt " 00b_run_all_pipeline.do — completed: " c(current_date) " " c(current_time)
di as txt "======================================================"
di as txt ""
di as txt " Core datasets:"
di as txt "   output/si_energy_emissions.dta"
di as txt "   output/wpio_extended.dta"
di as txt "   output/si_energy_intensity.dta"
di as txt ""
di as txt " Documentation tables (output/tables/):"
di as txt "   var_list.csv, var_coverage_matrix.csv, obs_by_year.csv"
di as txt "   psid_merge_check.csv"
di as txt "   unit_consistency.csv, structural_gaps.csv, pct_missing_by_year.csv"
di as txt "   coal_correction_check.csv"
di as txt "   flag_summary_by_year.csv, flag_summary_by_isic2.csv"
di as txt "   desc_*.csv (18 descriptive tables)"
di as txt ""
di as txt " Figures (output/figures/):"
di as txt "   fig01–02  : coal unit/coverage diagnostics"
di as txt "   fig03–07  : harmonised fuel/electricity trends and by-ISIC"
di as txt "   fig08–10  : cleaning diagnostics and literature comparison"
di as txt "   figC1–C3  : coal correction appendix"
di as txt "   figD1–D7  : descriptive emission statistics"
di as txt "   fig_ei_*  : energy intensity"
di as txt "   fig_unit_price_heterogeneity.png"
di as txt "   fig_subsidy_context.png"
di as txt "======================================================"

log close
