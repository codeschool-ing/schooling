---
title: Active-active, and the rule that keeps it honest
version: 1
---

Active-active needs nothing new, only a second VRRP instance. keepalived on both balancers is
reconfigured with two: `www_a` for `192.0.2.80`, where `lb1` has priority 150 and `lb2` 100, and `www_b`
for `192.0.2.81`, VRID 81, with the priorities the other way round. Both track the same `haproxy_alive`
script. The HAProxy file does not change, since it was already listening on both addresses.

Stop keepalived on both balancers first, on the virtual machine: `sudo bash netlab.sh kill lb1 keepalived`
and `sudo bash netlab.sh kill lb2 keepalived`; each gives up its address as it goes. Then add this at the
end of each balancer's `keepalived.conf`, `lb1`'s as it is here, and on `lb2` with the two priorities
swapped:

```schooling-example
{"language": "conf", "file": "keepalived.conf", "parts": [{"code": "vrrp_instance www_b {\n    state BACKUP\n    interface eth0\n    virtual_router_id 81\n    priority 100\n    advert_int 1", "note": "A second instance, with its own VRID, 81. On `lb1` it gets the lower priority, 100; on `lb2` the two are swapped, `www_a` at 100 and `www_b` at 150."}, {"code": "    virtual_ipaddress {\n        192.0.2.81/24\n    }", "note": "The second public address, which HAProxy already listens on."}, {"code": "    track_script {\n        haproxy_alive\n    }\n}", "note": "The same check as `www_a`: if HAProxy dies, this balancer gives up both of its addresses."}]}
```

Start keepalived on both with the command of the first section, and a few seconds later:

```
ana@lb1:~$ ip -br addr show eth0
eth0@if1314      UP             192.0.2.11/24 192.0.2.80/24 
ana@lb2:~$ ip -br addr show eth0
eth0@if1316      UP             192.0.2.12/24 192.0.2.81/24 
ana@laptop:~$ curl -s http://192.0.2.80/; curl -s http://192.0.2.81/
served by web1
served by web3
ana@lb1:~$ tail -n 1 /run/haproxy.log
203.0.113.2:57106 [28/Sep/2026:18:12:09.815] www web/web1 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
ana@lb2:~$ tail -n 1 /run/haproxy.log
203.0.113.2:49940 [28/Sep/2026:18:12:09.822] www web/web3 0/0/0/0/0 200 206 - - ---- 1/1/0/0/0 0/0 "GET / HTTP/1.1"
```

**Each balancer holds one public address and serves it.** A request to `.80` went through `lb1` and one
to `.81` through `lb2`, and each log has its own. Each balancer also keeps its own round robin, which is
why the two answers came from `web1` and `web3`: each balancer was at its own place in its own rotation.
Clients would normally be spread over the two addresses by DNS: the name returning both, in a different
order to different askers. The network's DNS returns only `192.0.2.80` for `www.example.com`, as `dig`
showed in the active-passive section, so here the two addresses were asked for by hand.

Then HAProxy on `lb2` was killed, `sudo bash netlab.sh kill lb2 haproxy KILL`, and five seconds later:

```
ana@lb1:~$ ip -br addr show eth0
eth0@if1314      UP             192.0.2.11/24 192.0.2.80/24 192.0.2.81/24 
```

`lb1` holds both addresses and carries all of the traffic, which is the moment active-active was built
for, and the moment it can fail.

## Each one has to carry everything

On a normal day each balancer carries half. On the day one fails, the survivor carries all of it, and
**the survivor has to have been sized for that day, not for the normal one**. When it was not, it
slows, its own health check starts timing out, and it gives up its addresses too: a total outage, caused
by the redundancy, on a pair whose dashboards looked healthy every day before it.

The rule is called **N+1**: with N machines needed for the load, have N+1, so the loss of any one leaves
enough. For an active-active group it sets a ceiling on how busy each member may be on a normal day:

| members | the load each may carry normally | what one loss leaves for the rest |
|---|---|---|
| 2 | 50% | 100% on one |
| 3 | 67% | 100% on each of two |
| 4 | 75% | 100% on each of three |

The more members, the less capacity sits idle in reserve, which is why large sites spread their load over
many balancers rather than two big ones. **A group of two runs each member at half, which is exactly the capacity active-passive has.**

## Sessions and state

Moving an address moves where new connections go. Everything that lived in the old machine's memory is
gone: the TCP connections open through it, and whatever it held about each user. For a balancer that is
mostly connections, and clients reconnect. For the web servers behind it, it can be a user's whole
session, a shopping basket or a login, kept in one server's memory. When that server dies, or the
balancer's persistence moves the user elsewhere (lesson 19), the session is simply not there.

The fixes are all the same idea: **keep the state somewhere that survives the machine**. Sessions go into
a shared store, a database or a cache that is itself replicated, so any server can serve any user. Or the
state travels with the user, in a signed cookie or token the server can check without remembering
anything. Balancers can go further and copy their own tables to each other. HAProxy synchronises its
stickiness tables between peers, and Linux's conntrackd can copy a firewall's connection table so that
connections survive a failover; neither was used here. **A stateless machine is easy to replace, and
making machines stateless is most of what a cluster design is.** What cannot be made stateless, the
database itself, is where lesson 14's split brain and lesson 17's replication come in.
