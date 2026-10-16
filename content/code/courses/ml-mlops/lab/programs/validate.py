"""validate.py: the checks a training set must pass before anything learns from it.

    python validate.py data/train.csv
"""
import sys

import pandas as pd

import features
from project import ROOT

path = ROOT / sys.argv[1]
rows = pd.read_csv(path)
problems = []

expected = ["cutoff", "member_id", *features.CATEGORICAL, *features.NUMERIC, "lapsed"]
if sorted(rows.columns) != sorted(expected):
    problems.append(f"columns differ: {sorted(set(rows.columns) ^ set(expected))}")
if rows["member_id"].duplicated().any():
    problems.append(f"{rows['member_id'].duplicated().sum()} members appear twice")
if rows["cutoff"].nunique() != 1:
    problems.append("more than one cutoff in one file")
for column in features.NUMERIC:
    if rows[column].isna().any():
        problems.append(f"{column} has {rows[column].isna().sum()} empty values")
    if (rows[column] < 0).any():
        problems.append(f"{column} is negative for {(rows[column] < 0).sum()} members")
if not rows["lapsed"].isin([0, 1]).all():
    problems.append("lapsed holds something other than 0 and 1")
if not 0.05 <= rows["lapsed"].mean() <= 0.35:
    problems.append(f"{rows['lapsed'].mean():.1%} lapsed, outside the 5% to 35% ever seen")
if len(rows) < 1000:
    problems.append(f"only {len(rows)} rows")

if problems:
    print(f"{sys.argv[1]}: REFUSED")
    for p in problems:
        print("  -", p)
    sys.exit(1)
print(f"{sys.argv[1]}: {len(rows)} rows, every check passed")
