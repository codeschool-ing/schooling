---
title: Persistence, and what it does when a server dies
version: 1
---

Some applications keep a visitor's state in the memory of the server that first served them: the
contents of a basket, the fact that they logged in. Send their next request to another server and that
state is not there. **The best fix is an application that keeps its state somewhere shared**, a database
or a cache every server reads, so any server can answer anybody. Where that has not been done yet, the
balancer has to send each visitor back to the same server every time, and that is **persistence**, also
called sticky sessions.

A layer 7 balancer can do it with a cookie. `cookie SERVERID insert` tells HAProxy to add a cookie of its
own to the first reply, naming the server that answered, and to send every later request carrying that
cookie back to the same server:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance roundrobin
    cookie SERVERID insert indirect nocache
    server web1 192.0.2.21:80 cookie w1
    server web2 192.0.2.22:80 cookie w2
    server web3 192.0.2.23:80 cookie w3
ana@laptop:~$ curl -s -D - -o /dev/null http://www.example.com/ | grep -i set-cookie
set-cookie: SERVERID=w1; path=/
ana@laptop:~$ for i in $(seq 4); do curl -s -b "SERVERID=w3" http://www.example.com/; done
served by web3
served by web3
served by web3
served by web3
ana@laptop:~$ for i in $(seq 3); do curl -s http://www.example.com/; done
served by web2
served by web3
served by web1
```

The first request, with no cookie, was given **`SERVERID=w1`**, because round robin sent it to `web1`.
Four requests carrying `SERVERID=w3` all went to `web3`, and three with no cookie at all were still
spread `web2`, `web3`, `web1`. **The cookie pins the clients that have one and leaves the rest to the
algorithm.** The value is a label the configuration chose, `w1` to `w3`, not the server's address, so it
tells a curious visitor nothing about the network behind the balancer.

## The pinned server dies

Now `web3`'s `nginx` is stopped, `sudo bash netlab.sh kill web3 nginx` on the virtual machine, and the
client pinned to it asks again:

```
ana@laptop:~$ curl -s -b "SERVERID=w3" http://www.example.com/
<html><body><h1>503 Service Unavailable</h1>
No server is available to handle this request.
</body></html>
```

**503 Service Unavailable.** Two servers were running and a third was not, and the balancer still sent
the request to the dead one, because the cookie said `w3` and nothing had told HAProxy that `web3` was
gone. This configuration has no health checks, so it could not know. It sent the request where the cookie
said, the connection failed, and there was nowhere else it was allowed to send it. Persistence without health checks turns one dead server into an
outage for exactly the users who were on it, while everybody else carries on and the dashboards look
fine.

Two lines fix it. Here is the backend as `sed` printed it on `lb1` after the change, with what each line
does; write it in place of the last one and restart HAProxy as before:

```schooling-example
{"language": "conf", "file": "haproxy.cfg", "parts": [{"code": "backend web\n    balance roundrobin", "note": "New visitors are still spread by round robin. Persistence only applies to a request that already carries a cookie."}, {"code": "    option redispatch", "note": "If the server a cookie names is down, send the request to another server instead of failing it. This line is new."}, {"code": "    cookie SERVERID insert indirect nocache", "note": "`insert`: HAProxy adds the cookie to the reply itself, so the application knows nothing about it. `indirect`: a client that already has a valid one is not sent it again, and it is taken out of the request before the server sees it. `nocache`: a reply that sets it is marked so a shared cache will not store it and hand one visitor's cookie to others."}, {"code": "    server web1 192.0.2.21:80 cookie w1 check inter 1s\n    server web2 192.0.2.22:80 cookie w2 check inter 1s\n    server web3 192.0.2.23:80 cookie w3 check inter 1s", "note": "`cookie w1` is the value that means this server. `check inter 1s` is new: HAProxy tests each server every second, so it learns within seconds that one has stopped answering. Lesson 16 showed those checks marking a server DOWN."}]}
```

```
ana@laptop:~$ curl -s -D - -b "SERVERID=w3" http://www.example.com/ | grep -iE "set-cookie|served"
set-cookie: SERVERID=w1; path=/
served by web1
```

The same client, with the same `SERVERID=w3`, was served by **`web1` and given a new cookie, `w1`**, so
its next request goes straight to `web1` without being redispatched again. That is the best a balancer
can do. **Whatever the visitor's session held in
`web3`'s memory died with `web3`.** The basket is empty and the login is gone. Persistence moves a
visitor back to the same server; it cannot move their state off a server that has stopped, and that is
the strongest argument for the shared store in this section's first paragraph.
