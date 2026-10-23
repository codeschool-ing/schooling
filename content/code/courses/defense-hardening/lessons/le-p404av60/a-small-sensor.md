---
title: A sensor in under forty lines
version: 1
---

**A sensor is a program that watches one machine and writes down what it sees, in a form a
machine can read back.** Commercial sensors are large because they watch everything, survive
attempts to stop them and send their records somewhere safe. The core is small enough to read in
one sitting, and reading it is the fastest way to understand what the large ones are doing and
where they can be wrong.

This one watches processes. Save it on `web` as `/usr/local/sbin/sensor.py`; you need `sudo` to
write there, and that is deliberate, because a sensor that any account can edit records whatever
that account wants it to:

```sh
sudo nano /usr/local/sbin/sensor.py
```

```schooling-example
{"language": "python", "file": "sensor.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"sensor.py: every new process on this machine, as one line of JSON, with its parents.\"\"\"\nimport json, os, pwd, socket, time\n\nOUT = \"/var/log/sensor.jsonl\"\nHOST = socket.gethostname()", "note": "The sensor writes one JSON object per line to `/var/log/sensor.jsonl`. One object per line is what log shippers and `jq` read without parsing the whole file, and it is the shape every EDR's raw telemetry takes on its way to a console."}, {"code": "def info(pid):\n    try:\n        with open(f\"/proc/{pid}/stat\") as f:\n            ppid = int(f.read().rsplit(\")\", 1)[1].split()[1])\n        with open(f\"/proc/{pid}/cmdline\", \"rb\") as f:\n            cmd = f.read().replace(b\"\\0\", b\" \").decode(errors=\"replace\").strip()\n        uid = os.stat(f\"/proc/{pid}\").st_uid\n        exe = os.readlink(f\"/proc/{pid}/exe\")\n    except OSError:\n        return None  # it ended between two reads, or is a kernel thread with no program\n    return {\"pid\": pid, \"ppid\": ppid, \"user\": pwd.getpwuid(uid).pw_name, \"exe\": exe, \"cmd\": cmd}", "note": "Everything the kernel knows about a process is a directory under `/proc`. `stat` holds the parent's id after the name in brackets, `cmdline` the arguments separated by zero bytes, and `exe` is a link to the program file itself. A process can end between two of these reads, and then the function gives up on it rather than guess."}, {"code": "def parents(pid):\n    chain = []\n    while pid > 1 and len(chain) < 6:\n        p = info(pid)\n        if p is None:\n            break\n        chain.append(os.path.basename(p[\"exe\"]))\n        pid = p[\"ppid\"]\n    return chain", "note": "The parent chain is the field that makes this telemetry rather than a process list. `bash` on its own means nothing; `bash` whose parent is the web server's account is the question an analyst asks first. Six levels are plenty to reach a service or a login."}, {"code": "seen = {int(p) for p in os.listdir(\"/proc\") if p.isdigit()}\nwith open(OUT, \"a\", buffering=1) as log:\n    while True:\n        now = {int(p) for p in os.listdir(\"/proc\") if p.isdigit()}\n        for pid in sorted(now - seen):\n            p = info(pid)\n            if p is not None:\n                p[\"parents\"] = parents(p[\"ppid\"])\n                p[\"time\"] = time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")\n                p[\"host\"] = HOST\n                log.write(json.dumps(p) + \"\\n\")\n        seen = now\n        time.sleep(0.2)", "note": "The loop compares the list of process ids five times a second with the list before it. Every id that is new gets a line. **That is the sensor's whole method, and its weakness**: a process that starts and ends between two looks is never seen at all."}]}
```

Check what you pasted, then start it as a service of its own. `systemd-run` turns a command into a
temporary unit, which gives it a name, restarts nothing and stops when you stop it:

```
ana@web:~$ sha256sum /usr/local/sbin/sensor.py
95d23b1ebe37822ea1714107ad42d9712acd63ea89e6c8698fdd4bd039422653  /usr/local/sbin/sensor.py
ana@web:~$ sudo systemd-run --unit sensor /usr/bin/python3 /usr/local/sbin/sensor.py
Running as unit: sensor.service; invocation ID: 1615c2408e18470980b66f65808a4224
ana@web:~$ sleep 1; grep "\"sleep 1\"" /var/log/sensor.jsonl | jq .
{
  "pid": 154,
  "ppid": 152,
  "user": "ana",
  "exe": "/usr/bin/sleep",
  "cmd": "sleep 1",
  "parents": [
    "bash",
    "su"
  ],
  "time": "2026-10-23T02:02:03-0300",
  "host": "web"
}
```

The `sleep 1` typed in the same command line was caught, and the JSON says everything the last
section asked for: the program file, the arguments, ana as the account, and above it `bash` and
`su`, the shell and the login it came from. Every process started on `web` from now on gets a line
like that.

## What it misses

A sensor that looks five times a second misses whatever lives less than a fifth of a second. That
is not a guess; it can be measured:

```
ana@web:~$ for i in $(seq 20); do /bin/true; done; sleep 1; grep -c "\"/usr/bin/true\"" /var/log/sensor.jsonl
0
ana@web:~$ sleep 0.5; sleep 1; grep -c "\"sleep 0.5\"" /var/log/sensor.jsonl
1
```

Twenty runs of `/bin/true`, each over in a millisecond or two, and **not one** reached the file. A
`sleep` of half a second was seen. Anything an intruder does in a single quick command, a download
that finishes fast, a file copied, a setting changed, passes between two looks. Looking faster costs
processor time and only narrows the gap, it never closes it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l08-gap\" aria-label=\"A timeline of one second with the sensor looking every fifth of a second, five looks drawn as ticks. A process that lives two milliseconds starts and ends between two ticks and is never seen. A process that lives half a second spans two or three ticks and is recorded at the first one.\"><path d=\"M60.0 150.0 L660.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 140.0 L60.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"60.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0 s</text><path d=\"M180.0 140.0 L180.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"180.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2 s</text><path d=\"M300.0 140.0 L300.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"300.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4 s</text><path d=\"M420.0 140.0 L420.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"420.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6 s</text><path d=\"M540.0 140.0 L540.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"540.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8 s</text><path d=\"M660.0 140.0 L660.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"660.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.0 s</text><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the sensor looks at /proc at each tick</text><rect x=\"170.0\" y=\"92.0\" width=\"6.0\" height=\"20.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"173.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">/bin/true, 2 ms: never seen</text><rect x=\"330.0\" y=\"92.0\" width=\"300.0\" height=\"20.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"480.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sleep 0.5: seen at 0.6 s</text><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">polling five times a second</text></svg>", "caption": "Anything that starts and ends between two looks leaves no trace in the file."}
```

The same weakness hides one more. When a process ends, its children are adopted by process 1, so a
sensor that reads the parents **after the fact** finds a chain that is already broken. The next
section meets exactly that.

A product closes both gaps the same way, by being told rather than by looking: the kernel calls
the sensor at the moment a program starts, before it has run a single instruction, with its
parents still in place. The last section of this lesson says how.
