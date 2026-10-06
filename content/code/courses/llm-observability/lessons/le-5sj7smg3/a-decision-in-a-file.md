---
title: A decision in a file
version: 1
---

The candidate a team would ship, lesson 14's 2026.10.3, through the same gate:

```
ana@lab:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
..FF.....                                                                [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: cost 0.00944242 -> 0.0182159, +93%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 0.9291579912776597 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: cost 0.00944242 -> 0.0182159, +93%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
E   AssertionError: median_ms 91.8558 -> 644.412, +602%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 6.015471020630091 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: median_ms 91.8558 -> 644.412, +602%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_within_budget[cost] - AssertionError: c...
FAILED tests/test_regression.py::test_within_budget[median_ms] - AssertionErr...
2 failed, 7 passed in 68.03s (0:01:08)
```

**It fails, and the gate is right to fail it.** Against production it is 93% more expensive and six
times slower. Both budgets are measured against the release in production, and the release in production
is the broken one: it was cheap and fast because it refused. The gate cannot know that. A person can,
and the gate's job is to make the person say so where it will be read.

So the decision goes into `gate.json`, under the candidate's name, with a ceiling and a reason:

```
ana@lab:~/obs$ cat gate.json
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {
    "2026.10.3": {
      "cost": {"up_to": 1.0, "why": "answers the five questions 2026.10.1 refused; costs what 2026.09.4 did"},
      "median_ms": {"up_to": 7.0, "why": "the same: 2026.10.1 was fast because it refused"}
    }
  }
}
```

The same command now passes:

```
ana@lab:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
.........                                                                [100%]Running teardown with pytest sessionfinish...

9 passed in 76.90s (0:01:16)
```

Three properties make this better than turning the budget up:

- **The exception belongs to one candidate.** The next release is held to 25% again; nobody inherits a
  budget that was raised for a reason that no longer applies.
- **The reason is written beside the number**, in the repository, and changes to it arrive in a pull
  request like code. A reviewer reads "answers the five questions 2026.10.1 refused" and can disagree.
- **The ceiling is still a ceiling.** The cost may rise by up to 100%, not by anything; a candidate that
  turned out to cost three times as much would fail again.

The same file accepts a broken case, under `broken`, with the case's id and the reason it is acceptable.
A broken case accepted that way has been read, which is lesson 14's rule; one that is not in the file has
not, and the gate says so.
