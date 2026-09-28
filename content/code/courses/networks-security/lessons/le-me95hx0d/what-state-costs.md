---
title: What keeping state costs, and where stateless still fits
version: 1
---

Memory is what makes a stateful firewall better, and memory is finite. On `fw`:

```
root@fw:~# sysctl net.netfilter.nf_conntrack_max net.netfilter.nf_conntrack_count
net.netfilter.nf_conntrack_max = 262144
net.netfilter.nf_conntrack_count = 7
root@fw:~# sysctl net.netfilter.nf_conntrack_tcp_timeout_established net.netfilter.nf_conntrack_udp_timeout net.netfilter.nf_conntrack_udp_timeout_stream net.netfilter.nf_conntrack_tcp_loose
net.netfilter.nf_conntrack_tcp_timeout_established = 432000
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120
net.netfilter.nf_conntrack_tcp_loose = 1
```

The table holds up to 262,144 entries and had 7 in use. **An established TCP connection is kept
for 432,000 seconds, five days, after its last packet**, because conntrack cannot know whether a
quiet connection is dead or only resting. A UDP flow is forgotten after 30 seconds, or after 120 once it has
become a stream, with packets going back and forth more than once.

Two consequences follow, and both come back later in the course:

- **The table can be filled.** Every conversation somebody starts costs an entry, even one that
  never completes. Filling it on purpose is one form of denial of service, and lesson 6 measures the
  defences: SYN cookies, rate limits and a smaller timeout for connections that never finished their
  handshake.
- **A restart forgets everything.** So does a failover to a second firewall, unless the two share
  their tables. What happens to a connection met in mid-stream depends on the product. Linux, by default,
  treats its next packet as `new`, which is the `1` in `nf_conntrack_tcp_loose` above, so the
  connection survives wherever a rule would have let it start. A stricter firewall calls it
  `invalid` and drops it. Firewalls built in pairs synchronise their tables so the question never
  comes up.

## Where a stateless filter still belongs

Stateless is not obsolete, it is cheap. It fits where there is too much traffic to remember and the
decision does not need memory:

| place | why stateless |
|---|---|
| a core or border router | millions of flows; only dropping what can never be legitimate, such as a private source address arriving from the internet (lesson 8) |
| in front of a stateful firewall under attack | throwing away a flood before it reaches a table it could fill |
| a switch or router ACL | the hardware matches headers at line rate and keeps no table (lesson 17) |

**The two are layers, not rivals.** A cheap stateless filter at the edge removes what is obviously
wrong; the stateful firewall behind it decides which conversations may exist. Lesson 2 adds a third
layer that reads what is inside the conversation.
