---
title: Rolling back, and what a rollback cannot undo
version: 1
---

If `v1.1.0` had gone wrong in production, the way back is the same move in the other direction:

```
ana@vm:~/etl-prod$ git checkout -q v1.0.0 && git describe --tags && dbt build --project-dir shop --target prod --quiet; echo "exit status $?"
v1.0.0
exit status 0
ana@vm:~/etl-prod$ git checkout -q v1.1.0 && dbt build --project-dir shop --target prod --quiet; git describe --tags
v1.1.0
done
```

Production went back to `v1.0.0`, was built, and came forward to `v1.1.0` again. No code
edited by hand, no guessing which version was the good one: **a tag is a version that can be
returned to**, and that is most of why it is worth making one.

A rollback of the code is a rollback of the data only as far as the data is rebuilt from the
code. Here that is nearly all of it: views are redefined, tables are rebuilt whole, and the
incremental `fact_sales` replaces its last thirty days on every run, so a rollback rebuilds those
from the old code as well. What it does not reach is anything older than the window, which would
need a full refresh, and anything that has already left the warehouse — the CSV sent to the managers
yesterday, an e-mail, a file uploaded to a partner. **Code can be rolled back; what was done with its
output cannot.** That is lesson 15's distinction between facts about the world and acts, met again
from the other side, and it is why the comparison happens before the deploy and not after.
