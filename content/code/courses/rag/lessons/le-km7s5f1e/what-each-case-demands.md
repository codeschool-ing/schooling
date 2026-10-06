---
title: What each case demands
version: 1
---

The four uses share a pipeline and differ in almost everything else. Laid side by side, the
differences say which parts of the pipeline each one has to get right, and therefore where a team
should spend its time first.

| | documentation | customer support | legal | internal knowledge |
| --- | --- | --- | --- | --- |
| who reads the answer | an engineer, who will run it | a customer, who will act on it | a lawyer, who will quote it | an employee, who may not be cleared for it |
| what a wrong answer costs | minutes, found quickly | a promise, a refund, a screenshot | a liability | a leak |
| the vocabulary | exact identifiers | the customer's own words | the document's own words | the company's jargon |
| the search that suits it | lexical and vector together | vector, in every language the customers use | vector, scoped to one document set | vector, filtered by who is asking |
| the citation | the page, for the reader to check | rarely shown | the document, version and clause | the document and its owner |
| freshness | every release | every price or policy change | every version, kept with its dates | constant, and nobody's job |
| "I don't know" | acceptable | better than a guess | the only safe default | acceptable |

## Three things the table says

**The search has to fit the vocabulary.** Documentation questions are about exact strings and support
questions are about paraphrase. One retrieval strategy serves both badly, which is why lesson 6
combines lexical and vector search and lets their weights differ by use.

**The cost of a wrong answer decides how much refusing is worth.** Where being wrong is cheap,
an assistant can answer from a weak match and let the reader check. Where it is expensive, it should
refuse below a threshold and say so. The threshold is a product decision, not a technical one, and
lesson 7 shows how to set it from measurements rather than taste.

**Two of the four uses fail by revealing, not by being wrong.** In legal work and internal knowledge
the worst outcome is a correct answer given to the wrong person, or an old version quoted as the
current one. Neither is visible in a test that checks whether answers are right. Both need metadata
stored with every chunk from the first day, because adding it later means re-indexing everything,
and the cheapest moment to store a document's audience, owner, version and status is when it is
first cut into chunks. Lesson 5 stores all four.

## Choosing where to start

A team starting from nothing does well to begin with customer support over the public help centre:
short articles, public text, a clear measure of success in tickets answered, and a familiar failure
in a wrong answer a person can correct. Documentation comes second, and needs lexical search early.
Legal and internal knowledge come last, not because they are less valuable but because they need the
permission and version machinery of lessons 5 and 14 before the first user sees them.
