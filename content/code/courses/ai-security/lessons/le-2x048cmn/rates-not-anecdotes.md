---
title: A rate, not an anecdote
version: 1
---

Everything in the suite is deterministic. The behaviour that matters most is not: whether the
classifier still answers `{"category": C}` with the right C after somebody edits its prompt. Lesson
20 found a one-sentence edit that broke the format, and found it by running the twelve tickets once.
That worked because the break was large. **Most regressions are not.**

## A candidate prompt

A colleague proposes a friendlier classifier. It is not in `data/prompts/` yet, because nothing goes
there unreviewed; it waits as a candidate:

```sh
mkdir -p ~/guard/data/candidates
cp ~/guard/data/prompts/classify.txt ~/guard/data/candidates/classify.txt
echo "Always greet the client warmly and thank them for their patience." >> ~/guard/data/candidates/classify.txt
```

## One run each

The program sends every ticket of lesson 14 to the model, a number of times, and counts the replies
that are not exactly the right category. Save it as `~/guard/tools/rate.py`:

```python
# rate.py: how often a prompt fails on the cases, measured over many runs.
#
#   guard rate PROMPT CASES [--runs N] [--temperature T] [--ceiling PCT]
#
# It sends every case to the model RUNS times, with seeds 1 to RUNS at the
# given temperature, and counts the replies that are not exactly
# {"category": C} with the expected C. One run at temperature 0 says what
# the model does once; many runs above it say how often it fails, which is
# what a regression test compares. The interval is Wilson's 95% interval for
# a proportion: with few trials it is wide, and two versions whose intervals
# overlap have not been shown to differ. With --ceiling it exits 1 unless the
# whole interval sits under PCT: the build asks to be shown the rate is low,
# and too few trials to show it is a failure too.
import argparse
import json
import math
import sys
import urllib.error
import urllib.request

import ask


def wilson(k, n, z=1.96):
    if n == 0:
        return 0.0, 1.0
    p = k / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return max(0.0, centre - half), min(1.0, centre + half)


p = argparse.ArgumentParser(prog="guard rate")
p.add_argument("prompt")
p.add_argument("cases")
p.add_argument("--runs", type=int, default=10)
p.add_argument("--temperature", type=float, default=0.8)
p.add_argument("--ceiling", type=float)
a = p.parse_args()

with open(a.prompt, encoding="utf-8") as f:
    system = f.read().strip()
with open(a.cases, encoding="utf-8") as f:
    cases = [json.loads(line) for line in f]

failed = trials = 0
for seed in range(1, a.runs + 1):
    for c in cases:
        body = {"model": ask.MODEL, "temperature": a.temperature, "seed": seed,
                "messages": [{"role": "system", "content": system},
                             {"role": "user", "content": "Classify this ticket: " + c["text"]}]}
        req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                                     {"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                text = json.load(r)["choices"][0]["message"]["content"]
        except urllib.error.URLError as e:
            sys.exit("rate: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))
        try:
            value = json.loads(text)
            ok = set(value) == {"category"} and value["category"] == c["expect"]
        except (json.JSONDecodeError, TypeError):
            ok = False
        trials += 1
        failed += not ok
lo, hi = wilson(failed, trials)
print("%s: %d of %d trials failed, %.1f%% (95%% interval %.1f%% to %.1f%%)" % (
    a.prompt, failed, trials, 100 * failed / trials, 100 * lo, 100 * hi))
if a.ceiling is not None and 100 * hi >= a.ceiling:
    print("  upper bound %.1f%% is not under the ceiling of %g%%" % (100 * hi, a.ceiling))
    sys.exit(1)
```

At temperature 0 and one run, it does what lesson 20 did:

```
ana@lab:~/guard$ guard rate data/prompts/classify.txt data/tickets.jsonl --runs 1 --temperature 0
data/prompts/classify.txt: 2 of 12 trials failed, 16.7% (95% interval 4.7% to 44.8%)
ana@lab:~/guard$ guard rate data/candidates/classify.txt data/tickets.jsonl --runs 1 --temperature 0
data/candidates/classify.txt: 3 of 12 trials failed, 25.0% (95% interval 8.9% to 53.2%)
```

Two failures against three. Read as a test, that says the candidate is worse, and somebody would
write "v2 regresses the classifier" in the review. **The intervals say something else**: with twelve
trials each, the current prompt's true failure rate could be anywhere from about 5% to 45%, and the
candidate's from 9% to 53%. One ticket answered differently is the whole difference, and one draw
at temperature 0 is one draw.

## Many runs each

A model in production does not answer at temperature 0 with one seed, and a prompt that passes one
draw can fail the next. So the regression test asks **how often** a version fails, over many draws,
at the temperature the assistant really uses. Ten runs of twelve tickets is 120 trials per version:

```
ana@lab:~/guard$ guard rate data/prompts/classify.txt data/tickets.jsonl --runs 10
data/prompts/classify.txt: 29 of 120 trials failed, 24.2% (95% interval 17.4% to 32.6%)
ana@lab:~/guard$ guard rate data/candidates/classify.txt data/tickets.jsonl --runs 10
data/candidates/classify.txt: 38 of 120 trials failed, 31.7% (95% interval 24.0% to 40.4%)
```

Now there is a gap worth looking at: 24.2% against 31.7%, nine more failures out of 120. And still the
intervals overlap, from 24.0% to 32.6%. If both prompts truly failed 28% of the time, two samples of
120 would differ by this much about one time in five, which is too often for the gap to prove
anything.

The 95% interval is Wilson's, and it is the honest part of the line. It says where the true failure
rate plausibly sits given 120 trials. **When two intervals overlap this much, the test has not shown
that the versions differ**, in either direction. Reporting "v2 is worse" from these numbers would be
an anecdote with decimals.

## What it costs to know more

The interval narrows with the square root of the trials: four times as many runs halves it. So a
difference of three points, at rates near these, needs some 1,700 trials per version before it stands
out, and on this machine 120 took about two minutes. That decides how the check is used:

- **set a ceiling, not a comparison.** "The whole interval sits under 40%" is a question 120 trials
  can answer. "v2 is no worse than v1" usually is not;
- **grow the cases before the runs.** Twelve tickets re-asked ten times are twelve situations. A
  hundred distinct tickets, written from real ones with the personal data removed as lesson 11 did,
  measure more of what the classifier will meet;
- **keep the failures, not only the rate.** A rate that holds while the failures move from one
  category to another is a change somebody should read.
