---
title: A year of findings, generated
version: 1
---

Real findings belong to a real company and are not something a course can hand out, and one
pipeline on one laptop produces a few dozen, too few to show what a median does. So the data set
in this lesson is generated: a year of findings for a made-up company with four teams, fourteen
targets and the four kinds of scanner this course has put in the pipeline.

**Generated does not mean random.** The program below seeds its own random number generator, so
every run writes the same two files, and the numbers you measure on your machine are the ones in
this lesson. It also lets you read the cause behind every pattern the measurements find, which a
real dashboard never offers: when a team's numbers look too good in the section on Goodhart's law,
you can find the line that made them so.

### The generator

Make a directory for the lesson, outside the project, since these numbers describe a company and
not linkbox:

```
ana@vm:~$ mkdir ~/metrics && cd ~/metrics
ana@vm:~/metrics$ python3 --version
Python 3.13.16
```

It needs nothing but Python 3. Save it as `~/metrics/gen.py`:

```schooling-example
{"language": "python", "file": "gen.py", "parts": [{"code": "\"\"\"A year of security findings for a made-up company of four teams, the\nsame every time it runs. It writes two files: inventory.csv, what exists\nand which scanners look at it, and findings.csv, what those scanners found\nand what happened to each finding.\"\"\"\nimport csv\nimport datetime as dt\nimport math\nimport random\n", "note": "Only the standard library, so the program runs on any Python 3 with nothing installed."}, {"code": "rng = random.Random(19)\nSTART, TODAY = dt.date(2025, 10, 1), dt.date(2026, 10, 1)\n", "note": "**The seed is what makes it a data set rather than a draw.** Every run of `random.Random(19)` produces the same sequence, so your files match the ones measured in this lesson byte for byte. `TODAY` is fixed for the same reason: the age of an open finding depends on it."}, {"code": "# What exists: name, team, kind, and the scanners that run on it.\nINVENTORY = [\n    (\"linkbox\", \"links\", \"repo\", \"sast sca secrets\"),\n    (\"linkbox\", \"links\", \"image\", \"image\"),\n    (\"link-stats\", \"links\", \"repo\", \"sast sca secrets\"),\n    (\"billing-api\", \"payments\", \"repo\", \"sast sca secrets\"),\n    (\"billing-api\", \"payments\", \"image\", \"image\"),\n    (\"invoices\", \"payments\", \"repo\", \"sca secrets\"),\n    (\"refunds-worker\", \"payments\", \"image\", \"\"),\n    (\"storefront\", \"web\", \"repo\", \"sast sca secrets\"),\n    (\"storefront\", \"web\", \"image\", \"image\"),\n    (\"web-assets\", \"web\", \"repo\", \"secrets\"),\n    (\"auth-gateway\", \"platform\", \"repo\", \"sast sca secrets\"),\n    (\"auth-gateway\", \"platform\", \"image\", \"image\"),\n    (\"legacy-reports\", \"platform\", \"repo\", \"\"),\n    (\"legacy-reports\", \"platform\", \"image\", \"\"),\n]\n", "note": "Fourteen targets: eight repositories and six images, and the scanners pointed at each. Two names have nothing pointed at them, and `invoices` has no static analysis. Coverage is measured from this list, never from the findings."}, {"code": "# Findings a scanner raises per month on one target, and their severities.\nRATE = {\"sast\": 2.0, \"sca\": 2.5, \"secrets\": 0.2, \"image\": 4.0}\nSEVERITY = {\"critical\": 0.05, \"high\": 0.20, \"medium\": 0.45, \"low\": 0.30}\n# The median number of days a fix takes, per severity.\nTYPICAL_FIX = {\"critical\": 5, \"high\": 18, \"medium\": 40, \"low\": 70}\n\n", "note": "How noisy each scanner is, per target and per month, and the mix of severities. `TYPICAL_FIX` is the median a fix takes when somebody does fix it."}, {"code": "def poisson(mean):\n    n, p, limit = 0, 1.0, math.exp(-mean)\n    while True:\n        p *= rng.random()\n        if p < limit:\n            return n\n        n += 1\n\n", "note": "A Poisson draw, Knuth's method: how many findings arrive on one day when the average is a fraction of one."}, {"code": "def outcome(team, severity):\n    \"\"\"How a finding leaves the open list, and how many days that takes.\"\"\"\n    roll = rng.random()\n    if roll < 0.08:\n        return \"false_positive\", rng.randint(1, 10)\n    # One team closes much of what is not urgent as \"won't fix\", and fast.\n    if team == \"payments\" and severity in (\"medium\", \"low\") and roll < 0.55:\n        return \"wont_fix\", rng.randint(1, 5)\n    if roll < 0.12:\n        return \"wont_fix\", rng.randint(10, 60)\n    return \"fixed\", max(1, round(TYPICAL_FIX[severity] * rng.lognormvariate(0, 0.9)))\n\n", "note": "How a finding leaves the list. Most are fixed, after a number of days drawn around `TYPICAL_FIX` with a long tail; some are false positives found out quickly; some are closed as \"won't fix\". **The `payments` line is planted on purpose**, so that the section on Goodhart's law has a team gaming its median for you to find."}, {"code": "findings = []\nfor name, team, kind, scanners in INVENTORY:\n    for tool in scanners.split():\n        day = START\n        while day < TODAY:\n            for _ in range(poisson(RATE[tool] / 30)):\n                severity = rng.choices(list(SEVERITY), list(SEVERITY.values()))[0]\n                if tool == \"secrets\":  # a leaked credential is high, always\n                    severity = \"high\"\n                resolution, days = outcome(team, severity)\n                closed = day + dt.timedelta(days=days)\n                if closed > TODAY:\n                    resolution, closed = \"\", None\n                findings.append([name, kind, team, tool, severity, day, closed, resolution])\n            day += dt.timedelta(days=1)\n", "note": "One day at a time, for every scanner on every target. A finding whose closing date falls after `TODAY` is still open, so its `closed` and `resolution` stay empty."}, {"code": "findings.sort(key=lambda f: f[5])\nwith open(\"findings.csv\", \"w\", newline=\"\") as out:\n    w = csv.writer(out)\n    w.writerow([\"id\", \"target\", \"kind\", \"team\", \"tool\", \"severity\", \"opened\", \"closed\", \"resolution\"])\n    for n, f in enumerate(findings, 1):\n        w.writerow([f\"F{n:04d}\", *f[:6], f[6] or \"\", f[7]])\nwith open(\"inventory.csv\", \"w\", newline=\"\") as out:\n    w = csv.writer(out)\n    w.writerow([\"target\", \"team\", \"kind\", \"scanners\"])\n    w.writerows(INVENTORY)\nprint(f\"{len(findings)} findings on {len(INVENTORY)} targets\")", "note": "Two CSV files, sorted by the day each finding was opened, with an id per finding."}]}
```

