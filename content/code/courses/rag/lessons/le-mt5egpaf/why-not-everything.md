---
title: Why not put everything in the prompt
version: 1
---

If one document in the prompt fixes one question, all thirteen should fix every question. It is the
first idea everybody has, and for a small enough corpus and a large enough window it even works.
Measured on this one, it fails before it starts, and the reasons it fails stay true long after the
window is big enough.

## Counting the corpus

A provider counts in tokens, so the corpus has to be counted in tokens too. `count.py` uses
tiktoken's `cl100k_base`, the encoding labgen counts with:

```
ana@lab:~/rag$ python count.py
   816  data/docs/affiliate-api.md
   660  data/docs/ebooks-and-audiobooks.md
   483  data/docs/finance-refund-controls.md
   342  data/docs/gift-cards.md
   617  data/docs/payments-and-invoices.md
   626  data/docs/privacy-notice.md
   403  data/docs/returns-policy-2025.md
 1,113  data/docs/returns-policy.md
   726  data/docs/seller-agreement.md
   845  data/docs/shipping-and-delivery.md
   906  data/docs/support-handbook.md
   841  data/docs/terms-of-sale.md
   536  data/docs/warehouse-runbook.md
 8,914  in all
```

**8,914 tokens for 6,843 words**, about 1.3 tokens a word, which is typical for English prose with
some numbers and identifiers in it. `everything.py` puts all thirteen in one prompt, numbered, and
asks the price of express delivery:

```
ana@lab:~/rag$ python everything.py
refused: prompt is too long: 9072 tokens + 256 max_tokens > 8192 maximum
```

The request was 9,072 tokens, the documents plus their numbers, names and the question, and the
provider refused it before reading a word. The 256 is room reserved for the reply: a request has to
fit what it sends **and** what it asks back, and labgen reserves 256 when the request does not say how
long a reply it wants.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three bars measured in tokens. Every document and one question: 9,072, longer than the window. The window of extract-1, for prompt and reply together: 8,192. One document and one question: 1,144.\"><text x=\"218\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">every document</text><text x=\"218\" y=\"71\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and one question</text><rect x=\"230\" y=\"44\" width=\"440.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"678.0\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9,072</text><text x=\"218\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">extract-1's window</text><text x=\"218\" y=\"133\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">prompt and reply</text><rect x=\"230\" y=\"106\" width=\"397.3\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><text x=\"635.3192239858906\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">8,192</text><text x=\"218\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">one document</text><text x=\"218\" y=\"195\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and one question</text><rect x=\"230\" y=\"168\" width=\"55.5\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"293.4850088183422\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1,144</text><text x=\"230\" y=\"236\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the first bar is 880 tokens longer than the second</text></svg>", "caption": "The thirteen documents and a question come to 9,072 tokens, which does not fit; one document and the same question come to 1,144. Every number is one the lab printed."}
```

## Suppose it fitted

A window of a million tokens would take this corpus a hundred times over. Three costs remain, and
each grows with the corpus, not with the question.

**Every question pays for every document.** At an illustrative price of 3 per million input tokens,
not any provider's, a 9,072-token prompt costs 0.027 to send, and ten thousand questions a day cost
272 a day before a single word of reply. The same questions with one relevant document cost about an
eighth of that. Providers cache a repeated prefix at a discount, and lesson 17 counts what that buys,
but a discount on text the question did not need is still a price for text the question did not
need.

**Every question waits for every document.** A model reads its whole prompt before it writes the
first token of a reply, and reading takes time in proportion to the length. A support chat that
reads the warehouse runbook before answering a question about gift cards is slower for no reason
the customer could see.

**Every question competes with every document.** The more unrelated text a prompt holds, the more
chances the reply has to use the wrong part of it. One document already pulled a sentence about
faulty books into an answer about the return window in the section before this one. Researchers
measuring real models with long contexts found that they use information at the start and the end
of a long prompt better than information in the middle; the paper is *Lost in the Middle*, Liu and
others, 2023. This lab cannot reproduce that finding, because extract-1 reads every sentence the
same way, and lesson 12 comes back to what it means for how a prompt is packed.

## And the corpus grows

Thirteen documents is a teaching corpus. A real support team's knowledge base runs to thousands of
articles, a law firm's to millions of pages, and both change every week. Whatever fits today will
not fit next year, and a design that depends on it fitting has a date on which it breaks.

So the useful question is not *how do I fit everything in* but **how do I find, for this question,
the few passages that answer it, and send only those.** That is retrieval, and the next section
builds the smallest version of it.
