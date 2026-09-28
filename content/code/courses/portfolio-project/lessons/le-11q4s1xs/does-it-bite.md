---
title: A test that cannot fail proves nothing
version: 1
---

The test for the one rule was written after the rule, so it never had its red moment. That leaves a
question worth asking of every important test: **would it notice if the rule were gone?** The way to find
out is to remove the rule and run it.

loanbook's rule is the partial unique index. Delete it, and run the suite:

```
ana@laptop:~/loanbook$ sed -i '/CREATE UNIQUE INDEX/,/WHERE returned_on IS NULL;/d' app.py
ana@laptop:~/loanbook$ git diff --stat
 app.py | 2 --
 1 file changed, 2 deletions(-)
ana@laptop:~/loanbook$ python3 -m unittest
....F..
======================================================================
FAIL: test_an_item_cannot_be_lent_twice (test_app.LoanRules.test_an_item_cannot_be_lent_twice)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/loanbook/test_app.py", line 22, in test_an_item_cannot_be_lent_twice
    with self.assertRaises(app.Refused) as refused:
AssertionError: Refused not raised

----------------------------------------------------------------------
Ran 7 tests in 0.003s

FAILED (failures=1)
ana@laptop:~/loanbook$ git restore app.py
```

`sed` deleted the two lines of the index, the stat confirms nothing else changed, and exactly one test
failed: `test_an_item_cannot_be_lent_twice`, with `Refused not raised`. The test bites. Then `git
restore` puts the index back, and nothing of the experiment remains.

This is a small, manual version of what is called *mutation testing*: change the code on purpose and
check that some test objects. Tools exist that do it automatically, over the whole codebase, and they
are slow. For a portfolio project, doing it by hand to **the one rule** takes a minute and answers the
only question that matters: the guarantee in the README is actually guarded.

It is also a good thing to be able to say in an interview. *How do you know your tests work?* has a
weak answer, *they pass*, and a strong one: *I removed the index and watched the right test fail.*
