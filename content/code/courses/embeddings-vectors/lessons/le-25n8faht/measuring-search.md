---
title: Measuring a search
version: 1
---

Trying a few questions and liking the answers is how most searches get shipped, and it is how a
search that fails on a third of real questions gets shipped too. To compare two searches, or one
search before and after a change, you need **relevance judgements**: a list of questions, each with
the documents that answer it, decided by a person before the search runs.

`data/queries.jsonl` is that list for this course: 24 questions a customer might type, each with
the article or articles the course decided answer it. The first one is
`{"id": "q01", "text": "how do I get my money back", "relevant": ["h15", "h14"]}`.

## Recall at k

The measure is simple. For each question, run the search and look at the top `k` results; count
the question as found if a relevant article is among them. **Recall@1** asks whether the right
article came first, and **recall@3** whether it made the top three, which is roughly what a
customer reads before giving up.

Strictly, recall@k is the share of *all* the relevant documents that appear in the top `k`, and
q01 has two. With one answer per question, as in 23 of these 24, the two definitions agree, and
this course counts a question as found when any of its answers is there.

```schooling-example
{
  "language": "python",
  "file": "evaluate.py",
  "parts": [
    {
      "code": "import json\nimport numpy as np\nfrom bm25 import keyword_search\nfrom search import D, ids, embed\n\nqueries = [json.loads(line) for line in open(\"data/queries.jsonl\")]\nexact = [(\"MG-20481937\", [\"h06\"]), (\"Pix\", [\"h20\"]), (\"EPUB\", [\"h32\"]), (\"4.90\", [\"h07\"]),\n         (\"Visa\", [\"h20\"]), (\"prepaid label\", [\"h14\"]), (\"photo ID\", [\"h11\"]),\n         (\"cash on delivery\", [\"h20\"])]\nnatural = [(q[\"text\"], q[\"relevant\"]) for q in queries]",
      "note": "Two sets of judgements: the course's 24 questions, and eight exact strings written for this section, each with the article that holds it."
    },
    {
      "code": "def embedding_search(text):\n    return list(np.argsort(-(D @ embed(text)[0])))\n\ndef recall(rank, questions, k):\n    found = 0\n    for text, relevant in questions:\n        found += any(ids[i] in relevant for i in rank(text)[:k])\n    return found",
      "note": "A ranking of all 40 articles by embedding, and recall: for how many questions a relevant article appears in the first `k` of a ranking. `rank` is any function from a question to a list of rows, so the same code measures both searches."
    },
    {
      "code": "if __name__ == \"__main__\":\n    for name, questions in ((\"24 questions\", natural), (\"8 exact strings\", exact)):\n        print(name)\n        for method, rank in ((\"keyword\", keyword_search), (\"embedding\", embedding_search)):\n            print(f\"  {method:10} recall@1 {recall(rank, questions, 1):2}  recall@3 {recall(rank, questions, 3):2}\")",
      "note": "Recall at 1 and at 3 for both searches, on both sets."
    },
    {
      "code": "    for text, relevant in exact:\n        k, e = keyword_search(text), embedding_search(text)\n        where = lambda r: r.index(ids.index(relevant[0])) + 1 if ids.index(relevant[0]) in r else \"-\"\n        print(f\"  {text:18} keyword rank {where(k)}  embedding rank {where(e)}\")",
      "note": "For each exact string, where each search put the article that holds it."
    }
  ]
}
```

```
ana@lab:~/emb$ python evaluate.py
24 questions
  keyword    recall@1 10  recall@3 15
  embedding  recall@1 19  recall@3 22
8 exact strings
  keyword    recall@1  8  recall@3  8
  embedding  recall@1  3  recall@3  7
  MG-20481937        keyword rank 1  embedding rank 1
  Pix                keyword rank 1  embedding rank 1
  EPUB               keyword rank 1  embedding rank 1
  4.90               keyword rank 1  embedding rank 11
  Visa               keyword rank 1  embedding rank 2
  prepaid label      keyword rank 1  embedding rank 3
  photo ID           keyword rank 1  embedding rank 2
  cash on delivery   keyword rank 1  embedding rank 2
```

## Reading the numbers

**On the 24 questions, the embedding search found the right article first 19 times and in the top
three 22 times. BM25 managed 10 and 15.** That gap is the whole argument of lesson 1, measured:
customers and articles use different words, and only one of the two searches is built for that.

The eight exact strings tell the other story. They were written for this lesson: an order number,
a price, brand names and phrases copied from an article, the kind of thing a customer pastes rather
than types. **BM25 put the right article first for all 8; the embedding search for 3.** It did find
the order number, `Pix` and `EPUB`, but `4.90`, a delivery price, left its article at rank 11. A string of digits has little meaning for a model to place. What came first for
it, as the last lines of the section *Hybrid search* show, was the Portuguese delivery article,
which writes the same price as `4,90`.

## How far 24 questions go

Each question is one twenty-fourth of the score, so one question moves recall by about four
points. 19 against 10 is a difference you can trust; 19 against 18 would not be, and neither would
a change of one question after you edit the code. The eight exact strings are thinner still, and
were chosen to probe one weakness, not to represent what customers type.

The judgements are also the course's own, and your help centre is not this one. **The set that
decides your search is a set you write**: real questions from your search logs or your support
inbox, each with the answer checked by somebody who knows the documents. It is slow work and
nothing else replaces it. A public benchmark tells you how a model does on somebody else's
questions; lesson 9 shows how far that goes.
