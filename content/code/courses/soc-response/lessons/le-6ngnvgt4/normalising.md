---
title: Normalising: one name for each thing
version: 1
---

Three files, three vocabularies. SSH says `from 203.0.113.66`, the firewall says `SRC=203.0.113.66`, the
flow file has a column called `src`. A question such as "everything this address did" has to be asked
three ways, and the firewall's time has no year. **Normalisation** writes each event once, in one table,
with one name per thing. Save this as `load.py`, in the same folder:

```schooling-example
{"language": "python", "file": "load.py", "parts": [{"code": "# load.py: read the week's three files into one table, every field named the same way\nimport csv, re, sqlite3, datetime as dt\n\nSP = dt.timezone(dt.timedelta(hours=-3))\ndb = sqlite3.connect(\"siem.db\")\ndb.execute(\"DROP TABLE IF EXISTS logs\")\ndb.execute(\"\"\"CREATE TABLE logs (timestamp TEXT, host TEXT, product TEXT, action TEXT,\n              detail TEXT, user TEXT, method TEXT, src_ip TEXT, dst_ip TEXT,\n              dst_port INTEGER, bytes INTEGER, raw TEXT)\"\"\")", "note": "One table, `logs`, with the same columns for every source. The name is the one Sigma's SQLite backend expects."}, {"code": "def utc(when):\n    return when.astimezone(dt.timezone.utc).strftime(\"%Y-%m-%d %H:%M:%S\")", "note": "Every time is stored in UTC, as lesson 2 asked."}, {"code": "SSH = re.compile(r\"(?P<ts>\\S+) (?P<host>\\S+) sshd: (?:Accepted (?P<method>\\S+) for (?P<ok>\\S+)\"\n                 r\"|Failed password for (?P<bad>\\S+)|Invalid user (?P<unknown>\\S+)) from (?P<src>\\S+)\")\nrows = []\nfor line in open(\"auth.log\"):\n    m = SSH.match(line)\n    if not m:\n        continue\n    when = dt.datetime.strptime(m[\"ts\"], \"%Y-%m-%dT%H:%M:%S%z\")\n    action = \"success\" if m[\"ok\"] else \"failure\"\n    detail = \"unknown_user\" if m[\"unknown\"] else (\"wrong_password\" if m[\"bad\"] else None)\n    user = m[\"ok\"] or m[\"bad\"] or m[\"unknown\"]\n    rows.append((utc(when), m[\"host\"], \"sshd\", action, detail, user, m[\"method\"],\n                 m[\"src\"], None, 22, None, line.strip()))", "note": "An SSH line becomes `success` or `failure`, with the account it named and, for a failure, whether that account exists. The regular expression is the parser; a line it does not match is skipped, and a real SIEM would count those."}, {"code": "for line in open(\"fw.log\"):\n    # the firewall writes no year and no zone: both are assumed here, out loud\n    when = dt.datetime.strptime(\"2026 \" + line[:15], \"%Y %b %d %H:%M:%S\").replace(tzinfo=SP)\n    f = dict(p.split(\"=\", 1) for p in line.split() if \"=\" in p)\n    rows.append((utc(when), \"fw\", \"firewall\", \"connection\", None, None, None,\n                 f[\"SRC\"], f[\"DST\"], int(f[\"DPT\"]), None, line.strip()))", "note": "The firewall's line has no year and no zone, so both are supplied here, written down where anyone reading the code sees them."}, {"code": "for r in csv.DictReader(open(\"flows.csv\")):\n    when = dt.datetime.strptime(r[\"start\"], \"%Y-%m-%d %H:%M:%S\").replace(tzinfo=SP)\n    rows.append((utc(when), \"fw\", \"flow\", \"flow\", None, None, None,\n                 r[\"src\"], r[\"dst\"], int(r[\"dport\"]), int(r[\"bytes\"]), \",\".join(r.values())))", "note": "A flow row keeps its bytes, the one field neither log has."}, {"code": "db.executemany(\"INSERT INTO logs VALUES (?,?,?,?,?,?,?,?,?,?,?,?)\", rows)\ndb.commit()\nprint(len(rows), \"rows in siem.db\")"}]}
```

Run it and count what landed:

```
ana@soc:~/week$ python3 load.py
382 rows in siem.db
ana@soc:~/week$ sqlite3 -header -column siem.db 'SELECT product, action, count(*) AS n FROM logs GROUP BY 1, 2'
product   action      n  
--------  ----------  ---
firewall  connection  191
flow      flow        8  
sshd      failure     150
sshd      success     33 
```

382 rows from 383 lines: the CSV's header is not an event. One row, all fields shown, next to the line it
came from:

```
ana@soc:~/week$ sqlite3 -line siem.db "SELECT * FROM logs WHERE user = 'hr' LIMIT 1"
timestamp = 2026-09-17 05:11:39
     host = gw
  product = sshd
   action = failure
   detail = unknown_user
     user = hr
   method = 
   src_ip = 203.0.113.66
   dst_ip = 
 dst_port = 22
    bytes = 
      raw = 2026-09-17T02:11:39-0300 gw sshd: Invalid user hr from 203.0.113.66 port 37412
```

The raw line is kept beside the fields. **Never throw the original away**: the parser is code, code has
bugs, and the day a field turns out wrong is the day you need to parse again. Notice also `detail =
unknown_user`, which says the account `hr` does not exist on `gw`. That distinction, between a wrong
password and an account that is not there, comes from lesson 2, and lesson 9 depends on it.

The firewall's row shows the other half of normalisation, the time:

```
ana@soc:~/week$ sqlite3 siem.db "SELECT timestamp, raw FROM logs WHERE product = 'firewall' LIMIT 1"
2026-09-14 04:00:00|Sep 14 01:00:00 fw fw-new  IN=eth2 OUT=eth0 SRC=192.168.20.10 DST=203.0.113.150 PROTO=TCP SPT=43379 DPT=443
```

The line says `Sep 14 01:00:00`, local, with no year; the table says `2026-09-14 04:00:00`, in UTC. Both
assumptions, the year and the zone, are written in `load.py` where a reader sees them. A SIEM does the same
thing through configuration rather than code, and the configuration deserves the same scrutiny: **a wrong
zone on one source moves every one of its events by hours**, and no alert says so.
