---
title: A model that checks itself
version: 1
---

Lesson 14 ended with a finding whose cause was "the check only runs when somebody remembers". The
fix for that cause is to make the model check itself, every time it changes and on a schedule, and
to make the check fail loudly enough that somebody has to act.

Everything needed is already in the repository. `trace.py` knows which threats have no requirement,
`acceptances.py` knows which reviews are due, and pytm knows which elements the model has.
`check_model.py` puts the three together and returns an exit status a CI system can act on:

```schooling-example
{"language": "python", "file": "check_model.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The checks every change to the model has to pass, and the ones it is known to fail.\n\n    python3 check_model.py              against today's date\n    python3 check_model.py 2026-10-12   against another date\n\nA problem listed in baseline.txt is known and reported; any other fails the check. So does a\nline in baseline.txt that is no longer a problem, because a stale exception reads as a real one.\n\"\"\"\nimport csv\nimport datetime\nimport json\nimport pathlib\nimport sys\n\ntoday = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()\n", "note": "A date on the command line, as in acceptances.py, so a run can be repeated and a future date tried on purpose."}, {"code": "\ndef front_matter(path):\n    lines = path.read_text().split(\"\\n\")\n    end = lines.index(\"---\", 1)\n    return dict(line.split(\": \", 1) for line in lines[1:end])\n\n"}, {"code": "model = json.load(open(\"model.json\"))\nelements = {e[\"name\"] for kind in (\"actors\", \"assets\", \"flows\", \"boundaries\") for e in model[kind]}\nthreats = list(csv.DictReader(open(\"threats.csv\")))\nrequirements = list(csv.DictReader(open(\"requirements.csv\")))\ndecisions = [front_matter(p) for p in sorted(pathlib.Path(\"decisions\").glob(\"*.md\"))]\nsuperseded = {d[\"supersedes\"] for d in decisions if \"supersedes\" in d}\ncurrent = [d for d in decisions if d[\"id\"] not in superseded]\n", "note": "Everything the model holds, read fresh on every run: the elements pytm wrote to model.json, the threats, the requirements and the decisions. A decision named by another's supersedes field is no longer current."}, {"code": "problems = []\nfor t in threats:\n    if t[\"element\"] not in elements:\n        problems.append(f\"{t['id']}: names {t['element']!r}, which is not in the model\")", "note": "A threat that names an element the model no longer has. This is the join by name that lesson 2 warned about, checked rather than trusted."}, {"code": "covered = {tid for r in requirements for tid in r[\"threats\"].split()}\ndecided = {d[\"threat\"] for d in current}\nfor t in threats:\n    if t[\"id\"] not in covered | decided:\n        problems.append(f\"{t['id']}: no requirement and no decision\")", "note": "A threat with neither a requirement nor a current decision is open: nobody has said what happens to it."}, {"code": "for r in requirements:\n    if not r[\"verified by\"]:\n        problems.append(f\"{r['id']}: not verified\")", "note": "A requirement nobody verifies is a promise."}, {"code": "for d in current:\n    if datetime.date.fromisoformat(d[\"review by\"]) < today:\n        problems.append(f\"{d['id']}: review overdue since {d['review by']}\")\n", "note": "A current decision past its review date. This is the one check that fails with no change at all, only a date."}, {"code": "baseline = [line for line in open(\"baseline.txt\").read().split(\"\\n\") if line]\nnew = [p for p in problems if p not in baseline]\nstale = [b for b in baseline if b not in problems]\nfor p in problems:\n    print((\"known  \" if p in baseline else \"NEW    \") + p)\nfor b in stale:\n    print(f\"STALE  {b}: fixed, so remove it from baseline.txt\")\nprint(f\"{len(threats)} threats, {len(requirements)} requirements, {len(current)} current decisions:\"\n      f\" {len(new)} new, {len(stale)} stale, {len(problems) - len(new)} known\")\nsys.exit(1 if new or stale else 0)", "note": "Compare with the baseline both ways. A new problem fails; so does a baseline line that is no longer a problem, because an exception nobody needs any more still reads as one somebody does."}]}
```

### The baseline

A model is never free of problems. R14 and R17 have no verification yet, and that has been known
since lesson 8. A check that failed on them would fail on every run, and a check that always fails
is ignored by the end of its first week.

So the known problems are written down, in `baseline.txt`, and the check fails only on the ones that
are not:

```
(.venv) ana@vm:~/tm/portal-model$ cat baseline.txt
R14: not verified
R17: not verified
```

**Adding a line to the baseline is a decision, made in a pull request where somebody can see it.**
That is the difference between a baseline and switching a check off: every exception has a line, a
commit and an author, and the list cannot grow without anybody noticing.

