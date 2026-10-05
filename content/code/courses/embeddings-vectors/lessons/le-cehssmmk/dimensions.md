---
title: What a dimension is
version: 1
---

A vector from all-MiniLM-L6-v2 has 384 numbers, and it is tempting to read them as 384 features:
one coordinate for *about money*, one for *urgent*, one for *about books*. Lesson 1 said the
numbers mean nothing one at a time. This section shows that this is literally true, and why it has
to be.

## A point, or an arrow from the origin

A **coordinate** is one number that places something along one axis. Two numbers place a point on a
map: so far east, so far north. Three place a point in a room. Each number added is one more axis,
at right angles to all the others, and nothing in the arithmetic changes when there are 384 of them.
Only the drawing becomes impossible.

So a vector is a point in a space with as many axes as the model has dimensions. It is easier to
think of it as an **arrow** from the origin, the point where every coordinate is zero, to that
point. An arrow has a **direction** and a **length**, and the rest of this lesson is about which of
the two carries meaning.

## Turn the whole space and nothing changes

If one coordinate measured *about money*, the axes would be special: turning them would move that
meaning to a different number. Turn them and see. `rotate.py` embeds the 40 help articles, then
multiplies every vector by the same random **rotation**, a matrix that turns the whole space around
the origin without stretching anything:

```schooling-example
{
  "language": "python",
  "file": "rotate.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom minilm import embed\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]\nD = embed([h[\"title\"] + \". \" + h[\"body\"] for h in help])",
      "note": "Embed the 40 help articles, each as its title and body joined, as lesson 1 did."
    },
    {
      "code": "rng = np.random.default_rng(2)\nQ, _ = np.linalg.qr(rng.standard_normal((384, 384)))\nR = D @ Q",
      "note": "Build a random rotation: the QR decomposition of a matrix of random numbers gives an orthogonal matrix `Q`, one that turns the space without stretching it. The seed makes it the same rotation on every run. `D @ Q` turns all 40 vectors at once."
    },
    {
      "code": "print(\"before:\", D[0, :4].round(4))\nprint(\"after: \", R[0, :4].round(4))",
      "note": "The first four coordinates of the first article, before and after."
    },
    {
      "code": "change = np.abs(D @ D.T - R @ R.T).max()\nprint(f\"largest change in any of {len(D) * len(D)} scores: {change:.1e}\")",
      "note": "Every score between every pair of articles, before and after, and the largest difference anywhere in the two 40 × 40 tables."
    }
  ]
}
```

```
ana@lab:~/emb$ python rotate.py
before: [-0.0291  0.0291  0.047   0.024 ]
after:  [ 0.0086 -0.0308  0.0113  0.0972]
largest change in any of 1600 scores: 7.0e-07
```

**Every coordinate changed, and no score did.** The first four numbers of the first article are
entirely different after the turn, yet all 1,600 dot products between the 40 articles moved by at
most `7.0e-07`, which is the rounding of 32-bit numbers. A search, a classifier or a picture built
on these scores would give exactly the same answers in the rotated space.

That is why no coordinate means anything on its own. A rotated copy of all-MiniLM-L6-v2 would be
just as good a model, and training had no reason to prefer one orientation over another, so the
axes it ended up with are an accident. Only the arrangement of the arrows relative to each other is
real: their **angles** and, where it matters, their lengths. It also explains lesson 1's warning
about mixing models. Two models with the same dimension are at best two arrangements turned
differently, and nobody knows the turn.

## 384, 256, 1536

The dimension is a choice the model's makers made. all-MiniLM-L6-v2 returns 384, WordLlama returns
256, and OpenAI's `text-embedding-3-small` returns 1536 by default (lesson 7 calls it). More
dimensions give a model more room to keep different meanings apart, and they cost in proportion:
1536 float32 numbers are 6,144 bytes a vector against 1,536 for 384, and every comparison does four
times the multiplications. Whether the extra room is worth it depends on your texts, which is why
lesson 9 measures two models on the course's own questions rather than trusting the larger number.
