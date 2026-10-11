---
title: A pipeline you can read in one sitting
version: 1
---

**The five stages fit in four programs of under forty lines each, and seeing them small is the
quickest way to recognise them when they are big.** One program plays the app and generates rides;
one ingests a day of them; one transforms; one delivers the morning report. Each reads only what the
stage before it wrote, so the boundaries between the stages are files you can open.

This lesson works in a directory of its own, inside the lab from lesson 1. Make it and go into it:

```sh
mkdir -p ~/roda/lifecycle && cd ~/roda/lifecycle
```

Every program below starts with a comment naming its file. Save each one under that name in
`~/roda/lifecycle`.

## Generation: the app

The first program stands in for Roda Livre's app. It writes the app's own database, a SQLite file
called `app.db`, with three days of rides in it.

```schooling-example
{"language": "python", "file": "lifecycle/app.py", "parts": [
{"code": "# lifecycle/app.py\nimport random\nimport sqlite3\nfrom datetime import datetime, timedelta\n\nSTATIONS = {\"ST01\": \"Praça Tiradentes\", \"ST02\": \"Rua XV\", \"ST03\": \"Jardim Botânico\",\n            \"ST04\": \"Passeio Público\", \"ST05\": \"Rodoferroviária\", \"ST06\": \"Largo da Ordem\",\n            \"ST07\": \"Shopping Estação\", \"ST08\": \"Parque Barigui\", \"ST09\": \"UFPR Politécnico\",\n            \"ST10\": \"Batel\", \"ST11\": \"Mercado Municipal\", \"ST12\": \"Ópera de Arame\"}\nBUSY = [4, 6, 2, 3, 4, 3, 2, 5, 3, 3, 2, 1]\n\n", "note": "The twelve stations, and how busy each one is as a weight: Rua XV comes up six times as often as the Ópera de Arame. A real app has no such list; it is how this program imitates a city."},
{"code": "random.seed(15)\ndb = sqlite3.connect(\"app.db\")\ndb.executescript(\"\"\"\nDROP TABLE IF EXISTS stations;\nDROP TABLE IF EXISTS rides;\nCREATE TABLE stations (station_id TEXT PRIMARY KEY, name TEXT);\nCREATE TABLE rides (ride_id TEXT PRIMARY KEY, bike_id TEXT, start_station TEXT,\n                    end_station TEXT, started_at TEXT, minutes INTEGER, price_cents INTEGER);\n\"\"\")\ndb.executemany(\"INSERT INTO stations VALUES (?, ?)\", STATIONS.items())\n\n", "note": "The app's database: one SQLite file, two tables. The SQL is `sql-databases`' subject; read it here as a list of columns. The `DROP` lines mean a second run starts again from nothing, and the fixed seed means it starts from the same rides."},
{"code": "n = 0\nfor day in (14, 15, 16):\n    count = random.randint(160, 220)\n    for offset in sorted(random.randint(0, 16 * 60) for _ in range(count)):\n        n += 1\n        start, end = random.choices(list(STATIONS), BUSY, k=2)\n        at = datetime(2025, 9, day, 6) + timedelta(minutes=offset)\n        minutes = random.randint(0, 45)\n        db.execute(\"INSERT INTO rides VALUES (?, ?, ?, ?, ?, ?, ?)\",\n                   (f\"R{n:06d}\", f\"B{random.randint(1, 90):03d}\", start, end,\n                    at.strftime(\"%Y-%m-%d %H:%M\"), minutes, 300 + 20 * minutes))\n", "note": "Three days of rides, 14 to 16 September, between 06:00 and 22:00, numbered in the order they started, as an app would number them. `minutes` can be 0 or 1, which the transformation will care about. The price is made up: 300 centavos plus 20 a minute."},
{"code": "db.commit()\nprint(n, \"rides in app.db, from 14 to 16 September\")\n", "note": "Nothing is in the file until `commit`."}
]}
```

```
ana@lab:~/roda/lifecycle$ python app.py
562 rides in app.db, from 14 to 16 September
```

From here on, `app.db` is the source: the other programs read it and never write to it.

## Ingestion: one day, copied out

```schooling-example
{"language": "python", "file": "lifecycle/ingest.py", "parts": [
{"code": "# lifecycle/ingest.py\nimport json\nimport os\nimport sqlite3\nimport sys\n\n"},
{"code": "day = sys.argv[1]\napp = sqlite3.connect(\"file:app.db?mode=ro\", uri=True)\napp.row_factory = sqlite3.Row\nrides = app.execute(\"SELECT * FROM rides WHERE started_at LIKE ?\", (day + \"%\",)).fetchall()\nstations = app.execute(\"SELECT * FROM stations\").fetchall()\n\n", "note": "The day comes from the command line. `mode=ro` opens the app's database read-only, so ingestion cannot change the source even by mistake. Rides are copied one day at a time, which is an incremental load; the twelve stations are copied whole, every time, which is a full one."},
{"code": "part = f\"raw/date={day}\"\nos.makedirs(part, exist_ok=True)\nfor name, rows in ((\"rides\", rides), (\"stations\", stations)):\n    with open(f\"{part}/{name}.jsonl\", \"a\", encoding=\"utf-8\") as f:\n        for row in rows:\n            f.write(json.dumps(dict(row), ensure_ascii=False) + \"\\n\")\n    print(f\"{len(rows):4} {name:8} -> {part}/{name}.jsonl\")\n", "note": "Each table lands as JSON Lines, a row to a line, with the app's own column names, in a directory named after the day. The `\"a\"` opens each file for appending, which is the line the next section comes back to."}
]}
```

Run it for Monday:

```
ana@lab:~/roda/lifecycle$ python ingest.py 2025-09-15
 187 rides    -> raw/date=2025-09-15/rides.jsonl
  12 stations -> raw/date=2025-09-15/stations.jsonl
