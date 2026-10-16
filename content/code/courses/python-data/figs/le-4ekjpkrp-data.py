"""The numbers lesson 18's charts are drawn from, written to le-4ekjpkrp.json.

THE STUDENT NEVER SEES THIS FILE. It runs in the lab, where pandas is, and computes exactly what the
lesson's cells compute; `le-4ekjpkrp.py` draws from the JSON with the standard library only.

    bash ../lab.sh exec "python $PWD/le-4ekjpkrp-data.py" > le-4ekjpkrp.json
"""
import json

import pandas as pd

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
stations = pd.read_csv("stations.csv")
daily = trips.set_index("started_at").resample("D").size()
week = daily.rolling(7).mean()
monthly = daily.resample("MS").sum()
current = stations.drop_duplicates("station_id", keep="last").set_index("station_id")["name"]
per_station = trips["start_station"].map(current).value_counts().sort_values()
trips["hour"] = trips["started_at"].dt.hour
trips["weekend"] = trips["started_at"].dt.dayofweek >= 5
days = pd.Series(daily.index.dayofweek >= 5).value_counts()
per_hour = trips.groupby(["weekend", "hour"]).size().unstack("weekend") / days
print(json.dumps({
    "daily": daily.tolist(),
    "week": [None if pd.isna(v) else round(v, 3) for v in week],
    "monthly": monthly.tolist(),
    "stations": [[k, int(v)] for k, v in per_station.items()],
    "weekday": [round(v, 3) for v in per_hour[False]],
    "weekend": [round(v, 3) for v in per_hour[True]],
}, ensure_ascii=False))
