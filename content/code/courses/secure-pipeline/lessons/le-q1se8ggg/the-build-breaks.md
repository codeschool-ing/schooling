---
title: Static analysis in the pipeline, and the first broken build
version: 1
---

Run by hand, a scanner is an opinion. **In the pipeline it is a rule**: every push is read the
same way, a finding stops the change before it reaches `main`, and nobody has to remember to run
anything. The stage is a script like the others, with one decision in it that matters more than
the rest: which findings break the build.

### The stage

Save it as `ci/sast.sh`:

```sh
# Static analysis: Semgrep with this project's own rules, then Bandit with
# its built-in ones. A finding of medium severity or worse breaks the build.
set -euo pipefail
semgrep scan --metrics=off --quiet --error --emacs --config .semgrep.yml .
bandit -q -r . -c bandit.yaml --severity-level medium
```

Each flag is there for a reason:

| flag | what it does |
|---|---|
| `--metrics=off` | Semgrep sends no usage data anywhere; a CI job should not call out to a vendor it did not need |
| `--quiet` | only the findings, not the progress and the summary |
| `--error` | exit with 1 when there is a finding; without it Semgrep reports and exits 0, and the stage passes |
| `--config .semgrep.yml` | the project's own rules and no others, so the result does not change when a registry does |
| `-c bandit.yaml` | the tuning of the previous sections: no `.venv`, no B101 in tests |
| `--severity-level medium` | report, and fail on, medium and high only |

**`--error` is the flag people forget**, and forgetting it is silent: the log fills with findings,
the stage prints "passed", and the pipeline looks like it checked something. Bandit has no such
trap, because it exits 1 whenever it reports a finding.

### Where to break, and where only to report

The last flag is a decision. Bandit's three findings in the service, placed by their two scores:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l03-gate\" aria-label=\"Bandit's two scores as a grid, severity from low to high going up and confidence from low to high going across. The rows for medium and high severity are the ones ci/sast.sh reports and breaks the build on; below them it reports nothing. B201, Flask's debugger, sits at high severity and medium confidence; B608, the search, at medium and medium; B105, the token in settings.py, at low and medium, below the line; B101, the assert in a test, at low severity and high confidence, and is skipped in the tests by bandit.yaml.\"><defs></defs><rect x=\"140\" y=\"30\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"265\" y=\"30\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"30\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"128\" y=\"65.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">high</text><rect x=\"140\" y=\"100\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"265\" y=\"100\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"100\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"128\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">medium</text><rect x=\"140\" y=\"170\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"265\" y=\"170\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"170\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"128\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">low</text><text x=\"202.5\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">low</text><text x=\"327.5\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">medium</text><text x=\"452.5\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">high</text><text x=\"327.5\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">confidence</text><text x=\"40\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">severity</text><line x1=\"140\" y1=\"170\" x2=\"535\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"543\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">breaks the build</text><text x=\"543\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">below it: not reported</text><rect x=\"270.5\" y=\"41.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B201</text><text x=\"327.5\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the debugger</text><rect x=\"270.5\" y=\"111.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B608</text><text x=\"327.5\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the search</text><rect x=\"270.5\" y=\"181.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B105</text><text x=\"327.5\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the token</text><rect x=\"395.5\" y=\"181.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"452.5\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B101</text><text x=\"452.5\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tests: skipped</text></svg>", "caption": "The gate reads one axis. What sits below its line is not false; it is waiting for a different fix."}
```

With `--severity-level medium`, the injection and the debugger break the build and the token in
`settings.py` does not appear at all. That is not because B105 is false: it is a true positive,
and lesson 6 is about it. It is because the fix for a committed secret is not a code change, so
**a gate that broke every build on it would stop every push until lesson 6's work was done**, for
a problem the person pushing cannot solve in their change. Lesson 7 makes that a general rule about
what a gate is for, and adds the middle ground, a warning that is counted, to this pipeline.

Confidence is the other axis, and this stage does not use it. Bandit can filter on it too, with
`--confidence-level`, and a team drowning in low-confidence findings sometimes does. That trades
noise for false negatives, the same trade as the previous section's, and is worth making only with
the findings in front of you.

### Into the list

The stage goes after the tests and before the build. Tests first, because a change that breaks
them has a problem that comes before its security; the build last, because nothing should be built
from code a check has refused. Save the list as `ci/stages`:

```
test
sast
build
```

### The first broken build

Commit what this lesson has added so far, the two configuration files and the stage, and push. The
code itself is still the code lesson 1 handed over:

```
ana@vm:~/linkbox$ git add .semgrep.yml bandit.yaml ci
ana@vm:~/linkbox$ git commit -q -m "static analysis in the pipeline"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 879b6bb        
remote: test: passed in 1s        
remote: sast: FAILED in 2s, the end of sast.log:        
remote:              33┆ def create():        
remote:              34┆     if request.headers.get("X-Token") != ADMIN_TOKEN:        
remote:              35┆         abort(401)        
remote:              36┆     code = secrets.token_urlsafe(4)        
remote:              37┆     db().execute("INSERT INTO links VALUES (?, ?)", (code, request.form["url"]))        
remote:              38┆     db().commit()        
remote:              39┆     return {"code": code}, 201        
remote:              
remote:      ❯❯❱ sql-built-from-a-string        
remote:             ❰❰ Blocking ❱❱        
remote:             SQL text built from a string reaches execute(). Write a ? where the value goes and pass the value as        
remote:             a parameter.                                                                                                
remote:                                                                                                                         
remote:              46┆ rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()        
remote:           
remote: run 1: failed, the logs are in ~/ci/runs/1/logs        
To /home/ana/ci/linkbox.git
   ed9bbb4..879b6bb  main -> main
```

**This is the build breaking as designed.** The tests passed, the static analysis stage found two
things, and the run stopped before building an image of code it refused. The last fifteen lines of
the stage's log are in the push itself, which is enough to see that Semgrep failed it: its findings
came first, and with `set -e` the script stopped there, before Bandit ran. The whole log stays on
the server:

```
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/sast.log
                   
                   
┌─────────────────┐
│ 2 Code Findings │
└─────────────────┘
          
    app.py
   ❯❯❱ writes-need-the-token
          ❰❰ Blocking ❱❱
          A POST route that never calls require_token() lets anybody write.
                                                                           
           32┆ @app.post("/links")
           33┆ def create():
           34┆     if request.headers.get("X-Token") != ADMIN_TOKEN:
           35┆         abort(401)
           36┆     code = secrets.token_urlsafe(4)
           37┆     db().execute("INSERT INTO links VALUES (?, ?)", (code, request.form["url"]))
           38┆     db().commit()
           39┆     return {"code": code}, 201
   
   ❯❯❱ sql-built-from-a-string
          ❰❰ Blocking ❱❱
          SQL text built from a string reaches execute(). Write a ? where the value goes and pass the value as
          a parameter.                                                                                        
                                                                                                              
           46┆ rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
```

Both of Semgrep's findings are there, the token rule and the SQL rule. Bandit never ran in this
build, so its B201 is not in the log. That is a property of the script worth knowing: **a stage
that stops at its first tool reports only that tool's findings**, and the next tool's appear only
once the first tool's are fixed. The alternative, running both and failing at the end, shows everything at once and
costs a few more lines; either is defensible, as long as the team knows which one it has.

A red build on `main` is not where this would happen in a team with pull requests: the branch would
be red, and the merge would be blocked. linkbox has one developer and one branch, so `main` is red
for now, and the next section makes it green.
