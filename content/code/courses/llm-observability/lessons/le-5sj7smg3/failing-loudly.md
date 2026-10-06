---
title: A gate that fails loudly
version: 1
---

The candidate that changed both the model and the floor:

```
ana@lab:~/obs$ CANDIDATE=2026.10.4 python -m pytest -q --tb=line -p no:cacheprovider tests
.FFF.....                                                                [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: checks the candidate newly fails: {'e38': ['short_enough']}
    assert not {'e38': ['short_enough']}
/home/ana/obs/tests/test_regression.py:31: AssertionError: checks the candidate newly fails: {'e38': ['short_enough']}
E   AssertionError: cost 0.00944242 -> 0.0416189, +341%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 3.407653970062759 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: cost 0.00944242 -> 0.0416189, +341%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
E   AssertionError: median_ms 94.9369 -> 1037.31, +993%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 9.9262832086127 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: median_ms 94.9369 -> 1037.31, +993%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
FAILED tests/test_regression.py::test_within_budget[cost] - AssertionError: c...
FAILED tests/test_regression.py::test_within_budget[median_ms] - AssertionErr...
3 failed, 6 passed in 83.29s (0:01:23)
```

Three failures, each with its own sentence: the check e38 now fails, the cost is up 341%, the median
latency is up nearly tenfold. Nothing in `gate.json` accepts them, so the pull request that proposes
this release cannot merge until somebody changes the candidate or writes down why each is acceptable.

## A gate that cannot pass by not running

The most common way a gate stops protecting anything is not a weak test: it is a test that quietly
did not run. A variable missing in a new pipeline, a skip added during an outage and never removed, a
condition that is false on a branch nobody tested. Here is the gate with no candidate named:

```
ana@lab:~/obs$ python -m pytest -q --tb=line -p no:cacheprovider tests
EEEE.....                                                                [100%]Running teardown with pytest sessionfinish...

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
5 passed, 4 errors in 4.89s
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
