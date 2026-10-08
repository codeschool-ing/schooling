---
title: A shared report, in STIX
version: 1
---

**STIX 2.1** is the OASIS standard for writing intelligence as JSON objects: indicators, the identities
that wrote them, campaigns, techniques, and the relationships between them. **TAXII** is the protocol for
moving STIX between servers. A report is a **bundle** of objects. Here is one, written for this course as
the sharing group's message of 12 September; save it in `~/week` as `intel.json`:

```json
{
  "type": "bundle",
  "id": "bundle--7c1d0e2f-3a4b-4c5d-8e6f-9a0b1c2d3e4f",
  "objects": [
    {
      "type": "marking-definition",
      "spec_version": "2.1",
      "id": "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da",
      "created": "2017-01-20T00:00:00.000Z",
      "definition_type": "tlp",
      "name": "TLP:GREEN",
      "definition": {
        "tlp": "green"
      }
    },
    {
      "type": "identity",
      "spec_version": "2.1",
      "id": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "name": "Accounting sector sharing group",
      "identity_class": "organization"
    },
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--1f2e3d4c-5b6a-4978-8a9b-0c1d2e3f4a5b",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "created_by_ref": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "name": "SSH password guessing source",
      "description": "Tried many account names against the SSH gateways of three member firms, a few seconds apart.",
      "indicator_types": [
        "malicious-activity"
      ],
      "pattern": "[ipv4-addr:value = '203.0.113.66']",
      "pattern_type": "stix",
      "valid_from": "2026-09-10T00:00:00Z",
      "valid_until": "2026-10-10T00:00:00Z",
      "confidence": 70,
      "object_marking_refs": [
        "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da"
      ]
    },
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--2a3b4c5d-6e7f-4089-9a1b-2c3d4e5f6071",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "created_by_ref": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "name": "Upload destination after SSH access",
      "description": "Received large HTTPS uploads from file servers of two member firms, after the guessing above.",
      "indicator_types": [
        "malicious-activity"
      ],
      "pattern": "[ipv4-addr:value = '203.0.113.200']",
      "pattern_type": "stix",
      "valid_from": "2026-09-10T00:00:00Z",
      "valid_until": "2026-10-10T00:00:00Z",
      "confidence": 60,
      "object_marking_refs": [
        "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da"
      ]
    },
    {
      "type": "indicator",
      "spec_version": "2.1",
      "id": "indicator--3b4c5d6e-7f80-4192-a3b4-c5d6e7f80912",
      "created": "2026-09-12T14:00:00.000Z",
      "modified": "2026-09-12T14:00:00.000Z",
      "created_by_ref": "identity--5b1e3a9c-2f4d-4e8a-9b7c-1d2e3f405162",
      "name": "SSH scanner",
      "description": "Generic scanning of SSH servers, reported in June.",
      "indicator_types": [
        "malicious-activity"
      ],
      "pattern": "[ipv4-addr:value = '203.0.113.174']",
      "pattern_type": "stix",
      "valid_from": "2026-06-01T00:00:00Z",
      "valid_until": "2026-08-01T00:00:00Z",
      "confidence": 30,
      "object_marking_refs": [
        "marking-definition--34098fce-860f-48ae-8e50-ebd3cc5e41da"
      ]
    }
  ]
}
```

Nobody reads STIX by eye for long. `jq` reads it well:

```
ana@soc:~/week$ jq -r '.objects[] | [.type, .name] | @tsv' intel.json
marking-definition	TLP:GREEN
identity	Accounting sector sharing group
indicator	SSH password guessing source
indicator	Upload destination after SSH access
indicator	SSH scanner
```

A marking, the group that wrote it, and three indicators. Their substance:

```
ana@soc:~/week$ jq '.objects[] | select(.type == "indicator") | {name, pattern, valid_until, confidence}' intel.json
{
  "name": "SSH password guessing source",
  "pattern": "[ipv4-addr:value = '203.0.113.66']",
  "valid_until": "2026-10-10T00:00:00Z",
  "confidence": 70
}
{
  "name": "Upload destination after SSH access",
  "pattern": "[ipv4-addr:value = '203.0.113.200']",
  "valid_until": "2026-10-10T00:00:00Z",
  "confidence": 60
}
{
  "name": "SSH scanner",
  "pattern": "[ipv4-addr:value = '203.0.113.174']",
  "valid_until": "2026-08-01T00:00:00Z",
  "confidence": 30
}
```

Each `pattern` is STIX's own language for "an IPv4 address whose value is…". To use them, match them
against what you saw. Save this as `match.py`:

```python
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
```

```
ana@soc:~/week$ python3 match.py intel.json
203.0.113.66    valid    confidence  70  seen 118 times, 2026-09-17 05:10:06 to 2026-09-17 06:05:22 UTC
203.0.113.200   valid    confidence  60  seen   2 times, 2026-09-17 05:41:12 to 2026-09-17 05:41:12 UTC
203.0.113.174   expired  confidence  30  seen  12 times, 2026-09-17 19:26:54 to 2026-09-21 01:44:02 UTC
```

Three different answers. `203.0.113.66` is a **valid indicator with 118 events** in the week, every one on
Thursday night: the report and the logs describe the same visitor, which raises confidence in both.
`203.0.113.200` matches **two** events, the firewall line and the flow of 612 MB: the report says three
other firms saw uploads to the same address after the same guessing, so **Thursday's transfer was very
probably the same thing**, not an innocent upload. And `203.0.113.174`, a scanner seen twelve times this
week, matches an indicator that **expired in August** with confidence 30: it explains some background
noise and justifies nothing.

Notice what the matches did and did not do. They did not find anything new: lesson 7 had already
escalated. They **raised the confidence of a hypothesis** and told the team that this is a campaign
against the sector, which matters for lessons 11 and 19. That is the usual value of an indicator: rarely
the first clue, often the one that tells you what the first clue was.
