---
title: Seeing what the rules decide
version: 1
---

**A rule set nobody reads becomes a rule set nobody understands.** Every firewall grows: an
exception for a vendor, a port for a project that ended, a rule copied from another server. A year
later nobody knows which rules still do anything, and nobody dares delete one. Two habits keep a
host firewall readable, and both are about evidence rather than memory.

## Counters

Every rule in this lesson that matters carries `counter`, and that is deliberate. A counter answers
the first review question, **does this rule ever match?**, without logging a single line. A
`drop` with a climbing counter is a rule doing its job and a question about who keeps trying. A
rule whose counter is zero after months either guards against something that never happens, or no
longer matches what it was written for, and both are worth knowing.

## Tracing one packet

When something is refused and nobody knows which rule did it, nftables can follow a packet through
the rule set. A rule sets a mark, `meta nftrace set 1`, on the packets it matches, and `nft monitor
trace`, run as root in a second shell, prints every rule each marked packet passes and the verdict
it ends with. Insert the marking rule at the top of `web`'s outbound chain, start the monitor in a
second shell on `web`, then try the connection the policy refuses:

```
ana@web:~$ sudo nft insert rule inet web_egress output meta nftrace set 1
ana@web:~$ nc -z -w1 desk 22; echo "exit $?"
exit 1
ana@web:~$ sudo cat /tmp/trace.txt | head -8 | cut -c1-150
trace id 70272c7b inet web_egress output packet: oif "eth0" ip saddr 192.168.60.10 ip daddr 192.168.60.20 ip dscp cs0 ip ecn not-ect ip ttl 64 ip id 5
trace id 70272c7b inet web_egress output rule meta nftrace set 1 (verdict continue)
trace id 70272c7b inet web_egress output rule counter packets 2 bytes 120 comment "web starts nothing else" (verdict continue)
trace id 70272c7b inet web_egress output policy drop 
```

The trace reads top to bottom: the packet as it entered the chain, with the addresses that identify
it, the two rules that matched it and let it continue, and the `policy drop` at the end. Rules it
did not match are not printed. The second trace id is the same connection tried again, which TCP
does when no answer comes. **That is the answer to
"which rule blocked this" without guessing**, and it is how an allow-list is debugged when a
legitimate program turns out to need a destination nobody wrote down.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l10-trace\" aria-label=\"A packet from web to desk port 22 walking down the chain web_egress output, as nft monitor trace prints it. First the marking rule, meta nftrace set 1, verdict continue. Then the rules for loopback, established connections and DNS, which it does not match. Then the counter, verdict continue. At the bottom, the chain policy, drop.\"><defs><marker id=\"l10-trace-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"140.0\" y=\"30.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">meta nftrace set 1</text><text x=\"540.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">marks it: continue</text><rect x=\"140.0\" y=\"67.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">oif &quot;lo&quot; accept</text><text x=\"540.0\" y=\"81.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no match</text><rect x=\"140.0\" y=\"104.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ct state established,related accept</text><text x=\"540.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no match</text><rect x=\"140.0\" y=\"141.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ip daddr 192.168.60.53 udp dport 53 accept</text><text x=\"540.0\" y=\"155.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no match</text><rect x=\"140.0\" y=\"178.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">counter</text><text x=\"540.0\" y=\"192.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">counts it: continue</text><rect x=\"140.0\" y=\"215.0\" width=\"380.0\" height=\"28.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"152.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">policy drop</text><text x=\"540.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the verdict</text><path d=\"M110.0 44.0 L110.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l10-trace-dh-ah-paper-dim)\"></path><text x=\"100.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">web to desk:22</text></svg>", "caption": "The trace names the rule that decided, so nobody has to guess."}
```

Tracing is for a question, not for every day: it prints for every marked packet, and on a busy
server that is a flood. Delete the marking rule when the question is answered.

## Logs

A `log` statement in a rule writes a line for every packet it matches, to the kernel's log. **In
this lab that log belongs to your computer, not to the containers**, for the same reason lesson 8's
audit trail did: a container is not given a piece of the kernel's ring buffer, so a `log` rule on
`web` writes lines that `web` cannot read. On a real server, or in your own virtual machine
outside the containers, `journalctl -k` shows them. A logged drop should be rate-limited, with
`limit rate 10/minute` before `log`, or one noisy client fills the disk.

## The review

Once a quarter, somebody reads the rule set of each server against its job, with the counters
beside it. Every rule needs an owner and a reason, which a `comment` in the rule can carry, as two
of this lesson's do. A rule nobody can explain is removed in monitor mode first, by changing its
verdict to a counter for a few weeks, and deleted when nothing breaks.
