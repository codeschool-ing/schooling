---
title: A gate for dependencies, and failing closed
version: 1
---

pip-audit has one opinion about a report: it exits 1 if it found any advisory at all. That
cannot tell the two cases this lesson separates, an advisory with a fixed version and one with
none, and it has no notion of an exception that ends. `--ignore-vuln` exists, and it ignores an
advisory for ever, which is the switched-off gate in a flag. **So the decision moves into a short
program of the project's own**, reading pip-audit's JSON report and answering with an exit status.

### The gate

Save it as `ci/gate.py`:

```schooling-example
{"language": "python", "file": "ci/gate.py", "parts": [{"code": "\"\"\"The composition gate: pip-audit's JSON on stdin, ci/exceptions.txt beside\nit, and one verdict as the exit status.\n\n    1  an advisory with a fixed version, and no exception in force for it\n    3  a warning: an advisory nobody can fix yet, or an exception that\n       expires within a week\n    0  nothing to report\n\"\"\"", "note": "The three verdicts, written at the top, where the next person to change the gate reads them before the code."}, {"code": "import datetime\nimport json\nimport sys\nfrom pathlib import Path\n"}, {"code": "BREAK, WARN, PASS = 1, 3, 0\n\n", "note": "The exit statuses as names, so that no line below compares against a bare number. A crash of this program exits 1, which is BREAK: the gate fails closed without a line of code to make it."}, {"code": "def judge(audit, exceptions, today):\n    \"\"\"The verdict and one line per advisory, for a pip-audit report.\"\"\"", "note": "`today` is a parameter rather than a call to the clock, so the tests can fix the day and check every side of an exception's date."}, {"code": "    until = {}\n    for line in exceptions.splitlines():\n        if line.strip() and not line.startswith(\"#\"):\n            advisory, day, _why = line.split(maxsplit=2)\n            until[advisory] = datetime.date.fromisoformat(day)", "note": "Each exception is three fields: the advisory, the last day it holds, and the reason. A line with no reason does not split into three, Python raises, and the build breaks: an exception nobody explained is refused."}, {"code": "    verdict, lines = PASS, []\n    for dep in audit[\"dependencies\"]:\n        for vuln in dep.get(\"vulns\", []):\n            what = f\"{dep['name']} {dep['version']} {vuln['id']}\"\n            if any(what in line for line in lines):\n                continue", "note": "pip-audit reads both requirements files and can report the same advisory twice; each one is judged once."}, {"code": "            day = until.get(vuln[\"id\"])\n            if day is not None and day >= today:\n                lines.append(f\"excepted until {day}: {what}\")\n                if (day - today).days < 7 and verdict == PASS:\n                    verdict = WARN", "note": "An exception in force passes the advisory, and turns into a warning in its last week, so the date is seen before it arrives."}, {"code": "            elif vuln[\"fix_versions\"]:\n                lines.append(f\"BREAKS: {what}, fixed in {', '.join(vuln['fix_versions'])}\")\n                verdict = BREAK", "note": "A fixed version exists and nobody excepted the advisory: the person who pushed can move the pin, so the build breaks. The line says which version fixes it."}, {"code": "            else:\n                lines.append(f\"warns: {what}, no fixed version yet\")\n                if verdict == PASS:\n                    verdict = WARN", "note": "No fixed version anywhere: nobody can act by changing a pin, so it is a warning, counted and shown."}, {"code": "    return verdict, lines\n\n"}, {"code": "if __name__ == \"__main__\":\n    verdict, lines = judge(json.load(sys.stdin), Path(\"ci/exceptions.txt\").read_text(),\n                           datetime.date.today())\n    print(\"\\n\".join(lines) or \"no advisories\")\n    sys.exit(verdict)", "note": "Run as a program: the report on standard input, the exceptions from the file, today's date. It prints one line per advisory, and the verdict is the exit status."}]}
```

The exceptions live beside it, one line each, and start empty. Save it as `ci/exceptions.txt`:

```
# Exceptions to the composition gate, one per line: the advisory, the last
# day the exception holds, and why. Past that day the line is ignored and
# the finding breaks the build again, until somebody decides afresh.
```

### Its tests

A gate is code that decides whether other code ships, so it gets tests like any other: one per
verdict, and two for the edges of an exception's date. Save them as `tests/test_gate.py`:

