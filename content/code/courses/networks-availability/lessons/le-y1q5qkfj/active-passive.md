---
title: Active-passive with keepalived and HAProxy
version: 1
---

Each balancer runs two programs. **HAProxy does the balancing**: it accepts a connection on the public
address, picks a web server and passes the request on. **keepalived decides which balancer holds the
public address**, exactly as it decided which router held the gateway in lesson 15. Both balancers carry
identical HAProxy configurations. This is `lb1`'s, as `cat /etc/haproxy/haproxy.cfg` printed it:

```schooling-example
{"language": "conf", "file": "haproxy.cfg", "parts": [{"code": "global\n    log stdout format raw local0\n    stats socket /run/haproxy.sock mode 600 level admin", "note": "HAProxy logs to its standard output, which the lab sent to `/run/haproxy.log`, and opens an administration socket; `show stat` talks to it in the section on health checks."}, {"code": "defaults\n    mode http\n    log global\n    option httplog\n    timeout connect 2s\n    timeout client 10s\n    timeout server 10s", "note": "Every proxy below speaks HTTP and logs each request in HAProxy's HTTP format. The timeouts: two seconds to connect to a server, ten for a client or a server to say something."}, {"code": "frontend www\n    bind 192.0.2.80:80\n    bind 192.0.2.81:80\n    default_backend web", "note": "The public side. It listens on `192.0.2.80`, the address keepalived moves, and on `.81`, which the last section uses. Both balancers carry this same file."}, {"code": "frontend health\n    bind 127.0.0.1:8404\n    monitor-uri /health", "note": "A page HAProxy answers itself, on the loopback only: `/health` returns `200` for as long as the process is alive. keepalived asks for it every second."}, {"code": "backend web\n    balance roundrobin\n    option httpchk GET /\n    server web1 192.0.2.21:80 check inter 1s fall 2 rise 2\n    server web2 192.0.2.22:80 check inter 1s fall 2 rise 2\n    server web3 192.0.2.23:80 check inter 1s fall 2 rise 2", "note": "The three web servers, in turn. Each is checked with `GET /` every second; two failed checks in a row take a server out, two good ones bring it back."}]}
```

One detail makes the passive balancer ready. HAProxy on `lb2` is running and told to listen on
`192.0.2.80`, an address `lb2` does not hold, and Linux normally refuses that. The lab set
`net.ipv4.ip_nonlocal_bind` on both balancers so that it does not, and it is not shown here. **The standby
is already listening when the address arrives**, so a failover is only keepalived's half; nothing has to
start.

keepalived on `lb1` is the lesson 15 configuration with one addition, a script that checks the balancer
rather than a cable:

```
ana@lb1:~$ cat /etc/keepalived/keepalived.conf
global_defs {
    enable_script_security
    script_user root
}
vrrp_script haproxy_alive {
    script "/usr/bin/curl -sf -o /dev/null http://127.0.0.1:8404/health"
    interval 1
    fall 2
    rise 2
}
vrrp_instance www_a {
    state BACKUP
    interface eth0
    virtual_router_id 80
    priority 150
    advert_int 1
    virtual_ipaddress {
        192.0.2.80/24
    }
    track_script {
        haproxy_alive
    }
}
```

`vrrp_script` runs `curl` against HAProxy's `/health` page every second. `fall 2` means two failures in a
row put the instance into `FAULT`, which gives the address up; `rise 2` means two successes bring it
back. `curl -sf` exits with 0 when the page answers and with an error code when it does not, and that exit
code is all keepalived reads. `lb2` has the same file with a priority of 100, written while the lab was
set up and not shown.

## Running

With both started, `lb1` holds the public address and `lb2` holds only its own:

```
ana@lb1:~$ ip -br addr show eth0
eth0@if1314      UP             192.0.2.11/24 192.0.2.80/24 
ana@lb2:~$ ip -br addr show eth0
eth0@if1316      UP             192.0.2.12/24 
ana@laptop:~$ dig +short www.example.com
192.0.2.80
ana@laptop:~$ for i in 1 2 3 4 5 6; do curl -s http://www.example.com/; done
served by web1
served by web2
served by web3
served by web1
served by web2
served by web3
ana@lb1:~$ tail -n 3 /run/haproxy.log
203.0.113.2:41868 [28/Sep/2026:18:11:44.448] www web/web1 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
203.0.113.2:41880 [28/Sep/2026:18:11:44.455] www web/web2 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
203.0.113.2:41882 [28/Sep/2026:18:11:44.461] www web/web3 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
ana@lb2:~$ tail -n 3 /run/haproxy.log
```

The name resolves to `192.0.2.80`, the address that moves, so the laptop never learns which balancer
answered. Six requests went to the three servers in turn, and `lb1`'s log has the last three of them.
Each log line reads left to right as the client, the time the request arrived, the frontend, the backend
and the server chosen, five timers in milliseconds, all 0 here, the status `200` and the 206 bytes sent.
The client is `203.0.113.2`, which is `hq`'s public address: the laptop is behind the head office's NAT.

**`lb2`'s log printed nothing at all.** It is running, with the same checks configured, and it has not
served a single request. That is the passive half of active-passive, and it is the machine that has to
work perfectly on the one day nobody has watched it work.
