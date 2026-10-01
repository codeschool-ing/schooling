---
title: Cutting a machine off, in seconds
version: 1
---

When a machine is suspected, the first decision is not what happened. It is **how to stop it touching
anything else while that is found out**. Pulling the cable works when somebody is standing next to it.
A rule at the firewall works from wherever the defender is, and it is a line that can be written in
advance, so that in the moment it only needs an address.

The quarantine for `desk`, as a one-line file, with the ticket number in the comment:

```
root@fw:~# cat quarantine.nft; nft -f quarantine.nft
insert rule ip filter forward ip saddr 192.168.10.21 counter drop comment "quarantine: desk, ticket 4711"
```

`insert` puts it first in the chain, ahead of every `accept`, so nothing the machine sends crosses
`fw`. Then `desk` tries its usual things:

```
ana@desk:~$ curl -s -m3 https://www.example.com/; echo "exit $?"
exit 28
ana@desk:~$ dig +short +time=1 +tries=1 www.example.com
;; communications error to 192.0.2.53#53: timed out
;; no servers could be reached
```

The shop times out, and so does the name server, which sits in the DMZ and is reached through `fw`.
Meanwhile its neighbour is unaffected:

```
ana@laptop:~$ curl -s https://www.example.com/
orders service: ok
```

The counter records what `desk` tried after it was cut off, which is itself evidence:

```
root@fw:~# nft list chain ip filter forward | grep quarantine
		ip saddr 192.168.10.21 counter packets 4 bytes 264 drop comment "quarantine: desk, ticket 4711"
```

Four packets in the few seconds the capture lasted. On a machine running ransomware, that counter
climbing steadily, with destinations that are not the company's, is the software trying to reach
whoever controls it.

Three things the quarantine does **not** do, and which have to be done by other means:

- it does not stop `desk` reaching machines on its own segment, which is why the host firewall of the
  previous section matters, and why switches can also shut a port;
- it does not preserve what is in `desk`'s memory, which is lost if somebody switches it off in a
  panic; isolating instead of powering down keeps the evidence;
- it does not tell anybody: the ticket number in the comment is there so the rule is removed when the
  ticket closes, rather than found in a year by somebody wondering what `desk` was.
