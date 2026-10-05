---
title: Keyword search, done properly
version: 1
---

Lesson 1 searched the help centre with `grep`, and it lost. That was not a fair fight: `grep` only
says whether a line contains a string. A real keyword search **ranks** documents by how well their
words match the question's, and the ranking function most search engines have used for decades is
**BM25**. It is the default in Lucene, and so in Elasticsearch and OpenSearch. Before building a
search by meaning, it is worth building the one it has to beat.

```schooling-example
{
  "language": "python",
  "file": "bm25.py",
  "parts": [
    {
      "code": "import collections\nimport json\nimport math\nimport re\nimport sys\n\nhelp = [json.loads(line) for line in open(\"data/help.jsonl\")]",
      "note": "Read the 40 articles."
    },
    {
      "code": "def words(text):\n    return re.findall(r\"[a-z0-9]+(?:[-.@][a-z0-9]+)*\", text.lower())\n\ndocs = [words(h[\"title\"] + \". \" + h[\"body\"]) for h in help]\naverage = sum(map(len, docs)) / len(docs)\ndf = collections.Counter(w for d in docs for w in set(d))",
      "note": "Split text into lower-case words. A hyphen, a dot or an `@` between letters or digits stays inside the word, so `MG-20481937`, `4.90` and an email address each stay whole. Then count, for every word, how many articles contain it."
    },
    {
      "code": "def bm25(query, k1=1.5, b=0.75):\n    scores = [0.0] * len(docs)\n    for w in words(query):\n        if w not in df:\n            continue\n        idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))\n        for i, d in enumerate(docs):\n            tf = d.count(w)\n            scores[i] += idf * tf * (k1 + 1) / (tf + k1 * (1 - b + b * len(d) / average))\n    return scores",
      "note": "BM25 itself. For each word of the query found in the help centre, `idf` is high for a rare word and low for a common one; `tf` is how often the word appears in this article, damped by `k1` and scaled by the article's length against the average through `b`. The two defaults are the usual ones."
    },
    {
      "code": "def keyword_search(query):\n    scores = bm25(query)\n    found = [i for i in range(len(docs)) if scores[i] > 0]\n    return sorted(found, key=lambda i: -scores[i])",
      "note": "The search: every article with a score above zero, best first. An article that shares no word with the query is not in the list at all."
    },
    {
      "code": "if __name__ == \"__main__\":\n    query = sys.argv[1]\n    scores = bm25(query)\n    for i in keyword_search(query)[:3]:\n        print(f\"{scores[i]:6.2f}  {help[i]['id']}  {help[i]['title']}\")",
      "note": "From the command line, print the top three with their scores."
    }
  ]
}
```

BM25 adds up, for every word of the question found in a document, a score made of three ideas:

- **A rare word counts more.** `idf` is high for a word few articles contain, such as an order
  number, and near zero for one nearly all of them contain, such as *the*.
- **Repeats help, with diminishing returns.** A word that appears twice scores more than once, but
  `k1` caps how much more, so a page cannot win by saying *refund* ten times.
- **Long documents are discounted.** `b` scales the score down for a document longer than the
  average, which would otherwise match more words by sheer size.

## Where it wins, and where it loses

```
ana@lab:~/emb$ python bm25.py "MG-20481937"
  3.22  h06  Where to find your order number
ana@lab:~/emb$ python bm25.py "get rid of my profile for good"
  4.11  h18  Returning a gift
  2.58  h05  Orders for schools and libraries
  2.57  h24  Using a gift card
```

**An order number is the case keyword search was made for.** `MG-20481937` appears in one article
of 40, so its `idf` is high and that article comes first, with nothing else matching at all. The
string means nothing a model could have learnt; it only has to be found.

The second question is lesson 1's problem again. *get rid of my profile for good* is answered by
**Closing your account**, which shares one word with it: *for*, so common in the help centre that its `idf` is low. BM25
ranks what shares more: the gift article matched *get* and *for*, and the other two matched *for*
and *of*. Every score above is a real match on a word, and none of them is about closing an
account.

So keyword search is strong where the customer types the same string as the article: codes, names,
prices, exact phrases. It is weak wherever the two describe one thing in different words, which
for a help centre is most questions. The section *Measuring a search* puts numbers on both halves.
