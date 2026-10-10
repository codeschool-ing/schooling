---
title: A feature store in eighty lines
version: 1
---

Here is a whole feature store for the lapse model: an offline store, an online store, the
materialisation that fills them and the two ways of reading them. It is small on purpose, so that
every part of the previous section is a function you can read. It keeps its data in a second SQLite
file, `features.db`, beside `shop.db`. Save it in `~/ml` as `featurestore.py`; it imports
`features.py` and lesson 5's `project.py`.

```schooling-example
{
  "language": "python",
  "file": "featurestore.py",
  "parts": [
    {
      "code": "\"\"\"featurestore.py: a small feature store for the lapse model, on SQLite.\n\n    python featurestore.py backfill 2025-06-01 2026-02-22   # one snapshot a week\n    python featurestore.py snapshot 2026-02-28              # tonight's snapshot\n    python featurestore.py online                           # latest values, for serving\n    python featurestore.py get 2                            # one member, as a service would ask\n\nThe offline store keeps every snapshot, so training can ask what a member looked\nlike on any past day. The online store keeps only the latest, one row per member,\nso a service can ask what they look like now.\n\"\"\"\n",
      "note": "The four commands are the whole interface. Two write the offline store, one builds the online store from it, and one reads a member the way a service would."
    },
    {
      "code": "import datetime as dt\nimport sqlite3\nimport sys\n\nimport pandas as pd\n\nimport features\nfrom project import ROOT, SHOP\n\nSTORE = ROOT / \"features.db\"\nCOLUMNS = features.CATEGORICAL + features.NUMERIC\nMAX_AGE = dt.timedelta(days=7)       # older than this, a value is too stale to use\n\n\n",
      "note": "The store is a file of its own, `features.db`, beside the shop. `MAX_AGE` is how old a value may be and still be used, the store's **time to live**."
    },
    {
      "code": "def snapshot(day):\n    rows = features.build(day, SHOP).drop(columns=\"lapsed\")   # never store a label here\n    rows.insert(1, \"as_of\", day)\n    with sqlite3.connect(STORE) as db:\n        if db.execute(\"SELECT 1 FROM sqlite_master WHERE name = 'offline'\").fetchone():\n            db.execute(\"DELETE FROM offline WHERE as_of = ?\", (day,))   # rerunning a day replaces it\n        rows.to_sql(\"offline\", db, if_exists=\"append\", index=False)\n        db.execute(\"CREATE INDEX IF NOT EXISTS offline_by_member ON offline (member_id, as_of)\")\n    return len(rows)\n\n\n",
      "note": "A snapshot is `features.py` run for one day and appended, with the day beside every row as `as_of`. **The label is dropped before anything is stored**: a feature store holds what was known on a day, and the label is what was learned after it. Running a day twice replaces it rather than doubling it."
    },
    {
      "code": "def historical(entities):\n    \"\"\"For each (member_id, at) row, the features as they stood at that moment, or nothing.\"\"\"\n    with sqlite3.connect(STORE) as db:\n        offline = pd.read_sql_query(\"SELECT * FROM offline\", db)\n    offline[\"as_of\"] = pd.to_datetime(offline[\"as_of\"])\n    left = entities.assign(at=pd.to_datetime(entities[\"at\"]), row=range(len(entities)))\n    joined = pd.merge_asof(left.sort_values(\"at\", kind=\"stable\"), offline.sort_values(\"as_of\"),\n                           left_on=\"at\", right_on=\"as_of\", by=\"member_id\",\n                           direction=\"backward\", tolerance=pd.Timedelta(MAX_AGE))\n    return joined.sort_values(\"row\").drop(columns=\"row\").reset_index(drop=True)\n\n\n",
      "note": "The **point-in-time join**. For each row asked about, `merge_asof` takes that member's newest snapshot on or before the moment, never after, and gives nothing if the newest is older than `MAX_AGE`. The `row` column puts the answers back in the order they were asked."
    },
    {
      "code": "def online():\n    \"\"\"The latest value per member, leaving out members whose latest is too old to serve.\"\"\"\n    with sqlite3.connect(STORE) as db:\n        newest = db.execute(\"SELECT max(as_of) FROM offline\").fetchone()[0]\n        oldest = (dt.date.fromisoformat(newest) - MAX_AGE).isoformat()\n        db.executescript(f\"\"\"\n            DROP TABLE IF EXISTS online;\n            CREATE TABLE online AS\n              SELECT * FROM offline o\n              WHERE as_of = (SELECT max(as_of) FROM offline WHERE member_id = o.member_id)\n                AND as_of >= '{oldest}';\n            CREATE UNIQUE INDEX online_by_member ON online (member_id);\n        \"\"\")\n        kept = db.execute(\"SELECT count(*) FROM online\").fetchone()[0]\n        known = db.execute(\"SELECT count(DISTINCT member_id) FROM offline\").fetchone()[0]\n    return kept, known - kept, newest\n\n\n",
      "note": "The online store is rebuilt from the offline one: each member's latest row, **unless that row is older than `MAX_AGE`**, and one index so a lookup by member is a single seek."
    },
    {
      "code": "def get(member_id):\n    with sqlite3.connect(STORE) as db:\n        db.row_factory = sqlite3.Row\n        row = db.execute(\"SELECT * FROM online WHERE member_id = ?\", (member_id,)).fetchone()\n    return dict(row) if row else None\n\n\n",
      "note": "What a service calls: one member, one row, or `None` when the store has nothing fresh enough."
    },
    {
      "code": "if __name__ == \"__main__\":\n    command = sys.argv[1]\n    if command == \"backfill\":\n        day, last = dt.date.fromisoformat(sys.argv[2]), dt.date.fromisoformat(sys.argv[3])\n        total, weeks = 0, 0\n        while day <= last:\n            total += snapshot(day.isoformat())\n            weeks += 1\n            day += dt.timedelta(days=7)\n        print(f\"{weeks} snapshots, {total} rows in the offline store\")\n    elif command == \"snapshot\":\n        print(f\"{sys.argv[2]}: {snapshot(sys.argv[2])} members\")\n    elif command == \"online\":\n        kept, stale, newest = online()\n        print(f\"online store: {kept} members as of {newest}; {stale} left out as too old to serve\")\n    elif command == \"get\":\n        print(get(int(sys.argv[2])))\n",
      "note": "`backfill` takes one snapshot a week between two days; `snapshot` takes one, which is what a nightly job would run after the shop's load."
    }
  ]
}
```

**Everything a production store adds is around these five functions, not instead of them**: a
schedule for `snapshot`, a database that answers faster than SQLite for many readers at once, a
registry of which feature views exist and who owns them, and monitoring of how fresh each one is.
Section 10 names the products that add them.
