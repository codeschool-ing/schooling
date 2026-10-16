---
title: Four more months of the shop
version: 1
---

Lesson 1 said the same program would one day draw the shop further on. **That day is now: four more
months of members and purchases, to 30 June 2026**, the same history up to February and new rows
after it:

```
ana@dev:~/ml$ python generate.py --until 2026-06-30
members       5000
purchases    72448
lines       116019
titles          80
last day   2026-06-30
```

`shop.db` is the data DVC versions, so the new shop is a new version of it, recorded the way lesson
7 recorded the first: DVC hashes the file, and Git commits the pointer.

```
ana@dev:~/ml$ dvc add -q shop.db && git add shop.db.dvc && git commit -qm "the shop to 30 June 2026" && git log --oneline -n 1
f0f580f the shop to 30 June 2026
```

Then the nightly routine the platform would have run since February, done at once: the feature
store's weekly snapshots for the new months, and the champion's scores for every one of them. The
query after it is the mean probability the champion gave on each night, the number the watch looks
at:

```
ana@dev:~/ml$ python featurestore.py backfill 2026-03-01 2026-06-28
18 snapshots, 63113 rows in the offline store
ana@dev:~/ml$ for night in $(sqlite3 features.db "SELECT DISTINCT as_of FROM offline WHERE as_of > '2026-02-28'"); do python score_batch.py $night > /dev/null; done
ana@dev:~/ml$ sqlite3 -column scores.db "SELECT cutoff, round(avg(p_lapse), 3) AS mean_p FROM lapse_scores WHERE cutoff >= '2026-02-28' GROUP BY cutoff"
2026-02-28  0.174 
2026-03-01  0.174 
2026-03-08  0.175 
2026-03-15  0.175 
2026-03-22  0.174 
2026-03-29  0.177 
2026-04-05  0.177 
2026-04-12  0.176 
2026-04-19  0.178 
2026-04-26  0.18  
2026-05-03  0.182 
2026-05-10  0.183 
2026-05-17  0.186 
2026-05-24  0.187 
2026-05-31  0.189 
2026-06-07  0.193 
2026-06-14  0.195 
2026-06-21  0.198 
2026-06-28  0.201 
```

**The mean crept up, from 0.174 at the end of February to 0.201 at the end of June**, a little each
week. The watch of lesson 9 compares each night with the four weeks before it, so run it over every
new night:

```
ana@dev:~/ml$ for night in $(sqlite3 features.db "SELECT DISTINCT as_of FROM offline WHERE as_of > '2026-02-28'"); do python watch.py $night > /dev/null && echo "$night ok" || echo "$night ALARM"; done
2026-03-01 ok
2026-03-08 ok
2026-03-15 ok
2026-03-22 ok
2026-03-29 ok
2026-04-05 ok
2026-04-12 ok
2026-04-19 ok
2026-04-26 ok
2026-05-03 ok
2026-05-10 ok
2026-05-17 ok
2026-05-24 ok
2026-05-31 ok
2026-06-07 ok
2026-06-14 ok
2026-06-21 ok
2026-06-28 ok
```

**Every night passed.** Nothing was ever more than a few percent away from the month before it,
because the month before it had already moved. A reference that moves with the data cannot see a
slow change, however far it goes in the end. That is the right design for catching a broken load,
which is sudden, and the wrong one for drift, which is not. The next section adds the reference
that does not move.
