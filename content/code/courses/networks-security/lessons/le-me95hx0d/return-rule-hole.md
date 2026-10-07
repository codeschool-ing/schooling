---
title: What a return rule lets in
version: 1
---

The return rule says: from the servers segment to the LAN, **any TCP packet whose source port is
8080** may pass. It was written to let replies through. It cannot tell a reply from anything else
carrying that number.

A source port is chosen by the sender. The web server on `app` uses 8080 because it listens there,
and any program on any server may choose 8080 as well. `laptop` happens to run a service on port
9999, and the rules were never meant to let a server reach it. In the lab a listener stands in for
it; start it on `laptop`, as root, with
`setsid socat TCP-LISTEN:9999,bind=192.168.10.20,fork,reuseaddr SYSTEM:"echo laptop answered" </dev/null >/dev/null 2>&1 &`. From `db`, first with a port the
system picks and then with 8080:

```
ana@db:~$ nc -w2 192.168.10.20 9999 </dev/null; echo "exit $?"
exit 1
ana@db:~$ nc -w2 -p 8080 192.168.10.20 9999 </dev/null; echo "exit $?"
laptop answered
exit 0
```

**The first attempt was dropped, and the second was answered.** `nc -p 8080` only asks the system
to use 8080 as the source port. Nothing was bypassed and no rule was broken. The rule set did exactly
what it says.

The same shape turns up in two familiar return rules:

| return rule | what it also lets in |
|---|---|
| `tcp sport 80 accept` | any connection *from* port 80, to any port inside |
| `udp sport 53 accept` | any datagram claiming to come from a DNS server's port |

A stateless filter can narrow this by also requiring the TCP flags a reply carries, which is the
`established` keyword of a Cisco ACL (lesson 17). That still checks only the flags on the packet in
front of it. **What a firewall needs to know is whether this packet belongs to a conversation it
already allowed**, and that means remembering conversations.
