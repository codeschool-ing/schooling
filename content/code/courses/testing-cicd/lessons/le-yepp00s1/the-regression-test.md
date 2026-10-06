---
title: The test that would have caught it
version: 1
---

The incident is over: 1.6.0 was stopped, 1.6.1 replaced it. One step remains, and it is the one most
often skipped. The fix in 1.6.1 was one character:

```
ana@laptop:~/shipquote$ git diff v1.6.0 v1.6.1 -- shipquote/quote.py
diff --git a/shipquote/quote.py b/shipquote/quote.py
index 0f1652b..860102b 100644
--- a/shipquote/quote.py
+++ b/shipquote/quote.py
@@ -10,7 +10,7 @@ FREE_FROM = 19900         # an order of R$ 199,00 or more ships free
 # Business days to deliver, by the first two digits of the CEP: the state.
 DAYS = {**{p: 1 for p in range(1, 20)},      # São Paulo
         **{p: 2 for p in range(20, 40)},     # Rio, Espírito Santo, Minas
-        **{p: 4 for p in range(40, 57)},     # Bahia to Pernambuco
+        **{p: 4 for p in range(40, 58)},     # Bahia to Alagoas
         **{p: 5 for p in range(58, 66)},     # Paraíba to Maranhão
         **{p: 6 for p in range(66, 70)},     # the North
         **{p: 3 for p in range(70, 80)},     # the Centre-West
ana@laptop:~/shipquote$ git checkout -q v1.6.0 -- shipquote/quote.py && python -m pytest tests/test_quote.py -q -k every_state
F                                                                        [100%]
=================================== FAILURES ===================================
_______________ test_every_state_prefix_has_a_delivery_estimate ________________

    def test_every_state_prefix_has_a_delivery_estimate():
        missing = [p for p in range(1, 100) if p not in DAYS]
>       assert missing == []
E       assert [57] == []
E         
E         Left contains one more item: 57
E         Use -v to get more diff

tests/test_quote.py:52: AssertionError
=========================== short test summary info ============================
FAILED tests/test_quote.py::test_every_state_prefix_has_a_delivery_estimate
1 failed, 15 deselected in 0.64s
ana@laptop:~/shipquote$ git checkout -q HEAD -- shipquote/quote.py && python -m pytest tests/test_quote.py -q -k every_state
.                                                                        [100%]
1 passed, 15 deselected in 0.14s
```

The second command puts 1.6.0's `quote.py` back in the working tree and runs the test 1.6.1 added
next to the fix, `test_every_state_prefix_has_a_delivery_estimate`. It fails, and its message says
exactly what was wrong: prefix 57 is missing. The third command restores the fixed file and the
test passes. A regression test is proved in both directions: **red on the code with the bug, green on
the code without it**. A test that was never seen failing might not test anything.

## Why this test, and not another

1.6.0 had a parametrized test, `test_delivery_takes_the_days_of_the_state`, with one CEP for each of
four regions. It passed, because none of its four examples was in Alagoas. The test checked examples;
the bug was in a range. The regression test checks the property instead: **every** prefix from 01 to
99 has an estimate. It does not care which state is missing, and it would have caught 57, or 58, or
any gap a future edit leaves in the table.

That is lesson 3's property-based testing in miniature, and it answers the question that should
follow every incident: what kind of test would have caught this, and does the suite now have one?

## The other gap the incident showed

The smoke test passed 1.6.0, because it only asked for `/health` and `/version`. A smoke test that
asked for one quote to each region would not have caught Alagoas either, but it would have caught a
release that could not quote at all. Adding a check is a decision about cost: each one makes every
deploy slower. The regression test lives in the suite, where it costs milliseconds and runs on every
commit.
