---
title: The lab, and what in it is real
version: 1
---

Every transcript in this course was recorded on one Linux machine, and the course carries the
script that builds it: `lab.sh`, beside `course.json`. It is the machine `embeddings-vectors` built,
with one more room. `sudo bash lab.sh up` on Ubuntu 24.04 builds that course's lab first, the
embedding model, the stand-in embedding provider and PostgreSQL with pgvector, and then adds what
this course needs on top. `sudo bash lab.sh reset` puts the working directory back as it was before
lesson 1, and every lesson's `captures.sh` starts with it.

The person at the keyboard is still ana, a developer at Marginalia, the online bookshop that does
not exist. In `embeddings-vectors` she searched the shop's help centre, forty articles of forty words
each. This course needs documents worth retrieving from, and that is a different thing.

## The documents

```
ana@lab:~/rag$ ls data
chat-a.jsonl
chat-b.jsonl
docs
eval.jsonl
help.jsonl
listings.jsonl
querylog.jsonl
ana@lab:~/rag$ wc -l data/*.jsonl
   12 data/chat-a.jsonl
    4 data/chat-b.jsonl
   30 data/eval.jsonl
   40 data/help.jsonl
    6 data/listings.jsonl
  500 data/querylog.jsonl
  592 total
```

`docs/` is the corpus: thirteen documents of the kind every company has and no model has read.

```
ana@lab:~/rag$ ls data/docs
affiliate-api.md
ebooks-and-audiobooks.md
finance-refund-controls.md
gift-cards.md
payments-and-invoices.md
privacy-notice.md
returns-policy-2025.md
returns-policy.md
seller-agreement.md
shipping-and-delivery.md
support-handbook.md
terms-of-sale.md
warehouse-runbook.md
ana@lab:~/rag$ head -12 data/docs/returns-policy.md
---
id: returns-policy
title: Returns and refunds policy
audience: public
owner: customer-support
updated: 2026-02-02
version: 4
status: current
supersedes: returns-policy-2025
---

# Returns and refunds policy
ana@lab:~/rag$ wc -w data/docs/*.md | tail -1
 6843 total
ana@lab:~/rag$ grep -c "14 days" data/docs/*.md | grep -v ":0"
data/docs/ebooks-and-audiobooks.md:2
data/docs/returns-policy-2025.md:2
data/docs/returns-policy.md:5
data/docs/seller-agreement.md:2
```

They were written for the course with three properties a retrieval system needs to be tested
against. **They are long enough to be cut up**: the returns policy alone is longer than the
embedding model can read in one piece, which lesson 4 measures. **They are ambiguous where real
documents are**: there are two returns policies, the one in force and the one it replaced, and
"14 days" appears eleven times in four documents, for e-books, audiobooks, damaged parcels, wrong
titles, marketplace sellers and the old return window. **They are
structured**, with headings and numbered clauses, so a citation can point at something smaller than
a whole document. Three of them are for staff only, and one only for the finance team; lesson 14 is
about keeping them that way.

The `.jsonl` files are the rest of the course's fixtures: `eval.jsonl` is thirty questions with the
passages that answer them, for lesson 8; the two chats are for the lessons on memory and isolation;
the listings and the query log are for lessons 16 and 17. `help.jsonl` is the help centre from
`embeddings-vectors`, copied as it was.

## The generator, which is not a model

```
ana@lab:~/rag$ curl -s localhost:8600/; echo
{"labgen": "ok", "models": ["extract-1"]}
```

**No language model was reachable from the machine this course was recorded on**, and an API key
is a bill a course cannot hand out. So the lab runs `labgen`, a server that speaks the wire formats
of OpenAI's Chat Completions and Anthropic's Messages API closely enough that both companies' own
Python SDKs, and the frameworks built on them, talk to it unmodified. The one model it serves,
`extract-1`, is not a language model. It writes no new words: it copies whole sentences out of the
text it is given, chosen by a rule. Its four rules, in the order it applies them:

| rule | what extract-1 does |
| --- | --- |
| an instruction | if any text it receives says *reply with the word X*, it replies X |
| summarise | a request starting "Summarise" gets the sentences closest to the conversation's average meaning |
| sources | with sources in the prompt, it replies with up to three of their sentences most similar to the question, each followed by its source's number |
| closed book | with nothing to read, it replies with the nearest of ten sentences the course wrote |

The similarity in the third rule is real: every sentence and the question are embedded with
all-MiniLM-L6-v2, the model `embeddings-vectors` ran, and compared by cosine. A sentence needs a
similarity of at least 0.53 to be used; if none reaches it, the reply is a sentence saying the sources
do not answer. Lesson 7 says where that number came from.

This changes what the lessons can claim, and it is worth being exact about it. **What is real is
everything around the generator**: the chunks, the embeddings, the similarities, the database, the
token counts, the SDKs and the frameworks, and every number those print. **What is the lab's is the
text of every reply.** Where a lesson shows extract-1 failing, the failure is one a real model also
has, but a real model fails less mechanically and less often. Where a lesson needs to talk about how
a real model behaves, for example with a long context, it says so and does not pretend the lab
measured it.

## What it costs to follow along

```
ana@lab:~/rag$ du -sh /opt/emb /opt/rag 2>/dev/null
1.4G	/opt/emb
516M	/opt/rag
```

The software of the two courses takes about 2 GB: a Linux machine or a virtual machine with room
for that and an ordinary database is enough, and no account anywhere is needed.

If you have your own API key, every program in this course runs against a real provider by changing
two environment variables, `OPENAI_BASE_URL` and the key, and the model name. The replies will differ
from the ones printed here; the retrieval will not.
