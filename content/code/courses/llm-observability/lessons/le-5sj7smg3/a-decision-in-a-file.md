---
title: A decision in a file
version: 2
---

The candidate a team would ship, lesson 14's 2026.10.3, through the same gate:

```
ana@dev:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
FFFF......                                                               [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: 2026.10.3 breaks ['e12', 'e29'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e12', 'e29']
/home/ana/obs/tests/test_regression.py:23: AssertionError: 2026.10.3 breaks ['e12', 'e29'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: 2026.10.3 newly fails a check on ['e02', 'e13', 'e14', 'e30']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e02', 'e13', 'e14', 'e30']
/home/ana/obs/tests/test_regression.py:30: AssertionError: 2026.10.3 newly fails a check on ['e02', 'e13', 'e14', 'e30']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: cost 0.00876128 -> 0.0130408, +49%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 0.48845602469045624 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: cost 0.00876128 -> 0.0130408, +49%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
E   AssertionError: median_ms 2486.21 -> 3354.84, +35%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 0.3493795226594898 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: median_ms 2486.21 -> 3354.84, +35%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_case_that_production_answers_is_broken
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
FAILED tests/test_regression.py::test_within_budget[cost] - AssertionError: c...
FAILED tests/test_regression.py::test_within_budget[median_ms] - AssertionErr...
4 failed, 6 passed in 186.37s (0:03:06)
```

**Four failures, and the gate is right about every one.** The two cases the floor fixed, e12 and
e29, break again. Four replies, right by their facts, now carry a sentence that cites nothing. And
against production it is 49% dearer and 35% slower. The budgets are measured against the release in
production, and the release in production is the broken one: it was cheap and fast because it refused.
The gate cannot know that. A person can, and the gate's job is to make the person say so where it will
be read.

So the decisions go into `gate.json`, under the candidate's name: each case by its id with the reason
it is acceptable, and each budget with a ceiling and a reason. Replace the file with:

```json
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {
    "2026.10.3": {
      "broken": {
        "e12": "refused with the Kindle chunk among three, as 2026.09.4 did; the next release looks at it",
        "e29": "refused with the return-window chunk among three, as 2026.09.4 did; the same"
      },
      "checks": {
        "e02": "right; a second sentence draws a conclusion and cites nothing",
        "e13": "right; a second sentence draws a conclusion and cites nothing",
        "e14": "right; the first sentence answers yes and cites nothing",
        "e30": "right; it repeats the customer's 12 working days, which no source says"
      },
      "cost": {"up_to": 0.75, "why": "answers the seven questions 2026.10.1 refused; costs what 2026.09.4 did"},
      "median_ms": {"up_to": 0.75, "why": "the same: 2026.10.1 was fast because it refused"}
    }
  }
}
```

```
ana@dev:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
..........                                                               [100%]Running teardown with pytest sessionfinish...

10 passed in 180.68s (0:03:00)
```

The same command now passes. Three properties make this better than turning the budgets up or
deleting the cases:

- **The exception belongs to one candidate.** The next release is held to 25% again and to every case,
  and nobody inherits an exception granted for a reason that no longer applies.
- **The reason is written beside the case or the number**, in the repository, and changes to it arrive
  in a pull request like code. A reviewer reads "refused with the Kindle chunk among three, as
  2026.09.4 did" and can disagree.
- **The ceiling is still a ceiling, and the list is still a list.** The cost may rise by up to 75%, not
  by anything. A third case breaking, or a fifth reply failing a check, fails the gate again.

A broken case accepted that way has been read, which is lesson 14's rule; one that is not in the file
has not, and the gate says so.
