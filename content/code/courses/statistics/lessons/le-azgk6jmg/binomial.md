---
title: The binomial distribution
version: 1
---

Horta's records say that 15% of deliveries arrive late. Tonight there are 10 deliveries. What is the chance that 3 or more are late?

The **binomial distribution** answers questions of exactly this form. It applies when:

1. there is a fixed number of **trials**, *n* — here 10 deliveries;
2. each trial has two outcomes, a **success** and a failure — late or on time, where "success" is just the outcome being counted;
3. each trial has the same probability of success, *p* — here 0.15;
4. the trials are **independent**: one delivery being late does not change the chance for another.

The random variable is the number of successes, which can be anything from 0 to *n*.

## The formula, and where it comes from

The probability of exactly *k* successes in *n* trials is

```localised
P(X = k) = C(n, k) × p^k × (1 − p)^(n − k)
```

Each piece has a reason. Any one particular sequence with *k* late and *n* − *k* on time has probability *p*^*k* × (1 − *p*)^(*n* − *k*), by multiplying independent chances. And there are **C(*n*, *k*)** such sequences — "*n* choose *k*", the number of ways to pick which *k* of the *n* trials are the late ones.

For exactly 2 late out of 10: C(10, 2) = 45, so P(X = 2) = 45 × 0.15² × 0.85⁸ = **0.2759**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l08-binomial\" aria-label=\"A bar chart of the binomial distribution with 10 deliveries, each late with probability 0.15. The bars for 0 to 5 late deliveries are 0.197, 0.347, 0.276, 0.130, 0.040 and 0.008; from 6 upwards they are too small to see. The bars for 3 or more are highlighted and add up to 0.180.\"><path d=\"M70.0 40.0 L70.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 200.0 L70.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0</text><path d=\"M70.0 160.0 L570.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 160.0 L70.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"160.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.1</text><path d=\"M70.0 120.0 L570.0 120.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 120.0 L70.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2</text><path d=\"M70.0 80.0 L570.0 80.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 80.0 L70.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"80.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.3</text><path d=\"M70.0 40.0 L570.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 40.0 L70.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">probability</text><path d=\"M83.4 200.0 L83.4 121.3 L110.2 121.3 L110.2 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"96.8\" y=\"112.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0.197</text><text x=\"96.8\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">0</text><path d=\"M128.0 200.0 L128.0 61.0 L154.8 61.0 L154.8 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"141.4\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0.347</text><text x=\"141.4\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><path d=\"M172.7 200.0 L172.7 89.6 L199.5 89.6 L199.5 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"186.1\" y=\"80.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0.276</text><text x=\"186.1\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><path d=\"M217.3 200.0 L217.3 148.1 L244.1 148.1 L244.1 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"230.7\" y=\"139.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">0.130</text><text x=\"230.7\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><path d=\"M262.0 200.0 L262.0 184.0 L288.8 184.0 L288.8 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"275.4\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">0.040</text><text x=\"275.4\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4</text><path d=\"M306.6 200.0 L306.6 196.6 L333.4 196.6 L333.4 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"320.0\" y=\"187.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">0.008</text><text x=\"320.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5</text><path d=\"M351.2 200.0 L351.2 199.5 L378.0 199.5 L378.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"364.6\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">6</text><path d=\"M395.9 200.0 L395.9 199.9 L422.7 199.9 L422.7 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"409.3\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">7</text><path d=\"M440.5 200.0 L440.5 200.0 L467.3 200.0 L467.3 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"453.9\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">8</text><path d=\"M485.2 200.0 L485.2 200.0 L512.0 200.0 L512.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"498.6\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">9</text><path d=\"M529.8 200.0 L529.8 200.0 L556.6 200.0 L556.6 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"543.2\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">10</text><path d=\"M70.0 200.0 L570.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"320.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">late deliveries out of 10</text><text x=\"387.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">3 or more: 0.180</text></svg>", "caption": "One count, eleven possible values, and a probability for each. The highlighted bars are the evenings with three or more late deliveries."}
```

## Three or more late

"3 or more" is everything except 0, 1 and 2. Adding those three bars and subtracting from 1:

```localised
1 − (0.1969 + 0.3474 + 0.2759) = 0.1798
```

About **18% of evenings** with ten deliveries will have three or more late. A spreadsheet does the adding for you:

```localised
=BINOM.DIST(2, 10, 0.15, FALSE)        0.275896656602051
=1 - BINOM.DIST(2, 10, 0.15, TRUE)     0.179803519632422
```

The last argument chooses between one bar (`FALSE`) and the total of all bars up to and including that one (`TRUE`), called the **cumulative** probability.

## Mean and spread

A binomial distribution has mean ***np*** and standard deviation **√(*np*(1 − *p*))**. For ten deliveries at 15%: a mean of 1.5 late deliveries per evening, with a standard deviation of 1.13.

## When the conditions fail

The fourth condition is the one that breaks most often. On a rainy evening, all deliveries are more likely to be late together. The trials are no longer independent, late evenings cluster, and the binomial will understate how often three or more are late. A model with the right mean and the wrong independence gets the tails wrong, which is usually where the important questions are.
