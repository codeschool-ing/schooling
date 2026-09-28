---
title: Write the test before the fix
version: 1
---

The test about spaces was written for a bug: a borrower typed as three spaces was accepted, and the list showed
an item lent to nobody. The order in which it was written matters, so here it is again.

**First the test, on its own**, with the code still as it was:

```
ana@laptop:~/loanbook$ git diff --stat
 test_app.py | 5 +++++
 1 file changed, 5 insertions(+)
ana@laptop:~/loanbook$ python3 -m unittest
F......
======================================================================
FAIL: test_a_borrower_made_of_spaces_is_refused (test_app.LoanRules.test_a_borrower_made_of_spaces_is_refused)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/loanbook/test_app.py", line 39, in test_a_borrower_made_of_spaces_is_refused
    with self.assertRaises(app.Refused) as refused:
AssertionError: Refused not raised

----------------------------------------------------------------------
Ran 7 tests in 0.003s

FAILED (failures=1)
```

`F......` means one failure and six passes, and the report says which test and why: `Refused not raised`,
because `"   "` is not empty and so `if not borrower` let it through. This is the most useful moment a test
ever has. **It proves the test can see the bug.** A test written after the fix passes from its first run,
and there is no way to tell whether it passes because the code is right or because the test checks
nothing.

**Then the fix**, one line, and the same command:

```
ana@laptop:~/loanbook$ git diff app.py
diff --git a/app.py b/app.py
index e6039b6..e48521f 100644
--- a/app.py
+++ b/app.py
@@ -71,6 +71,7 @@ def item_named(db, item_id):
 
 
 def lend(db, item_id, borrower, today):
+    borrower = (borrower or "").strip()
     if not borrower:
         raise Refused(HTTPStatus.BAD_REQUEST, "Say who is borrowing it.")
     item = item_named(db, item_id)
ana@laptop:~/loanbook$ python3 -m unittest
.......
----------------------------------------------------------------------
Ran 7 tests in 0.004s

OK
```

Seven dots. The commit that holds both, lesson 9's *Refuse a borrower made of spaces*, says in its body
that the test came first and failed. A reviewer who reads that knows how you work.

This habit has a name, *test-driven development*, and a whole method built around it. For a portfolio
project you do not need the method. You need the one rule: **for a bug, the test comes first, and you see
it fail.**
