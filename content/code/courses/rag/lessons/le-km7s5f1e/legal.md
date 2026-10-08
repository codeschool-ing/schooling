---
title: Legal documents
version: 2
---

Contracts, terms, regulations and case files are the second classic use, and the most demanding one.
The reader is a lawyer, a compliance officer or a support lead quoting the terms to a customer, and
what they need is not an answer in the model's words. It is **the text that binds, located exactly,
in the version that was in force.**

## Asking when the contract is formed

```
ana@vm:~/rag$ python sections.py "When is the contract of sale formed?"
[1] 0.458  seller-agreement > 9. Ending the agreement
[2] 0.407  terms-of-sale > 2. Placing an order
[3] 0.402  affiliate-api > Commission
According to [2], the contract of sale is formed when the seller sends an email confirming that the order has been dispatched. This is stated in section 2.2 of the terms-of-sale.

In other words, the contract of sale is formed when the seller sends a confirmation email, not when the buyer sends an order.
ana@vm:~/rag$ grep -n "^2\.2" data/docs/terms-of-sale.md
25:2.2 The contract is formed when we send the email confirming that your order has been dispatched.
```

The answer came back with the clause number, and it is wrong in the one word a lawyer would read
first. Three things about it would worry one.

**The best-scoring section was the wrong document.** The seller agreement's clause on *Ending the
agreement* scored 0.458, above the terms of sale at 0.407. Both are contracts with numbered clauses,
and both talk about agreements and what happens when; to the embedding model they are the same kind
of text. In a legal corpus that is the normal case: every document is a contract and they all sound
alike, so the search has to be told which document set a question belongs to. Lesson 14's filters do
that.

**The reply changed who acts.** The clause says the contract is formed when *we* send the email,
and *we* in Marginalia's terms is Marginalia. The reply says *the seller* sends it, and on a
marketplace the seller is somebody else entirely: a customer who bought from a marketplace seller and
reads this reply has been told the wrong party is bound. The model put the clause into its own words,
which is what answering looks like, and its own words were a different contract. It did keep the
clause number, *section 2.2*, because the number was written in the text it read; the citation `[2]`
itself names only the heading, *2. Placing an order*, which is as close as `sections.py` can point.
**In a legal answer the citation is half of the answer**, so the clause number has to be stored beside
the chunk and printed in the citation, which is what lesson 5 does with each chunk's heading path.

**Nothing says which version.** These are version 9 of the terms, in force from 5 January 2026, and
clause 11.1 says the terms that apply to an order are the ones in force on the day it was placed. A
question about an order from 2025 needs the 2025 terms, which this corpus does not have. A legal
retrieval system keeps every version, records the dates each was in force, and filters by the date
the question is about.

## Quote, do not paraphrase

A model asked to answer from a contract will usually paraphrase it, as llama3.2:3b just did. A
paraphrase of a clause is a new text with no legal force, and it can be wrong in exactly the word
that mattered: *we* is not *the seller*, *dispatched* is not *delivered*, and *may* is not *must*. So
the prompt for a legal use asks for the relevant clause quoted verbatim with its number, and a check
afterwards confirms the quoted text appears in the source character for character, because a model
asked to quote still sometimes paraphrases. Lesson 7 builds that check.

## What legal work asks of a pipeline

- **Precise location**: the document, the version and the clause, in every citation.
- **Verbatim quotation**, checked against the source.
- **Scoping by document set and date**, because every document sounds like every other.
- **A conservative refusal.** "The documents do not say" is a legitimate legal answer; a plausible
  clause that does not exist is malpractice. The support handbook's own rule applies doubly here: if
  a customer asks for the legal text, send the link to the clause.
