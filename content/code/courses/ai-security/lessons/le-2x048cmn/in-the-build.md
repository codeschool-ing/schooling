---
title: Putting both in the build
version: 1
---

The two kinds of check have different prices, so they run at different moments. The script the build
calls holds both. Save it as `~/guard/ci.sh`:

```sh
cat > ~/guard/ci.sh <<'EOF'
#!/usr/bin/env bash
# ci.sh: what the build runs. The suite on every change; the rate of every
# candidate prompt, against a ceiling, when there is one.
set -u
cd ~/guard
export PATH=~/guard/bin:$PATH
status=0
guard defences data/suite.json --now "${CI_DATE:-$(date +%F)}" || status=1
for f in data/candidates/*.txt; do
  [ -e "$f" ] || continue
  guard rate "$f" data/tickets.jsonl --runs 10 --ceiling 40 || status=1
done
exit $status
EOF
```

The ceiling is 40%: a candidate passes when the whole interval of its failure rate sits under it.
That is a stricter question than "is the rate under 40%", and deliberately so. The build is not
asking for a best guess; it is asking to be shown.

```
ana@lab:~/guard$ CI_DATE=2026-10-09 bash ci.sh; echo "exit status $?"
PASS     every boundary flow has a threat
PASS     retrieval shows each reader only theirs
PASS     files under review are approved
PASS     screens follow the rules
KNOWN    no credentials in the repository         SEC-41 until 2026-10-31: lesson 17's findings, moving to the secret store
OVERDUE  keys narrow, stored and rotated          SEC-42 was due 2026-10-05
6 checks, 1 failing the build
data/candidates/classify.txt: 38 of 120 trials failed, 31.7% (95% interval 24.0% to 40.4%)
  upper bound 40.4% is not under the ceiling of 40%
exit status 1
```

Two reasons for a red build, and they are different kinds. The overdue key is a promise past its
date. The candidate is a measurement that could not clear the bar: 40.4% is a tenth of a point over
the ceiling. **That is not a finding that the candidate is bad.** It says 120 trials cannot show it
is good enough. The author's choices are honest ones: run more trials and see whether the interval
comes down under 40%, or drop the sentence the classifier never needed. Lowering the ceiling to let
it through is not one of them.

## Which check runs when

| check | needs | runs |
|---|---|---|
| the suite | Python and the repository; no model, no key, no network | on every pull request, in seconds |
| the rate of a candidate | the model, and a key for it if it is hosted | when a file under review or a candidate changes |
| the rate of what is deployed | the same | every night, against the model the provider serves today |

The nightly run is the one people leave out. Lesson 19 asked every provider whether a model version
can be pinned, because a hosted model can change underneath the assistant, and nothing in the
repository changes when it does. **The only way to notice is to
re-measure what is deployed on a schedule** and compare it with the ceiling, exactly as the
monitoring of lesson 22 compares an hour with the hours before it.

## The key the model check needs

The suite needs no secret, so it can run on a pull request from anybody. The model check needs the
provider's key when the model is hosted, and lesson 17's rules apply to the build like to any other
program: **a key of its own, narrowed to the one model, with a spending limit**. It is stored in the
CI system's secret store rather than in the repository, and given only to jobs that run on code
somebody with write access has already accepted. A pull request from a fork that could print the key
in its own build log is the leak lesson 17 was about, with the CI system as the courier.

The rate check also costs money every time it runs. Its 240 calls cost under one real at lesson 18's
prices; 240 calls on every push of every branch, on a busy repository, is a budget line that grows
without anybody deciding it should. Running it only when the files it measures
change is the cheap answer, and lesson 18's daily ceiling is the backstop.

## What a red build means

Every failure in this suite names its fix: approve the file, finish the ticket, measure the
candidate on more trials or improve it. **None of them is "re-run it until it is green".** For the
deterministic checks a re-run gives the same answer. For the rate, re-running with new seeds until
one passes is choosing the draw you liked, which is the same mistake as reporting one run at
temperature 0, made on purpose.
