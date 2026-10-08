---
title: The week the SIEM will read
version: 1
---

A SIEM is worth building only if it has something to read, and the lab's own logs from lesson 1 hold a
few minutes. The rest of the course reads a **week**: Monday 14 to Sunday 20 September 2026, at the lab's
company, written by a short program so that every reader gets exactly the same lines. Make a folder
called `week` in your home folder and save this in it as `week.py`:

```schooling-example
{"language": "python", "file": "week.py", "parts": [{"code": "# week.py: one week of logs from the company in the lab, 14 to 20 September 2026.\n# Ordinary days, plus one night somebody has to find. Same output on every run.\nimport random, datetime as dt\n\nrandom.seed(7)\nZ = dt.timezone(dt.timedelta(hours=-3))\nSTAFF = {\"ana\": \"203.0.113.11\", \"bruno\": \"203.0.113.17\", \"carla\": \"203.0.113.23\",\n         \"diego\": \"203.0.113.31\", \"helena\": \"203.0.113.41\"}\nKEYS = {\"ana\", \"diego\"}                      # who logs in with a key\nGUESSES = [\"root\", \"admin\", \"test\", \"oracle\", \"ubuntu\", \"user\", \"backup\", \"git\"]\nauth, fw, flows = [], [], []", "note": "The cast: five people and the addresses they work from at home, which two of them log in with a key, and the names strangers on the internet try. `random.seed(7)` makes every run identical."}, {"code": "def t(day, h, m, s=0):\n    return dt.datetime(2026, 9, day, h, m, s, tzinfo=Z)\n\n\ndef port():\n    return random.randint(32768, 60999)\n\n\ndef ssh(when, host, text):\n    auth.append((when, f\"{when:%Y-%m-%dT%H:%M:%S%z} {host} sshd: {text}\"))\n\n\ndef conn(when, inn, out, src, dst, dport):\n    fw.append((when, f\"{when:%b %e %H:%M:%S} fw fw-new  IN={inn} OUT={out} \"\n                     f\"SRC={src} DST={dst} PROTO=TCP SPT={port()} DPT={dport}\"))\n\n\ndef flow(when, src, dst, dport, seconds, nbytes):\n    flows.append((when, f\"{when:%Y-%m-%d %H:%M:%S},{seconds},{src},{dst},{dport},{nbytes}\"))\n\n\ndef attempt(when, src, name, known):\n    conn(when, \"eth0\", \"eth1\", src, \"198.51.100.22\", 22)\n    if known:\n        ssh(when, \"gw\", f\"Failed password for {name} from {src} port {port()} ssh2\")\n    else:\n        ssh(when, \"gw\", f\"Invalid user {name} from {src} port {port()}\")\n\n\ndef login(when, user, src, how):\n    conn(when, \"eth0\", \"eth1\", src, \"198.51.100.22\", 22)\n    ssh(when, \"gw\", f\"Accepted {how} for {user} from {src} port {port()} ssh2\")", "note": "Four writers, one per kind of line, in the formats of lesson 1: `ssh` in `ts`'s format, `conn` like the firewall's (only the fields this course reads), and `flow` as a CSV row."}, {"code": "for day in range(14, 21):\n    conn(t(day, 1, 0), \"eth2\", \"eth0\", \"192.168.20.10\", \"203.0.113.150\", 443)\n    flow(t(day, 1, 0), \"192.168.20.10\", \"203.0.113.150\", 443,\n         random.randint(500, 700), random.randint(330, 380) * 1_000_000)  # nightly backup\n    for n in range(random.randint(4, 8)):              # strangers trying common names\n        src = f\"203.0.113.{random.randint(100, 199)}\"\n        when = t(day, random.randint(0, 23), random.randint(0, 59), random.randint(0, 59))\n        for name in random.sample(GUESSES, random.randint(1, 3)):\n            when += dt.timedelta(seconds=random.randint(2, 9))\n            attempt(when, src, name, name == \"root\")\n    if dt.date(2026, 9, day).weekday() < 5:            # staff start work from home\n        for user, src in STAFF.items():\n            when = t(day, 8, random.randint(0, 59), random.randint(0, 59))\n            if user not in KEYS and random.random() < 0.15:   # a typo first\n                attempt(when, src, user, True)\n                when += dt.timedelta(seconds=random.randint(4, 12))\n            login(when, user, src, \"publickey\" if user in KEYS else \"password\")\n            if user == \"diego\":                         # IT: on to the file server\n                when += dt.timedelta(minutes=random.randint(2, 20))\n                conn(when, \"eth1\", \"eth2\", \"198.51.100.22\", \"192.168.20.10\", 22)\n                ssh(when, \"files\", f\"Accepted publickey for diego from 198.51.100.22 port {port()} ssh2\")", "note": "An ordinary day: the nightly backup to a fixed provider at 01:00, a handful of strangers trying common names, and on weekdays everybody logging in around eight, now and then after a typo. Diego, who runs IT, goes on to the file server."}, {"code": "# Thursday night\nnames = list(STAFF) + GUESSES + [\"finance\", \"hr\", \"scanner\", \"printer\", \"support\", \"dev\"]\nwhen = t(17, 2, 10)\nfor _ in range(3):\n    for name in names:\n        when += dt.timedelta(seconds=random.randint(5, 9))\n        attempt(when, \"203.0.113.66\", name, name in STAFF or name == \"root\")\nlogin(t(17, 2, 33, 7), \"bruno\", \"203.0.113.66\", \"password\")\nconn(t(17, 2, 35, 40), \"eth1\", \"eth2\", \"198.51.100.22\", \"192.168.20.10\", 22)\nssh(t(17, 2, 35, 40), \"files\", \"Accepted password for bruno from 198.51.100.22 port 40112 ssh2\")\nconn(t(17, 2, 41, 12), \"eth2\", \"eth0\", \"192.168.20.10\", \"203.0.113.200\", 443)\nflow(t(17, 2, 41, 12), \"192.168.20.10\", \"203.0.113.200\", 443, 1104, 612_408_119)\nlogin(t(17, 3, 5, 22), \"bruno\", \"203.0.113.66\", \"publickey\")", "note": "The night the rest of the course investigates. You are reading the generator, so you know the plot; the exercises ask you to find it with the tools, the way you would with no generator to read."}, {"code": "for name, rows in ((\"auth.log\", auth), (\"fw.log\", fw), (\"flows.csv\", flows)):\n    with open(name, \"w\") as f:\n        if name == \"flows.csv\":\n            f.write(\"start,seconds,src,dst,dport,bytes\\n\")\n        f.writelines(line + \"\\n\" for _, line in sorted(rows))", "note": "Each file sorted by time and written once."}]}
```

