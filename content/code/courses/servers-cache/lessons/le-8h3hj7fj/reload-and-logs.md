---
title: Logs, reloads and the broken configuration
version: 1
---

Every request leaves a line in an access log, and each of the three servers wrote one for the
benchmark of the previous section:

```
ana@web:~$ tail -n 2 /var/log/nginx/ipelivros.access.log
127.0.0.1 - - [07/Oct/2026:00:11:23 -0300] "GET /css/site.css HTTP/1.0" 200 237 "-" "ApacheBench/2.3"
127.0.0.1 - - [07/Oct/2026:00:11:23 -0300] "GET /css/site.css HTTP/1.0" 200 237 "-" "ApacheBench/2.3"
ana@web:~$ sudo tail -n 1 /var/log/apache2/ipelivros-access.log
127.0.0.1 - - [07/Oct/2026:00:11:24 -0300] "GET /css/site.css HTTP/1.0" 200 506 "-" "ApacheBench/2.3"
ana@web:~$ sudo tail -n 1 /var/log/caddy/ipelivros.access.log | jq -c '{status, uri: .request.uri, size, duration}'
{"status":200,"uri":"/css/site.css","size":237,"duration":0.00247275}
```

The first two are the **combined log format**, older than any of these servers and still the most
common: the client's address, the time, the request line, the status, the size of the response,
the referring page and the client's name for itself. Nginx counted 237 bytes, the file; Apache
counted 506, the file plus its headers. Same request, two meanings of one column, and the kind of
detail that matters the day you add two logs together. Caddy's JSON names every field, and its
`duration` is in seconds: 0.00247, two and a half milliseconds for the last request of a benchmark
that kept fifty in flight at once.

A request that fails leaves a line in the **error log** as well, and the error log says why:

```
ana@web:~$ curl -s -o /dev/null http://ipelivros.example/nothing-here; tail -n 1 /var/log/nginx/ipelivros.error.log
2026/10/07 00:11:24 [error] 285#285: *2035 open() "/var/www/ipe/nothing-here" failed (2: No such file or directory), client: 127.0.0.1, server: ipelivros.example, request: "GET /nothing-here HTTP/1.1", host: "ipelivros.example"
```

## Reload, and what it does not interrupt

Changing a configuration means telling the server to read it again. There are two ways, and the
difference is the most useful thing in this section.

```
ana@web:~$ ps -o pid,cmd --ppid $(cat /run/nginx.pid) -p $(cat /run/nginx.pid)
    PID CMD
    227 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
    283 nginx: worker process
    284 nginx: worker process
    285 nginx: worker process
    287 nginx: worker process
ana@web:~$ sudo systemctl reload nginx; sleep 1; ps -o pid,cmd --ppid $(cat /run/nginx.pid) -p $(cat /run/nginx.pid)
    PID CMD
    227 nginx: master process /usr/sbin/nginx -g daemon on; master_process on;
    609 nginx: worker process
    610 nginx: worker process
    611 nginx: worker process
    612 nginx: worker process
```

**After a reload, the master is the same process and the workers are new.** The master reads the
new configuration, starts workers that use it, and tells the old workers to finish the requests they
are serving and exit. No connection is refused at any moment. A `restart` stops everything and
starts it again, and anything that arrives in between is turned away.

Now break the configuration on purpose, with a typo that a tired person makes:

```
ana@web:~$ sudo sed -i 's/    root /    rooot /' /etc/nginx/sites-available/ipelivros
ana@web:~$ sudo nginx -t
2026/10/07 00:11:25 [emerg] 625#625: unknown directive "rooot" in /etc/nginx/sites-enabled/ipelivros:5
nginx: configuration file /etc/nginx/nginx.conf test failed
ana@web:~$ sudo systemctl reload nginx; echo "exit $?"
Job for nginx.service failed.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
exit 1
ana@web:~$ sudo journalctl -u nginx --no-pager -o cat | tail -n 3
2026/10/07 00:11:25 [emerg] 631#631: unknown directive "rooot" in /etc/nginx/sites-enabled/ipelivros:5
nginx.service: Control process exited, code=exited, status=1/FAILURE
Reload failed for nginx.service - A high performance web server and a reverse proxy server.
```

**The test caught it, the reload refused it, and the site never stopped.** `systemctl reload` asks
Nginx to check the new configuration before it signals anything, the check failed, and the master
kept running on the configuration it already had. The site answered `200` throughout. A restart
with the same broken file does something very different:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/
200
ana@web:~$ sudo systemctl restart nginx; echo "exit $?"
Job for nginx.service failed because the control process exited with error code.
See "systemctl status nginx.service" and "journalctl -xeu nginx.service" for details.
exit 1
```

A restart stops the running server first and then fails to start the new one, and **the site is
down**: `000` is `curl` saying nothing answered at all. That is the whole argument for the habit:
**test, then reload; never restart to apply a configuration change.** Restart is for upgrading the
server's own binary, and even then only after `nginx -t` says the configuration is good.

Fixing the typo and starting it brings the site back:

```
ana@web:~$ curl -s -o /dev/null -w '%{http_code}\n' http://ipelivros.example/
000
ana@web:~$ sudo sed -i 's/    rooot /    root /' /etc/nginx/sites-available/ipelivros && sudo nginx -t && sudo systemctl start nginx
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Apache and Caddy have the same two verbs. `systemctl reload apache2` is a graceful restart, which
lets current requests finish, and `systemctl reload caddy` loads the new Caddyfile without dropping
connections. Both refuse a configuration that does not parse, as long as you reload rather than
restart.