```python
import datetime

from ci.gate import BREAK, PASS, WARN, judge

DAY = datetime.date(2026, 10, 14)
FIXED = {"id": "PYSEC-1", "fix_versions": ["1.1"]}
UNFIXED = {"id": "PYSEC-2", "fix_versions": []}


def verdict(vulns, exceptions=""):
    audit = {"dependencies": [{"name": "pkg", "version": "1.0", "vulns": vulns}]}
    return judge(audit, exceptions, DAY)[0]


def test_a_fix_nobody_applied_breaks_the_build():
    assert verdict([FIXED]) == BREAK


def test_an_advisory_with_no_fix_warns():
    assert verdict([UNFIXED]) == WARN


def test_an_exception_holds_until_its_date():
    assert verdict([FIXED], "PYSEC-1 2026-12-31 the vendor's fix is due in November") == PASS


def test_an_exception_close_to_its_date_warns():
    assert verdict([FIXED], "PYSEC-1 2026-10-16 the vendor's fix is due in November") == WARN


def test_an_expired_exception_breaks_the_build_again():
    assert verdict([FIXED], "PYSEC-1 2026-10-13 the vendor's fix is due in November") == BREAK
```

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q tests/test_gate.py
.....                                                                    [100%]
5 passed in 0.02s
```

**The tests fix the day as 14 October**, so they pass on any day they are run. A gate that called
the clock inside `judge` could only be tested on the day its dates happened to be right.

### The stage

Save it as `ci/sca.sh`:

```sh
# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes, judged by ci/gate.py. If pip-audit
# produced no report at all, the gate has nothing to judge and the build
# breaks: a scanner that did not run is not a scanner that found nothing.
# The report goes to a file made empty for this run, so a report left over
# from an earlier run can never stand in for one that was not written.
set -uo pipefail
report=$(mktemp)
trap 'rm -f "$report"' EXIT
pip-audit --strict -r requirements.txt -r requirements-dev.txt -f json -o "$report"
[ -s "$report" ] || exit 1
python3 ci/gate.py <"$report"
```

pip-audit's own exit status is ignored, on purpose: it is 1 for any advisory and the gate decides
instead. What is not ignored is whether it produced a report. **The report goes to a file made
empty for this run**, and that detail was found while this lesson was recorded. The first version
wrote `audit.json` into the project and checked that it was not empty. On the laptop, a run in
which pip-audit failed passed, on a report an earlier run had left behind. In the CI's fresh clone
it would have failed correctly, which is exactly why nobody would have noticed: the check worked
where it was watched.

### Failing closed, on screen

Two ways for the stage to have nothing to judge. First, the gate given no report at all: its last
line, and its status.

```
ana@vm:~/linkbox$ python3 ci/gate.py </dev/null 2>&1 | tail -n 1; echo "exit ${PIPESTATUS[0]}"
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
exit 1
```

The `json` module raised, Python exited 1, and 1 is BREAK. Nobody wrote a line of code to make
an empty report break the build; choosing 1 for BREAK did.

Second, a requirements file that cannot be installed. Pin `werkzeug` back to 3.0.1, the version
lesson 1 inherited, while `flask` stays at 3.1.3, which needs a newer one:

```
ana@vm:~/linkbox$ sed -i s/werkzeug==3.1.9/werkzeug==3.0.1/ requirements.txt
ana@vm:~/linkbox$ bash ci/sca.sh; echo "exit $?"
ERROR:pip_audit._virtual_env:internal pip failure: ERROR: Cannot install -r requirements.txt (line 1) and werkzeug==3.0.1 because these package versions have conflicting dependencies.
ERROR: ResolutionImpossible: for help visit https://pip.pypa.io/en/latest/topics/dependency-resolution/#dealing-with-dependency-conflicts

ERROR:pip_audit._cli:Failed to install packages: ['/tmp/tmpmmfv6__1/bin/python3.13', '-m', 'pip', 'install', '--no-input', '--keyring-provider=subprocess', '--dry-run', '--report', '/tmp/tmp5ic0xh4h/tmpu1k_inme', '-r', 'requirements.txt', '-r', 'requirements-dev.txt']
exit 1
ana@vm:~/linkbox$ git checkout -q requirements.txt
```

**pip-audit could not resolve the dependencies, so it audited nothing and wrote nothing**, and the
stage broke. A requirements file nobody can install is not a requirements file without
advisories. Before `[ -s "$report" ]` existed, the gate would have read an empty report and the
stage would have broken anyway, with a traceback in place of a reason; with a report left behind
from another run, it would have passed.

### The first run

Commit everything and push:

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git commit -q -m "a gate that breaks, warns or passes, and exceptions that expire"
9:28AM INF 0 commits scanned.
9:28AM INF scanned ~4950 bytes (4.95 KB) in 297ms
9:28AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 8c3836b        
remote: secrets: passed in 1s        
remote: test: passed in 2s        
remote: sast: passed in 2s        
remote: sca: passed in 10s        
remote: build: passed in 1s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   8ab3d2a..8c3836b  main -> main
```

**`pipeline passed with 0 warning(s)`** is the new last line, and on this commit it is true: the
history has no live secret, the pins have no advisories, and the code has no finding of any
severity. The next two sections push branches that each change one thing, and watch the verdict.
