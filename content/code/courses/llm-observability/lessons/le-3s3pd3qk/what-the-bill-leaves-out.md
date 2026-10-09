---
title: What a bill made from traces leaves out
version: 2
---

`bill.py` adds up what the spans recorded. The provider's invoice adds up what the provider charged.
They should agree, and the ways they fail to are worth knowing before the day somebody asks why the
dashboard says one thing and the invoice another.

**Calls nobody traced.** A batch job, a script somebody ran from a laptop, a second service with the
same API key and no instrumentation. Every one is on the invoice and none is in the spans. The fix is
not more care; it is **one key per service**, so that the provider's own usage page splits the bill
the same way the traces do, and a key with spend and no spans stands out.

**Attempts that failed after work was done.** A provider that refuses a request before doing anything
usually charges nothing for it. A reply cut off half way is
another matter: the tokens already generated have been produced, and a provider may charge for them.
The assistant records a cut-off attempt as an error span with the number of pieces received
(`app.partial_pieces`), but its usage never arrives, because the final chunk that carries it was the
part that was lost. Lesson 4 makes one happen.

**Evaluation.** Lessons 9 to 12 send replies to a judge model, and every one of those calls is billed.
They belong in the same accounting, under their own feature name, so that "what does quality cost us"
has an answer. Lesson 9 measures it.

**Caching and discounts.** A provider that caches a prompt prefix charges less for the cached part,
and a batch interface charges less for waiting. Both appear in the usage the provider returns, as
separate counts, and both need their own price. `rag` lesson 17 and `prompt-reliability` lesson 17
measure caching; a cost table that ignores those counts will overstate the bill of any system that
uses it.

**Taxes, minimums, exchange.** An invoice in dollars paid from a Brazilian account has an exchange
rate and taxes on top that no span knows about. The traces measure the cost of the work; finance
measures the cost of the invoice. Both are right, and they are different numbers.

## Reconciling

Once a month, compare the two: the provider's usage report, by key and by model, against the sum of
the spans for the same period and the same models. A difference of a percent or two is retries, cut
streams and clocks at the edge of the month. **A difference of ten percent is untraced work**, and
finding it is worth an afternoon, because it is the part of the bill nobody is watching.
