---
title: Four outcomes
version: 1
---

Lesson 10 ended with a detection that could not work, because the log had no times. Suppose it had
them. A detection is a rule that looks at events and decides, for each one, whether to raise an
alert. Every such decision is either right or wrong, and the alert is either raised or not, so
there are exactly four outcomes:

```schooling-figure
{"svg": "<svg id=\"sf-confusion\" viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A confusion matrix. Columns: what really happened, an attack or nothing bad. Rows: what the detector said, alert or no alert. Alert and attack is a true positive. Alert and nothing bad is a false positive. No alert and attack is a false negative. No alert and nothing bad is a true negative.\"><text x=\"440\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">what really happened</text><text x=\"330\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">an attack</text><text x=\"550\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nothing bad</text><text x=\"20\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">what the</text><text x=\"20\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">detector said</text><text x=\"210\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alert</text><text x=\"210\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">no alert</text><rect x=\"230\" y=\"60\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">TP</text><text x=\"330\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">true positive</text><rect x=\"450\" y=\"60\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">FP</text><text x=\"550\" y=\"114.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">false positive</text><rect x=\"230\" y=\"150\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--amber)\">FN</text><text x=\"330\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">false negative</text><rect x=\"450\" y=\"150\" width=\"200\" height=\"80\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"550\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">TN</text><text x=\"550\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">true negative</text></svg>", "caption": "Second word: what the detector said. First word: whether it was right."}
```

| outcome | the alert | what really happened | at the shop |
|---|---|---|---|
| **true positive (TP)** | raised | something bad | the alert fires on somebody guessing passwords |
| **false positive (FP)** | raised | nothing bad | the alert fires on a backup job with an old password |
| **false negative (FN)** | not raised | something bad | somebody guesses slowly enough to stay under the rule |
| **true negative (TN)** | not raised | nothing bad | a member of staff mistypes once and gets in on the second try |

The names are built from two words, and reading them that way makes them impossible to mix up. The
second word, **positive** or **negative**, is what the detector said: alert or no alert. The first
word, **true** or **false**, is whether it was right. A false negative is a "no alert" that was
wrong: the bad thing happened and nothing said so.

The grid has a name too: a **confusion matrix**, because it shows exactly where the detector
confuses one thing for another.

### Which mistake is worse

Neither, in general. It depends on what each one costs, and they cost different things:

- a **false positive** costs **time and attention**. Somebody has to look, decide it is nothing, and
  move on. One costs minutes. Thousands cost the team's trust in the alerts, which is the subject of
  this lesson's last section.
- a **false negative** costs **whatever the attack achieves**, and it costs it silently. Nobody looks,
  because nothing asked them to.

A smoke detector is tuned to accept false positives (burnt toast) because a false negative is a fire.
A spam filter is tuned the other way, because a real email lost in the spam folder is worse than an
occasional advert in the inbox. Security detections sit somewhere between, and where exactly is a
decision about cost, which is why lesson 3's risk thinking applies to detection too.

The same four words appear far outside security: in medical tests, in quality control, in the
evaluation of any classifier. `statistics` and the courses on machine learning use them with the same
meaning.
