---
title: A repository that tests what it receives
version: 1
---

A bare repository has no working copy, only Git's own files, which is what a server holds. The
project is cloned from it into `net`, where the work happens:

```
ana@ctl:~$ git init --bare -q net.git && git clone -q net.git net 2>&1 && ls net.git
warning: You appear to have cloned an empty repository.
HEAD
branches
config
description
hooks
info
objects
refs
```

The tests and the deployment live **in the project**, in `ci/`, so a change to the pipeline is a
commit like any other and is tested by the pipeline it changes:

```sh
# The checks every pushed commit has to pass: lesson 13's, in order of cost.
set -e
echo "== yamllint"
yamllint -d relaxed data/
echo "== validate"
python validate.py
echo "== offline tests"
python -m pytest -q -p no:cacheprovider test_configs.py test_links.py
```

```sh
# Render, apply, and check the network, retrying while it converges.
set -e
echo "== render"
python render.py
echo "== apply"
python push.py --commit
echo "== post-check"
for attempt in 1 2 3 4 5 6; do
  if python -m pytest -q -p no:cacheprovider test_network.py > post-check.log; then
    echo "attempt $attempt: $(tail -1 post-check.log)"
    exit 0
  fi
  echo "attempt $attempt: $(tail -1 post-check.log)"
  sleep 10
done
cat post-check.log
echo "post-check still failing after six attempts"
exit 1
```

`test.sh` is lesson 13's offline checks in order of cost, and `set -e` stops it at the first one
that fails. `deploy.sh` renders, applies, and then runs the post-check up to six times, ten seconds
apart, which is lesson 13's lesson about convergence turned into a loop: a network still converging
gets a minute, and one that is broken is reported at the end of it.

The hooks themselves are installed in the server's repository, outside the project:

```schooling-example
{
  "language": "sh",
  "file": "pre-receive",
  "parts": [
    {
      "code": "#!/bin/sh\n# Every commit pushed to any branch is tested before the repository accepts it."
    },
    {
      "code": "while read old new ref; do\n  [ \"$new\" = 0000000000000000000000000000000000000000 ] && continue",
      "note": "**A hook on the server, not on anybody's laptop.** Git runs `pre-receive` with one line per branch being pushed, the old commit, the new one and the branch name, and refuses the whole push if it exits with anything but 0."
    },
    {
      "code": "  work=$(mktemp -d)\n  git archive \"$new\" | tar -x -C \"$work\"\n  echo \"testing $ref at $(git rev-parse --short \"$new\")\"\n  if ! (cd \"$work\" && sh ci/test.sh); then\n    echo \"REFUSED: $ref fails its tests\"\n    rm -rf \"$work\"\n    exit 1\n  fi\n  rm -rf \"$work\"\ndone",
      "note": "**The commit is tested as pushed**, extracted into a directory of its own, so nothing a person has in their working copy and forgot to commit can make it pass."
    }
  ]
}
```

```schooling-example
{
  "language": "sh",
  "file": "post-receive",
  "parts": [
    {
      "code": "#!/bin/sh\n# What reaches main is deployed, and checked on the network afterwards.\nwhile read old new ref; do"
    },
    {
      "code": "  [ \"$ref\" = refs/heads/main ] || continue\n  work=$HOME/deploy\n  rm -rf \"$work\" && mkdir -p \"$work\"\n  git archive \"$new\" | tar -x -C \"$work\"\n  echo \"deploying main at $(git rev-parse --short \"$new\")\"\n  (cd \"$work\" && sh ci/deploy.sh) || echo \"DEPLOY FAILED at $(git rev-parse --short \"$new\")\"\ndone",
      "note": "**Only `main` is deployed.** Any other branch has been tested by `pre-receive` and stops there: a branch is a proposal, and `main` is what the network runs."
    }
  ]
}
```

```
ana@ctl:~$ chmod +x net.git/hooks/pre-receive net.git/hooks/post-receive && cd net && find . -path ./.git -prune -o -type f -print | sort
./.gitignore
./ci/deploy.sh
./ci/test.sh
./data/core1.yaml
./data/edge1.yaml
./data/edge2.yaml
./model.py
./push.py
./render.py
./templates/frr.j2
./test_configs.py
./test_links.py
./test_network.py
./validate.py
```

The project is lesson 10's data and template with lesson 13's model and tests. Nothing in it is new;
what is new is who runs it.
