"""The numbers lesson 19's charts are drawn from, written to le-mtd9h75r.json.

THE STUDENT NEVER SEES THIS FILE. It runs in the lab, where pandas and seaborn are, and computes what
the lesson's cells compute; `le-mtd9h75r.py` draws from the JSON with the standard library only.

    bash ../lab.sh exec "python $PWD/le-mtd9h75r-data.py" > le-mtd9h75r.json
"""
import json

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
trips["ended_at"] = pd.to_datetime(trips["ended_at"], format=fmt)
trips["minutes"] = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60
out = {"hist": {}, "box": {}}
edges = np.arange(0, 82, 2)
for plan, m in trips.groupby("plan")["minutes"]:
    m = m.dropna()
    out["hist"][plan] = np.histogram(m, bins=edges)[0].tolist()
    q1, med, q3 = m.quantile([0.25, 0.5, 0.75])
    hi = m[m <= q3 + 1.5 * (q3 - q1)].max()
    lo = m[m >= q1 - 1.5 * (q3 - q1)].min()
    out["box"][plan] = {"q1": q1, "median": med, "q3": q3, "lo": lo, "hi": hi,
                        "fliers": m[m > hi].round(1).tolist()}
weather = pd.read_csv("weather.csv")
weather["date"] = pd.to_datetime(weather["date"], format="%Y-%m-%d")
daily = trips.groupby(trips["started_at"].dt.normalize()).size().rename("trips")
days = daily.rename_axis("date").reset_index().merge(weather, on="date")
days["weekend"] = days["date"].dt.dayofweek >= 5
days = days.dropna(subset=["rain_mm"])
out["scatter"] = [[r, int(t), bool(w)] for r, t, w in zip(days["rain_mm"], days["trips"], days["weekend"])]
fig, ax = plt.subplots()
sns.barplot(data=trips, x="plan", y="minutes", seed=8, ax=ax)
out["bars"] = [{"plan": t.get_text(), "mean": round(b.get_height(), 3),
                "lo": round(l.get_ydata()[0], 3), "hi": round(l.get_ydata()[1], 3)}
               for t, b, l in zip(ax.get_xticklabels(), ax.patches, ax.lines)]
print(json.dumps(out))
