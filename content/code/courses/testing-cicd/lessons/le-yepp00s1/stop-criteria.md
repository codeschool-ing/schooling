---
title: Deciding when to stop, before you start
version: 1
---

Lesson 10 stopped releases by hand: somebody read a table of numbers and edited a file. That works
while somebody is watching and thinking clearly. A release that goes wrong at the end of a long day,
with a manager asking whether it can stay, is the moment a person argues with the numbers.

**Stop criteria** are the answer: the conditions under which a release is abandoned, written down
before it starts. The lab's `ops/canary.py` carries them as four constants at the top of the file:

```python
STEPS = [5, 25, 50, 100]      # the canary's share of traffic, in percent
BATCH = 400                   # requests sent at each step
MIN_REQUESTS = 50             # do not judge a side on fewer answers than this
MAX_GAP = 1.0                 # percentage points of errors above the baseline
```

Read together, they say: move the canary through 5%, 25%, 50% and all the traffic; send 400 requests
at each step; never judge a side on fewer than 50 answers; and stop the moment the canary's error rate
is more than one percentage point above the baseline's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"A flow of the canary script. Raise the share, to 5, 25, 50 and 100 percent in turn; send 400 requests; check whether there are 50 answers or more. If not, go to the next step. If so, check whether the canary is more than 1 point worse than blue: if yes, abort with exit 1; if no, go to the next step. After 100 percent, promote with exit 0.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 5 L0 10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"70\" width=\"130\" height=\"54\" rx=\"5\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">raise the share</text><text x=\"75.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">5 25 50 100</text><rect x=\"170\" y=\"70\" width=\"130\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">send 400 requests</text><rect x=\"330\" y=\"70\" width=\"120\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">50 answers</text><text x=\"390.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">or more?</text><rect x=\"480\" y=\"70\" width=\"130\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"545.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">more than 1 point</text><text x=\"545.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">worse than blue?</text><rect x=\"640\" y=\"70\" width=\"70\" height=\"54\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"675.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">abort</text><text x=\"675.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">exit 1</text><rect x=\"10\" y=\"168\" width=\"130\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"75.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">promote</text><text x=\"75.0\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">exit 0</text><path d=\"M140 97.0 L168 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M300 97.0 L328 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M450 97.0 L478 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"464\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">yes</text><path d=\"M610 97.0 L638 97.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"624\" y=\"87.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">yes</text><path d=\"M390 70 L390 30 L75 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M545 70 L545 30 L390 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M75 30 L75 68\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"400\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no</text><text x=\"555\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">no</text><text x=\"232\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">next step</text><path d=\"M75 124 L75 166\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"85\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">after 100%</text></svg>", "caption": "The rule ops/canary.py applies at every step, written before the release started."}
```

## Why in advance

- **The decision is made once, calmly.** During the release nobody has to decide whether 2% is bad.
  That was decided on a quiet afternoon, by people who could see the whole picture.
- **It can be reviewed.** The criteria sit in a file in the repository, so a change to them goes
  through a pull request like any other change. Loosening them to get one release out is visible.
- **It can be automated.** A rule written as a comparison of two numbers is a rule a program can
  apply at three in the morning, without waking anybody.

## What a criterion needs

Each of the four constants answers a question a criterion has to answer:

| question | constant | value |
| --- | --- | --- |
| what is compared | the error rate, canary against baseline | |
| how much worse is too much | `MAX_GAP` | 1.0 point |
| how much evidence before judging | `MIN_REQUESTS` | 50 |
| how the exposure grows | `STEPS` and `BATCH` | 5, 25, 50, 100; 400 each |

And one more that no constant answers: **what happens when the rule fires**. Here it is written
into the program: the weights go back to 0 and the script exits 1. The next section runs it.
