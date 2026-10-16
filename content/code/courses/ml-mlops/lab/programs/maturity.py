"""maturity.py: the share of members labelled lapsed, cutoff by cutoff."""
import features

for cutoff in ["2025-10-31", "2025-11-15", "2025-11-30", "2025-12-15", "2025-12-31",
               "2026-01-15", "2026-01-31", "2026-02-15"]:
    rows = features.build(cutoff)
    print(f"{cutoff}  {len(rows):5} active  {rows['lapsed'].mean():6.1%} lapsed")
