---
title: Bandit's first run, and how to read a finding
version: 1
---

Bandit is the static analyser of the Python Code Quality Authority, the group that also maintains
`flake8`. It parses each file into Python's syntax tree and runs a set of checks over
it, each with an id such as `B608`. **It knows Python and nothing about your project**, which is
its strength on the first day and its limit afterwards.

### Install it

Like every tool in this course, it is installed at an exact version, so a run next month reads the
same rules as this one. `uv tool install` puts it in an environment of its own, out of the
project's way, with the command in `~/.local/bin`:

```
ana@vm:~/linkbox$ uv tool install bandit==1.9.4
Resolved 7 packages in 642ms
Installed 7 packages in 291ms
 + bandit==1.9.4
 + markdown-it-py==4.2.0
 + mdurl==0.1.2
 + pygments==2.21.0
 + pyyaml==6.0.3
 + rich==15.0.0
 + stevedore==5.9.1
Installed 3 executables: bandit, bandit-baseline, bandit-config-generator
ana@vm:~/linkbox$ bandit --version
bandit 1.9.4
  python version = 3.13.16 (main, Oct  1 2026, 15:40:24) [GCC 13.3.0]
```

### The first run reads too much

Point it at the project and count what it says:

```
ana@vm:~/linkbox$ bandit -q -r . --format custom --msg-template "{relpath}" | wc -l
436
ana@vm:~/linkbox$ bandit -q -r . --format custom --msg-template "{relpath}" | cut -d/ -f1-2 | sort | uniq -c | sort -rn
    427 .venv/lib
      6 tests/test_app.py
      2 app.py
      1 settings.py
```

**Four hundred and thirty-six findings, in a service of 69 lines.** The second command says where
they are: 427 of them are inside `.venv`, the virtual environment lesson 1 made. Flask, Werkzeug,
pytest and the rest were scanned as if you had written them. Bandit was told to
read everything under `.`, and it did.

This is the most common first run of any scanner, and the most damaging. A developer who sees four
hundred findings for a change of three lines concludes the tool is noise, and that conclusion
outlives the configuration that caused it. **The first thing to tune is the scope: what the tool
reads.** Third-party code has its own scanner, the dependency audit of lesson 5, which reads
published advisories instead of guessing from the source.

Read only the project:

```
ana@vm:~/linkbox$ bandit -q -r . -x ./.venv --format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"
app.py:46 B608 MEDIUM/MEDIUM Possible SQL injection vector through string-based query construction.
app.py:59 B201 HIGH/MEDIUM A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
settings.py:4 B105 LOW/MEDIUM Possible hardcoded password: 'lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x'
tests/test_app.py:14 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:20 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:23 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:24 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:31 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:32 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
```

Nine, in three files, with four different ids. The template made each one a line: the file and
line, the check's id, its severity and confidence, and its message.

### One finding, whole

The default output says more about each finding. Ask for the one on the search:

```
ana@vm:~/linkbox$ bandit -q -r . -x ./.venv -t B608
Run started:2026-10-23 12:27:16.778693+00:00

Test results:
>> Issue: [B608:hardcoded_sql_expressions] Possible SQL injection vector through string-based query construction.
   Severity: Medium   Confidence: Medium
   CWE: CWE-89 (https://cwe.mitre.org/data/definitions/89.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b608_hardcoded_sql_expressions.html
   Location: ./app.py:46:26
45	    q = request.args.get("q", "")
46	    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
47	    return render_template_string(PAGE, q=q, rows=rows)

--------------------------------------------------

Code scanned:
	Total lines of code: 69
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

Every field is there for a reason:

| field | what it tells you |
|---|---|
| `B608:hardcoded_sql_expressions` | the check that fired; the name is the documentation's page |
| Severity: Medium | how bad it would be if it is real, in Bandit's own scale of low, medium and high |
| Confidence: Medium | how sure the check is that this is a real case of what it looks for |
| CWE-89 | the class of weakness in MITRE's Common Weakness Enumeration, here SQL injection |
| Location: `./app.py:46:26` | file, line and column, with the lines around it |

**Severity and confidence are two different questions.** Severity is about the consequence;
confidence is about the evidence. A check can be sure of something harmless, like an `assert`
statement, which is low severity and high confidence, or unsure of something serious, which is
this one: Bandit cannot see what `q` holds, so it says medium. The section after next uses the two
separately, because a pipeline that breaks on one and ignores the other is making a choice.

### The three that are not about tests

Six of the nine are `B101` in `tests/test_app.py`, and the next section is about them. The other
three are in the service itself:

| id | where | severity | what it says |
|---|---|---|---|
| B608 | `app.py:46`, the search | medium | a query built by formatting a string |
| B201 | `app.py:59`, the last line | **high** | Flask run with `debug=True`, which exposes Werkzeug's debugger |
| B105 | `settings.py:4` | low | a string that looks like a password, assigned to a name that sounds like one |

All three are real. **The search is lesson 1's SQL injection**, the one the previous section drew.
The debugger is a way to run code on the server from a browser, if that line ever runs where
somebody else can reach it. And the token in `settings.py` is the administration token itself,
committed to the repository. This lesson fixes the first two, with a test for each. The third is a
different kind of problem, because the token is already in the history and changing the code does
not take it back out, and it is lesson 6's.
