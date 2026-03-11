# PROJECT INDEX — Green-Trade Statistik Industry Data Cleaning
_Last updated: 2026-03-11_

## Research Context
**Question:** Do newly internationalizing firms become more energy-efficient?
**Data:** Indonesian Industrial Survey (IBS/SI) panel, 1985–2014
**Task:** Clean energy variables → convert to carbon emission equivalents

## Data Dictionary (to be filled as variables are identified)

### Energy Variables
| Variable Name | Description | Unit | Years Available | Source Questionnaire |
|--------------|-------------|------|-----------------|---------------------|
| TBD | Solar/diesel | Liter | TBD | Kuesioner IBS |
| TBD | Bensin/gasoline | Liter | TBD | Kuesioner IBS |
| TBD | Electricity | kWh | TBD | Kuesioner IBS |
| TBD | Minyak tanah/kerosene | Liter | TBD | Kuesioner IBS |
| TBD | LPG | kg | TBD | Kuesioner IBS |

### Key Firm Variables
| Variable | Description |
|----------|-------------|
| TBD | Firm ID |
| TBD | Year |
| TBD | Export status (internationalization flag) |
| TBD | Industry code (KBLI/ISIC) |
| TBD | Total output / value added |

## Carbon Emission Conversion Factors
_To be confirmed against official source (IPCC, MoEF Indonesia, IEA)_

| Fuel Type | Factor | Unit |
|-----------|--------|------|
| Solar/diesel | ~2.68 | kg CO₂/liter |
| Bensin/gasoline | ~2.31 | kg CO₂/liter |
| Kerosene | ~2.54 | kg CO₂/liter |
| LPG | ~1.51 | kg CO₂/liter |
| Electricity (Indonesia grid) | ~0.87 | kg CO₂/kWh (verify year-specific) |

## Pipeline Status
| Step | Script | Status |
|------|--------|--------|
| 1. Explore data structure | `dofiles/01_explore.do` | Not started |
| 2. Clean energy variables | `dofiles/02_clean_energy.do` | Not started |
| 3. Convert to emissions | `dofiles/03_convert_emissions.do` | Not started |
| 4. Export clean dataset | — | Not started |

## File Locations
| Item | Path |
|------|------|
| Raw data | `data8514_SI/data8514_SI.dta` |
| Questionnaires | `data8514_SI/*.pdf` |
| Do-files | `dofiles/` |
| Output datasets | `output/` |
| GitHub | `albertludi/Green-Trade Statistik Industry Data Cleaning` |
