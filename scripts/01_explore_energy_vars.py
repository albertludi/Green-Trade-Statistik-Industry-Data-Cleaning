"""
01_explore_energy_vars.py
Green-Trade Project — Statistik Industri (SI) Data Cleaning
Session 1-2: Energy variable exploration and electricity identification

Purpose:
  - List all 98 variable names and labels from data8514_SI.dta
  - Report coverage (non-missing, non-zero) for all energy variables
  - Identify electricity sub-variables (eplvcu, enpvcu, efuvcu)
  - Confirm that efuvcu = eplvcu + enpvcu

Input:  data8514_SI/data8514_SI.dta
Output: printed summary (no files written)

Run:  python3 scripts/01_explore_energy_vars.py
"""

import pandas as pd
import numpy as np

DATA = "data8514_SI/data8514_SI.dta"

# ── 1. Variable list ──────────────────────────────────────────────────────────

reader = pd.read_stata(DATA, iterator=True)
labels = reader.variable_labels()

print("=" * 60)
print("ALL VARIABLES IN data8514_SI.dta")
print("=" * 60)
for v in sorted(labels.keys()):
    print(f"  {v:20s}  {labels[v]}")
print(f"\nTotal: {len(labels)} variables\n")

# ── 2. Energy variable coverage ───────────────────────────────────────────────

ELEC_VARS  = ["efuvcu", "eplvcu", "enpvcu"]
FUEL_VCU   = [
    "zpdvcu", "zndvcu",
    "zpsvcu", "znsvcu",
    "zpovcu", "znovcu",
    "zpivcu", "znivcu",
    "zpzvcu", "znzvcu",
    "zpxvcu", "znxvcu",
]
FUEL_KCU   = [
    "zpdkcu", "zndkcu",
    "zpskcu", "znskcu",
    "zpokcu", "znokcu",
    "zpikcu", "znikcu",
]

all_energy = ELEC_VARS + FUEL_VCU + FUEL_KCU
df = pd.read_stata(DATA, columns=["year"] + all_energy)

total = len(df)
print("=" * 60)
print(f"ENERGY VARIABLE COVERAGE  (N = {total:,})")
print("=" * 60)

def coverage(df, varname, total):
    s = df[varname]
    nonmiss = s.notna().sum()
    nonzero = (s.notna() & (s != 0)).sum()
    pos = s[s > 0]
    yr_min = df.loc[s > 0, "year"].min() if len(pos) > 0 else "—"
    yr_max = df.loc[s > 0, "year"].max() if len(pos) > 0 else "—"
    return nonmiss, nonzero, nonzero / total * 100, yr_min, yr_max

for section, varlist in [
    ("Electricity", ELEC_VARS),
    ("Fuel — monetary value (vcu)", FUEL_VCU),
    ("Fuel — physical quantity (kcu)", FUEL_KCU),
]:
    print(f"\n  {section}")
    print(f"  {'Variable':<12} {'Non-zero':>10}  {'%':>6}  Years")
    print(f"  {'-'*50}")
    for v in varlist:
        nm, nz, pct, y0, y1 = coverage(df, v, total)
        print(f"  {v:<12} {nz:>10,}  {pct:>5.1f}%  {y0}–{y1}")

# ── 3. Confirm efuvcu = eplvcu + enpvcu ───────────────────────────────────────

print("\n" + "=" * 60)
print("ELECTRICITY: efuvcu vs eplvcu + enpvcu")
print("=" * 60)

sub = df[df["eplvcu"] > 0].copy()
sub["sum_pln"] = sub["eplvcu"].fillna(0) + sub["enpvcu"].fillna(0)
mask = sub["sum_pln"] > 0
ratio = (sub.loc[mask, "efuvcu"] / sub.loc[mask, "sum_pln"]).median()
print(f"  Median efuvcu / (eplvcu + enpvcu) where eplvcu > 0:  {ratio:.4f}")
print(f"  Conclusion: {'efuvcu ≈ eplvcu + enpvcu (CONFIRMED)' if abs(ratio - 1) < 0.05 else 'NOT confirmed — investigate further'}")

sub3 = df[(df["efuvcu"] > 0) & (df["eplvcu"] > 0) & (df["enpvcu"] > 0)]
print(f"\n  Obs with all three > 0: {len(sub3):,}")
print(f"\n  Correlations (all-three-positive subset):")
print(sub3[["efuvcu", "eplvcu", "enpvcu"]].corr().round(3).to_string(index=True))
