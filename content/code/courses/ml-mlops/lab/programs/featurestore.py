"""featurestore.py: a small feature store for the lapse model, on SQLite.

    python featurestore.py backfill 2025-06-01 2026-02-22   # one snapshot a week
    python featurestore.py snapshot 2026-02-28              # tonight's snapshot
    python featurestore.py online                           # latest values, for serving
    python featurestore.py get 2                            # one member, as a service would ask

The offline store keeps every snapshot, so training can ask what a member looked
like on any past day. The online store keeps only the latest, one row per member,
so a service can ask what they look like now.
"""
import datetime as dt
import sqlite3
import sys

import pandas as pd

import features
from project import ROOT, SHOP

STORE = ROOT / "features.db"
COLUMNS = features.CATEGORICAL + features.NUMERIC
MAX_AGE = dt.timedelta(days=7)       # older than this, a value is too stale to use


def snapshot(day):
    rows = features.build(day, SHOP).drop(columns="lapsed")   # never store a label here
    rows.insert(1, "as_of", day)
    with sqlite3.connect(STORE) as db:
        if db.execute("SELECT 1 FROM sqlite_master WHERE name = 'offline'").fetchone():
            db.execute("DELETE FROM offline WHERE as_of = ?", (day,))   # rerunning a day replaces it
        rows.to_sql("offline", db, if_exists="append", index=False)
        db.execute("CREATE INDEX IF NOT EXISTS offline_by_member ON offline (member_id, as_of)")
    return len(rows)


def historical(entities):
    """For each (member_id, at) row, the features as they stood at that moment, or nothing."""
    with sqlite3.connect(STORE) as db:
        offline = pd.read_sql_query("SELECT * FROM offline", db)
    offline["as_of"] = pd.to_datetime(offline["as_of"])
    left = entities.assign(at=pd.to_datetime(entities["at"]), row=range(len(entities)))
    joined = pd.merge_asof(left.sort_values("at", kind="stable"), offline.sort_values("as_of"),
                           left_on="at", right_on="as_of", by="member_id",
                           direction="backward", tolerance=pd.Timedelta(MAX_AGE))
    return joined.sort_values("row").drop(columns="row").reset_index(drop=True)


def online():
    """The latest value per member, leaving out members whose latest is too old to serve."""
    with sqlite3.connect(STORE) as db:
        newest = db.execute("SELECT max(as_of) FROM offline").fetchone()[0]
        oldest = (dt.date.fromisoformat(newest) - MAX_AGE).isoformat()
        db.executescript(f"""
            DROP TABLE IF EXISTS online;
            CREATE TABLE online AS
              SELECT * FROM offline o
              WHERE as_of = (SELECT max(as_of) FROM offline WHERE member_id = o.member_id)
                AND as_of >= '{oldest}';
            CREATE UNIQUE INDEX online_by_member ON online (member_id);
        """)
        kept = db.execute("SELECT count(*) FROM online").fetchone()[0]
        known = db.execute("SELECT count(DISTINCT member_id) FROM offline").fetchone()[0]
    return kept, known - kept, newest


def get(member_id):
    with sqlite3.connect(STORE) as db:
        db.row_factory = sqlite3.Row
        row = db.execute("SELECT * FROM online WHERE member_id = ?", (member_id,)).fetchone()
    return dict(row) if row else None


if __name__ == "__main__":
    command = sys.argv[1]
    if command == "backfill":
        day, last = dt.date.fromisoformat(sys.argv[2]), dt.date.fromisoformat(sys.argv[3])
        total, weeks = 0, 0
        while day <= last:
            total += snapshot(day.isoformat())
            weeks += 1
            day += dt.timedelta(days=7)
        print(f"{weeks} snapshots, {total} rows in the offline store")
    elif command == "snapshot":
        print(f"{sys.argv[2]}: {snapshot(sys.argv[2])} members")
    elif command == "online":
        kept, stale, newest = online()
        print(f"online store: {kept} members as of {newest}; {stale} left out as too old to serve")
    elif command == "get":
        print(get(int(sys.argv[2])))
