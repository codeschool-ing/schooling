---
title: Words are not enough
version: 1
---

A customer types *how do I get my money back* into the help centre of Marginalia, an online
bookshop. The help centre has the answer. It is the article called **When your refund arrives**,
and nowhere in its title or body do the words *money back* appear.

The obvious way to search is to look for the words the customer typed. Here that is `grep` over the
40 articles in `data/help.jsonl`:

```
ana@lab:~/emb$ grep -i "money back" data/help.jsonl
{"id": "h18", "category": "returns", "lang": "en", "updated": "2026-01-08", "title": "Returning a gift", "body": "The person who received the gift can return it with the gift receipt and gets store credit for the price paid, without the buyer being told. To get the money back on the original card instead, the buyer has to start the return."}
ana@lab:~/emb$ grep -ci "refund" data/help.jsonl
8
```

**The one article that matches is the wrong one.** It is about returning a gift, and it matched
because its last sentence happens to say *money back*. The eight articles that mention a refund
were invisible to the search, because the customer said *money back* and the articles say
*refund*.

## Two people, two vocabularies

This is the ordinary case, not an unlucky one. The person who writes a help article and the person
who searches it describe the same thing in different words:

| the customer types | the article says |
|---|---|
| money back | refund |
| the box never showed up | a parcel marked as delivered that never arrived |
| I can't remember my login | resetting your password |
| make the letters bigger | change the typeface and the size |

Search engines have fought this for decades with tricks: lists of synonyms somebody keeps by hand,
cutting words to their stems so that *refunds* matches *refund*, spelling correction. Each trick
helps a little, and each one is another list that somebody has to maintain. None of them knows
that *the box never showed up* and *never arrived* describe the same event, because none of them
works with what the words mean.

## What would have to change

To find the refund article, a search would need to compare the **meaning** of the question with
the meaning of each article, and rank the articles by how close the two are. That needs two
things a word list does not have:

1. a way to turn any piece of text into something that can be compared, whatever words it uses;
2. a notion of *close* that puts *money back* near *refund* and far from *delivery times*.

An **embedding** gives you both. It turns a piece of text into a list of numbers, a vector, chosen
so that texts with similar meanings get similar vectors. Comparing meanings then becomes comparing
lists of numbers, which a computer does very fast.

The rest of this lesson computes one, looks at what is in it, and measures how close a few texts
are. Lesson 3 comes back to the customer's question and builds the search that answers it.
