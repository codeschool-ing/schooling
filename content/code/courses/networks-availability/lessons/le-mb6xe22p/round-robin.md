---
title: Round robin, and weights for unequal servers
version: 1
---

The simplest rule is to take turns. **Round robin sends each new request to the next server in the
list**, back to the first after the last, and it needs no information at all about the servers:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance roundrobin
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
ana@laptop:~$ for i in $(seq 6); do curl -s http://www.example.com/; done
served by web1
served by web2
served by web3
served by web1
served by web2
served by web3
```

Six requests, two each, in the order the servers are written. Across many clients the effect is the same:
every server gets an equal share of the requests, which is exactly right when the servers are equal and
the requests cost about the same.

Servers are often not equal. A newer machine with twice the cores should get twice the work, and round
robin says nothing about that. **A weight tells it how many turns each server gets per round:**

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance roundrobin
    server web1 192.0.2.21:80 weight 2
    server web2 192.0.2.22:80 weight 1
    server web3 192.0.2.23:80 weight 1
ana@laptop:~$ for i in $(seq 8); do curl -s http://www.example.com/; done | sort | uniq -c
      4 served by web1
      2 served by web2
      2 served by web3
```

Eight requests, and `web1`, with weight 2, served **4 of them**, while `web2` and `web3` served 2 each.
The shares are the weights over their total: 2 of 4 is half the requests, 1 of 4 a quarter. Weights are
also how a server is brought into service gently. A new or freshly patched server can start at a low
weight and be raised once it has shown it copes, which HAProxy allows at run time without a restart.

Round robin's one assumption is in the phrase "about the same". **It counts requests, not work.** A request
that streams a large file and one that returns a line of text are both one turn, and the next section
shows what that costs.
