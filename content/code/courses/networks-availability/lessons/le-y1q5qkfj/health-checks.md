---
title: Health checks, one level down
version: 1
---

The balancer pair protects the site from a dead balancer. The balancer protects it from a dead web
server, and it does so the same way, with a check that runs whether or not anything is wrong. Each
`server` line in the configuration ends `check inter 1s fall 2 rise 2`, and `option httpchk GET /` makes
the check a real HTTP request for the home page rather than a test that the port is open.

With HAProxy on `lb1` started again, which is not shown, nginx on `web2` was stopped. Each balancer checks the servers itself; this is
`lb2`'s view:

```
ana@lb2:~$ grep -E "web2" /run/haproxy.log | tail -n 2
[WARNING]  (1711) : Server web/web2 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 2 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
Server web/web2 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 2 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
ana@lb2:~$ echo "show stat" | sudo socat stdio /run/haproxy.sock | cut -d, -f1,2,18 | grep -E "^web,"
web,web1,UP
web,web2,DOWN
web,web3,UP
web,BACKEND,UP
ana@laptop:~$ for i in 1 2 3 4 5 6; do curl -s http://www.example.com/; done
served by web1
served by web3
served by web1
served by web3
served by web1
served by web3
ana@lb2:~$ grep -E "web2" /run/haproxy.log | tail -n 1
Server web/web2 is UP, reason: Layer7 check passed, code: 200, check duration: 0ms. 3 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
```

HAProxy's log says what it saw and how it judged it: **`Layer4 connection problem`, `Connection
refused`**, meaning that the check did not even get as far as HTTP, since nothing was listening on
`web2`'s port 80 any more. The line appears twice, once as HAProxy's own warning and once as the log
message, and it ends by counting what is left: `2 active and 0 backup servers left`.

`show stat` on the administration socket prints a line of comma-separated fields per server, and the
`cut` keeps three of them: the backend, the server and its status. **`web2` is `DOWN` and the backend as a
whole is still `UP`**, because two of its three servers are. The six requests that followed went to
`web1` and `web3` in turn, and none of them failed or even noticed. When nginx was started again, two
successful checks brought `web2` back, and this time the reason is `Layer7 check passed, code: 200`: the
home page itself answered.

## Two checks, two layers

There are now two health checks in the design, and they answer different questions:

| check | who runs it | what it asks | what happens when it fails |
|---|---|---|---|
| `haproxy_alive` | keepalived, on each balancer | is my own HAProxy answering? | this balancer gives up the public address |
| `httpchk GET /` | HAProxy, on each balancer | is this web server serving pages? | the server leaves the rotation |

The first check deliberately asks very little. `/health` is answered by HAProxy itself, so it passes
while HAProxy runs, **even if all three web servers are down**. That is the right choice here: if all
the web servers were dead, moving the address to the other balancer would reach the same dead servers
through a different door and gain nothing. A check should ask the question whose answer the failover
can actually fix.

The second check is only as good as the page it requests. `GET /` proved that nginx on `web2` answered
with `200`. It would pass just as happily for a server whose database connection had died, if the home
page does not touch the database. **A check that asks for a page which exercises the real dependencies**,
often a dedicated `/health` path on the application that queries its database and reports what it
found, is the difference between knowing that the process is running and knowing that the service works.
