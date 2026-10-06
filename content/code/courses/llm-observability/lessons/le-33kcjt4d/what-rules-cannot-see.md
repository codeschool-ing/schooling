---
title: What the rules cannot see
version: 1
---

Go back to the run graded against the facts. Fourteen of thirty replies were wrong, and every check
passed every one of them. Two of the wrong ones:

```
ana@lab:~/obs$ python facts.py current
exact      16/30 right
normalised 16/30 right
  e02  Who pays for the return postage?                      I could not find that in our documents.
  e04  Can I return a signed copy?                           I could not find that in our documents.
  e05  My e-book was downloaded yesterday, can I still get   An e-book can be refunded within 14 days of purchase if you 
  e06  How much is express delivery?                         Express delivery is not free at any order value. [1]
  e07  Above what order value is standard delivery free?     Express delivery is not free at any order value. [1]
  e14  Can I pay in instalments?                             I could not find that in our documents.
  e17  When is the contract of sale formed?                  I could not find that in our documents.
  e19  What commission does Marginalia take from a marketpl  Marginalia is an online bookshop operated at marginalia.exam
  e20  How often are sellers paid?                           I could not find that in our documents.
  e21  What does error E-4102 mean in the affiliate API?     I could not find that in our documents.
  e22  What commission do affiliates earn on e-books?        I could not find that in our documents.
  e24  Do you store my IP address?                           I could not find that in our documents.
  e25  What is the most a support agent can refund without   I could not find that in our documents.
  e26  What must I check before changing a customer's order  I could not find that in our documents.
```

**e06 asks how much express delivery costs, and the reply says express delivery is not free at any
order value.** It cites its source. The source exists. The reply has no numbers to check, no personal
data, no refusal in the wrong words, and it is nine words long. Every rule passes, and the customer
still does not know the price.

**e07 asks above what order value standard delivery is free, and gets the same sentence**, about the
other kind of delivery. That is the reply lesson 1 explained from its trace: one chunk survived the
floor, and it was the wrong one.

Rules see the **form** of a reply. Whether it **answers the question**, and whether what it says is
**true of the sources**, are properties of its meaning, and a rule can reach meaning only through a
proxy: a fact that has one wording, a number that has one value. The ten refusals are wrong for the
same reason: a refusal has perfect form, and only the answer key knows the documents could have
answered.

So deterministic evaluation does two jobs well and one not at all:

- it **catches broken form** on every reply, at no cost, forever;
- it **grades facts with one wording** against an answer key, before a change ships;
- it **cannot judge relevance or truth in free text**, which is what the customer actually cares
  about.

The third job needs something that reads. The options are a model, which lesson 9 uses on a sample of
live traffic and whose cost it measures, and a person, which lesson 10 uses on a smaller sample and
whose agreement with other people it measures. Neither replaces the rules. Both are checked against
them.
