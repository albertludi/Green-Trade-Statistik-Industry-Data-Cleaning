# TODO — Green-Trade Statistik Industry Data Cleaning
_Last updated: 2026-03-11_

## Active
- [ ] Explore `data8514_SI.dta` — identify energy variables across survey years
- [ ] Map energy variable names to questionnaire definitions (per-year Kuesioner)
- [ ] Standardize energy quantities to common units
- [ ] Apply carbon emission conversion factors (per fuel type)
- [ ] Identify internationalization / first-time exporter flag variable
- [ ] Validate cleaned energy panel against raw totals

## Backlog
- [ ] Document variable crosswalk (year × energy type × variable name)
- [ ] Write `01_explore.do` — describe data structure, check coverage
- [ ] Write `02_clean_energy.do` — standardize energy variables
- [ ] Write `03_convert_emissions.do` — apply emission factors
- [ ] Export clean dataset to `output/`

## Done
- [x] Set up project folder structure
- [x] Connect to GitHub (`albertludi/Green-Trade Statistik Industry Data Cleaning`)
