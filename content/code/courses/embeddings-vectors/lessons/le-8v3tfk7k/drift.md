---
title: When normal moves
version: 1
---

A detector is a description of normal frozen on the day it was built. In the second week of the
course's story Marginalia launches a subscription, **Marginalia Unlimited**, and the inbox changes.
`data/week2.jsonl` holds twenty messages from that week, most of them about the subscription.

None of them is spam. They are customers, asking about something the reference has never heard
of. Scoring them one at a time, as the previous section did, answers the wrong question; the
useful view is the **batch**.

```schooling-example
{
  "language": "python",
  "file": "drift.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ninbox = [json.loads(l) for l in open(\"data/inbox.jsonl\")]\nweek2 = [json.loads(l) for l in open(\"data/week2.jsonl\")]\nref = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"train\"])\nheld = embed([t[\"text\"] for t in tickets if t[\"split\"] == \"test\"])\nbest = lambda Q, R: (Q @ R.T).max(axis=1)\ncut = np.percentile(1 - best(held, ref), 95)",
      "note": "The reference and the cut-off from the previous section: k=1, at the 95th percentile of the held-out tickets."
    },
    {
      "code": "def batch(name, B):\n    S = B @ B.T\n    np.fill_diagonal(S, -1)\n    score = 1 - best(B, ref)\n    inside = (S.max(axis=1) > best(B, ref)).sum()\n    print(f\"{name}: {len(B)} messages, mean score {score.mean():.3f}, \"\n          f\"flagged {(score > cut).sum()}, nearest neighbour in the batch {inside}\")\n    return score\n\nbatch(\"inbox (normal)\", embed([m[\"text\"] for m in inbox if not m[\"odd\"]]))\nW = embed([w[\"text\"] for w in week2])\ns = batch(\"week 2\", W)",
      "note": "Three numbers per batch: the mean score, how many messages cross the cut-off, and how many have their nearest neighbour inside the batch rather than among the old tickets."
    },
    {
      "code": "for i in np.argsort(-s)[:7]:\n    print(f\"   {s[i]:.3f}  {'*' if s[i] > cut else ' '} {week2[i]['id']}  {week2[i]['text'][:52]}\")",
      "note": "The seven week-2 messages furthest from normal, starred when they cross the cut-off."
    },
    {
      "code": "for name, R in ((\"before\", ref), (\"after adding w01-w10\", np.vstack([ref, W[:10]]))):\n    s = 1 - best(W[10:], R)\n    print(f\"w11-w20 {name}: flagged {(s > cut).sum()}, mean score {s.mean():.3f}\")",
      "note": "Re-baseline: add the first ten week-2 messages to the reference and score the other ten again."
    }
  ]
}
```

```
ana@lab:~/emb$ python drift.py
inbox (normal): 32 messages, mean score 0.357, flagged 0, nearest neighbour in the batch 1
week 2: 20 messages, mean score 0.461, flagged 4, nearest neighbour in the batch 11
   0.810  * w19  Upgrade from monthly to yearly, how?
   0.682  * w10  How much is the annual subscription compared to mont
   0.617  * w13  Can I pause my subscription while I'm travelling?
   0.600  * w16  Is there a student discount on the subscription?
   0.554    w01  How do I cancel my Marginalia Unlimited subscription
   0.537    w03  Which books are included in the Unlimited subscripti
   0.536    w05  Can I share my Unlimited plan with my family?
w11-w20 before: flagged 3, mean score 0.450
w11-w20 after adding w01-w10: flagged 0, mean score 0.368
```

## What the batch shows that a single message does not

**Only four of the twenty cross the cut-off**, and all four are about the subscription: moving
from monthly to yearly, comparing prices, pausing it, a student discount. The message about
cancelling Unlimited scores 0.554, just under the line at 0.560, and the next two, about what
Unlimited includes and whether it can be shared, sit right behind it. Message by message, the new topic mostly passes.

The batch numbers do not miss it. Against the normal messages of the first inbox:

| | inbox (normal) | week 2 |
|---|---|---|
| mean score | 0.357 | 0.461 |
| flagged | 0 | 4 |
| nearest neighbour in the same batch | 1 of 32 | 11 of 20 |

The mean rose, which says the batch as a whole has moved away from the reference. The last row is
the stronger signal. In the first inbox, only one normal message was closer to another inbox
message than to any old ticket. In week 2, **eleven of twenty** were: the subscription messages are
closest to each other. A group of new messages that resemble each other more than they resemble
anything known is what a **new topic** looks like, as opposed to a scatter of unrelated oddities.

This is called **drift**: the data a system sees moves away from the data it was built on. It is not
an anomaly in any message, and flagging those messages one by one, every day, would send twenty
legitimate customers a week to a review queue.

## What to do about it

Two things, and both are decisions a person makes.

**Add the topic.** If the shop routes tickets by category, subscriptions are now a sixth category,
and lesson 4's classifier needs labelled examples of it.

**Re-baseline.** Add examples of the new normal to the reference. The last two lines of the output
add the first ten week-2 messages and score the other ten again: the flags drop from 3 to 0 and the
mean from 0.450 to 0.368.

Re-baselining has a cost of its own. Anything added to the reference stops being flagged, which is
what the planted spam did to k=1 two sections ago. So add messages somebody has read, not
everything that arrived, and keep watching the batch numbers. A mean score that climbs week after
week is the sign that the reference needs another look.
