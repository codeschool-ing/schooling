---
title: The handover
version: 1
---

The owners should be able to start where you stopped, without asking you anything. So the evidence goes
with the ticket, not only a description of it:

```
ana@srv1:~$ mkdir -p ~/esc && sudo tail -n 20 /var/log/nginx/error.log > ~/esc/nginx-error.log && sudo journalctl -u sales-api --no-pager > ~/esc/sales-api.journal && systemctl status sales-api --no-pager > ~/esc/sales-api.status; tar czf sales-502.tar.gz -C ~ esc && tar tzf sales-502.tar.gz && ls -l sales-502.tar.gz
esc/
esc/nginx-error.log
esc/sales-api.status
esc/sales-api.journal
-rw-rw-r-- 1 ana ana 1011 Sep 26 01:09 sales-502.tar.gz
```

**1011 bytes**, three files: nginx's recent errors, the service's journal and its status. And a message
that reads on its own:

```localised
To:        the sales system's team
Impact:    /sales/ answers 502 for everyone in sales, since 01:09
Evidence:  nginx on srv1: connect() failed (111: Connection refused) to 127.0.0.1:9000
           nothing listens on 9000; sales-api is failed
           journal: PermissionError: [Errno 13] Permission denied: '/etc/sales/api.conf'
           api.conf is root:root, mode 600; the service runs as sales
Not done:  api.conf's permissions were not changed: the file is yours, and I don't
           know why it is 600
Attached:  sales-502.tar.gz (nginx errors, the service's journal and status)
Users:     told the system is down and your team is on it; next update from me in an hour
```

Every line saves the receiver a question. **"Not done"** is the line most often missing, and it may be
the most valuable: it tells them what state they will find, and that nothing was changed behind their
back.
