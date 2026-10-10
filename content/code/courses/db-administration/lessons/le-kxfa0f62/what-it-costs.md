---
title: What it costs
version: 1
---

```bash
#!/usr/bin/env bash
# logcost.sh: how many bytes one fixed pgbench run adds to the server log
log=/var/log/postgresql/postgresql-16-main.log
before=$(sudo stat -c %s "$log")
pgbench -n -c 4 -t 2500 bench | grep -E 'processed|tps'
after=$(sudo stat -c %s "$log")
echo "the log grew by $((after - before)) bytes"
```
