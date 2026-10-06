---
title: Customer support
version: 1
---

Customer support is where most retrieval systems earn their keep, and where most of them are judged
in public. The documents are the help centre and the policies behind it; the reader is a customer
who wants one thing, now, in their own words, and who will not open the source to check it. That
last fact changes the design more than any other.

## The help centre is already a retrieval corpus

`embeddings-vectors` searched Marginalia's help centre by meaning, and the same search is the
retrieval half of a support assistant. `help_search.py` is that search, over the forty short
articles in `data/help.jsonl`:

```
ana@lab:~/rag$ python help_search.py "how do I send a book back"
0.723  h14 en  How to return a book
0.625  h12 en  Damaged books on arrival
0.613  h16 en  Exchanging a book for a different edition
```

**Short articles written for customers are the easiest material a retrieval system will ever get.**
Each answers one question, in the customer's vocabulary, under a title that says what it answers. The
policies behind them are the opposite: long, precise, written for whoever has to enforce them. A
support assistant usually needs both, the article to answer and the policy to get the edge cases
right, and lesson 12 is about putting the two in one prompt without drowning the first in the second.

## A question in another language

Marginalia sells in Brazil, and some of its customers write in Portuguese. The help centre has three
Portuguese articles, translations of three English ones:

```
ana@lab:~/rag$ python help_search.py "como devolvo um livro"
0.717  h38 pt  Como devolver um livro
0.426  h40 pt  Como redefinir sua senha
0.325  h39 pt  Prazos e custos de entrega
ana@lab:~/rag$ python help_search.py "quanto custa a entrega expressa"
0.647  h39 pt  Prazos e custos de entrega
0.513  h40 pt  Como redefinir sua senha
0.352  h38 pt  Como devolver um livro
```

Both Portuguese questions found their Portuguese article first. Look at what came second and third,
though: **the other two Portuguese articles, whatever they are about.** A question about returns
ranked an article on resetting passwords above any of the thirty-seven English articles, several of
which are about returns. all-MiniLM-L6-v2 was trained on English, and to it a Portuguese text is a set
of word pieces that mostly look like other Portuguese text. It matches Portuguese to Portuguese by
spelling, not by meaning, and it cannot carry a Portuguese question across to an English answer.

For a support assistant that is a hard requirement, not a detail: **the embedding model has to cover
every language the customers write in**, or every document has to exist in every such language.
Lesson 1 of `embeddings-vectors` showed what this model makes of a Portuguese title and why a
multilingual model places a translation next to its original, and its lesson 10 weighed the
multilingual models a shop like this one would choose between.

## What support asks of a pipeline

- **Short answers first.** The customer wants yes or no and the number; the support handbook in the
  corpus says the same about how agents write, "the answer first and the explanation after it".
- **The customer's words, not the policy's.** People ask "send a book back", "money back", "the box
  never showed up". The search has to bridge from those to the policy's vocabulary, which is what
  embeddings are good at.
- **A refusal is better than a guess.** A wrong answer to a customer becomes a promise the shop may
  have to keep, and a screenshot of it can travel. Lesson 7 makes refusing a rule.
- **A way out to a person.** The handbook lists the cases that go to a team lead: a refund over the
  agent's limit, a third message about the same problem, a mention of a lawyer. An assistant that
  answers those itself is doing a job nobody gave it.
- **Freshness.** Shipping prices and delivery times change several times a year, and customers ask
  about them every day. The index has to be rebuilt when a document changes, which lesson 5 makes
  cheap.
