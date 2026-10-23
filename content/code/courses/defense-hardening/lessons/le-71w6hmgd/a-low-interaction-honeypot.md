---
title: A low-interaction honeypot
version: 1
---

**A low-interaction honeypot answers just enough to notice a visitor and nothing more.** It does not
pretend to be a full server with logins and files, which takes work to build and gives a visitor
something to attack. It listens, it writes down who came, and it closes the door. On `trap`, a
machine nobody in the firm uses, save this as `bait.py` in your home:

```schooling-example
{"language": "python", "file": "bait.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"bait.py: listen on ports nobody in the firm uses, and record whoever connects.\"\"\"\nimport json, socket, selectors, syslog, time\n\nPORTS = [23, 445, 1433, 3389]\nLOG = \"/var/log/bait.jsonl\"", "note": "Four ports that ask to be tried: telnet, Windows file sharing, a SQL Server database and remote desktop. Jatobá runs none of them anywhere, which is the whole point. A connection to any of them on `trap` has no innocent explanation in this firm's normal work."}, {"code": "sel = selectors.DefaultSelector()\nfor port in PORTS:\n    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)\n    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)\n    s.bind((\"0.0.0.0\", port))\n    s.listen()\n    sel.register(s, selectors.EVENT_READ, port)\nsyslog.openlog(\"bait\")", "note": "One socket per port, all watched by a single loop. Nothing behind them answers like a real service: this is a **low-interaction** honeypot, which records a touch and offers nothing to work with, and so has almost nothing in it that could itself be attacked."}, {"code": "with open(LOG, \"a\", buffering=1) as log:\n    while True:\n        for key, _ in sel.select():\n            conn, (addr, sport) = key.fileobj.accept()\n            event = {\"time\": time.strftime(\"%Y-%m-%dT%H:%M:%S%z\"), \"from\": addr, \"port\": key.data}\n            conn.close()\n            log.write(json.dumps(event) + \"\\n\")\n            syslog.syslog(syslog.LOG_WARNING, f\"touched: {addr} on port {key.data}\")", "note": "Each connection is accepted, closed at once and written down twice: a JSON line for whoever studies the touches later, and a warning in the system log, which is where an alert would be raised from. The address that connected is the finding."}]}
```

Start it as a service. Ports below 1024 need root to listen on, which `systemd-run` with `sudo`
provides:

```
ana@trap:~$ sudo systemd-run -q --unit bait python3 /home/ana/bait.py
ana@trap:~$ sleep 1; sudo ss -Htlnp | grep python3 | awk '{print $4}'
0.0.0.0:1433
0.0.0.0:23
0.0.0.0:445
0.0.0.0:3389
```

Four ports are open on `trap` that Jatobá never uses. Nothing else has changed: no firewall rule,
no product, and the honeypot's own code is short enough to have read in full before running it,
which is the right standard for anything running as root on a machine meant to be touched.

## The bait has to look like something

The ports were chosen because they are what somebody exploring a network tries first: remote
desktop, file sharing, a database, an old remote login. A honeypot listening on a port nobody would
try catches nobody. **The best bait is what the firm would plausibly have**, and in a firm of
accountants a database and Windows file shares are exactly that.

`trap` also has a name, and the name matters as much as the ports. In real use it would be called
something worth a look, `fs-backup` or `sql-legacy`, never `trap` or `honeypot`. This lab calls it
`trap` so that you always know which machine is the bait.
