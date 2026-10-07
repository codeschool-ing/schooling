---
title: Reranking, the thing Cohere is known for
version: 1
---

A **reranker** is a model with one job: given a question and a list of documents, put the documents
in order of how well they answer it. It writes nothing. It is the second stage of retrieval, the
fix lesson 1 section 11 named for missing facts: a fast search finds fifty passages that might be
relevant, and a reranker picks the five worth putting in the prompt. `embeddings-vectors` and `rag`,
the two courses after this one, build that pipeline; this section is about what the model is and
how it is sold.

The sheet prices Cohere's reranker in a different unit from every chat model so far:

```
ana@desk:~/desk$ sheet show rerank-v4.0-pro | grep -E "^(input_cost_per_query|max_input|mode|source)"
input_cost_per_query                       0.0025
max_input_tokens                           32768
mode                                       rerank
source                                     https://cohere.com/pricing
```

**$0.0025 per query**, not per token: a search is billed as one unit, whatever the number of
documents. Its window, 32,768 tokens, bounds how much text one query can rank.

## What a rerank request looks like

`lab/rerank.py` asks the question a customer's e-mail raises against four lines of the shop's
policy, with Cohere's own SDK:

```python
import os

import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
policies = [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse.",
]
r = co.rerank(model="rerank-v4.0-pro", query="my book arrived damaged, I want my money back",
              documents=policies, top_n=2)
for hit in r.results:
    print(f"{hit.relevance_score:.4f}  {policies[hit.index]}")
```

```
ana@desk:~/desk$ python-cohere lab/rerank.py
0.1250  Refunds for damaged or misprinted books are paid to the original card within ten days.
0.0000  Orders ship from our warehouse within two working days of payment.
```

**The scores come from the stand-in, and the stand-in is not a reranker.** It scores each document
by the share of the question's words it contains, which is why "damaged" carried the refund policy
to the top with an eighth of the words matching. A real reranker reads meaning, and would rank
"I want my money back" against "refunds" without a shared word. What is real is the SDK and what it
sent:

```
ana@desk:~/desk$ wire --headers user-agent,authorization
POST /v2/rerank
user-agent: cohere/7.2.0
authorization: Bearer lab-c…

{
  "model": "rerank-v4.0-pro",
  "query": "my book arrived damaged, I want my money back",
  "documents": [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse."
  ],
  "top_n": 2
}
```

The request is the whole interface: a model, a query, the documents as plain strings, and how many
to return. The reply gives each hit's **index into the list you sent** and a
relevance score, not the text, so the program maps back to its own documents, as `rerank.py` does.
