---
title: Enforcing a standard with a machine
version: 1
---

A standard that people check is checked whenever somebody remembers, by whoever happens to look.
**A standard that a machine checks is checked on every change, the same way for everybody**, and
nobody has to be the person who says no. That is the whole argument of this section, and the
figure below puts a time on it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Six boxes in a row, from left to right: in the editor, seconds; on commit, seconds; in CI, minutes; in code review, hours; in production, days; in a wiki page, never. The first three are grouped as a machine giving the same answer every time, the fourth as a person whose answer depends on who looks, the last two as nobody until it costs something. An arrow under the row says found later, costs more.\"><defs><marker id=\"std-ladder-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"64\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">in the editor</text><text x=\"64\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seconds</text><rect x=\"130\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">on commit</text><text x=\"182\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seconds</text><rect x=\"248\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">in CI</text><text x=\"300\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"366\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"418\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">in code review</text><text x=\"418\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hours</text><rect x=\"484\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"536\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">in production</text><text x=\"536\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">days</text><rect x=\"602\" y=\"90\" width=\"104\" height=\"56\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"654\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">in a wiki page</text><text x=\"654\" y=\"129\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">never</text><path d=\"M12 78 L12 70 L338 70 L338 78\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"175\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a machine: the same answer every time</text><path d=\"M366 78 L366 70 L470 70 L470 78\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"418\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a person:</text><text x=\"418\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depends on who looks</text><path d=\"M484 78 L484 70 L706 70 L706 78\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><text x=\"595\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nobody, until it costs something</text><path d=\"M12 168 L704 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#std-ladder-ah)\"></path><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">found later, costs more</text></svg>", "caption": "Where a broken standard is found, and how long after it was written. The three on the left answer the same way for everybody; review depends on who happens to look; the last two are found by the incident."}
```

The payout failure from the previous section sat at the wrong end of that row. The import that
caused it had been in Payments' code for eleven months, it had passed code review, and it was found
by 312 drivers checking their bank accounts on a Friday. Nobody had been careless. A reviewer in
Payments had no reason to know that `offers.py` was Matching's private business, and a reviewer in
Matching never saw Payments' pull request.

## What a machine can check

Most of the nine standards fall to tools Carreto already ran for other reasons:

- a linter or a type checker in the editor and in CI, for the rules about the code itself. The
  money rule is a type check: an amount field typed as `float` fails.
- a CI job on every pull request, for rules about the repository: the secret scanner, the
  comparison of a public API's schema against the previous version, the import check this section
  builds.
- the deploy pipeline, for rules about what reaches production. A service without `/healthz`
  is refused, and since the pipeline is the only thing holding production credentials, refused
  means it does not ship.
- a scanner over a running environment, for rules that only show at run time, like the CPF
  that turns up in a log line built from a request body.

**Seven of Carreto's nine standards are checked by a machine.** The money rule is half-checked: the
type check catches a `float` and cannot catch a conversion done by hand. The ADR rule is checked by
people in the architecture forum (lesson 10), because "this decision crosses team boundaries" is a
judgement. Knowing which standards a machine cannot hold tells you where review time has to go.

## Fitness functions

Neal Ford, Rebecca Parsons and Patrick Kua gave this kind of check a name in *Building Evolutionary
Architectures* (2017): a **fitness function** is an objective, automated assessment of how well
the system keeps one of its architectural characteristics. The term comes from evolutionary
computing, where a fitness function scores how close a candidate solution is to the goal.

The useful part of the idea is the word *architectural*. A unit test checks that a function returns
the right value. A fitness function checks a property of the structure that no single function
owns:

- a dependency rule: Payments does not import Matching's internals;
- a performance budget: a quote takes under 300 ms at the 95th percentile in the nightly load
  test;
- an operational limit: the payout job finishes in under 20 minutes on a copy of last Friday's
  data.

The book sorts them along a few axes, of which two are worth knowing by name. A **triggered**
fitness function runs when something changes, like a CI job on a pull request; a **continual** one
runs all the time against production, like an alert on the quote latency. An **atomic** one checks
one characteristic in isolation; a **holistic** one checks several together, like a load test that
measures latency and error rate at once. Tools exist for the common dependency rules: ArchUnit for
Java, import-linter for Python, dependency-cruiser for JavaScript. The one in this section is
written by hand so that you can see all of it, and so that it fits a monolith whose rule is
Carreto's own. Lesson 15 comes back to fitness functions as the kind of code an architect keeps
writing.

## An example project

The real monolith has one directory per team under `carreto/`. The example keeps three of them and
two or three files in each, enough to break the rule once and to need an exception once. This short
script writes it:

```sh
# make-carreto.sh: writes a tiny example project into ./carreto
mkdir -p carreto/matching carreto/tracking carreto/payments
touch carreto/__init__.py carreto/matching/__init__.py \
      carreto/tracking/__init__.py carreto/payments/__init__.py

