---
title: A gate that fails loudly
version: 2
---

The candidate that changed both the model and the floor:

```
ana@dev:~/obs$ CANDIDATE=2026.10.4 python -m pytest -q --tb=line -p no:cacheprovider tests
FF........                                                               [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: 2026.10.4 breaks ['e03', 'e09', 'e10', 'e11', 'e13', 'e18', 'e31'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e03', 'e09', 'e10', 'e11', 'e13', 'e18', ...]
/home/ana/obs/tests/test_regression.py:23: AssertionError: 2026.10.4 breaks ['e03', 'e09', 'e10', 'e11', 'e13', 'e18', 'e31'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: 2026.10.4 newly fails a check on ['e02', 'e03', 'e04', 'e05', 'e06', 'e07', 'e08', 'e10', 'e11', 'e12', 'e13', 'e15', 'e16', 'e17', 'e18', 'e19', 'e26', 'e28', 'e29', 'e32']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e02', 'e03', 'e04', 'e05', 'e06', 'e07', ...]
/home/ana/obs/tests/test_regression.py:30: AssertionError: 2026.10.4 newly fails a check on ['e02', 'e03', 'e04', 'e05', 'e06', 'e07', 'e08', 'e10', 'e11', 'e12', 'e13', 'e15', 'e16', 'e17', 'e18', 'e19', 'e26', 'e28', 'e29', 'e32']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_case_that_production_answers_is_broken
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
2 failed, 8 passed in 190.92s (0:03:10)
```

Two failures, and the second is one line naming twenty cases. That is as much as a test message should
carry. Which check each case fails is a question for `regress.py`, which reads the two runs the gate
has just made:

```
ana@dev:~/obs$ python regress.py production candidate | head -12
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.4
               both right  both wrong  fixed  broken
  dev                  8           6      4       4
  held-out             5           2      0       3
exact McNemar p = 0.5488 on 11 changed verdicts
  broken e10 dev      How long does a pickup point keep my parcel?
  broken e11 dev      On how many devices can I read my e-books?
  broken e13 dev      Can I listen to an audiobook without an internet connect
  broken e31 dev      Order MG-00000003 - I want to return it. Who pays for th
  broken e03 held-out How long after my return arrives will I get the refund?
  broken e09 held-out When is a standard parcel considered lost?
  broken e18 held-out What happens if my order costs more than my gift card ho
EXIT 0
```

Nothing in `gate.json` accepts any of it, so the pull request that proposes this release cannot merge
until somebody changes the candidate or writes down, case by case, why each is acceptable. Twenty-seven
sentences would be a strange thing to write for a release, and that is the point: the effort of
accepting a change grows with how much it breaks.

**The budgets passed**, because 2026.10.4 is cheaper than production and, on this run, no more than
25% slower. In lesson 14 the same comparison measured it 17% slower, and an earlier run of this
same gate measured 30%, and failed. A median over 32 replies on one machine moves by that much from run to run, so a
latency budget set near the noise passes and fails at random. Either the budget is wider than the
noise, or the measurement is made of more requests.

## A gate that cannot pass by not running

The most common way a gate stops protecting anything is not a weak test: it is a test that quietly
did not run. A variable missing in a new pipeline, a skip added during an outage and never removed, a
condition that is false on a branch nobody tested. Here is the gate with no candidate named:

```
ana@dev:~/obs$ python -m pytest -q --tb=line -p no:cacheprovider tests
EEEE......                                                               [100%]Running teardown with pytest sessionfinish...

==================================== ERRORS ====================================
_______ ERROR at setup of test_no_case_that_production_answers_is_broken _______
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
_________________ ERROR at setup of test_no_check_newly_fails __________________
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
__________________ ERROR at setup of test_within_budget[cost] __________________
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
_______________ ERROR at setup of test_within_budget[median_ms] ________________
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
=========================== short test summary info ============================
ERROR tests/test_regression.py::test_no_case_that_production_answers_is_broken
ERROR tests/test_regression.py::test_no_check_newly_fails - pytest.UsageError...
ERROR tests/test_regression.py::test_within_budget[cost] - pytest.UsageError:...
ERROR tests/test_regression.py::test_within_budget[median_ms] - pytest.UsageE...
6 passed, 4 errors in 6.21s
```

**Four errors, not four skips.** pytest reports an error at setup as a failure of the run: the summary
is red and the exit code is non-zero, so the pipeline fails. The set's own tests still ran and passed,
because they need no candidate. Had `conftest.py` called `pytest.skip` instead, the same run would have
printed a green summary over four tests that checked nothing, and every pull request after it would
have merged on that green.

The rules this follows are the ones this repository holds itself to:

- **A gate fails when it cannot run.** A missing variable, a missing set, a manifest that does not
  match: each is an error that names what is missing.
- **No test is skipped to get to green.** A test that is wrong is fixed; one that is right and failing is
  the gate doing its job.
- **A failure says what to do.** Every assertion in these files ends with the next step.
