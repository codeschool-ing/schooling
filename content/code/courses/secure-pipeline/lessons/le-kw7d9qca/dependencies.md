---
title: Direct and transitive: what linkbox actually runs
version: 1
---

Ask a team what its service depends on and the usual answer is the list in its requirements file.
That list is a decision about versions. **What the service runs is every package installed to
satisfy it**, and most of those were chosen by the authors of other packages, not by the team.

linkbox's own code is one file. The code that runs when it answers a request is mostly somebody
else's: Flask's routing, Werkzeug's parsing of the request, Jinja's templates, gunicorn's handling
of the connection. A flaw in any of them is a flaw in linkbox, in exactly the way a flaw in
`app.py` would be, because it runs in the same process with the same data.

### Direct and transitive

A **direct** dependency is one your code uses by name. linkbox has two: `app.py` imports `flask`,
and the Dockerfile starts `gunicorn`. A **transitive** dependency is one a dependency needs: Flask
needs Werkzeug, Jinja and four others, and Jinja needs MarkupSafe. You did not choose them, and you
run them anyway.

`uv pip tree` draws the whole thing from the environment the tests use:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt
ana@vm:~/linkbox$ uv pip tree
flask v3.0.0
├── blinker v1.7.0
├── click v8.1.7
├── itsdangerous v2.1.2
├── jinja2 v3.1.2
│   └── markupsafe v2.1.3
└── werkzeug v3.0.1
    └── markupsafe v2.1.3
gunicorn v21.2.0
└── packaging v26.3
pytest v8.4.2
├── iniconfig v2.3.1
├── packaging v26.3
├── pluggy v1.7.0
└── pygments v2.21.0
```

Read it as a list of who brought what in. `flask` and `gunicorn` are at the left margin because
nothing else requires them; the same is true of `pytest`, which comes from the second requirements
file. Everything indented came in because a package above it asked for it. `markupsafe` appears
twice because two packages need it, and is installed once.

Thirteen packages are installed, and the two requirements files name nine. **Lesson 1 pinned the
transitive dependencies of Flask by hand**, which is why `werkzeug==3.0.1` sits in
`requirements.txt` beside `flask==3.0.0` although `app.py` never imports Werkzeug. Four packages
are named nowhere: `packaging`, which gunicorn and pytest pull in, and `iniconfig`, `pluggy` and
`pygments`, which pytest does. Their versions are whatever the index offered on the day the
environment was made. Lesson 13 finds `packaging` again inside the image, and lesson 15 pins it
with the rest in a compiled lock file.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l05-tree\" aria-label=\"linkbox's thirteen installed packages on two axes. Direct and pinned in a requirements file: flask, gunicorn and pytest. Direct and named nowhere: none. Transitive and pinned: werkzeug, jinja2, markupsafe, itsdangerous, click and blinker. Transitive and named nowhere: packaging, iniconfig, pluggy and pygments. Five carry advisories in lesson 1's pins: flask, gunicorn, pytest, werkzeug and jinja2.\"><defs></defs><text x=\"300\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">pinned in a requirements file</text><text x=\"595\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">named nowhere</text><rect x=\"140\" y=\"44\" width=\"320\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"44\" width=\"240\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"114\" width=\"320\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"114\" width=\"240\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">direct</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">transitive</text><rect x=\"150\" y=\"59\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">flask</text><rect x=\"254\" y=\"59\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"302.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">gunicorn</text><rect x=\"358\" y=\"59\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pytest</text><text x=\"590\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">none</text><rect x=\"150\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">werkzeug</text><rect x=\"254\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"302.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">jinja2</text><rect x=\"358\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">markupsafe</text><rect x=\"150\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">itsdangerous</text><rect x=\"254\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"302.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">click</text><rect x=\"358\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">blinker</text><rect x=\"486\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">packaging</text><rect x=\"596\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">iniconfig</text><rect x=\"486\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pluggy</text><rect x=\"596\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pygments</text><rect x=\"140\" y=\"262\" width=\"22\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">has an advisory in lesson 1's pins</text></svg>", "caption": "Nine packages are pinned and thirteen are installed; two of the five with advisories are packages linkbox never chose."}
```

### Why the transitive half is the larger risk

Three things make the packages you did not choose harder to look after than the ones you did.

- **Nobody on the team decided to use them**, so nobody follows their releases. A team reads
  Flask's changelog because it upgrades Flask on purpose. Few teams read Werkzeug's.
- **They change without a commit.** An unpinned transitive package moves when its parent's range
  allows it, the next time an environment or an image is built. The image built on Monday and the
  one built on Thursday can differ while the repository did not. Lesson 2's nightly rebuild exists
  partly for this reason.
- **There are more of them.** Here three direct packages, pytest included, bring in ten others. In a service of
  ordinary size the ratio is usually far wider, and every one of them can carry an advisory.

### The development dependencies count too

pytest is not in the image, so it is tempting to leave it out of an audit. It runs, though: on
every developer's laptop and on the CI server, with the repository checked out and whatever
credentials the pipeline holds nearby. A flaw in a test tool is a flaw on the build machine, and
lesson 16 treats the build machine as a target in its own right. **This lesson audits both files**,
and the first pipeline run of the stage it adds fails on pytest, not on anything linkbox ships.

### What a composition analyser does with this

Software composition analysis, SCA, is the name for checking that list against what is publicly
known to be wrong with each version in it. The tool collects the packages and their versions, from
a requirements file, a lock file, an environment or an image, and looks each one up in a database
of advisories. The quality of its answer depends on both halves: a tool that collects the wrong
list checks the wrong packages perfectly, and the section on Trivy, near the end of this lesson, shows
two tools collecting different lists from the same directory.
