---
title: The limits, and closing the obvious one
version: 1
---

**A DNS control only stops programs that ask your resolver.** Everything in this lesson so far
depends on that. A program that asks somebody else, or never asks at all, walks past it, and an
honest account of the control starts there.

## Asking somebody else

`desk` was pointed at `dns` by one line in `/etc/resolv.conf`. Nothing stops a program from
ignoring that file and putting a question straight to another resolver:

```
ana@desk:~$ dig +short @192.168.60.66 boletos-jatoba.example.net
198.51.100.23
```

The lookalike domain the firm blocked resolves to its real address, because `trap`, playing the
internet, has never heard of Jatobá's list. On a real network the other resolver is `8.8.8.8` or
any of thousands like it, and plenty of programs carry their own.

**This one can be closed, and the place to close it is the network, not the machine.** A rule on the
switch that lets name traffic reach only the firm's resolver, and lets only the resolver ask
outside, makes every other resolver unreachable from inside. In the lab the switch is `sw`, and
nftables can filter what crosses its bridge:

```
root@sw:~# nft -f - <<'EOF'
table bridge dnsguard {
    chain forward {
        type filter hook forward priority filter; policy accept;
        ip daddr 192.168.60.53 udp dport 53 accept
        ip daddr 192.168.60.53 tcp dport 53 accept
        ip saddr 192.168.60.53 ip daddr 192.168.60.66 udp dport 53 accept
        udp dport 53 counter drop
        tcp dport 53 counter drop
    }
}
EOF
ana@desk:~$ dig +tries=1 +time=2 +short @192.168.60.66 boletos-jatoba.example.net; echo "exit $?"
;; communications error to 192.168.60.66#53: timed out
;; no servers could be reached
exit 9
ana@desk:~$ dig +short pagamento.cobranca-urgente.example.org
192.168.60.53
root@sw:~# nft list chain bridge dnsguard forward | grep counter
		udp dport 53 counter packets 1 bytes 95 drop
		tcp dport 53 counter packets 0 bytes 0 drop
```

The rules read in order. Questions to `dns` pass; `dns` itself may ask `trap`, its forwarder; any
other packet to port 53 is counted and dropped. `desk`'s direct question timed out, its ordinary one
still works, and the counter shows the one packet the guard stopped. On a real network the same
rule lives in the firewall at the edge, which is where lesson 10 puts egress rules for a single host.

## The ones that cannot be closed this way

Three remain, and none of them was run for this course:

- **DNS over HTTPS** (DoH) sends questions inside ordinary HTTPS to port 443, mixed with web
  traffic. Browsers can do this on their own: Firefox and Chrome both have a setting for it, and
  both document an **enterprise policy** that turns it off on managed machines. That policy is the
  control, and it belongs to the configuration of lesson 3, not to the resolver.
- **DNS over TLS** (DoT) uses port 853 and can be blocked like port 53.
- **An address written into the program** needs no name at all. Nothing at the resolver sees it.
  Lesson 10's outbound rules, which allow a server to talk only to the addresses its job needs, are
  the control for that.

So the resolver is one layer, cheap and wide: it covers every machine at once and every program that
behaves ordinarily, and it produces the best single log of what the firm's machines tried to reach.
It is not the only layer, and a policy that treats it as one leaves exactly the traffic a careful
attacker would choose.
