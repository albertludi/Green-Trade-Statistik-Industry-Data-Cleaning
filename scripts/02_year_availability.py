"""
02_year_availability.py
Check year-by-year availability (any non-zero obs) for electricity and fuel
dataset variables, 2000-2014.
"""

import pandas as pd

DATA = "data8514_SI/data8514_SI.dta"

ELEC = ["efuvcu", "eplvcu", "enpvcu"]

FUEL_ZP = ["zpovcu", "zpdvcu", "zpsvcu", "zpivcu", "zpzvcu", "zpxvcu"]
FUEL_ZN = ["znovcu", "zndvcu", "znsvcu", "znivcu", "znzvcu", "znxvcu"]

YEARS = list(range(2000, 2015))

all_vars = ELEC + FUEL_ZP + FUEL_ZN
df = pd.read_stata(DATA, columns=["year"] + all_vars)
df = df[df["year"].between(2000, 2014)]

print("Variable availability (✓ = any non-zero obs in that year)\n")
print(f"{'Variable':<12}", end="")
for y in YEARS:
    print(f"  {str(y)[2:]}", end="")
print()
print("-" * (12 + 4 * len(YEARS)))

for section, varlist in [("Electricity", ELEC),
                          ("Fuel zp*vcu (production)", FUEL_ZP),
                          ("Fuel zn*vcu (non-production)", FUEL_ZN)]:
    print(f"\n  {section}")
    for v in varlist:
        print(f"  {v:<12}", end="")
        for y in YEARS:
            sub = df[df["year"] == y][v]
            has_data = ((sub > 0) & sub.notna()).any()
            print(f"  {'Y' if has_data else '-'}", end="")
        print()
