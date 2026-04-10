* ============================================================
* 00_config.do — ONE-LINE SETUP for Green-Trade-Emission-Handoff
*
* INSTRUCTIONS
* ------------
* 1. Edit the single line below: set global handoff to the
*    absolute path of this folder on YOUR machine.
* 2. Run this file: do "/path/to/Green-Trade-Emission-Handoff/dofiles/00_config.do"
* 3. Then run the pipeline: do "$dofiles/00b_run_all_pipeline.do"
*
* All other do-files read their paths from this global — you
* never need to edit any other file.
* ============================================================

* ── Stata version requirement ──────────────────────────────
version 16
* ──────────────────────────────────────────────────────────

* ── EDIT THIS ONE LINE ─────────────────────────────────────
global handoff "/path/to/Green-Trade-Emission-Handoff"
* ──────────────────────────────────────────────────────────

* ── Derived paths (do not edit) ───────────────────────────
global root    "$handoff"
global sidata  "$handoff/data/si_annual"
global output  "$handoff/output"
global logs    "$handoff/logs"
global rawdata "$handoff/data/raw"
global concord "$handoff/data/concordance"
global ihpbdir "$handoff/data/ihpb"
global dofiles "$handoff/dofiles"

* ── Create output directories if missing ──────────────────
cap mkdir "$output"
cap mkdir "$output/tables"
cap mkdir "$output/figures"
cap mkdir "$logs"

di as txt "======================================================"
di as txt " 00_config.do: handoff root configured."
di as txt "   handoff = $handoff"
di as txt "   sidata  = $sidata"
di as txt "   rawdata = $rawdata"
di as txt "======================================================"
di as txt " Next step: do {dollar}dofiles/00b_run_all_pipeline.do"
di as txt "======================================================"
