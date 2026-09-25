---
title: What the missing help costs
version: 1
---

The same small program, a loop that adds up three million squares in Python, timed twice on host and
twice inside vm1:

```
ana@host:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m0.122s
user    0m0.115s
sys     0m0.000s
ana@vm1:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m3.050s
user    0m2.985s
sys     0m0.060s
ana@host:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m0.131s
user    0m0.130s
sys     0m0.000s
ana@vm1:~$ time python3 -c "sum(i * i for i in range(3000000))"

real    0m2.930s
user    0m2.867s
sys     0m0.062s
```

`real` is the time on the clock. On host the loop took 0.122 and 0.131 seconds; inside vm1, 3.050 and 2.930. **The guest
was between 22 and 25 times slower**, on a loop that touches no disk and no network, only the
processor.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The same Python loop, timed twice on each side, as bars. On host it took 0.122 and 0.131 seconds. Inside vm1 it took 3.050 and 2.930 seconds, between 22 and 25 times as long.\"><defs><marker id=\"sp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on host, run 1</text><rect x=\"180\" y=\"20\" width=\"17.6\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"207.6\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.122 s</text><text x=\"20\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inside vm1, run 1</text><rect x=\"180\" y=\"64\" width=\"440.0\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"630.0\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3.050 s</text><text x=\"20\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">on host, run 2</text><rect x=\"180\" y=\"108\" width=\"18.898360655737708\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"208.89836065573772\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.131 s</text><text x=\"20\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inside vm1, run 2</text><rect x=\"180\" y=\"152\" width=\"422.688524590164\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"612.688524590164\" y=\"169\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2.930 s</text></svg>", "caption": "Between 22 and 25 times slower, for a loop that only uses the processor. This is the price of a processor imitated in software, and it is what VT-x or AMD-V saves."}
```

That is the cost of a processor imitated in software, and it is the reason the lab in this course is
patient, waiting for each guest to boot. With VT-x or AMD-V, the guest's instructions run
on the real processor and a loop like this one runs close to the host's speed; what stays slower is
anything that goes through an imitated device, which lesson 8 looks at.

If a virtual machine on somebody's computer is unbearably slow, **find out whether the processor's
help is reaching the hypervisor at all** before anything else. It is the largest difference there is,
and it is usually a setting.
