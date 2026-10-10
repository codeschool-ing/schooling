---
title: What the rules cannot see
version: 2
---

Go back to the run graded against the facts. Six of its twenty-four replies were really wrong, and
every check passed every one of them:

```
ana@dev:~/obs$ python facts.py current
exact      16/24 right
normalised 16/24 right
  e02  Who pays for the return postage?                      According to [1], the customer pays for the return postage.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  I downloaded an e-book yesterday. Can I still return  I could not find that in our documents.
  e12  Will my e-books open on a Kindle?                     I could not find that in our documents.
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e16  When do I get the invoice for my order?               You will receive the electronic invoice for your order as so
  e18  What happens if my order costs more than my gift car  If your order costs more than your gift card holds, you pay 
  e19  How long is the statutory right of withdrawal?        I could not find that in our documents.
```

**e02 asks who pays for the return postage, and the reply says the customer does.** It cites its
source. The source exists, and it is the right one. The reply has no numbers to check, no personal
data, no refusal in the wrong words, and it is ten words long. Every rule passes, and the reply says
the opposite of the document it cites: returns are free, with a prepaid label.

Rules see the **form** of a reply. Whether it **answers the question**, and whether what it says is
**true of the sources**, are properties of its meaning, and a rule can reach meaning only through a
proxy: a fact that has one wording, a number that has one value. The five refusals are wrong for the
same reason: a refusal has perfect form, and only the answer key knows the documents could have
answered. And e16 and e18 show the proxy failing the other way, a right reply marked wrong because
it chose its own words.

So deterministic evaluation does two jobs well and one not at all:

- it **catches broken form** on every reply, at no cost, forever;
- it **grades facts with one wording** against an answer key, before a change ships;
- it **cannot judge relevance or truth in free text**, which is what the customer actually cares
  about.

The third job needs something that reads. The options are a model, which lesson 9 uses on a sample of
live traffic and whose cost it measures, and a person, which lesson 10 uses on a smaller sample and
whose agreement with other people it measures. Neither replaces the rules. Both are checked against
them.
