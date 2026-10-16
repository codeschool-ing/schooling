---
title: What a retry buys, and what it hides
version: 1
---

**A retry runs a failed test again, and if a later attempt passes, the run carries on.** That is
all it does. It does not make the test right, and it does not make the page right. What it changes
is the verdict the suite reports, and that is why it has to be used with its report in view.

Playwright takes `--retries N` on the command line, or `retries` in a configuration. A test that
fails is run again, up to N more times. One that fails and then passes is not counted as passed:
Playwright files it under a third verdict, **flaky**, and prints that count in the summary.

## On the quarantined test

The test from the diagnosis section, twenty times, with up to two retries each:

```
ana@laptop:~/quitanda$ npx playwright test --config quarantine.config.js --repeat-each 20 --retries 2 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  1 failed
  7 flaky
  12 passed (1.1m)
```

Twelve attempts passed the first time. **Seven failed and then passed on a retry, and they are
the 7 flaky.** One failed three times in a row and is still a failure. A retry lowers the rate a
reader sees and does not take it to zero: eight attempts in twenty met the defect, and only one
of them is counted as failed.

## On the gate's pair

The shared-basket pair from the causes section, with two workers and two retries:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --retries 2 > /tmp/run.log; echo "exit code $?"
exit code 0
ana@laptop:~/quitanda$ grep -E '^  [0-9]+ (failed|flaky|passed)' /tmp/run.log
  5 flaky
  15 passed (53.8s)
```

The exit code is the number a CI job reads: 0 means the gate is open, anything else means it is
shut. **With retries, five attempts that failed on the shared basket became 5 flaky
and an exit code of 0.** The defect in the suite, the shared basket, is still there, and the only
trace of it is one line of the summary. Nobody reads that line on a green build.

That is what a retry hides. Without a report, a retry turns *this test fails one time in four*
into *this test passes*, which is the same move as the person pressing the button again, done by
the machine and done every time.

## Make flakiness visible

Retries earn their place in one situation: the team has decided to keep a gate open while it
fixes something, and it has somewhere to look that says how often the retries were needed. The
summary's flaky count is that place, and Playwright can be told to treat it as a failure:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --retries 2 --fail-on-flaky-tests > /tmp/run.log; echo "exit code $?"
exit code 1
ana@laptop:~/quitanda$ grep -E '^  [0-9]+ (failed|flaky|passed)' /tmp/run.log
  5 flaky
  15 passed (53.9s)
```

`--fail-on-flaky-tests` keeps the retries, so the report still says whether a test passed on a
second attempt, and **shuts the gate anyway**. Five attempts were flaky again, and this time the exit code was 1. A suite with retries and this flag cannot go flaky without somebody seeing it.

Three habits follow from all this:

- **Count flaky results over time**, per test, the way the summary counts them per run. A test
  that is flaky once a month and one that is flaky every day need different answers, and only a
  count tells them apart.
- **Never raise the retries to make a run pass.** If two retries are not enough, the third is the
  same coin tossed again.
- **Keep the failing attempt.** The trace from the diagnosis section, recorded on retry or on
  failure, is the evidence of what went wrong; a retry that passed has thrown nothing away only if
  that trace was kept.

A test that keeps showing up in the flaky count needs to leave the gate until it is fixed. The
next section is how.
