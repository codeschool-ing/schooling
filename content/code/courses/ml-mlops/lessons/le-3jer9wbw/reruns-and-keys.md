---
title: Running it twice, and reading what it wrote
version: 1
---

Batch jobs are rerun. A load arrives late and the night is scored again; somebody fixes a bug and
reruns last week. **A job that appends would double every member's score on the second run**, and
every report built on the table would count them twice without an error anywhere. `score_batch.py`
deletes the night before it writes it, inside one transaction, so a rerun replaces rather than adds.

```
ana@dev:~/ml$ python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 3355 rows in lapse_scores
ana@dev:~/ml$ sqlite3 -header -column scores.db "SELECT * FROM lapse_scores ORDER BY p_lapse DESC LIMIT 5"
member_id  cutoff      p_lapse  model_version
---------  ----------  -------  -------------
2291       2026-02-28  0.9431   1            
877        2026-02-28  0.9292   1            
1920       2026-02-28  0.9214   1            
2443       2026-02-28  0.8971   1            
4539       2026-02-28  0.8853   1            
```

The second run wrote the same 3,355 rows and the table still holds 3,355: **the job is idempotent**,
the word for a step that leaves the same result however many times it runs. The query is what
marketing would run, the members most likely to lapse, each with the cutoff and the version that
scored them. When version 2 takes over, its rows will say so, and a report that mixes two versions
in one month can tell which is which.

**The table grows one night at a time, and that is deliberate.** Next month's scores do not
overwrite this month's, because lesson 9 needs both: the scores of 28 February, compared with what
the members actually did in the 90 days after it, are the model's report card, and they can only be
read if they were kept.