```

The raw zone now holds Monday, exactly as the app had it. Each line is one row of the app's table:

```
ana@lab:~/roda/lifecycle$ find raw -type f | sort
raw/date=2025-09-15/rides.jsonl
raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ head -1 raw/date=2025-09-15/rides.jsonl
{"ride_id": "R000174", "bike_id": "B014", "start_station": "ST10", "end_station": "ST04", "started_at": "2025-09-15 06:01", "minutes": 44, "price_cents": 1180}
```

## Transformation: clean, join, count

```schooling-example
{"language": "python", "file": "lifecycle/transform.py", "parts": [
{"code": "# lifecycle/transform.py\nimport csv\nimport json\nimport os\nimport sys\n\n"},
{"code": "day = sys.argv[1]\n\n\ndef read(name):\n    with open(f\"raw/date={day}/{name}.jsonl\", encoding=\"utf-8\") as f:\n        return [json.loads(line) for line in f]\n\n", "note": "The transformation reads the raw zone and nothing else. It never asks the app."},
{"code": "names = {s[\"station_id\"]: s[\"name\"] for s in read(\"stations\")}\nrides = read(\"rides\")\nkept = [r for r in rides if r[\"minutes\"] >= 2]\n\n", "note": "The lookup table for the join, and the cleaning rule: a ride under 2 minutes is a false start and is dropped. The threshold is a decision, and this line is where it is written down."},
{"code": "per_station = {}\nfor r in kept:\n    r[\"start_name\"] = names[r[\"start_station\"]]\n    per_station.setdefault(r[\"start_station\"], []).append(r[\"minutes\"])\n\n", "note": "The join, which gives each ride its station's name, and the grouping the counts come from."},
{"code": "os.makedirs(f\"clean/date={day}\", exist_ok=True)\nwith open(f\"clean/date={day}/rides.jsonl\", \"w\", encoding=\"utf-8\") as f:\n    for r in kept:\n        f.write(json.dumps(r, ensure_ascii=False) + \"\\n\")\n", "note": "The cleaned zone: every ride kept, with its name. `\"w\"` overwrites, so this step can run any number of times."},
{"code": "os.makedirs(f\"curated/date={day}\", exist_ok=True)\nwith open(f\"curated/date={day}/rides_per_station.csv\", \"w\", newline=\"\", encoding=\"utf-8\") as f:\n    out = csv.writer(f)\n    out.writerow([\"station_id\", \"name\", \"rides\", \"minutes\"])\n    for st, mins in sorted(per_station.items()):\n        out.writerow([st, names[st], len(mins), sum(mins)])\nprint(f\"{len(rides)} raw, {len(kept)} kept, {len(rides) - len(kept)} under 2 minutes dropped\")\n", "note": "The curated zone: one row per station, the shape the report wants."}
]}
```

```
ana@lab:~/roda/lifecycle$ python transform.py 2025-09-15
187 raw, 176 kept, 11 under 2 minutes dropped
```

## Delivery: the morning report

The last program reads the curated zone and nothing else. It is short enough to read whole:

```python
# lifecycle/report.py
import csv
import sys

day = sys.argv[1]
with open(f"curated/date={day}/rides_per_station.csv", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))

total = sum(int(r["rides"]) for r in rows)
print(f"Roda Livre, rides on {day}: {total}")
print("Busiest stations:")
for r in sorted(rows, key=lambda r: -int(r["rides"]))[:3]:
    print(f"  {r['station_id']} {r['name']:<16} {r['rides']:>4}")
```

```
ana@lab:~/roda/lifecycle$ python report.py 2025-09-15
Roda Livre, rides on 2025-09-15: 176
Busiest stations:
  ST02 Rua XV             29
  ST01 Praça Tiradentes   21
  ST08 Parque Barigui     16
```

That is Marta's morning report, and every stage of the lifecycle is on disk behind it:

```
ana@lab:~/roda/lifecycle$ find raw clean curated -type f | sort
clean/date=2025-09-15/rides.jsonl
curated/date=2025-09-15/rides_per_station.csv
raw/date=2025-09-15/rides.jsonl
raw/date=2025-09-15/stations.jsonl
ana@lab:~/roda/lifecycle$ head -4 curated/date=2025-09-15/rides_per_station.csv
station_id,name,rides,minutes
ST01,Praça Tiradentes,21,572
ST02,Rua XV,29,610
ST03,Jardim Botânico,12,325
```

**Each directory is one stage's output and the next stage's input.** That is what makes the
pipeline readable: when the report looks wrong, the question "which stage?" has an answer you can
open with a text editor. The next section breaks one stage on purpose, and the one after it uses the
directories to walk a number back to the app.
