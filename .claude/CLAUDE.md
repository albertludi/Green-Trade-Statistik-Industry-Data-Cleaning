# Project: Green-Trade — Statistik Industri Data Cleaning

## Overview
Data cleaning and processing project for Mba Deasy's research on whether newly internationalizing firms become more energy-efficient (greener). My role is to clean the energy variables in the Indonesian Industrial Survey (SI/IBS) panel and convert them to carbon-equivalent emissions.

## Research Question
Do firms that first internationalize (begin exporting/importing) subsequently improve their energy efficiency or reduce carbon intensity?

## My Task
- Clean energy consumption variables from the SI panel (1985–2014)
- Convert energy types (electricity, fuel, etc.) to carbon-equivalent emissions
- Produce a clean, analysis-ready dataset for Mba Deasy

## Data

| File | Description |
|------|-------------|
| `data8514_SI/data8514_SI.dta` | Raw Stata panel, Indonesian Industrial Survey 1985–2014 (~344MB) |
| `data8514_SI/*.pdf` | Survey questionnaires by year (variable definitions) |

**Key variables to focus on:** energy consumption items (electricity, coal, diesel, gasoline, LPG, etc.) and firm identifiers (plant ID, year, export/import status).

## Folder Structure
```
Mba Deasy-Green Project/
├── data8514_SI/           ← raw data (never modify)
├── dofiles/               ← Stata do-files (cleaning pipeline)
├── output/                ← cleaned/derived datasets (.dta, .csv)
├── AI_Collaboration/      ← TODO.md, session notes, transcripts
└── .claude/               ← this file
```

## Tools
- **Stata** — primary tool for all data work
- **Python** — if needed for auxiliary tasks (e.g., emission factor lookups)
- Do NOT modify raw data in `data8514_SI/`

## Stata Conventions
- Use `data8514_SI/data8514_SI.dta` as the source; save outputs to `output/`
- Name do-files descriptively: `01_energy_clean.do`, `02_carbon_convert.do`, etc.
- Comment all variable transformations; note emission factor sources

## GitHub
- Repo: `Green-Trade Statistik Industry Data Cleaning` (github.com/albertludi)
- Large files (.dta, .zip, .pdf) are gitignored — only commit do-files, outputs, and docs

## Project Status
- [ ] Explore energy variables in raw data
- [ ] Map energy types across survey years (questionnaires differ by year)
- [ ] Apply emission conversion factors
- [ ] Produce clean panel: firm × year × carbon intensity
