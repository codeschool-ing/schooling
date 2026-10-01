---
title: Related, invalid, and reading the counters
version: 1
---

Two states are easy to write and easy to misunderstand.

**`related` is what lets an error come back.** When a packet cannot be delivered, the router or host
that failed answers with an ICMP message, and that message is not part of the conversation's own
flow: it has its own protocol and its own addresses. Conntrack recognises it as belonging to a known
entry and marks it `related`.

This rule set splits the two states onto separate rules, so each has its own counter, and lets the
LAN ask two things of UDP port 53: the real name server in the DMZ, and `app`, which runs no DNS at
all:

```
root@fw:~# nft -f related.nft
ana@laptop:~$ dig +short @192.0.2.53 www.example.com
192.0.2.80
```

The answer came back as `established`, and the table shows the UDP entry it matched: `29` seconds
left, because UDP has no handshake and conntrack simply forgets a quiet flow. Now the question to
`app`:

```
root@fw:~# conntrack -L -p udp 2>/dev/null
udp      17 29 src=192.168.10.20 dst=192.0.2.53 sport=44628 dport=53 src=192.0.2.53 dst=192.168.10.20 sport=53 dport=44628 mark=0 use=1
ana@laptop:~$ dig +tries=1 @192.168.20.10 www.example.com
;; communications error to 192.168.20.10#53: connection refused

; <<>> DiG 9.18.39-0ubuntu0.24.04.7-Ubuntu <<>> +tries=1 @192.168.20.10 www.example.com
; (1 server found)
;; global options: +cmd
;; no servers could be reached
```

`app` answered the question with an ICMP *port unreachable*, and the `related` rule let it through.
**`dig` reported the refusal at once instead of waiting out its timeout.**
Drop `related` and every such error vanishes on the firewall, so programs wait and retry where they
could have failed straight away. Worse, the ICMP message that tells a sender its packets are too
big is `related` too, and losing it breaks connections in ways that look like anything but a
firewall.

**`invalid` is dropped on purpose.** A packet that belongs to no conversation and cannot start one,
such as a TCP acknowledgement for a connection the table never saw, has no legitimate business here.

## Counters say what the rules actually did

A rule with `counter` counts the packets and bytes it matched. After three requests from `laptop`
and one attempt from `remote` at the database:

```
root@fw:~# nft -f stateful.nft
ana@laptop:~$ for i in 1 2 3; do curl -s -m2 -o /dev/null http://192.168.20.10:8080/health; done
ana@remote:~$ nc -w2 192.168.20.30 5432 </dev/null; echo "exit $?"
exit 1
root@fw:~# nft list chain ip filter forward
table ip filter {
	chain forward {
		type filter hook forward priority filter; policy drop;
		ct state established,related counter packets 34 bytes 2689 accept
		ct state invalid counter packets 0 bytes 0 drop
		iifname "eth2" oifname "eth3" ip daddr 192.168.20.10 tcp dport 8080 ct state new counter packets 3 bytes 180 accept
		counter packets 2 bytes 120 comment "everything else, about to be dropped"
	}
}
```

Read it bottom up. The last line has no verdict of its own, so it only counts what fell past every
rule: `remote`'s two packets, the first try and one retransmission, just before the policy dropped
them. The `new` rule matched **three packets**, one per request, because a conversation starts once.
Everything else, 34 packets in all, was `established` traffic.

**That ratio is normal.** On a busy firewall, nearly all packets hit the
first rule, which is why it is the first rule. Lesson 18 comes back to what the order of rules
costs.
