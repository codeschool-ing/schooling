---
title: mtr, and the loss that is not real
version: 1
---

mtr is traceroute that keeps going. It sends probes to every hop, round after round, and keeps a table
of what came back: `-r` prints the table as a report at the end, `-c` says how many rounds, and `-i`
sets the gap between them. Two runs from the laptop. For the first, the random drop towards web2 from
the ping section was still in place; before the second it was removed:

```
ana@laptop:~$ sudo mtr -n -r -c 20 192.0.2.22
Start: 2026-09-28T18:17:16-0300
HOST: laptop                      Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1               0.0%    20    0.1   0.1   0.1   0.1   0.0
  2.|-- 203.0.113.1                0.0%    20    0.1   0.1   0.0   0.3   0.1
  3.|-- 192.0.2.22                10.0%    20    0.1   0.1   0.1   0.1   0.0
ana@laptop:~$ sudo mtr -n -r -c 50 -i 0.1 192.0.2.21
Start: 2026-09-28T18:17:40-0300
HOST: laptop                      Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1              80.0%    50    0.0   0.0   0.0   0.1   0.0
  2.|-- 203.0.113.1               80.0%    50    0.0   0.1   0.0   0.3   0.1
  3.|-- 192.0.2.21                 0.0%    50    0.1   0.0   0.0   0.1   0.0
ana@hq:~$ sysctl net.ipv4.icmp_ratelimit net.ipv4.icmp_ratemask
net.ipv4.icmp_ratelimit = 1000
net.ipv4.icmp_ratemask = 6168
```

**The first report shows real loss.** web2, the destination, lost 10.0%, 2 of 20 probes, to a rule that
drops 20% at random: the sampling of the ping section at work again. Hops 1 and 2 lost nothing, because
the probes that expire there never reach the rule, which acts on what the ISP forwards. **Loss that
appears at a hop and stays on every hop after it, down to the destination, is real**, and it starts at or
after the first hop that shows it.

**The second report shows loss that is not real.** `hq` and the ISP router each lost 80.0% of 50
probes, and the destination lost none. If `hq` were really dropping four packets in five, nothing beyond
it could do better than one in five, and web2 got every one. What the two routers lost is their own
answers, and the `sysctl` on `hq` says why:

- `icmp_ratelimit = 1000` is a gap in milliseconds: after a small burst, the kernel sends a given
  destination at most one ICMP error a second.
- `icmp_ratemask = 6168` is the set of ICMP types the limit applies to, one bit per type. 6168 is 4096 +
  2048 + 16 + 8, bits 12, 11, 4 and 3, and **bit 11 is "time exceeded"**, the answer every intermediate
  hop sends. The echo reply the destination sends is type 0, and it is not limited.

The first run sent one probe a second, and the limit never bit. The second sent ten a second for about
five seconds, and each router answered ten: the burst, then one a second.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 780 216\" role=\"img\" aria-label=\"Two mtr reports drawn as loss bars per hop. Left, with the random drop towards web2 and one probe a second: hop 1 192.168.10.1 0.0%, hop 2 203.0.113.1 0.0%, hop 3 192.0.2.22 10.0%; the destination loses, so the loss is real. Right, with the drop removed and ten probes a second: hop 1 80.0%, hop 2 80.0%, hop 3 192.0.2.21 0.0%; the destination loses nothing, so the hops only held back their own answers.\"><rect x=\"20\" y=\"10\" width=\"360\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"34\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">drop towards web2, one probe a second</text><text x=\"34\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mtr -c 20 192.0.2.22</text><text x=\"34\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.</text><text x=\"50\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.168.10.1</text><rect x=\"148\" y=\"70\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"326\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0%</text><text x=\"34\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.</text><text x=\"50\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.1</text><rect x=\"148\" y=\"100\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"326\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0%</text><text x=\"34\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.</text><text x=\"50\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.0.2.22</text><rect x=\"148\" y=\"130\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><rect x=\"148\" y=\"130\" width=\"17.0\" height=\"18\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"326\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10.0%</text><text x=\"34\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">loss per hop, 0 to 100%</text><text x=\"34\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the destination loses: the loss is real</text><rect x=\"400\" y=\"10\" width=\"360\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"414\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">drop removed, ten probes a second</text><text x=\"414\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mtr -c 50 -i 0.1 192.0.2.21</text><text x=\"414\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.</text><text x=\"430\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.168.10.1</text><rect x=\"528\" y=\"70\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><rect x=\"528\" y=\"70\" width=\"136.0\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 2\"></rect><text x=\"706\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">80.0%</text><text x=\"414\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2.</text><text x=\"430\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">203.0.113.1</text><rect x=\"528\" y=\"100\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><rect x=\"528\" y=\"100\" width=\"136.0\" height=\"18\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"3 2\"></rect><text x=\"706\" y=\"109\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">80.0%</text><text x=\"414\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3.</text><text x=\"430\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">192.0.2.21</text><rect x=\"528\" y=\"130\" width=\"170\" height=\"18\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.4\"></rect><text x=\"706\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0.0%</text><text x=\"414\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">loss per hop, 0 to 100%</text><text x=\"414\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the destination loses nothing: the hops only held back their answers</text></svg>", "caption": "The two reports above, drawn to scale. Read the bottom row first: loss that reaches the destination is real, and loss that stops before it is a router declining to answer."}
```

Reading an mtr report comes down to one rule: **look at the last line
first.** If the destination loses nothing, loss on the hops above it is those routers declining to
answer, however large the percentage. If the destination loses, walk up the table to the first hop where
the loss begins and stays; that link, or the one after it, is where to look. A trace that ends in a
firewall which drops the probes altogether needs `-T` or `-u`, the same choice traceroute offered.
