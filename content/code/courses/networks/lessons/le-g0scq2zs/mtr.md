---
title: mtr: loss per hop, and how to read it
version: 1
---

`mtr` runs traceroute over and over and counts, per hop, how many probes got an answer. For this
ticket, "the site is slow at times", the lab was set up with two things wrong at once. The ISP's router
answers only some of the probes that expire on it, as busy routers do, and then `core` was made to drop
one packet in five on the way to `www`:

```
ana@laptop:~$ mtr -rwn -c 20 www.example.com
Start: 2026-09-25T15:58:46-0300
HOST: laptop         Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1    0.0%    20    0.1   0.1   0.1   0.1   0.0
  2.|-- 203.0.113.1    60.0%    20    0.1   0.1   0.1   0.1   0.0
  3.|-- 198.51.100.254  0.0%    20    0.1   0.1   0.1   0.3   0.0
  4.|-- 192.0.2.80      0.0%    20    0.1   0.1   0.1   0.2   0.0
ana@laptop:~$ mtr -rwn -c 20 www.example.com
Start: 2026-09-25T15:59:11-0300
HOST: laptop         Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.10.1    0.0%    20    0.1   0.1   0.1   0.1   0.0
  2.|-- 203.0.113.1    45.0%    20    0.1   0.1   0.1   0.4   0.1
  3.|-- 198.51.100.254  0.0%    20    0.2   0.1   0.1   0.3   0.1
  4.|-- 192.0.2.80     10.0%    20    0.1   0.1   0.1   0.1   0.0
```

The first run has only the ISP's habit: `203.0.113.1` shows `60.0%`, and every hop
after it `0.0%`. **Loss that does not carry on to the end is not loss.** Hop 3 and hop 4 are reached
through hop 2, so if hop 2 were really dropping packets, they would show it too. It was only declining
to answer probes addressed to it.

The second run adds the real fault, and `192.0.2.80` shows `10.0%` while `core`, just
before it, shows `0.0%`. Twenty probes are a small sample, and one in five came
out as 10 in a hundred this time. **Loss that starts at a hop and goes on
to the end is real**, and it happens just before the first hop that shows it: here, between `core` and
`www`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The second mtr run, drawn as loss per hop. Hop 1, 192.168.10.1, 0.0 percent. Hop 2, 203.0.113.1, 45.0 percent, but every hop after it answers, so the router was only declining to answer probes aimed at it. Hop 3, 198.51.100.254, 0.0 percent. Hop 4, 192.0.2.80, 10.0 percent: loss that starts there and reaches the end of the path, which is real.\"><defs><marker id=\"mt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"40\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.10.1</text><rect x=\"170\" y=\"28\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0%</text><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><text x=\"40\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">203.0.113.1</text><rect x=\"170\" y=\"78\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"170\" y=\"78\" width=\"135.0\" height=\"20\" rx=\"3\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"480\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">45.0%</text><text x=\"20\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"40\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">198.51.100.254</text><rect x=\"170\" y=\"128\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"480\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0.0%</text><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><text x=\"40\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.0.2.80</text><rect x=\"170\" y=\"178\" width=\"300\" height=\"20\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"170\" y=\"178\" width=\"30.0\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"480\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">10.0%</text><text x=\"540\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the router did not answer every probe</text><text x=\"540\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing after it is lost</text><text x=\"540\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">real loss</text><text x=\"540\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">it starts here and goes on to the end</text></svg>", "caption": "Loss that stops at one hop is that router being too busy to answer; loss that carries on to the destination is packets really going missing, somewhere just before the first hop that shows it."}
```

That reading is what a provider needs to hear. An mtr report sent with a ticket, `-r` for a report and
`-c` for a count, is worth more than any description of "slow".
