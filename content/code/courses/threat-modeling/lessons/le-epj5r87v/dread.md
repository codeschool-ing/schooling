---
title: DREAD, and why Microsoft dropped it
version: 1
---

STRIDE leaves its threats unranked, and the obvious next wish is a score. **DREAD** was Microsoft's
answer in the early 2000s: rate each threat on five factors, average them, and sort.

| factor | the question | 1 | 10 |
|---|---|---|---|
| **D**amage | how bad is it if it happens? | a nuisance | every record, or the whole system |
| **R**eproducibility | does it work every time? | rarely, under odd conditions | every time |
| **E**xploitability | how much skill and effort does it take? | an expert, with time | anybody, with a browser |
| **A**ffected users | how many people does it reach? | one | all of them |
| **D**iscoverability | how easy is it to find? | needs inside knowledge | obvious from outside |

The idea is reasonable, and the method was used widely. It is also the one named method in this
lesson that this course recommends against, and the reason can be shown in one figure.

### Two people, one threat

carla and ana each scored T01, the forged webhook, with the same facts in front of them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l05-dread-raters\" aria-label=\"Two people score the forged webhook, T01, with DREAD from 1 to 10. carla: damage 6, reproducibility 9, exploitability 8, affected users 3, discoverability 7, average 6.6. ana: 4, 8, 5, 2 and 3, average 4.4. The biggest gaps are discoverability, 7 against 3, and exploitability, 8 against 5.\"><text x=\"160.0\" y=\"43.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Damage</text><rect x=\"170.0\" y=\"30.0\" width=\"180.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"36.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6</text><rect x=\"170.0\" y=\"45.0\" width=\"120.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"296.0\" y=\"51.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4</text><text x=\"160.0\" y=\"83.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Reproducibility</text><rect x=\"170.0\" y=\"70.0\" width=\"270.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"446.0\" y=\"76.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">9</text><rect x=\"170.0\" y=\"85.0\" width=\"240.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"91.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">8</text><text x=\"160.0\" y=\"123.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Exploitability</text><rect x=\"170.0\" y=\"110.0\" width=\"240.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"416.0\" y=\"116.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">8</text><rect x=\"170.0\" y=\"125.0\" width=\"150.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"326.0\" y=\"131.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5</text><text x=\"160.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Affected users</text><rect x=\"170.0\" y=\"150.0\" width=\"90.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"156.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><rect x=\"170.0\" y=\"165.0\" width=\"60.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"236.0\" y=\"171.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2</text><text x=\"160.0\" y=\"203.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Discoverability</text><rect x=\"170.0\" y=\"190.0\" width=\"210.0\" height=\"13.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"386.0\" y=\"196.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7</text><rect x=\"170.0\" y=\"205.0\" width=\"90.0\" height=\"13.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"266.0\" y=\"211.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><path d=\"M170.0 24.0 L170.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M230.0 24.0 L230.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M290.0 24.0 L290.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M350.0 24.0 L350.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M410.0 24.0 L410.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><path d=\"M470.0 24.0 L470.0 224.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><rect x=\"500.0\" y=\"60.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"510.0\" y=\"70.0\" width=\"10.0\" height=\"10.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">carla: average 6.6</text><rect x=\"500.0\" y=\"100.0\" width=\"200.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"510.0\" y=\"110.0\" width=\"10.0\" height=\"10.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ana: average 4.4</text><text x=\"600.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">same threat, same facts,</text><text x=\"600.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a gap of 2.2 points</text><text x=\"320.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">score, 0 to 10</text></svg>", "caption": "Discoverability did most of the damage: carla assumed somebody will find the address, ana assumed nobody will."}
```

**Same threat, same facts, a gap of 2.2 points on a ten-point scale.** Neither is wrong. carla
assumed that somebody will find the webhook's address, because addresses leak in logs, browser
histories and the gateway's own error pages; ana assumed nobody outside Vereda knows it. Both are
assumptions, the scale has no way to say which is right, and the average hides that the disagreement
was ever there. Rank fourteen threats this way and the order depends on who held the pen.

That was Microsoft's own conclusion. Its security teams stopped using DREAD in the late 2000s,
and the people who had promoted it wrote publicly about why: the ratings were subjective, they did
not agree between raters, and Discoverability in particular rewarded hiding a weakness rather than
fixing it.

### What to keep from it

Two things in DREAD are sound and survive in better methods:

- **Separate how likely from how bad.** Reproducibility, Exploitability and Discoverability are
  about likelihood; Damage and Affected users are about impact. Lessons 9 and 10 keep exactly that
  split and measure each half properly.
- **Write the factors down.** Even a disputed score shows *why* somebody thought a threat
  mattered. carla's 7 for Discoverability is an argument that can be checked: search the logs for
  the webhook's address. The average of five such arguments is not.

### What not to do with it

Do not average scores from different people, and do not compare a DREAD score with a CVSS score
or a risk in reais. They are different scales measuring different things, and putting them side
by side in a spreadsheet gives an order with nothing behind it.
