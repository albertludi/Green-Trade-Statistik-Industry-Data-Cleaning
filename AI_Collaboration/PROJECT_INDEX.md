# Project Index — Green-Trade SI Data Cleaning

## Summary
Clean energy variables from Indonesian Industrial Survey (SI/IBS) panel 1985–2014 and convert to carbon-equivalent emissions for Mba Deasy's research on export entry and green productivity.

## Key Files

| File | Description |
|------|-------------|
| `data8514_SI/data8514_SI.dta` | Source data — DO NOT MODIFY |
| `data8514_SI/*.pdf` | Survey questionnaires (variable definitions by year) |
| `dofiles/01_energy_clean.do` | Step 1: energy variable cleaning |
| `dofiles/02_carbon_convert.do` | Step 2: carbon emission conversion |
| `output/energy_clean_8514.dta` | Clean output (to be created) |

## Pipeline

```
data8514_SI.dta
    → 01_energy_clean.do     (harmonize units, handle missings)
    → 02_carbon_convert.do   (apply emission factors)
    → output/energy_clean_8514.dta
```

## Variable Notes
_(to be filled as exploration proceeds)_

## Emission Conversion Factors
_(to be documented — note source/reference for each factor)_

## Decisions Log
| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-11 | Project initialized | — |
