---
title: Checks on a machine that belongs to nobody
version: 1
---

Cloning into `/tmp/fresh` works, and nobody remembers to do it every time. So teams hand the job to a
machine: **continuous integration**, or CI. On every pull request, a service creates a clean machine,
clones the branch exactly as it was pushed, runs the team's checks, and reports a green tick or a red cross
on the pull request.

Bruno's check is a short shell script, and it is worth reading once:

```schooling-example
{"language": "sh", "file": "check-links.sh", "parts": [{"code": "#!/bin/sh\n# Fail if any page links to a file that is not in the repository.\nstatus=0\n", "note": "The script starts by assuming all is well. status becomes 1 the moment one link is missing."}, {"code": "links=$(grep -oh '\\(src\\|href\\)=\"[^\":]*\"' *.html | cut -d'\"' -f2 | sort -u)\nfor f in $links; do\n", "note": "Every src= and href= in every page, with the quotes cut off and duplicates removed. Addresses with a colon, like https:, are skipped: they point outside the site."}, {"code": "  [ -e \"$f\" ] || { echo \"missing: $f\"; status=1; }\ndone\n", "note": "If the file does not exist here, say which one and remember the failure. It keeps going, so one run lists every missing file."}, {"code": "exit $status\n", "note": "0 if everything was found, 1 if anything was not. That number is all CI reads."}]}
```

On GitHub, the instructions for CI live in the repository itself, as a file under `.github/workflows/`.
GitLab and Bitbucket have their own formats with the same ideas:

```schooling-example
{"language": "yaml", "file": ".github/workflows/checks.yml", "parts": [{"code": "name: checks\n", "note": "The name the pull request page shows beside the result."}, {"code": "on: pull_request\n", "note": "When it runs: every time a pull request is opened or gets a new commit."}, {"code": "jobs:\n  links:\n    runs-on: ubuntu-latest\n", "note": "A fresh machine, created for this run and thrown away after it. Nothing of anybody's laptop is on it."}, {"code": "    steps:\n      - uses: actions/checkout@v5\n", "note": "A clone of the branch, exactly as it was pushed. The untracked picture is not in it, as it was not in /tmp/fresh."}, {"code": "      - run: ./check-links.sh\n", "note": "The check. A non-zero exit fails the run, and the pull request shows a red cross instead of a green tick."}]}
```

With that file on `main`, Ana's first push of `34-allergens` would have come back with a red cross within a
minute, and the log would have said `missing: images/allergens.png`. Nobody would have had to open the branch
to find out.

## Making it count

A red cross that anybody can ignore gets ignored. Lesson 8's **protected branches** close that gap: `main`
can be set to refuse a merge until the named checks are green. From then on, *checks green on a clean
machine* is not a habit somebody remembers; it is a gate nothing gets past.

## What CI cannot see

CI answers questions a script can answer: does it build, do the tests pass, are the links there. It cannot
tell whether the allergens picture is the right size on a phone, whether the text is clear to a customer, or
whether the change does what the ticket's author actually wanted. Those need a person, and that is where
the definition of done comes in. The course *Automated Testing and CI/CD* goes much further into writing checks; for now,
the idea is enough.
