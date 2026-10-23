---
title: True, false, and the assert in a test
version: 1
---

Every finding is a claim, and a claim can be right or wrong. So can a silence. Four words cover the
cases, and a team that uses them precisely argues about the right things:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l03-matrix\" aria-label=\"The four outcomes of a check, as a two by two table. Columns: there is a real defect, or there is none. Rows: the tool reports something, or it is silent. A true positive is a report about a real defect, such as B608 on linkbox's search. A false positive is a report about something that is not a defect, such as B101 on an assert in a test. A false negative is a real defect the tool is silent about, such as create() comparing the token with an ordinary string comparison. A true negative is a correct silence, such as follow(), whose query already takes a parameter.\"><defs></defs><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a real defect</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">no defect</text><text x=\"100\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the tool reports</text><text x=\"100\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the tool is silent</text><rect x=\"215\" y=\"40\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">true positive</text><text x=\"330.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">B608 on the search</text><rect x=\"460\" y=\"40\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">false positive</text><text x=\"575.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">B101 on a test's assert</text><rect x=\"215\" y=\"140\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">false negative</text><text x=\"330.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the token compared with !=</text><rect x=\"460\" y=\"140\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">true negative</text><text x=\"575.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">follow() with a ?</text></svg>", "caption": "Tuning moves findings between the boxes you can see and the one you cannot. A rule switched off has no false positives and all of its false negatives."}
```

- A **true positive** is a finding about a real defect: B608 on the search.
- A **false positive** is a finding about something that is not a defect: the next paragraphs.
- A **false negative** is a defect the tool did not report. It is the expensive one, because nothing
  points at it, and every tool has them: Bandit does not know that linkbox's `create()` compares
  the token with `!=`, which section 05 of this lesson is about.
- A **true negative** is a correct silence: `follow()` builds its query with a `?`, and Bandit says
  nothing about it.

**Tuning trades one kind of error for the other.** A rule switched off produces no false positives,
and lets through every defect it would have caught. The job is to remove the false positives
without paying for it in the box you cannot see.

### B101, the classic false positive

Six of Bandit's nine findings are the same one, `B101` on every `assert` in `tests/test_app.py`.
The check is right about Python. Run with `-O`, the interpreter drops every `assert` statement, so
code that relies on one for a security decision, such as `assert user.is_admin`, stops checking
anything in an optimised deployment. **In application code, B101 is a true positive worth having.**
In a test it is wrong: pytest is built on `assert`, nobody runs tests under `-O`, and an assert in a
test is the test.

There are three ways to make it stop, and only one of them is right:

| the move | what it costs |
|---|---|
| skip B101 everywhere, `skips: [B101]` | the check is gone from `app.py` too, where it matters: a false negative waiting for the first `assert` in a route |
| a `# nosec` on each of the six lines | six comments in the tests, and one more on every assert anybody writes from now on |
| **skip B101 in the tests, and only there** | nothing: the rule keeps watching the code it was written for |

Bandit's configuration file can do the third. Save it as `bandit.yaml`:

```yaml
# Bandit's settings for linkbox.
exclude_dirs:
  - .venv
# B101 flags every assert, because Python drops them under -O. In a test an
# assert is the whole point, so it is skipped there and nowhere else.
assert_used:
  skips:
    - "*/tests/*.py"
```

`exclude_dirs` makes the scope of the last section permanent, so nobody has to remember `-x`, and
`assert_used` is B101's own setting: the files it does not apply to. Run it with the file:

```
ana@vm:~/linkbox$ bandit -q -r . -c bandit.yaml --format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"
app.py:46 B608 MEDIUM/MEDIUM Possible SQL injection vector through string-based query construction.
app.py:59 B201 HIGH/MEDIUM A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
settings.py:4 B105 LOW/MEDIUM Possible hardcoded password: 'lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x'
```

Three findings, the three that are about the service. **Every line of `bandit.yaml` says why it is
there**, because a tuning nobody can explain is removed by the next person who finds it in the way,
or kept forever by the next person who is afraid to touch it.

### A suppression on one line, with its reason

Sometimes the finding is wrong about one line and right about every other. A query whose table name
has to be inserted into the SQL is the usual case, because a `?` can stand for a value and never for
a table. Here is one in a scratch directory, outside the project:

```
ana@vm:~/linkbox$ mkdir -p /tmp/scratch && cd /tmp/scratch
ana@vm:/tmp/scratch$ cat counts.py
import sqlite3

TABLES = ("links",)


def counts(db):
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}
ana@vm:/tmp/scratch$ bandit -q counts.py
Run started:2026-10-23 12:27:17.278153+00:00

Test results:
>> Issue: [B608:hardcoded_sql_expressions] Possible SQL injection vector through string-based query construction.
   Severity: Medium   Confidence: Medium
   CWE: CWE-89 (https://cwe.mitre.org/data/definitions/89.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b608_hardcoded_sql_expressions.html
   Location: ./counts.py:7:28
6	def counts(db):
7	    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}

--------------------------------------------------

Code scanned:
	Total lines of code: 4
	Total lines skipped (#nosec): 0
	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0

Run metrics:
	Total issues (by severity):
		Undefined: 0
		Low: 0
		Medium: 1
		High: 0
	Total issues (by confidence):
		Undefined: 0
		Low: 0
		Medium: 1
		High: 0
Files skipped (0):
```

B608 is wrong here: `t` can only be a name from `TABLES`, a constant in the same file. The answer
is a suppression on that line, naming the check and saying why. The first attempt puts the reason
in the same comment:

```
ana@vm:/tmp/scratch$ tail -n 1 counts.py
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}  # nosec B608: t is one of TABLES
ana@vm:/tmp/scratch$ bandit -q counts.py; echo "exit $?"
[manager]	WARNING	Test in comment: t is not a test name or id, ignoring
[manager]	WARNING	Test in comment: is is not a test name or id, ignoring
[manager]	WARNING	Test in comment: one is not a test name or id, ignoring
[manager]	WARNING	Test in comment: of is not a test name or id, ignoring
[manager]	WARNING	Test in comment: TABLES is not a test name or id, ignoring
exit 0
```

Bandit read every word after `nosec` as the id of a check to skip, and warned about each. The finding
was suppressed, and **the reason was turned into noise**. Bandit wants the ids alone after `nosec`,
so the reason goes on the line above:

```
ana@vm:/tmp/scratch$ tail -n 2 counts.py
    # A table name cannot be a ? parameter, and t only ever comes from TABLES.
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}  # nosec B608
ana@vm:/tmp/scratch$ bandit counts.py 2>/dev/null | grep -i 'issues identified\|skipped'
	No issues identified.
	Total lines skipped (#nosec): 0
	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 1
Files skipped (0):
ana@vm:/tmp/scratch$ cd ~/linkbox && rm -rf /tmp/scratch
```

"No issues identified", and the summary still counts **one issue skipped on purpose**, so a reviewer
or a script can find every suppression in the code.

### Why a bare suppression is a smell

A `# nosec` with no id switches off every check on that line, including ones written next year. A
suppression with no reason cannot be reviewed: nobody can tell a considered decision from a
developer who wanted a red build to go green. Three rules keep suppressions honest:

- **name the check**, `# nosec B608`, never a bare `# nosec`; Semgrep's form is
  `# nosemgrep: rule-id`;
- **say why, in words a reviewer can check**, beside it;
- **count them**. Bandit's summary already does; a suppression added in a pull request is a line a
  reviewer should be asked about, the same as a change to the tests.
