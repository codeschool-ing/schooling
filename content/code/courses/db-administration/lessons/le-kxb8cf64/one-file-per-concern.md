---
title: One file per concern, in git
version: 1
---

```conf
# 50-shop.conf: what the shop's server sets differently from Ubuntu's
# defaults. provision.sh copies it into /etc/postgresql/16/main/conf.d/.
listen_addresses = '*'               # the application connects from 10.0.0.0/24
shared_buffers = 1GB                 # a quarter of a 4 GB machine (lesson 6)
work_mem = 16MB
maintenance_work_mem = 256MB
log_min_duration_statement = 500ms   # lesson 19
log_lock_waits = on
```
