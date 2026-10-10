"""asof.py: one member, asked about on three different days."""
import pandas as pd

from featurestore import historical

ask = pd.DataFrame({"member_id": [2, 2, 2], "at": ["2025-11-27", "2025-11-30", "2026-02-28"]})
print(historical(ask)[["member_id", "at", "as_of", "recency_days", "visits_180d"]]
      .to_string(index=False))