Three choices in it shape everything measured later, and each one imitates something real.

**Fix times have a long tail.** A fix is drawn as a typical number of days for its severity,
multiplied by a log-normal factor. Most fixes land near the typical value and a few take three or
four times as long: the dependency whose update breaks an interface, the finding nobody owns. Fix
times tend to have that shape, and it is the reason the next section argues for the median.

**Not everything leaves the list by being fixed.** About one finding in twelve is a false positive,
found out within days, and a few are closed as "won't fix" after weeks. The `payments` team closes
nearly half of its medium and low findings as "won't fix" within five days. Nothing marks that
team as special in the output; only the measurements can find it.

**The inventory is part of the data.** Two targets have no scanner at all and some have only one
or two. A generator of findings alone could not show what is missing, because a target with no
scanner produces no rows.

### Running it

```
ana@vm:~/metrics$ python3 gen.py
509 findings on 14 targets
ana@vm:~/metrics$ sha256sum findings.csv inventory.csv
fc6105a65c5c57724e841df691dfa1f73a1b7617e5ca611df3ef3239226b5faa  findings.csv
3b06a2c6982610dcb6849d9bd4538fd97f9d6db9201241ec9014d7db9c218960  inventory.csv
ana@vm:~/metrics$ python3 gen.py
509 findings on 14 targets
ana@vm:~/metrics$ sha256sum findings.csv inventory.csv
fc6105a65c5c57724e841df691dfa1f73a1b7617e5ca611df3ef3239226b5faa  findings.csv
3b06a2c6982610dcb6849d9bd4538fd97f9d6db9201241ec9014d7db9c218960  inventory.csv
```

Two runs, the same checksums: that is what the seed buys. If your checksums differ, your copy of the
program differs from the one above, and every number in this lesson will be different too.

The findings file starts like this, one row per finding, with the header first:

```
ana@vm:~/metrics$ head -n 6 findings.csv
id,target,kind,team,tool,severity,opened,closed,resolution
F0001,linkbox,repo,links,secrets,high,2025-10-01,2025-11-06,fixed
F0002,linkbox,image,links,image,medium,2025-10-02,2025-11-27,fixed
F0003,billing-api,image,payments,image,medium,2025-10-02,2025-10-24,fixed
F0004,auth-gateway,repo,platform,sast,medium,2025-10-04,2025-11-18,fixed
F0005,linkbox,repo,links,sast,high,2025-10-06,2025-10-16,fixed
ana@vm:~/metrics$ wc -l findings.csv inventory.csv
  510 findings.csv
   15 inventory.csv
  525 total
```

509 findings and the header line, 14 targets and theirs. Each row says where the finding was
(`target` and `kind`), who owns it (`team`), which scanner raised it (`tool`), how serious it is
(`severity`), and its two dates. `resolution` is how it left the list, and both `closed` and
`resolution` are empty while it is open.

### A first look, with no program at all

Before writing any measurement, count the column that matters most. `cut` takes the ninth field,
and `uniq -c` counts each value:

```
ana@vm:~/metrics$ cut -d, -f9 findings.csv | sort | uniq -c
     59 
     42 false_positive
    338 fixed
      1 resolution
     70 wont_fix
```

The empty value is the open findings, 59 of them, and `resolution` is the header line counted with
the rest. 338 were fixed, 70 closed as "won't fix" and 42 found to be false positives. That one line
already says something a total could not: **about one closed finding in four left the list without
being fixed**, and any number that treats "closed" as "fixed" is counting those 112 as work done.

A count like this is worth running on real data before anything else, for the same reason. If a
tracker stores only "open" and "closed", there is nothing to count here, and every later number is
built on a merge of three different outcomes.
