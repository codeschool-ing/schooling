---
title: A cost that fell for the wrong reason
version: 1
---

By day, the week looks like good news:

```
ana@lab:~/obs$ python bill.py --by day
day                requests    input  output  cost US$  per 1k  share  features
Mon 28                  200    46627    7594    0.1541    0.77  18.7%  help/order/summary
Tue 29                  210    48889    8259    0.1639    0.78  19.9%  help/order/summary
Wed 30                  207    51814    7772    0.1658    0.80  20.2%  help/order/summary
Thu 01                  208    51089    7742    0.1231    0.59  15.0%  help/order/summary
Fri 02                  224    39663    7039    0.1018    0.45  12.4%  help/order/summary
Sat 03                  153    21175    4117    0.0565    0.37   6.9%  help/order/summary
Sun 04                  143    21815    4140    0.0576    0.40   7.0%  help/order/summary
total                  1345   281072   46663    0.8228    0.61
```

The cost of a thousand requests fell from 0.80 dollars on Wednesday to 0.37 on Saturday. Anybody
watching that line would be pleased. Two different things made it fall, and only one of them is good.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Bars of the cost of 1,000 requests on each day of the replayed week: 0.77, 0.78 and 0.80 dollars from Monday to Wednesday, 0.59 on Thursday, 0.45 on Friday, 0.37 on Saturday and 0.40 on Sunday. A line before Thursday marks the price cut of 1 October; a line inside Friday marks the release of 2 October at 10:00.\"><path d=\"M80 210 L692 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 170 L86 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M80 130 L86 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M80 90 L86 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M80 50 L86 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8</text><rect x=\"90\" y=\"56\" width=\"64\" height=\"154\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.77</text><text x=\"122\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Mon 28</text><rect x=\"176\" y=\"54\" width=\"64\" height=\"156\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.78</text><text x=\"208\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Tue 29</text><rect x=\"262\" y=\"50\" width=\"64\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"294\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.80</text><text x=\"294\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Wed 30</text><rect x=\"348\" y=\"92\" width=\"64\" height=\"118\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.59</text><text x=\"380\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Thu 01</text><rect x=\"434\" y=\"120\" width=\"64\" height=\"90\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"466\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.45</text><text x=\"466\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Fri 02</text><rect x=\"520\" y=\"136\" width=\"64\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"552\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.37</text><text x=\"552\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat 03</text><rect x=\"606\" y=\"130\" width=\"64\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"638\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.40</text><text x=\"638\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M337 30 L337 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"333\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">price cut</text><path d=\"M460.667 30 L460.667 98\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"464.667\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">release 2026.10.1</text><text x=\"380\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">US$ per 1,000 requests</text></svg>", "caption": "The cost per request fell by half in a week. Some of it is the price list; most of it is the assistant answering less."}
```

**Thursday is the price list.** extract-1's price fell by 25% on 1 October, and the cost per thousand
went from 0.80 to 0.59, a fall of 26%. Nothing about the assistant changed; the tokens per request
were the same as on Wednesday, within the day-to-day noise.

**Friday and the weekend are the release.** On Friday at 10:00 the floor went up, and from then on
fewer chunks cleared it. The same week split by release:

```
ana@lab:~/obs$ python bill.py --by release
release            requests    input  output  cost US$  per 1k  share  features
2026.09.4               879   212233   33434    0.6401    0.73  77.8%  help/order/summary
2026.10.1               466    68839   13229    0.1827    0.39  22.2%  help/order/summary
total                  1345   281072   46663    0.8228    0.61
```

Under `2026.10.1`, a request carried 148 input tokens on average (68,839 over 466); under `2026.09.4`,
241. The prompts got shorter because they carry fewer sources, and more requests were refused before
any prompt was built. **The assistant got cheaper because it answers less**, and lesson 5 finds out
whether the customers noticed.

## Separating price from usage

Two numbers, kept apart, are what makes that readable:

- **tokens per request**, which only changes when the system does: the prompt, the retrieval, the
  model's habits, the mix of features;
- **price per token**, which only changes when the price list does.

Cost per request is their product, and a change in it is always one, the other, or both. The cost
column shows both at once and cannot say which; the token columns beside it, which no price list can
move, can. **Record tokens on the span and work out money at reading
time**, as `costs.py` does, and the two stay separable for as long as the spans exist.
