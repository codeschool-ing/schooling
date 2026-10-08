# match.py INTEL.json: look up every indicator address in siem.db, and say if it is still valid
import json, sqlite3, sys, datetime as dt

WEEK_END = dt.datetime(2026, 9, 21, 3, tzinfo=dt.timezone.utc)   # Sunday midnight, local
db = sqlite3.connect("siem.db")
for o in json.load(open(sys.argv[1]))["objects"]:
    if o["type"] != "indicator":
        continue
    ip = o["pattern"].split("'")[1]
    until = dt.datetime.fromisoformat(o["valid_until"].replace("Z", "+00:00"))
    state = "valid" if until > WEEK_END else "expired"
    seen = db.execute("SELECT count(*), min(timestamp), max(timestamp) FROM logs "
                      "WHERE src_ip = ? OR dst_ip = ?", (ip, ip)).fetchone()
    print(f"{ip:15} {state:8} confidence {o['confidence']:3}  seen {seen[0]:3} times"
          + (f", {seen[1]} to {seen[2]} UTC" if seen[0] else ""))
