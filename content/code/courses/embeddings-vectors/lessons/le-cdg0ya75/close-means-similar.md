---
title: Close means similar
version: 1
---

The point of an embedding is the comparison. Two texts with similar meanings should produce
vectors that point in similar directions, and two unrelated texts should not. That can be checked
directly: embed the customer's question, embed six articles, and score each article against the
question.

```schooling-example
{
  "language": "python",
  "file": "near.py",
  "parts": [
    {
      "code": "import json\nfrom minilm import embed\n\nhelp = {h[\"id\"]: h for h in map(json.loads, open(\"data/help.jsonl\"))}\nquestion = \"how do I get my money back\"\nids = [\"h15\", \"h14\", \"h18\", \"h33\", \"h07\", \"h29\"]",
      "note": "Read the 40 articles into a dictionary keyed by id, and pick six: four about getting money back, one about delivery and one about signing in."
    },
    {
      "code": "docs = [help[i][\"title\"] + \". \" + help[i][\"body\"] for i in ids]\nq = embed(question)[0]\nD = embed(docs)",
      "note": "Embed the question once and the six articles together. Each article is its title and body joined, which is what a search would compare against."
    },
    {
      "code": "scores = D @ q\nfor i, s in sorted(zip(ids, scores), key=lambda p: -p[1]):\n    print(f\"{s:6.3f}  {i}  {help[i]['title']}\")",
      "note": "`D @ q` is six dot products at once, one per article. Print them from the highest score down."
    }
  ]
}
```

```
ana@lab:~/emb$ python near.py
 0.446  h18  Returning a gift
 0.438  h15  When your refund arrives
 0.392  h14  How to return a book
 0.390  h33  Refunds for e-books
 0.169  h29  Two-step sign-in
-0.016  h07  Delivery times and costs
```

The score is the **dot product** of two vectors: multiply them coordinate by coordinate and add up
the 384 products. Because every vector from this model has length 1, the dot product is also the
cosine of the angle between them, which is 1 for the same direction and 0 for unrelated ones.
Lesson 2 builds that formula by hand; here it is enough to read it as *higher is closer*.

**All four articles about getting money back score between 0.390 and 0.446**, and the two
unrelated ones score 0.169 and −0.016. None of the four contains the words *money back* except the
gift article. The model put *money back* near *refund* without anybody telling it they were
synonyms.

It also put the gift article first, by 0.008, ahead of the article that actually answers the
question. That is a real result and not a slip in the program, and it is typical: an embedding
ranks by closeness of meaning, and *returning a gift to get the money back* is genuinely close to
*getting my money back*. Lesson 3 measures how often the best answer lands first and how often it
lands in the top three, which is the number a search is usually judged by.

## A picture of the space

Nobody can draw 384 dimensions. What can be drawn is a **projection**: a flat picture that keeps as
much of the spread between the points as two axes can hold. The figure below takes the titles of
the shipping, payment and e-book articles, embeds them, and projects them with principal component
analysis, the same method any statistics library offers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 430\" role=\"img\" aria-label=\"A scatter plot of nineteen help-centre article titles, embedded with all-MiniLM-L6-v2 and projected from 384 dimensions to two. Shipping articles cluster on the left and top, payment articles at the bottom, and e-book articles on the right. Damaged books on arrival, a shipping article, sits towards the e-books; Refunds for e-books sits towards the payments.\"><path d=\"M50 400 L690 400\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M50 400 L50 30\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><circle cx=\"179.8\" cy=\"134\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"189.8\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h07</text><circle cx=\"154.4\" cy=\"79.7\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"164.4\" y=\"79.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h08</text><circle cx=\"135.8\" cy=\"82.4\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"125.8\" y=\"82.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h09</text><circle cx=\"199.3\" cy=\"69.8\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"209.3\" y=\"69.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h10</text><circle cx=\"193.6\" cy=\"167\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"203.6\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h11</text><circle cx=\"423.3\" cy=\"72.5\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"433.3\" y=\"72.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h12</text><text x=\"459.3\" y=\"72.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Damaged books on arrival</text><circle cx=\"124.7\" cy=\"110.9\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"134.7\" y=\"110.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h13</text><rect x=\"322.2\" y=\"358.4\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"338.2\" y=\"364.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h20</text><rect x=\"295.1\" y=\"340.4\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"311.1\" y=\"346.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h21</text><rect x=\"229.3\" y=\"238.4\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"245.3\" y=\"244.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h22</text><rect x=\"293.3\" y=\"226.1\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"289.3\" y=\"232.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h23</text><rect x=\"384.4\" y=\"226.7\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"400.4\" y=\"232.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h24</text><rect x=\"306.7\" y=\"224.6\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"322.7\" y=\"230.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h25</text><circle cx=\"619.8\" cy=\"104\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"629.8\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h32</text><circle cx=\"558.4\" cy=\"183.5\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"568.4\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h33</text><text x=\"594.4\" y=\"183.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Refunds for e-books</text><circle cx=\"600.2\" cy=\"81.8\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"610.2\" y=\"81.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h34</text><circle cx=\"595.3\" cy=\"215.9\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"605.3\" y=\"215.9\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h35</text><circle cx=\"580.7\" cy=\"124.4\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"590.7\" y=\"124.4\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h36</text><circle cx=\"586\" cy=\"153.5\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"596\" y=\"153.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">h37</text><circle cx=\"470\" cy=\"40\" r=\"6\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></circle><text x=\"482\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">shipping</text><rect x=\"554\" y=\"34\" width=\"12\" height=\"12\" rx=\"1\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"572\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payments</text><circle cx=\"650\" cy=\"40\" r=\"6\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></circle><text x=\"662\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e-books</text><text x=\"690\" y=\"418\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">two axes keep 0.317 of the variance</text></svg>", "caption": "Nineteen article titles from three categories, embedded and flattened to two axes. The categories separate without being told; the two articles that sit between groups are the ones whose subject crosses the line."}
```

The three groups separate on their own. Nothing told the model which category an article belongs
to; the categories came out of the meaning of the titles. Two points sit where you would not
expect them, and both make sense once you read the title: **Damaged books on arrival** is a
shipping article that talks about books, so it drifts towards the e-books; **Refunds for e-books**
is an e-book article about money, so it drifts towards the payments.

Treat the picture as a sketch and not a measurement. The two axes kept 0.317 of the variance, a
bit under a third, so distances in the picture are only roughly the distances in the space. A
point can look close to another on paper and be further from it in 384 dimensions. The scores
from `near.py` are the real comparison; the picture is a way to see that a structure exists.
