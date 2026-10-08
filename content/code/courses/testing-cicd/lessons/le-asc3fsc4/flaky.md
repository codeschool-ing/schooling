---
title: Flaky tests in the pipeline
version: 2
---

Lesson 3 section 09 defined a flaky test: one that passes and fails with no change in between. In a
pipeline, flakiness is no longer one person's annoyance; it is a red run on somebody else's pull
request, and a team habit of pressing "re-run" until it goes green.

The UTC failure of section 06 was **not** flaky. It failed every time in every UTC cell and passed
every time in every São Paulo cell. That is a deterministic failure that depends on the
environment, and the matrix is what made it visible. Telling the two apart is the first step with
any red test.

## A flaky test, measured

This test, written for the section, checks the zones of two CEPs by turning a set into a list.
Delete it when the section is done. Save it as `tests/test_zones_seen.py`:

```python
from shipquote.quote import zone_of


def test_the_zones_of_two_ceps():
    seen = {zone_of(cep) for cep in ["01310-100", "20040-002"]}
    assert list(seen) == ["SP", "SE"]
```

Run ten times in a row, on the same code and the same machine:

```
ana@laptop:~/shipquote$ for i in 1 2 3 4 5 6 7 8 9 10; do python -m pytest -q tests/test_zones_seen.py | tail -1; done | sed "s/ in .*//" | sort | uniq -c
      4 1 failed
      6 1 passed
ana@laptop:~/shipquote$ for i in 1 2 3 4 5 6 7 8 9 10; do PYTHONHASHSEED=0 python -m pytest -q tests/test_zones_seen.py | tail -1; done | sed "s/ in .*//" | sort | uniq -c
     10 1 passed
```

**Five passes, five failures.** Python randomises the hashing of strings in every new process, as a
defence against a kind of denial-of-service attack, so the order in which a set yields `"SP"` and
`"SE"` changes from run to run. Setting `PYTHONHASHSEED=0` fixes the hash seed, and the second loop
passed ten times out of ten.

**Fixing the seed is the wrong fix.** It makes the test pass by freezing an accident; the test would
still be asserting something the code never promised. The right fix is to compare what matters, the
set itself or `sorted(seen)`, so the test passes whatever the order.

## What a team does about flakiness

1. **Measure before believing.** Run the suspect test many times in a loop, as above; a test that
   fails one time in fifty is still flaky.
2. **Find the source.** Time, randomness and order, from lesson 3, cover most cases; shared state
   between tests and real network calls cover most of the rest.
3. **Quarantine while fixing, visibly.** Some teams move a flaky test to a separate, non-blocking
   job with an owner and a deadline. That keeps the main run trustworthy without pretending the
   test is fine.

What a team must not do is configure the pipeline to **retry failed tests automatically** and call
the second attempt a pass. It turns every flaky test into a green one, including the test that was
right, and it teaches everybody that red means "try again".