cat > carreto/matching/offers.py <<'END'
def accepted_driver(load_id):
    return {"load": load_id, "driver": "D-1042"}
END

cat > carreto/matching/api.py <<'END'
from carreto.matching.offers import accepted_driver

__all__ = ["accepted_driver"]
END

cat > carreto/tracking/models.py <<'END'
class DeliveryProof:
    def __init__(self, load_id, photo):
        self.load_id, self.photo = load_id, photo
END

cat > carreto/tracking/api.py <<'END'
def delivery_proved(load_id):
    return True
END

cat > carreto/payments/payout.py <<'END'
from carreto.matching.offers import accepted_driver
from carreto.tracking.api import delivery_proved


def pay_driver(load_id):
    if delivery_proved(load_id):
        return accepted_driver(load_id)["driver"]
END

cat > carreto/payments/invoice.py <<'END'
from carreto.tracking.models import DeliveryProof


def attach_proof(invoice, proof: DeliveryProof):
    invoice["proof"] = proof.photo
    return invoice
END
```

Running it is optional; reading the program and its output below is enough to follow the lesson.
To run it, save the script as `make-carreto.sh` in an empty directory, run it with `sh`, and the
project appears beside it. On Windows, run it in Git Bash or WSL, or create the ten files by hand
from the script.

```
$ sh make-carreto.sh
$ find carreto -name '*.py' | sort
carreto/__init__.py
carreto/matching/__init__.py
carreto/matching/api.py
carreto/matching/offers.py
carreto/payments/__init__.py
carreto/payments/invoice.py
carreto/payments/payout.py
carreto/tracking/__init__.py
carreto/tracking/api.py
carreto/tracking/models.py
```

`api.py` in each package is **the front door**: what that team promises to keep working. Everything
else inside the package can change on a Thursday without warning anyone. Matching's `api.py`
re-exports `accepted_driver` from `offers.py`, so if Matching splits `offers.py` again, it updates
one import in its own `api.py` and nobody outside notices. Payments' `payout.py` is written the way
the real one was before March: straight past the door into `offers.py`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Three package boxes side by side: carreto/matching, carreto/payments and carreto/tracking. Matching holds api.py and offers.py, Payments holds payout.py and invoice.py, Tracking holds api.py and models.py. A solid arrow goes from payout.py to Matching's api.py and another from payout.py to Tracking's api.py: allowed. A dashed amber arrow goes from payout.py to offers.py: refused by the check. A dashed grey arrow goes from invoice.py to models.py: allowed until 2027-03-31 as a granted exception.\"><defs><marker id=\"std-bound-ok\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"std-bound-no\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"std-bound-ex\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"20\" width=\"220\" height=\"230\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">carreto/matching</text><rect x=\"250\" y=\"20\" width=\"220\" height=\"230\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">carreto/payments</text><rect x=\"490\" y=\"20\" width=\"220\" height=\"230\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">carreto/tracking</text><rect x=\"120\" y=\"80\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api.py</text><rect x=\"20\" y=\"170\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">offers.py</text><rect x=\"300\" y=\"80\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">payout.py</text><rect x=\"300\" y=\"170\" width=\"120\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">invoice.py</text><rect x=\"500\" y=\"80\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"97\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api.py</text><rect x=\"600\" y=\"170\" width=\"100\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">models.py</text><path d=\"M300 92 L222 92\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#std-bound-ok)\"></path><path d=\"M420 92 L498 92\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#std-bound-ok)\"></path><path d=\"M300 106 L122 182\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#std-bound-no)\"></path><path d=\"M420 187 L598 187\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\" marker-end=\"url(#std-bound-ex)\"></path><path d=\"M20 276 L56 276\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#std-bound-ok)\"></path><text x=\"66\" y=\"276\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">allowed: through the other team's api.py</text><path d=\"M20 298 L56 298\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#std-bound-no)\"></path><text x=\"66\" y=\"298\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">refused by the check: an internal module</text><path d=\"M20 320 L56 320\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 3\" marker-end=\"url(#std-bound-ex)\"></path><text x=\"66\" y=\"320\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">allowed until 2027-03-31: a granted exception</text></svg>", "caption": "The example project and the rule the checker holds it to. Each team's package has one front door, its api.py; everything else inside is that team's business and may change without warning."}
```

## The checker

Save this beside `make-carreto.sh` as `check_imports.py`. It uses the standard library only, so any
Python 3 runs it. The notes say what each part is for; the copy button takes the program without
them.

