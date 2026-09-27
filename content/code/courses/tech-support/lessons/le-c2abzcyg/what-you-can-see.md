---
title: What level 1 can see
version: 1
---

On `srv1`, with read access, the technician follows the request one step back at a time:

```
ana@srv1:~$ sudo tail -n 1 /var/log/nginx/error.log
2026/09/26 01:09:46 [error] 1082#1082: *1 connect() failed (111: Connection refused) while connecting to upstream, client: 10.30.0.96, server: , request: "GET /sales/ HTTP/1.1", upstream: "http://127.0.0.1:9000/", host: "srv1"
ana@srv1:~$ ss -tln | grep -c ":9000 "; systemctl is-active sales-api
0
failed
ana@srv1:~$ sudo journalctl -u sales-api --no-pager -o cat | grep -m1 -E "PermissionError"
PermissionError: [Errno 13] Permission denied: '/etc/sales/api.conf'
ana@srv1:~$ ls -l /etc/sales/api.conf; systemctl show -p User sales-api
-rw------- 1 root root 9 Sep 26 01:09 /etc/sales/api.conf
User=sales
```

- nginx's error log: it tried to pass the request to `127.0.0.1:9000` and was **refused**: nothing is
  listening there.
- `ss` confirms **0** listeners on port 9000, and the service that should be there, `sales-api`, is
  **failed**.
- Its journal says why: `PermissionError`, **it cannot read its own configuration file**,
  `/etc/sales/api.conf`.
- And the file explains the error: it belongs to `root` with mode `600`, readable by root alone, while
  the service runs as the user `sales`.

That is a cause, found in four commands, by someone who does not own the system. The next section is
about what to do with it.
