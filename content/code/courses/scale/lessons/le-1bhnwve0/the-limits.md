---
title: The limit of each, in one formula
version: 1
---

The last four sections measured three results: more processors helped until the machine ran out,
more copies helped in proportion, and neither helped a sale that waited for one row. **One formula
explains all three**, and it is worth knowing because it predicts the result before the
measurement.

## Amdahl's law

Split the work of one request into two parts: the part that can run in parallel, a fraction *p* of
the time, and the part that cannot, the remaining 1 − *p*. With *n* processors, or copies, the
parallel part takes *p*/*n* of the time it took and the serial part takes as long as ever. The
speed-up is:

```
speed-up(n) = 1 / ((1 - p) + p / n)
```

That is **Amdahl's law**, from 1967, and its consequence is harsh. With *n* growing without limit,
*p*/*n* goes to zero and the speed-up approaches 1 / (1 − *p*). **The serial part sets a ceiling
that no amount of hardware passes.** A request that is 95% parallel can never go more than 20 times
faster, on a thousand processors or a million; at 75% the ceiling is 4.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Speed-up against the number of processors or copies, from 1 to 64, for three parallel fractions. At 99% parallel the curve keeps rising and reaches about 39 at 64. At 95% it bends and approaches its ceiling of 20, reaching about 15 at 64. At 75% it flattens almost at once and approaches 4. A dashed diagonal shows perfect scaling, where 64 copies would be 64 times faster.\"><path d=\"M80 30 L80 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M80 250 L550 250\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><path d=\"M80 195.0 L550 195.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M80 140.0 L550 140.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M80 85.0 L550 85.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M80 30.0 L550 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.5\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"80.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"191.9047619047619\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"311.26984126984127\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32</text><text x=\"430.63492063492066\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">48</text><text x=\"550.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">64</text><text x=\"315.0\" y=\"282\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">processors or copies, n</text><text x=\"30\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">speed-up</text><path d=\"M80 244.5 L370.95238095238096 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"374.95238095238096\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perfect</text><path d=\"M80.0 244.5 L87.5 239.1 L94.9 233.8 L102.4 228.6 L109.8 223.6 L117.3 218.6 L124.8 213.7 L132.2 208.9 L139.7 204.2 L147.1 199.5 L154.6 195.0 L162.1 190.5 L169.5 186.2 L177.0 181.9 L184.4 177.6 L191.9 173.5 L199.4 169.4 L206.8 165.4 L214.3 161.4 L221.7 157.6 L229.2 153.8 L236.7 150.0 L244.1 146.3 L251.6 142.7 L259.0 139.1 L266.5 135.6 L274.0 132.1 L281.4 128.7 L288.9 125.4 L296.3 122.1 L303.8 118.8 L311.3 115.6 L318.7 112.5 L326.2 109.4 L333.7 106.3 L341.1 103.3 L348.6 100.4 L356.0 97.4 L363.5 94.6 L371.0 91.7 L378.4 88.9 L385.9 86.2 L393.3 83.5 L400.8 80.8 L408.3 78.1 L415.7 75.5 L423.2 72.9 L430.6 70.4 L438.1 67.9 L445.6 65.4 L453.0 63.0 L460.5 60.6 L467.9 58.2 L475.4 55.9 L482.9 53.6 L490.3 51.3 L497.8 49.0 L505.2 46.8 L512.7 44.6 L520.2 42.5 L527.6 40.3 L535.1 38.2 L542.5 36.1 L550.0 34.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560\" y=\"34.04907975460131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">p = 0.99  →  39.3</text><path d=\"M80.0 244.5 L87.5 239.5 L94.9 235.0 L102.4 230.9 L109.8 227.1 L117.3 223.6 L124.8 220.4 L132.2 217.4 L139.7 214.6 L147.1 212.1 L154.6 209.7 L162.1 207.4 L169.5 205.3 L177.0 203.3 L184.4 201.5 L191.9 199.7 L199.4 198.1 L206.8 196.5 L214.3 195.0 L221.7 193.6 L229.2 192.3 L236.7 191.0 L244.1 189.8 L251.6 188.6 L259.0 187.5 L266.5 186.4 L274.0 185.4 L281.4 184.5 L288.9 183.5 L296.3 182.7 L303.8 181.8 L311.3 181.0 L318.7 180.2 L326.2 179.4 L333.7 178.7 L341.1 178.0 L348.6 177.3 L356.0 176.7 L363.5 176.0 L371.0 175.4 L378.4 174.8 L385.9 174.3 L393.3 173.7 L400.8 173.2 L408.3 172.7 L415.7 172.2 L423.2 171.7 L430.6 171.2 L438.1 170.7 L445.6 170.3 L453.0 169.9 L460.5 169.4 L467.9 169.0 L475.4 168.6 L482.9 168.2 L490.3 167.9 L497.8 167.5 L505.2 167.1 L512.7 166.8 L520.2 166.5 L527.6 166.1 L535.1 165.8 L542.5 165.5 L550.0 165.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560\" y=\"165.18072289156632\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">p = 0.95  →  15.4</text><path d=\"M80.0 244.5 L87.5 241.2 L94.9 239.0 L102.4 237.4 L109.8 236.2 L117.3 235.3 L124.8 234.6 L132.2 234.0 L139.7 233.5 L147.1 233.1 L154.6 232.7 L162.1 232.4 L169.5 232.1 L177.0 231.9 L184.4 231.7 L191.9 231.5 L199.4 231.3 L206.8 231.1 L214.3 231.0 L221.7 230.9 L229.2 230.8 L236.7 230.6 L244.1 230.5 L251.6 230.4 L259.0 230.4 L266.5 230.3 L274.0 230.2 L281.4 230.1 L288.9 230.1 L296.3 230.0 L303.8 229.9 L311.3 229.9 L318.7 229.8 L326.2 229.8 L333.7 229.7 L341.1 229.7 L348.6 229.7 L356.0 229.6 L363.5 229.6 L371.0 229.5 L378.4 229.5 L385.9 229.5 L393.3 229.4 L400.8 229.4 L408.3 229.4 L415.7 229.3 L423.2 229.3 L430.6 229.3 L438.1 229.3 L445.6 229.2 L453.0 229.2 L460.5 229.2 L467.9 229.2 L475.4 229.2 L482.9 229.1 L490.3 229.1 L497.8 229.1 L505.2 229.1 L512.7 229.1 L520.2 229.0 L527.6 229.0 L535.1 229.0 L542.5 229.0 L550.0 229.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560\" y=\"228.98507462686567\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">p = 0.75  →  3.8</text></svg>", "caption": "Amdahl's law for three values of p. The serial part, 1 − p, sets the ceiling."}
```

The box office gave both ends:

- Selling across a hundred shows, almost nothing was serial: each sale locked a different row. Two
  copies sold 2.1 times what one did and three sold 3.2 times. That is *p* very close to 1, and a
  little better than Amdahl allows, for the reason section 07 gave: a lone copy capped at one
  processor loses part of its share to the cap.
- Selling one show, the serial part was the lock held during `sign()`, nearly the whole sale.
  *p* close to 0, and a ceiling of about 1: three copies, 1.0 times one copy.

## Worse than Amdahl

Amdahl's law assumes the serial part stays the same size as copies are added. In real systems it
grows. Every copy that has to agree with the others pays for the agreement: locks taken and
released, caches kept in step, messages exchanged. Neil Gunther's **Universal Scalability Law**
adds that cost as a second term, one that grows with the number of pairs of copies that have to
coordinate, *n*(*n* − 1). With it, throughput does not just flatten: **it peaks and falls**. Past a
certain number of copies, adding one makes the whole system slower.

That is the curve to fear, because it looks like success right up to the peak. The hot-row test
already showed a mild form of it: fifteen waiting connections are fifteen processes PostgreSQL has
to keep track of, wake and put back to sleep, which is coordination that one waiting connection
did not cost.

## Choosing

Neither direction is the right answer; each is right for a part of the system.

| | vertical | horizontal |
|---|---|---|
| changes to the program | none | it must be stateless, or its state must live elsewhere |
| ceiling | the largest machine, and the price near it | the serial part, and the cost of coordination |
| failure | one machine, all or nothing | one copy at a time, if there are enough |
| suits | the database, the part that holds state | the stateless tier: web servers, workers |

The usual shape of a growing system follows from that table. **The stateless parts scale out
early**, because it is cheap: the box office was stateless from its first line. **The database
scales up for a long time**, because it is where the state is and dividing state is hard, and a
single large PostgreSQL serves more than most systems ever need. When even the largest machine is
not enough, or one machine is too much to lose, the state itself has to be divided or copied. That
is lesson 2, and lesson 3 is what it costs to keep the copies in agreement.
