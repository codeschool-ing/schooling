---
title: Choosing the line, or two of them
version: 1
---

The threshold of 0.5 in the last section was a default nobody chose. **Moving it trades one kind of
mistake for the other**, and the trade is easiest to see on spam, where the stand-in's scores are
spread out:

```
ana@lab:~/guard$ guard modeval data/forum.jsonl --category spam --sweep
category spam: 10 of 60 messages labelled spam by a person
threshold  flagged  precision  recall
     0.1       13       0.69    0.90
     0.2       13       0.69    0.90
     0.3       12       0.75    0.90
     0.4       12       0.75    0.90
     0.5       10       0.80    0.80
     0.6        8       0.88    0.70
     0.7        6       1.00    0.60
     0.8        5       1.00    0.50
     0.9        2       1.00    0.20
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Precision and recall of the stand-in for spam at thresholds from 0.1 to 0.9. Precision rises from 0.69 to 1.00 and recall falls from 0.90 to 0.20; at 0.5 both are 0.80.\"><text x=\"20\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">spam, 60 messages: precision and recall as the threshold rises</text><line x1=\"80\" y1=\"250.0\" x2=\"560\" y2=\"250.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"none\"></line><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><line x1=\"80\" y1=\"145.0\" x2=\"560\" y2=\"145.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"72\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><line x1=\"80\" y1=\"40.0\" x2=\"560\" y2=\"40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\"></line><text x=\"72\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1.0</text><text x=\"80.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><text x=\"140.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><text x=\"200.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><text x=\"260.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><text x=\"320.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"380.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><text x=\"440.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.7</text><text x=\"500.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.8</text><text x=\"560.0\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.9</text><text x=\"320.0\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">threshold</text><polyline points=\"80.0,105.1 140.0,105.1 200.0,92.5 260.0,92.5 320.0,82.0 380.0,65.2 440.0,40.0 500.0,40.0 560.0,40.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></polyline><circle cx=\"80.0\" cy=\"105.1\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"140.0\" cy=\"105.1\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"200.0\" cy=\"92.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"260.0\" cy=\"92.5\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"320.0\" cy=\"82.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"380.0\" cy=\"65.2\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"440.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"500.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><circle cx=\"560.0\" cy=\"40.0\" r=\"3.5\" fill=\"var(--phosphor)\"></circle><text x=\"574\" y=\"40.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">precision</text><polyline points=\"80.0,61.0 140.0,61.0 200.0,61.0 260.0,61.0 320.0,82.0 380.0,103.0 440.0,124.0 500.0,145.0 560.0,208.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></polyline><circle cx=\"80.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"140.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"200.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"260.0\" cy=\"61.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"320.0\" cy=\"82.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"380.0\" cy=\"103.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"440.0\" cy=\"124.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"500.0\" cy=\"145.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"560.0\" cy=\"208.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"574\" y=\"208.0\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">recall</text><line x1=\"320.0\" y1=\"40\" x2=\"320.0\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></line><text x=\"320.0\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5, the threshold measured first</text></svg>", "caption": "Raising the threshold buys precision with recall. The two lines cross at 0.5, and every point is a row of `guard modeval --sweep` above."}
```

At 0.1 the filter catches 9 of the 10 spam messages and 4 of the 13 it flags are legitimate. At 0.7
nothing legitimate is flagged and 4 spam messages get through. No row is the right one in general.
**The right row is the one whose mistakes Tarefa would rather live with**, and that depends on what
each mistake costs:

- a legitimate message blocked costs its writer: a freelancer whose portfolio link never appears,
  `m38`, loses work and may never learn why;
- spam published costs the readers: one scam that reaches a hundred freelancers is a hundred chances
  for somebody to lose money.

For spam on a marketplace, many teams lean towards recall and accept some blocked messages, provided
the writer is told and can appeal. For a category where a missed message can hurt somebody, such as
threats, the lean is further towards recall still. The lean is a decision, and like the fairness
metric in lesson 3 it goes in writing with the numbers that justified it.

## A score that does not spread out

The same sweep over harassment looks different:

```
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --sweep
category harassment: 15 of 60 messages labelled harassment by a person
threshold  flagged  precision  recall
     0.1       15       0.73    0.73
     0.2       15       0.73    0.73
     0.3       15       0.73    0.73
     0.4       15       0.73    0.73
     0.5       15       0.73    0.73
     0.6       15       0.73    0.73
     0.7       11       0.82    0.60
     0.8        9       0.78    0.47
     0.9        4       0.75    0.20
```

From 0.1 to 0.6 nothing changes, because the lowest score any harassing message gets from the
stand-in is 0.6, and every message with no listed word scores 0. A word list produces a handful of
distinct values, so most thresholds are the same threshold. Real classifiers produce scores that
are more spread out, but **a score is not automatically a probability**: a 0.8 from one vendor does
not mean that 80% of such messages are harassment. The sweep over your own labelled set is what
tells you what a score means at your platform.

## Two lines and three lanes

A single line forces every message into *blocked* or *published*. Most platforms draw two, and the
band between them goes to a person:

```
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --review 0.5 --block 0.85 --show
category harassment: 15 of 60 messages labelled harassment by a person
  publish m08 0.00  u r an id1ot
  publish m10 0.00  Seu idiota, ninguém te contrata
  publish m11 0.00  Vai catar coquinho, incompetente
  publish m15 0.00  Such a brilliant idea, genius. Really.
  block   m32 0.90  He called me an idiot in the chat, can a moderator look?
lane     score        labelled yes  labelled no
block    >= 0.85              4            1
review   0.50-0.85            7            3
publish  <  0.50              4           41
```

Above 0.85, a message is blocked straight away: 4 harassing messages and 1 that is not. Between 0.5
and 0.85, ten messages wait for a moderator, and 7 of them are harassment. Below 0.5, the 41 clean
messages are published along with 4 that should not have been, which no threshold fixes because they
all score 0.

Read the one message in the block lane that should not be there. It is `m32`, the person reporting
that they were called an idiot, **blocked automatically** because a report repeats the insult word
for word. A block lane needs its own safeguards for exactly this: the writer is told why, there is a
way to appeal, and the messages blocked automatically are sampled and read by a person every week,
because the block lane is where nobody looks.

Three more things keep the arrangement honest:

- **Measure the lanes per category.** The 0.85 that suits harassment says nothing about threats or
  spam.
- **Feed the moderators' decisions back as labels.** Every message reviewed in the middle lane is
  a new labelled example, so the set the thresholds were chosen on keeps growing.
- **Re-run the set when the endpoint changes.** A vendor updates its classifier without asking you,
  and the same text can score differently next month. Pin a version where the vendor offers one, and
  run the labelled set on a schedule where it does not.
