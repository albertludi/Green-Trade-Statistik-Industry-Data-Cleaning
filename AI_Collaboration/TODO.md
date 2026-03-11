# TODO — Green-Trade SI Data Cleaning
_Last updated: 2026-03-11_

## Active Tasks

- [ ] Explore energy variables in `data8514_SI.dta` — identify all energy-related columns
- [ ] Check variable consistency across years (questionnaires differ; see `data8514_SI/*.pdf`)
- [ ] Map energy types to standard categories (electricity, coal, diesel, LPG, etc.)
- [ ] Research/confirm emission conversion factors for each energy type (Indonesian context)
- [ ] Write `01_energy_clean.do` — handle missing values, unit harmonization
- [ ] Write `02_carbon_convert.do` — apply conversion factors, generate carbon intensity var
- [ ] Save clean output to `output/energy_clean_8514.dta`

## Backlog

- [ ] Merge cleaned energy data back to full SI panel for Mba Deasy
- [ ] Document all variable decisions in `AI_Collaboration/PROJECT_INDEX.md`

## Completed

_(nothing yet)_
