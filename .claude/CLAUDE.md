# Project: Green-Trade Statistik Industry Data Cleaning

## Overview
Cleaning and transforming energy variables from Indonesian Industrial Survey (IBS/SI) data (1985–2014) for analysis of whether newly internationalizing firms become more energy-efficient.

**Research question:** Do firms that internationalize for the first time experience gains in energy efficiency / greener energy use?

**My role:** Data cleaning — standardize energy variables, convert to comparable carbon emission equivalents.

## Project Status
- Phase: Data cleaning (active)
- PI: Mba Deasy (main author)

## Data
| File | Description |
|------|-------------|
| `data8514_SI/data8514_SI.dta` | Main Stata panel: Indonesian Industrial Survey 1985–2014 (~344MB) |
| `data8514_SI/*.pdf` | Survey questionnaires (Kuesioner IBS) per year — use for variable definitions |

**Key data notes:**
- Panel of manufacturing firms (Industri Besar dan Sedang)
- Energy variables: fuel types (solar, bensin, minyak tanah, etc.), electricity — need to locate variable names in each wave
- Conversion target: carbon emission equivalents (CO₂e or similar)
- Internationalization flag: export status variable (to identify first-time exporters)

## Folder Map
```
Mba Deasy-Green Project/
├── data8514_SI/       ← raw data (DO NOT modify)
├── dofiles/           ← Stata do-files (cleaning, transformation)
├── output/            ← cleaned datasets, derived variables
├── AI_Collaboration/  ← TODO.md, project index, session notes
│   └── Transcripts/
└── .claude/           ← this config
```

## Stata Conventions
- Use `python3` for any preprocessing; Stata for main analysis
- Do-file naming: `01_explore.do`, `02_clean_energy.do`, `03_convert_emissions.do`
- Always preserve raw data — save cleaned versions to `output/`
- Comment do-files with variable source (questionnaire year, variable name)

## GitHub
- Repo: `albertludi/Green-Trade Statistik Industry Data Cleaning`
- Branch: `main`
- Excluded from git: `.dta`, `.zip`, large data files (see `.gitignore`)

## Key Tasks
See `AI_Collaboration/TODO.md` for current task list.
See `AI_Collaboration/PROJECT_INDEX.md` for variable notes and pipeline status.
