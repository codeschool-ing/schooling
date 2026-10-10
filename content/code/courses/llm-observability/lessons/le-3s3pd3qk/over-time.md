---
title: A cost that fell for the wrong reason
version: 2
---

By day, the week looks like good news:

```
ana@dev:~/obs$ python bill.py --by day
day                requests    input  output  cost US$  per 1k  share  features
Mon 28                   46     9704    1420    0.0308    0.67  21.5%  help/order/summary
Tue 29                   47     9996    1382    0.0311    0.66  21.7%  help/order/summary
Wed 30                   45    10037    1607    0.0247    0.55  17.2%  help/order/summary
Thu 01                   55     8356    1112    0.0192    0.35  13.4%  help/order/summary
Fri 02                   48     6137    1138    0.0160    0.33  11.2%  help/order/summary
Sat 03                   36     4631     662    0.0109    0.30   7.6%  help/order/summary
Sun 04                   34     4379     684    0.0107    0.31   7.4%  help/order/summary
total                   311    53240    8005    0.1434    0.46
```

The cost of a thousand requests fell from 0.67 dollars on Monday to 0.30 on Saturday. Anybody
watching that line would be pleased. Two different things made it fall, and only one of them is good.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Bars of the cost of 1,000 requests on each day of the replayed week: 0.67 and 0.66 dollars on Monday and Tuesday, 0.55 on Wednesday, 0.35 on Thursday, 0.33 on Friday, 0.30 on Saturday and 0.31 on Sunday. A line before Wednesday marks the price cut of 30 September; a line inside Thursday marks the release of 1 October at 10:00.\"><path d=\"M80 210 L692 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M80 170 L86 170\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M80 130 L86 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><path d=\"M80 90 L86 90\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6</text><path d=\"M80 50 L86 50\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"74\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8</text><rect x=\"90\" y=\"76\" width=\"64\" height=\"134\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"122\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.67</text><text x=\"122\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Mon 28</text><rect x=\"176\" y=\"78\" width=\"64\" height=\"132\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"208\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.66</text><text x=\"208\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Tue 29</text><rect x=\"262\" y=\"100\" width=\"64\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"294\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.55</text><text x=\"294\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Wed 30</text><rect x=\"348\" y=\"140\" width=\"64\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"380\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.35</text><text x=\"380\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Thu 01</text><rect x=\"434\" y=\"144\" width=\"64\" height=\"66\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"466\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.33</text><text x=\"466\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Fri 02</text><rect x=\"520\" y=\"150\" width=\"64\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"552\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.30</text><text x=\"552\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat 03</text><rect x=\"606\" y=\"148\" width=\"64\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"638\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.31</text><text x=\"638\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sun 04</text><path d=\"M251 30 L251 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"247\" y=\"24\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">price cut</text><path d=\"M374.7 30 L374.7 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"378.7\" y=\"24\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">release 2026.10.1</text><text x=\"380\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">US$ per 1,000 requests</text></svg>", "caption": "The cost per request fell by half in a week. Some of it is the price list; most of it is the assistant answering less."}
```

**Wednesday is the price list.** The price of `llama3.2:3b` fell by 25% on 30 September, and the
cost per thousand went from 0.66 to 0.55, a fall of 17%. Nothing about the assistant changed. The
fall is smaller than the price's because Wednesday's requests happened to be a little longer, 36
output tokens each against Tuesday's 29: the day-to-day noise of a week with forty-odd requests a day.

**Thursday and after are the release.** On Thursday at 10:00 the floor went up, and from then on
fewer chunks cleared it. The cost per thousand fell to 0.35, and stayed there. The same week split by
release:

```
ana@dev:~/obs$ python bill.py --by release
release            requests    input  output  cost US$  per 1k  share  features
2026.09.4               150    31790    4645    0.0910    0.61  63.5%  help/order/summary
2026.10.1               161    21450    3360    0.0524    0.33  36.5%  help/order/summary
total                   311    53240    8005    0.1434    0.46
```

Under `2026.10.1`, a request carried 133 input tokens on average (21,450 over 161); under `2026.09.4`,
212. The prompts got shorter because they carry fewer sources, and more requests were refused before
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
