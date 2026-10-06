---
title: Logging every query
version: 1
---

Three lessons have promised this section. Lesson 2 wanted a record of what was asked and retrieved, so
that a leak is found in a log rather than in a screenshot. Lesson 6 wanted the score of every query, to
adjust the floor against real questions. Lesson 8 wanted real questions to grow the test set. All three
are the same file: **one line per query, saying everything that happened.**

`ask` in `rag.py` writes it, after the reply is known:

```
ana@lab:~/rag$ wc -l < queries.jsonl
2
ana@lab:~/rag$ python rag.py "How long is a gift card valid?" > /dev/null; python last_query.py
{
  "question": "How long is a gift card valid?",
  "sources": [
    [
      "gift-cards:40925d184216",
      0.835
    ],
    [
      "payments-and-invoices:7c26788f8bc3",
      0.714
    ],
    [
      "payments-and-invoices:b3d2df106a40",
      0.573
    ]
  ],
  "reply": "A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]",
  "cited": [
    "gift-cards:40925d184216",
    "payments-and-invoices:7c26788f8bc3"
  ],
  "prompt_tokens": 314,
  "completion_tokens": 37
}
```

The two earlier queries of this lesson left two lines; the third query's line is printed whole, apart
from its timing, which changes from run to run and is left out of the printout for that reason only.

## What each field is for

| field | read by |
| --- | --- |
| `question` | the test set's next questions, and anybody asking what users want |
| `sources`, with scores | adjusting the floor, and finding questions whose best score is low |
| `reply` | review, and the evaluation of lesson 8 run on real questions |
| `cited` | which chunks are actually used, and which are never cited at all |
| `prompt_tokens`, `completion_tokens` | the cost per query of lesson 17 |
| `ms` | how long the customer waited |

Two of those deserve a second look. **The scores turn the floor from a guess into a measurement**: a
week of logged best scores, with the questions people complained about marked, is a far better basis
for lesson 6's threshold than thirty questions written by the course. **The cited chunk ids turn the
corpus into something that can be audited**: a chunk never cited in a month of queries is either about
something nobody asks, or written so that the search never finds it, and both are worth knowing.

## What not to log

The question is the customer's words, and customers type their names, order numbers and addresses into
support chats. A log of questions is personal data, under the same law the privacy notice in this
corpus cites: it needs a retention period, a way to delete one person's lines when they ask, and access
limited to the people who need it. The privacy notice's own rule for support conversations, names and
order numbers removed before the text is used to improve the search, applies to this log the moment it
is used for that.

The reply is generated text that may quote internal documents: the leak of lesson 2 would be in this
log in full. So the log inherits the strictest audience of anything it may contain, which for a
pipeline over internal documents means staff only.

## Where it goes next

A file is the right place to start and the wrong place to stay. The same record sent to a logging
pipeline or a tracing tool becomes searchable, aggregated and alerted on; `llm-observability`, later
in the track, builds exactly that from records like these. What matters now is
the habit: **if a query happened, there is a line that says what it did**, and nothing the pipeline
decided, the sources, the floor, the refusal, the citations, is missing from it.
