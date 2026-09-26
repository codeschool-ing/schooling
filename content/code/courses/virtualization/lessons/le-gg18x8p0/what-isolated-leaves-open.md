---
title: What an isolated network leaves open
version: 1
---

The lab is lesson 14's network, `labnet`, with two guests on it, and the office network of lesson 11
standing in for the real one. First, the wall that is already there:

```
ana@host:~$ ip route get 10.0.0.50
10.0.0.50 dev lan0 src 10.0.0.1 uid 1000 
    cache 
ana@client:~$ ip route; ip route get 10.0.0.50
10.20.0.0/24 dev enp1s0 proto kernel scope link src 10.20.0.12 metric 100 
10.20.0.1 dev enp1s0 proto dhcp scope link src 10.20.0.12 metric 100 
RTNETLINK answers: Network is unreachable
ana@client:~$ curl -sS -m 5 http://server/
lab server: ok
```

host reaches the printer through `lan0`. The client has no `default via` line, so for anything off
`10.20.0.0/24` its answer is **`Network is unreachable`**, decided inside the guest before a packet
leaves. And the two guests still reach each other, which is the point of the lab.

Now look at the host from the same guest. Two things on host listen on **every** address, `0.0.0.0`: its
ssh server, and a small web server serving a folder of notes, the kind of thing somebody starts for five
minutes and forgets:

```
ana@host:~$ ss -tln | grep -E ":(22|8000) "
LISTEN 0      4096         0.0.0.0:22        0.0.0.0:*          
LISTEN 0      5            0.0.0.0:8000      0.0.0.0:*          
ana@client:~$ curl -sS -m 5 http://10.20.0.1:8000/todo.txt; nc -zv -w 3 10.20.0.1 22
renew the office printer's toner
Connection to 10.20.0.1 22 port [tcp/ssh] succeeded!
```

Both answered. **An isolated network is isolated from the world, not from the host**, as lesson 11
found with DNS: the host has an address on it, `10.20.0.1`, and anything the host serves on every
address is served there too. For a guest you only practise on, that may be acceptable. For one running
something you do not trust, it is a way into the one machine that holds all the others.
