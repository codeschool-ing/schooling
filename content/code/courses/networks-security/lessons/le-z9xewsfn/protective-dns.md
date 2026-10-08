---
title: Names the company refuses to resolve
version: 1
---

Almost every stage of the pattern starts with a name. The phishing page is at an address somebody has
to look up, and so is the server that software calls home to. **A resolver that refuses to answer for
known-bad names cuts the chain at its cheapest point**, and a resolver that logs who asked for them
tells the defender who clicked.

This is **protective DNS**. The company's name server gets a list of names it will not resolve: here,
two lookalikes of the company's own domain that were reported in phishing messages. Names under
`.test` are reserved and can never belong to anybody real. In your lab this lesson starts from
`sudo bash nslab.sh reset`, with the company's policy loaded on `fw` by `nft -f baseline.nft`. Add the
four lines printed below to the end of `/etc/dnsmasq.d/lab.conf` on `dns`, and restart the name server
there with `kill $(cat /var/log/lab/dnsmasq.pid); sleep 0.5; dnsmasq --conf-dir=/etc/dnsmasq.d --pid-file=/var/log/lab/dnsmasq.pid --user=root`:

```
root@dns:~# grep -A3 "^# names the company" /etc/dnsmasq.d/lab.conf
# names the company refuses to resolve for its staff: reported phishing and
# lookalikes of its own domain
address=/example-support.test/
address=/example.com.login-verify.test/
```

Then two staff machines ask: `laptop` for the shop and one lookalike, `desk` for the other:

```
ana@laptop:~$ dig +short www.example.com; dig www.example-support.test | grep status
192.0.2.80
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 41812
ana@desk:~$ dig example.com.login-verify.test | grep status
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 56159
```

The shop resolves; the lookalikes come back **`NXDOMAIN`**, *no such name*, so the browser has nowhere
to go. The name server's query log says who asked:

```
root@dns:~# grep -E "example-support|login-verify" /var/log/lab/dnsmasq.log | cut -d" " -f5-
using only locally-known addresses for example.com.login-verify.test
using only locally-known addresses for example-support.test
query[A] www.example-support.test from 192.168.10.20
config www.example-support.test is NXDOMAIN
query[A] example.com.login-verify.test from 192.168.10.21
config example.com.login-verify.test is NXDOMAIN
```

`192.168.10.20` asked for `www.example-support.test` and `192.168.10.21` for the other. **That log is
the first list of people to talk to**: they received the message and clicked, and one of them may
have typed a password into the page before the name was blocked.

Two limits, stated plainly. A blocklist only knows names somebody has already reported, and lookalikes
are cheap to register, so it catches the known campaign and misses the new one. Commercial feeds of
newly registered and reported names close part of that gap, and so do NGFW category filters (lesson 2)
that block whole classes of site. And a machine that uses a different resolver ignores the policy
entirely, which is why the matrix of lesson 4 lets the staff reach DNS only at the company's own
server.