```schooling-example
{
  "language": "python",
  "file": "check_imports.py",
  "parts": [
    {
      "code": "# check_imports.py: fail when one team's package imports another team's internals\nimport ast\nimport datetime\nimport pathlib\nimport sys",
      "note": "Four modules from the standard library and nothing to install. `ast` reads Python source into a tree without running it, so the check is safe on any branch, however broken the code is."
    },
    {
      "code": "\nROOT = pathlib.Path(\"carreto\")\nEXCEPTIONS = {  # (file, module it may import) -> last day the exception holds\n    (\"carreto/payments/invoice.py\", \"carreto.tracking.models\"): \"2027-03-31\",\n}",
      "note": "Where the code lives, and the one exception granted so far, with the last day it holds. A list kept in the repository is reviewed in pull requests like the code it excuses. The last section of this lesson is about it."
    },
    {
      "code": "\n\ndef imports_in(path):\n    tree = ast.parse(path.read_text(), filename=str(path))\n    for node in ast.walk(tree):\n        if isinstance(node, ast.Import):\n            for alias in node.names:\n                yield node.lineno, alias.name\n        elif isinstance(node, ast.ImportFrom) and node.level == 0:\n            yield node.lineno, node.module",
      "note": "Every `import x` and every `from x import y` in one file, with its line number. A relative import (`from . import y`) stays inside its own package, so `level == 0` keeps only the absolute ones."
    },
    {
      "code": "\n\ndef team_of(module):\n    parts = module.split(\".\")\n    return parts[1] if parts[0] == \"carreto\" and len(parts) > 1 else None",
      "note": "`carreto.matching.offers` belongs to `matching`. A module outside `carreto`, such as `datetime`, belongs to no team and is not this check's business."
    },
    {
      "code": "\n\ndef main():\n    today = datetime.date.today().isoformat()\n    violations = 0\n    for path in sorted(ROOT.rglob(\"*.py\")):\n        own = path.parts[1]\n        for line, module in imports_in(path):\n            team = team_of(module)\n            if team in (None, own) or module == f\"carreto.{team}.api\":\n                continue",
      "note": "The standard itself, in one condition: an import from your own package, or of another package's `api` module, is fine. `own` is the directory under `carreto/` that the file sits in."
    },
    {
      "code": "            until = EXCEPTIONS.get((path.as_posix(), module))\n            if until and today <= until:\n                print(f\"{path}:{line}: allowed until {until}: {module}\")\n                continue\n            print(f\"{path}:{line}: imports {module}; use carreto.{team}.api\")\n            violations += 1",
      "note": "An exception counts until its date. The day after, the same import is a violation again, and nobody had to remember. The message names the file, the line and what to import instead, so whoever reads it in CI can fix it without asking anyone."
    },
    {
      "code": "    print(f\"{violations} violation(s)\")\n    return 1 if violations else 0\n\n\nif __name__ == \"__main__\":\n    sys.exit(main())",
      "note": "The exit status is what CI reads: 1 fails the build and 0 lets it through. The count is for the person."
    }
  ]
}
```

Run from the directory that holds `carreto/` (on Windows the command is `python` rather than
`python3`):

```
$ python3 check_imports.py
carreto/payments/invoice.py:1: allowed until 2027-03-31: carreto.tracking.models
carreto/payments/payout.py:1: imports carreto.matching.offers; use carreto.matching.api
1 violation(s)
$ echo $?
1
```

**The message is the standard, stated at the moment somebody breaks it.** It names the file, the
line, the module that should not be imported and the one to use instead. A developer in Payments who
has never read the wiki can fix this from the CI log, which is the difference between a rule that
teaches and a rule that only refuses. The `echo $?` shows the exit status: `1`, which is what makes a
CI job go red.

The fix is one line. Change the first line of `carreto/payments/payout.py` to:

```python
from carreto.matching.api import accepted_driver
```

Then look at the first two lines, to be sure the edit landed, and run the check again:

```
$ head -2 carreto/payments/payout.py
from carreto.matching.api import accepted_driver
from carreto.tracking.api import delivery_proved
$ python3 check_imports.py
carreto/payments/invoice.py:1: allowed until 2027-03-31: carreto.tracking.models
0 violation(s)
$ echo $?
0
```

The exception on `invoice.py` is still printed on every run. **An exception nobody sees is an
exception nobody remembers to close**, and printing it costs one line of the log. On 1 April 2027
the same run will print it as a violation instead, and the build will fail until Tracking's `api.py`
offers what Payments needs or somebody grants a new date. The last section of this lesson is about
how that decision gets made.

## Turning it on in a codebase that already breaks the rule

Carreto's monolith was not the tidy example. When Renata ran the real version of this check against
it for the first time, in report-only mode, it found **23 imports across team boundaries**. Making
the build fail that afternoon would have blocked every team for code most of them had not written,
and the check would have been switched off by the end of the week.

So the first version worked as a **ratchet**. The 23 went into a baseline file in the repository,
the check failed only on an import that was not in the baseline, and an entry could be removed from
the baseline but never added. A new violation failed the build from the first day; the old ones
became a list with a number on it. Four months later the baseline held six entries, each with an
owner. The `EXCEPTIONS` list in the program above is the same idea with a date on each entry: a
baseline says that an old violation will go, and an exception says by when.

**A check that starts strict on an old codebase is a check that gets disabled.** A check that starts
by freezing the current state, and only ever tightens, gets the codebase to the rule without a week
in which nobody can merge.
