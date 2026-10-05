---
title: Distance to the centroid
version: 1
---

The simplest description of a region is its centre. Average the 150 tickets' vectors into one
**centroid**, and score every inbox message by how far it points from it: one minus the cosine,
so that 0 means *exactly like the average ticket* and the score grows as a message turns away.

```schooling-example
{
  "language": "python",
  "file": "centroid.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\ntickets = [json.loads(l) for l in open(\"data/tickets.jsonl\")]\ninbox = [json.loads(l) for l in open(\"data/inbox.jsonl\")]\nN = embed([t[\"text\"] for t in tickets])\nX = embed([m[\"text\"] for m in inbox])",
      "note": "Embed every ticket, which is the whole description of normal, and every inbox message."
    },
    {
      "code": "c = N.mean(axis=0)\nprint(\"length of the mean:\", round(float(np.linalg.norm(c)), 3))\nc /= np.linalg.norm(c)",
      "note": "The mean of 150 unit vectors is shorter than 1, so divide it by its length to get a direction again."
    },
    {
      "code": "score = 1 - X @ c\norder = np.argsort(-score)\nfor r, i in enumerate(order, 1):\n    m = inbox[i]\n    if r <= 10 or m[\"odd\"]:\n        print(f\"{r:2}  {score[i]:.3f}  {m['id']}  {'ODD' if m['odd'] else '   '}  {m['text'][:44]}\")",
      "note": "The score is one minus the cosine to that direction: 0 means pointing exactly at normal, higher means further away. Print the ten highest, and every odd message wherever it landed."
    }
  ]
}
```

```
ana@lab:~/emb$ python centroid.py
length of the mean: 0.425
 1  1.026  m35  ODD  What is the boiling point of water at the to
 2  0.941  m34  ODD  Meu pedido ainda não chegou e já faz duas se
 3  0.923  m40  ODD  Je n'arrive pas à me connecter à mon compte 
 4  0.910  m38  ODD  Can you recommend a good recipe for vegetabl
 5  0.895  m39  ODD  Increase your website traffic by 500% with o
 6  0.791  m36  ODD  asdf qwer zxcv 12345 lkjh
 7  0.740  m37  ODD  Dear hiring manager, please find attached my
 8  0.724  m21       The font in the reading app is impossible to
 9  0.695  m22       How long does shipping to Argentina take?
10  0.692  m20       Two-factor codes from my app are always reje
16  0.642  m33  ODD  Congratulations!!! You have been selected to
```

**Seven of the eight odd messages take the first seven places**, and the Everest question is first
with a score above 1, which means its cosine with the average ticket is slightly negative. That
is a good start for so little code.

The eighth is the problem. **The free-iPhone spam, m33, comes 16th**, below eight ordinary messages
about fonts, shipping to Argentina and two-factor codes. A detector set to flag the top eight would let it
through and flag the complaint about the reading app's font instead.

## Why one centre misses it

The first line of the output is the clue. The mean of 150 vectors of length 1 has a length of
0.425. Vectors that all pointed the same way would average to length 1; these average to well
under half, because they point in five different directions, one per kind of ticket. The
centroid is a point **between** the five groups, where no actual ticket lives.

Distance from that point measures how far a message is from the average of all five topics, and
that is not the same as how far it is from any of them. A normal message that sits at the far
edge of one group, like *The font in the reading app is impossible to change*, is a long way from
the middle even though it is a perfectly ordinary e-book ticket. And a message that borrows a
little vocabulary from several groups can sit closer to the middle than it deserves. The spam looks
like such a case: it talks of receiving something and claiming it, and in `forced.py` it scored 0.321
against the returns centroid, more than any other odd message scored against any label.

A single centroid works when normal is **one** tight group: one kind of log line, one product's
reviews. Marginalia's normal is five groups, and the next section measures against the groups
themselves.