The check also fails the other way. A baseline line that is no longer a problem is **stale**, and
the check fails on it until the line is removed. Without that, R14 could be verified next month and
its line stay in the baseline for years, and somebody reading the file would believe R14 was still
unverified.

### The first run fails

ana added the check on 12 October, the same morning T18 and T19 went into the model, and ran
it through `check.sh`, which builds the model with pytm first so that a broken `model.py` fails too:

```
(.venv) ana@vm:~/tm/portal-model$ cat check.sh
#!/bin/sh
# What CI runs on every change to the model. Any failure stops the merge.
set -e
python3 model.py --json model.json
python3 check_model.py "$@"
(.venv) ana@vm:~/tm/portal-model$ sh check.sh 2026-10-12; echo "exit $?"
NEW    T18: no requirement and no decision
NEW    T19: no requirement and no decision
known  R14: not verified
known  R17: not verified
19 threats, 19 requirements, 3 current decisions: 2 new, 0 stale, 2 known
exit 1
```

It fails on purpose. Two threats were added with no answer, and the check says so in the terms the
course has used all along: no requirement, no decision. RA-002 is not in the list, because RA-003
supersedes it.

### Making it pass, honestly

There are three ways to answer a new problem, and the check does not care which, as long as one is
chosen: write a requirement, write a decision, or **add it to the baseline with a reason in the
commit**. For T18 and T19, ana wrote requirements, R20 for the API key and R21 for the dashboard
logins. R20 is verified by review of the configuration; R21 is a monthly process with nothing to
verify yet, so it went into the baseline in the same commit:

```
(.venv) ana@vm:~/tm/portal-model$ tail -2 requirements.csv
R20,T18,The gateway API key is kept only in the portal's secret store and is rotated every 90 days.,review
R21,T19,Access to the gateway's dashboard is reviewed every month and removed on the day a person leaves.,
(.venv) ana@vm:~/tm/portal-model$ cat baseline.txt
R14: not verified
R17: not verified
R21: not verified
(.venv) ana@vm:~/tm/portal-model$ sh check.sh 2026-10-12; echo "exit $?"
known  R14: not verified
known  R17: not verified
known  R21: not verified
19 threats, 21 requirements, 3 current decisions: 0 new, 0 stale, 3 known
exit 0
```

### Two triggers, not one

In CI, `sh check.sh` is a single step in whatever system the repository uses, run on every pull
request that touches the model. That catches a change that breaks the model. It cannot catch the
calendar. Nothing changes on 16 December, and on that day RA-003 is overdue:

```
(.venv) ana@vm:~/tm/portal-model$ python3 check_model.py 2026-12-16; echo "exit $?"
known  R14: not verified
known  R17: not verified
known  R21: not verified
NEW    RA-003: review overdue since 2026-12-15
19 threats, 21 requirements, 3 current decisions: 1 new, 0 stale, 3 known
exit 1
```

So the same check also runs **on a schedule**, every Monday morning, and a failure goes to the
decision's owner. That is the management response of lesson 14 made into a job, and it is the
reason RA-003 will not be found a week late the way RA-002 was.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l15-ci\" aria-label=\"The model’s check in CI. Two things start it: a pull request that changes the model, and a weekly schedule. check.sh first builds the model with pytm, so a broken model.py fails; then check_model.py compares the problems it finds with baseline.txt. A new problem or a stale baseline line fails the check and stops the merge; known problems are reported and pass.\"><defs><marker id=\"l15-ci-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a pull request</text><rect x=\"20.0\" y=\"110.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every Monday</text><rect x=\"220.0\" y=\"30.0\" width=\"160.0\" height=\"124.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">check.sh</text><text x=\"300.0\" y=\"79.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1. model.py builds</text><text x=\"300.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2. check_model.py</text><text x=\"300.0\" y=\"104.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">against baseline.txt</text><path d=\"M170.0 52.0 L220.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><path d=\"M170.0 132.0 L220.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"30.0\" width=\"260.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"452.0\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">known only</text><text x=\"452.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reported, passes</text><path d=\"M380.0 92.0 L440.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"80.0\" width=\"260.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"452.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a new problem</text><text x=\"452.0\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fails: fix, decide or baseline</text><path d=\"M380.0 92.0 L440.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"130.0\" width=\"260.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"452.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a stale line</text><text x=\"452.0\" y=\"159.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fails: remove it</text><path d=\"M380.0 92.0 L440.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the schedule is what catches a date passing when nothing changed</text></svg>", "caption": "A change can break the model, and so can the calendar. The check has to run for both."}
```