Run it, and look at what it wrote:

```
ana@soc:~/week$ python3 week.py
ana@soc:~/week$ wc -l auth.log fw.log flows.csv
  183 auth.log
  191 fw.log
    9 flows.csv
  383 total
ana@soc:~/week$ head -n 2 auth.log; head -n 2 fw.log; head -n 3 flows.csv
2026-09-14T06:31:52-0300 gw sshd: Invalid user backup from 203.0.113.179 port 47617
2026-09-14T06:31:59-0300 gw sshd: Invalid user git from 203.0.113.179 port 40908
Sep 14 01:00:00 fw fw-new  IN=eth2 OUT=eth0 SRC=192.168.20.10 DST=203.0.113.150 PROTO=TCP SPT=43379 DPT=443
Sep 14 06:31:52 fw fw-new  IN=eth0 OUT=eth1 SRC=203.0.113.179 DST=198.51.100.22 PROTO=TCP SPT=51955 DPT=22
start,seconds,src,dst,dport,bytes
2026-09-14 01:00:00,538,192.168.20.10,203.0.113.150,443,355000000
2026-09-15 01:00:00,652,192.168.20.10,203.0.113.150,443,361000000
```

Three files, 383 lines, in the formats you already know: `auth.log` is SSH on `gw` and `files`,
`fw.log` is the firewall's line for each new connection, and `flows.csv` holds one summary per long
transfer. Notice that the first firewall line, at 01:00 on Monday, is the backup leaving for
`203.0.113.150`, and the flows file shows it every night at about 340 to 370 MB. That is what normal looks
like here, and the lessons that follow keep coming back to it.

You will meet these files again in lessons 5 to 15. Keep the folder; if you lose it, running `week.py`
again rebuilds every file identically.
