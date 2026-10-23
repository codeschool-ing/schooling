---
title: What each machine runs
version: 1
---

**A list of machines says where to look. A software inventory says what is there**: the operating
system, every package and its version, what is running, what listens on the network, and what is held
back. Lesson 1 asked those questions of one machine by hand. Here one script asks them of all of them,
over the SSH access that lesson 15 made the only way in, and keeps the answers in one file.

```schooling-example
{"language": "python", "file": "inventory.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"inventory.py HOST...: what each machine is and runs, collected over SSH, written to inventory.json.\"\"\"\nimport json, subprocess, sys\n\nASK = {\n    \"os\": \". /etc/os-release && echo $PRETTY_NAME\",\n    \"packages\": \"dpkg-query -W -f='${Package} ${Version}\\\\n'\",\n    \"services\": \"systemctl list-units --type=service --state=running --no-legend --plain | cut -d' ' -f1\",\n    \"listening\": \"ss -Htuln | awk '{print $1 \\\"/\\\" $5}' | sort -u\",\n    \"held\": \"apt-mark showhold\",\n}", "note": "Five questions, each one command that every Ubuntu machine already has. An inventory needs no agent to start with: the same SSH access lesson 15 controls is enough, and what is collected is exactly what earlier lessons asked one machine at a time."}, {"code": "\ndef ask(host, command):\n    r = subprocess.run([\"ssh\", \"-o\", \"ConnectTimeout=3\", host, command], capture_output=True, text=True)\n    if r.returncode != 0:\n        raise RuntimeError(r.stderr.strip() or f\"exit {r.returncode}\")\n    return r.stdout.strip().splitlines()", "note": "Every answer goes through one function, and a machine that does not answer raises an error instead of returning an empty list. **An empty answer would look like a machine with nothing on it**, which is the worst mistake an inventory can make."}, {"code": "\ninventory = {}\nfor host in sys.argv[1:]:\n    try:\n        facts = {name: ask(host, command) for name, command in ASK.items()}\n    except RuntimeError as e:\n        inventory[host] = {\"error\": str(e)}\n        print(f\"{host:6} UNREACHABLE  {e}\")\n        continue\n    facts[\"os\"] = facts[\"os\"][0]\n    inventory[host] = facts\n    print(f'{host:6} {facts[\"os\"]:22} {len(facts[\"packages\"]):4} packages  '\n          f'{len(facts[\"services\"]):3} services  listening: {\" \".join(facts[\"listening\"])}')\n\njson.dump(inventory, open(\"inventory.json\", \"w\"), indent=1)", "note": "A machine that cannot be read is written down as such, with the reason, and the run carries on with the others. The whole result is kept in `inventory.json`, for the next script to compare."}]}
```

Run it over every machine on the list, both the unlisted ones, and one name that does not exist, to
see what failure looks like:

```
ana@admin:~$ python3 inventory.py web desk admin jump dns sw trap printer
web    Ubuntu 24.04 LTS        322 packages   17 services  listening: tcp/0.0.0.0:111 tcp/0.0.0.0:21 tcp/0.0.0.0:22 tcp/0.0.0.0:23 tcp/0.0.0.0:80 tcp/127.0.0.1:8080 udp/0.0.0.0:111 udp/0.0.0.0:161 udp/0.0.0.0:46010 udp/0.0.0.0:5353
desk   Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
admin  Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
jump   Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
dns    Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
sw     Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
trap   Ubuntu 24.04 LTS        308 packages   10 services  listening: tcp/0.0.0.0:22
printer UNREACHABLE  ssh: Could not resolve hostname printer: Temporary failure in name resolution
```

One line per machine, and the shape is already informative. Six machines run the same 308 packages
and the same 10 services, because they come from the same image and nobody has changed them, and each
listens only for SSH. `web` stands out: 322 packages, 17 services and ten listeners, among them FTP on
21, telnet on 23 and SNMP on 161, every one of them a finding from lesson 1, back because every lesson
starts from a fresh lab.

The last line is the failure: `printer` is not a name the lab knows, and the script says so instead of
reporting an empty machine. The file `inventory.json` now holds everything collected, package by
package, and lesson 16's assessment can be run against it for every machine at once instead of one.

**This is the measured half of the inventory**, and it has to be repeated: a laptop's software changes
every week, and an inventory a month old describes a firm that no longer exists. Agents exist so it
can run continuously; the script is the same idea run by hand.
