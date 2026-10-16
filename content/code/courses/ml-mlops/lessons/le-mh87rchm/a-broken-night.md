---
title: A night that broke without an error
version: 1
---

The watch earns its place on the night something goes wrong upstream and nothing fails. **Make one
on purpose.** The commonest unit mistake in data loads is converting an amount that was already
converted: `spend_180d` is in cents, and a load that multiplies it by a hundred again leaves a
perfectly valid number in every row. Break tonight's snapshot that way, and run the night again:

```
ana@dev:~/ml$ sqlite3 features.db "UPDATE offline SET spend_180d = spend_180d * 100 WHERE as_of = '2026-02-28'"
ana@dev:~/ml$ python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 16603 rows in lapse_scores
ana@dev:~/ml$ python watch.py 2026-02-28; echo "exit status $?"
ok    members scored         before  3312.000   tonight  3355.000
ALARM mean p_lapse           before     0.174   tonight     0.001
ALARM share over 0.2         before     0.241   tonight     0.000
ok    tenure_days median     before   430.000   tonight   437.000
ok    recency_days median    before    20.000   tonight    20.000
ok    visits_180d median     before     6.000   tonight     5.000
ALARM spend_180d median      before 52910.000   tonight 5191000.000
ok    basket_avg median      before  9485.000   tonight  9486.000
ok    online_share median    before     0.250   tonight     0.231
ok    shops_180d median      before     2.000   tonight     2.000
3 alarm(s) for 2026-02-28
exit status 1
```

**The batch reported success.** It scored 3,355 members, as it did last night, and wrote them to the
table marketing reads. Nothing raised an error, because nothing was malformed: every value was a
number, in the right column, of the right type.

**The watch did not.** The median of `spend_180d` jumped a hundredfold, and the model, seeing every
member spend a hundred times more than anybody it trained on, decided nobody would lapse: a mean
probability of 0.001 and nobody over 0.2. Marketing's list for the month would have been empty, or
worse, built from whoever came out on top of a column of near-zeros. Exit status 1, three alarms,
and the one on the input names the cause.

The repair is the feature store's own: rebuild tonight's snapshot from the shop, which lesson 6
made a rerunnable step, then score the night again, which lesson 8 made a rerunnable step too:

```
ana@dev:~/ml$ python featurestore.py snapshot 2026-02-28 && python score_batch.py 2026-02-28
2026-02-28: 3355 members
3355 members scored as of 2026-02-28 by lapse version 1; 16603 rows in lapse_scores
ana@dev:~/ml$ python watch.py 2026-02-28; echo "exit status $?"
ok    members scored         before  3312.000   tonight  3355.000
ok    mean p_lapse           before     0.174   tonight     0.174
ok    share over 0.2         before     0.241   tonight     0.243
ok    tenure_days median     before   430.000   tonight   437.000
ok    recency_days median    before    20.000   tonight    20.000
ok    visits_180d median     before     6.000   tonight     5.000
ok    spend_180d median      before 52910.000   tonight 51910.000
ok    basket_avg median      before  9485.000   tonight  9486.000
ok    online_share median    before     0.250   tonight     0.231
ok    shops_180d median      before     2.000   tonight     2.000
exit status 0
```

Back to the numbers of the first run. **Two properties built earlier made the fix one line**: the
snapshot can be rebuilt for a single day, and the batch replaces a night instead of adding to it. A
pipeline without them would need somebody to delete rows by hand at night, under pressure, which is
how one bad load becomes two.
