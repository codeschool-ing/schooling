---
title: Four ways an answer goes wrong
version: 1
---

`status` in the header is the first thing to read when a name does not work, because each value points
somewhere different.

**NXDOMAIN, the name does not exist.** A typo:

```
ana@laptop:~$ dig ww.example.com | grep -E "status|SOA"
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 38652
example.com.            300     IN      SOA     ns1.example.com. hostmaster.example.com. 2026092502 3600 900 1209600 300
```

The `SOA` line in the answer is the zone saying "I am `example.com`, and I have no `ww`". Its last
number, 300, is how long a resolver may cache the *absence*: create the name a minute later and some
users will still be told it does not exist, for up to five minutes.

**NOERROR with no answer, the name exists without that type.** Often called NODATA:

```
ana@laptop:~$ dig mail.example.com AAAA | grep -E "status|ANSWER:"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 17568
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
```

`mail.example.com` exists and has an `A` record; it has no `AAAA`. Not an error, and a program simply
uses the IPv4 address.

**REFUSED, you asked the wrong server.** `ns1` answers only for its own zones and does not recurse, so
asking it about somebody else's domain gets a refusal:

```
ana@laptop:~$ dig @192.0.2.53 www.example.org | grep -E "status|WARNING"
;; ->>HEADER<<- opcode: QUERY, status: REFUSED, id: 26030
;; WARNING: recursion requested but not available
```

**SERVFAIL, the resolver tried and could not get an answer.** It does not say why, and the why is
usually on somebody else's server. Here `old.example.com` was handed to a server that does not serve
it, a **lame delegation**:

```
ana@laptop:~$ dig old.example.com | grep -E "status|Query time"
;; ->>HEADER<<- opcode: QUERY, status: SERVFAIL, id: 57730
;; Query time: 4 msec
ana@laptop:~$ dig @192.0.2.20 old.example.com +norecurse | grep -E "status|flags|IN"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 1139
;; flags: qr; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 2
; EDNS: version: 0, flags:; udp: 1232
;old.example.com.               IN      A
example.com.            172800  IN      NS      ns1.example.com.
ns1.example.com.        172800  IN      A       192.0.2.53
```

Asked directly, the server `old` was delegated to does not answer the question at all: it points back
up to `example.com`'s servers, which pointed to it. The resolver gave up in 4 milliseconds. A dead
authoritative server gives SERVFAIL too, only slowly; asked directly, it looks like this:

```
ana@laptop:~$ dig @192.0.2.53 www.example.com +tries=1 +time=2
;; communications error to 192.0.2.53#53: connection refused

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> @192.0.2.53 www.example.com +tries=1 +time=2
; (1 server found)
;; global options: +cmd
;; no servers could be reached
```

| status | means | whose problem |
|---|---|---|
| `NXDOMAIN` | no such name | a typo, or a record nobody created |
| `NOERROR`, `ANSWER: 0` | the name has no record of that type | usually nobody's |
| `REFUSED` | this server will not answer that | the wrong server was asked |
| `SERVFAIL` | the resolver could not get an answer | the domain's DNS servers |
