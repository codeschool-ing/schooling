---
title: What continuous integration is
version: 2
---

**Continuous integration** is a practice before it is a tool: everybody merges their work into the
shared main line often, at least daily, and **every merge is checked automatically** by building
the project and running its tests on a machine that is not the author's. The tool, a CI server, is
what makes the second half cheap enough to do on every push.

Both halves matter. Merging rarely means that when two people finally integrate, a week of changes
collide at once and nobody can say which one broke the build. Checking by hand means the check gets
skipped. A CI server turns "is main still working?" into a question that answers itself a few
minutes after every push.

## The smallest CI there is

Hosted services, GitHub Actions and GitLab CI among them, are the subject of lesson 6. To see what
they do without any of their vocabulary, this lesson uses a CI that fits in one file: a git
**post-receive hook**, a script git runs on the receiving repository after every push. It lives in
a **bare repository**, one with no working files, which is what a server keeps. Make one beside the
project:

```sh
git init --bare -b main ~/ci/shipquote.git
```

and put the hook in its `hooks` directory. Save it as `~/ci/shipquote.git/hooks/post-receive`:

```schooling-example
{
  "language": "sh",
  "file": "post-receive",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# The lab's whole CI. On every push to main: a clean checkout of the pushed\n# commit, then the test suite once per Python version and per time zone. What\n# it prints reaches the person who pushed, each line prefixed with \"remote:\".\nset -uo pipefail\nPYTHONS=${CI_PYTHONS:-\"3.11 3.12 3.13\"}\nZONES=${CI_ZONES:-\"America/Sao_Paulo UTC\"}\nRUNS=$(cd \"$(dirname \"$0\")/../..\" && pwd)/runs\n",
      "note": "The configuration: which Python versions and which time zones to test under, and where to keep what each run produced. Each combination is a **cell** of the matrix that section 06 is about."
    },
    {
      "code": "while read -r old new ref; do\n  if [ \"$ref\" != refs/heads/main ]; then\n    echo \"ci: ${ref#refs/heads/} is not main, nothing to run\"\n    continue\n  fi",
      "note": "git hands the hook one line per updated branch: old commit, new commit, branch name. **This is the trigger**: only pushes to `main` run anything."
    },
    {
      "code": "  mkdir -p \"$RUNS\"\n  n=$(( $(ls \"$RUNS\" | wc -l) + 1 ))\n  run=$RUNS/$n\n  mkdir \"$run\"\n  work=$(mktemp -d)\n  git archive \"$new\" | tar -x -C \"$work\"\n  echo \"ci: run $n, commit ${new:0:7}, checked out clean\"\n  failed=0",
      "note": "A numbered run, and a **clean checkout**: `git archive` writes the pushed commit, and only what was committed, into a new empty directory. Nothing from anybody's laptop comes with it."
    },
    {
      "code": "  for py in $PYTHONS; do\n    venv=$work/.venv-$py\n    if ! { uv venv -q -p \"$py\" \"$venv\" &&\n           VIRTUAL_ENV=$venv uv pip install -q -r \"$work/requirements-dev.txt\"; } \\\n         > \"$run/install-$py.log\" 2>&1; then\n      echo \"ci: python $py could not be installed, see install-$py.log\"\n      failed=1\n      continue\n    fi",
      "note": "A fresh virtual environment per Python version, with the pinned dependencies. If installing fails, the cell is a failure too, with its own log."
    },
    {
      "code": "    for tz in $ZONES; do\n      cell=\"py$py-${tz//\\//-}\"\n      if (cd \"$work\" && TZ=$tz \"$venv/bin/python\" -m pytest -q -p no:cacheprovider \\\n            --junitxml=\"$run/$cell.xml\" > \"$run/$cell.log\" 2>&1); then\n        result=pass\n      else\n        result=FAIL\n        failed=1\n      fi\n      printf 'ci: %-5s %-18s %-4s  %s\\n' \"$py\" \"$tz\" \"$result\" \"$(tail -1 \"$run/$cell.log\")\"\n    done\n  done",
      "note": "The suite, once per time zone, with its output and a JUnit XML report kept under the run's directory. One line per cell is printed back, ending with pytest's own summary."
    },
    {
      "code": "  rm -rf \"$work\"\n  if [ \"$failed\" = 0 ]; then\n    echo \"ci: run $n passed\"\n  else\n    echo \"ci: run $n FAILED, logs in $run\"\n  fi\ndone",
      "note": "Clean up the checkout and give a verdict for the run."
    }
  ]
}
```

## The first push

git runs a hook only if it is executable, so `chmod +x ~/ci/shipquote.git/hooks/post-receive` first.
The hook builds an environment with `uv` for each Python version, and uv downloads any of 3.11,
3.12 and 3.13 the machine does not have, which makes the first push slower than the ones after it.
On a network that refuses those downloads, give the hook the versions you have, for instance
`CI_PYTHONS="3.12" git push`: every push in this lesson then shows two cells where these show six,
and nothing else changes.

Ana connects her clone to that repository and pushes `main`:

```
ana@laptop:~/shipquote$ git remote add origin ~/ci/shipquote.git
ana@laptop:~/shipquote$ git push -u origin main
remote: ci: run 1, commit b3062cb, checked out clean        
remote: ci: 3.11  America/Sao_Paulo  pass  41 passed, 2 skipped in 2.05s        
remote: ci: 3.11  UTC                pass  41 passed, 2 skipped in 1.41s        
remote: ci: 3.12  America/Sao_Paulo  pass  41 passed, 2 skipped in 1.94s        
remote: ci: 3.12  UTC                pass  41 passed, 2 skipped in 1.41s        
remote: ci: 3.13  America/Sao_Paulo  pass  41 passed, 2 skipped in 2.03s        
remote: ci: 3.13  UTC                pass  41 passed, 2 skipped in 1.43s        
remote: ci: run 1 passed        
To /home/ana/ci/shipquote.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
```

Every line starting with `remote:` was printed by the hook, on the receiving side, and relayed by
git. **Run 1 checked commit `b3062cb` in six cells**, three Python versions by two time zones, and
all six passed with 41 tests passed and 2 skipped, the contract tests of lesson 2. Then git reports
the push itself: `main` created on the remote.

## What this toy leaves out

Three things separate it from a real CI service, and they are worth naming because lesson 6 adds
them back:

- **It runs on the same machine**, so "a machine that is not the author's" is only half true. The
  checkout is clean, but the Python installations and the network are shared.
- **It reports after the fact.** A post-receive hook runs once the push is accepted, so a red run
  does not stop a broken commit reaching `main`. A hosted service reports on a pull request
  *before* the merge, which is the point of section 11.
- **Its cells run one after the other.** Hosted runners run them in parallel, on separate machines.

What it shares with every CI service is the loop: **a push triggers a run, the run starts from
what was committed, the tests run in every configuration that matters, and the result comes back
to the person who pushed.** The rest of this lesson takes that loop apart.
