---
title: The baseline, and the drift from it
version: 1
---

**A baseline is a written statement of what a machine of a given kind should look like.** Without one,
an inventory is a description; with one, it is a test. The role column of `hosts.csv` says what each
machine is for, and the baseline says, per role, what may listen on the network, and lists the
packages the firm has decided no machine may carry. Write it on `admin` as `baseline.json`:

```json
{
  "listening": {
    "portal":         ["tcp/0.0.0.0:22", "tcp/0.0.0.0:80", "tcp/127.0.0.1:8080"],
    "workstation":    ["tcp/0.0.0.0:22"],
    "administration": ["tcp/0.0.0.0:22"],
    "bastion":        ["tcp/0.0.0.0:22"],
    "resolver":       ["tcp/0.0.0.0:22", "tcp/0.0.0.0:53", "udp/0.0.0.0:53"]
  },
  "forbidden": ["inetutils-telnetd", "openbsd-inetd", "vsftpd", "rpcbind", "snmpd", "avahi-daemon"]
}
```

The listeners are the job of each role, from the earlier lessons: the portal's three from lesson 1,
SSH everywhere, and name service on `dns`, which lesson 14 built. The forbidden packages are the six
lesson 1 removed. Then the script that compares:

```schooling-example
{"language": "python", "file": "drift.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"drift.py: inventory.json against hosts.csv and baseline.json; one line per difference.\"\"\"\nimport csv, json\n\nhosts = {row[\"name\"]: row for row in csv.DictReader(open(\"hosts.csv\"))}\nbaseline = json.load(open(\"baseline.json\"))\ninventory = json.load(open(\"inventory.json\"))", "note": "Three files: what the firm says it has (`hosts.csv`), what each kind of machine should look like (`baseline.json`), and what was found (`inventory.json`)."}, {"code": "\nfor name, facts in inventory.items():\n    if \"error\" in facts:\n        print(f\"{name:6} could not be read: {facts['error']}\")\n        continue\n    if name not in hosts:\n        print(f\"{name:6} not in hosts.csv: nobody owns it\")\n        continue", "note": "A machine that could not be read is said first, with the reason. A machine that answered but is not listed is the next finding, because everything else about it is unknown: nobody owns it, so nobody patches it."}, {"code": "    row = hosts[name]\n    expected = set(baseline[\"listening\"][row[\"role\"]])\n    # above 32767 the kernel hands out ports nobody chose: a program's own socket, not a service\n    found = {p for p in facts[\"listening\"] if int(p.rsplit(\":\", 1)[1]) < 32768}\n    for port in sorted(found - expected):\n        print(f\"{name:6} listening, not in the baseline: {port}  (owner {row['owner']})\")\n    for port in sorted(expected - found):\n        print(f\"{name:6} in the baseline, not listening: {port}  (owner {row['owner']})\")\n    installed = {line.split(\" \")[0] for line in facts[\"packages\"]}\n    for pkg in sorted(installed & set(baseline[\"forbidden\"])):\n        print(f\"{name:6} forbidden package installed: {pkg}  (owner {row['owner']})\")", "note": "Then each listed machine against the baseline for its role: listeners that should not be there, listeners that should be and are not, and packages the firm has decided no machine may carry."}, {"code": "for name in sorted(set(hosts) - set(inventory)):\n    print(f\"{name:6} in hosts.csv, not collected\")", "note": "And the last check runs the other way: a machine on the list that nothing collected may be switched off, renamed, or gone, and the list has to say which."}]}
```

Run it:

```
ana@admin:~$ python3 drift.py
web    listening, not in the baseline: tcp/0.0.0.0:111  (owner Marta)
web    listening, not in the baseline: tcp/0.0.0.0:21  (owner Marta)
web    listening, not in the baseline: tcp/0.0.0.0:23  (owner Marta)
web    listening, not in the baseline: udp/0.0.0.0:111  (owner Marta)
web    listening, not in the baseline: udp/0.0.0.0:161  (owner Marta)
web    listening, not in the baseline: udp/0.0.0.0:5353  (owner Marta)
web    forbidden package installed: avahi-daemon  (owner Marta)
web    forbidden package installed: inetutils-telnetd  (owner Marta)
web    forbidden package installed: openbsd-inetd  (owner Marta)
web    forbidden package installed: rpcbind  (owner Marta)
web    forbidden package installed: snmpd  (owner Marta)
web    forbidden package installed: vsftpd  (owner Marta)
dns    in the baseline, not listening: tcp/0.0.0.0:53  (owner Marta)
dns    in the baseline, not listening: udp/0.0.0.0:53  (owner Marta)
sw     not in hosts.csv: nobody owns it
trap   not in hosts.csv: nobody owns it
printer could not be read: ssh: Could not resolve hostname printer: Temporary failure in name resolution
```

Every line is a finding, and every one about a listed machine has an owner beside it. `web` comes
first, with six listeners that are not in its baseline and the six packages behind them: exactly lesson
1's work, found this time by a script that would find it on fifty machines as easily as on one. Then
`dns`, whose baseline says it answers names on port 53 and which does not, because every lesson starts
from a fresh lab and lesson 14's resolver is not configured in this one.
A machine that does less than
its role says is drift too, the kind that shows up as an outage. Last come the two machines nobody owns,
and `printer`, which could not be read at all.

## Closing the drift, and proving it

Drift is closed the way lesson 1 closed it on `web`, and the inventory is how you prove it was:

```
ana@web:~$ sudo apt-get purge -y -q vsftpd openbsd-inetd inetutils-telnetd rpcbind avahi-daemon snmpd >/dev/null 2>&1; echo done
done
ana@admin:~$ python3 inventory.py web desk admin jump dns sw trap > /dev/null; python3 drift.py
dns    in the baseline, not listening: tcp/0.0.0.0:53  (owner Marta)
dns    in the baseline, not listening: udp/0.0.0.0:53  (owner Marta)
sw     not in hosts.csv: nobody owns it
trap   not in hosts.csv: nobody owns it
```

After the purge, a new collection and a new comparison, and `web` has nothing left to report. The
remaining lines are the ones that need a person rather than a command: an owner for two machines and a
decision about the resolver.

**The loop, measure, compare and fix, is what lesson 3's centralised configuration automates.** There,
the desired state is written as a playbook and applied; here, it is written as a baseline and checked.
Both are needed, because a machine can drift between runs of the first, and only the second says that
it did.
