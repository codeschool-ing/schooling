---
title: Start from the reader, not from what you know
version: 1
---

Most technical writing is organised around the writer: what they found, in the order they found it,
with the effort on display. **A document is a tool for somebody else's next action**, and it is
judged by whether that action happens, not by how much it contains.

This course follows one company the whole way through. **Marola** is fictional: an online grocery
delivery business in Recife with about sixty engineers in seven teams. Lívia is a staff engineer
there, the person other teams call when a decision crosses their boundaries, and most of what she
does in a week is write. A proposal, a reply to the finance director, a review comment, a message
in an incident channel. Each one is read by people who did not ask to read it and have something
else to do afterwards.

## Four questions before the first sentence

Before writing anything longer than a chat message, Lívia answers four questions, usually in her
head and sometimes at the top of a draft she later deletes:

1. **Who reads this?** A name or a role, not "the team" or "stakeholders". If the honest answer is
   three different people, it may be three documents.
2. **What do they already know?** The finance director knows what a refund costs and does not know
   what a connection pool is. A tech lead is the other way round.
3. **What should they do after reading?** Approve, decide between two options, change a date, stop
   worrying, or nothing at all. A document with no answer to this question is a diary entry.
4. **How long will they give it?** Thirty seconds on a phone between meetings is a different
   document from twenty minutes at a desk before a review.

The answers change the document more than any style rule. Here is the same fact written for two
readers. On Friday evenings Marola's checkout fails for about two in every hundred customers,
because one database is shared by too many things.

To Bruna, the tech lead of the checkout team:

> Checkout timeouts on Fridays line up with the connection count on the primary hitting
> `max_connections` between 18:00 and 21:00. The route planner's reads are most of it. Can we pair
> on Tuesday and look at moving them to a replica?

To Caio, the finance director:

> About 180 customers a week fail to pay on Friday evenings because of a capacity limit in one of
> our systems. I am preparing a proposal to fix it, with a cost, for the meeting on the 19th. You
> do not need to do anything yet.

Neither is better writing in general. **Each is right for one reader and useless to the other.**
Bruna gets the evidence she would check and an action; Caio gets the business effect, the next
step and an explicit statement that nothing is asked of him, which is the line that stops him
replying with questions.

## The arithmetic of a reader's time

**The writer pays once and every reader pays again.** A status note sent to thirty people that
takes each of them five minutes to decode has cost two and a half hours of other people's time. If
twenty minutes of editing gets it down to one minute each, the edit saved two hours. That sum is
the whole argument for this lesson, and it gets larger the more senior the readers are, because
their time is both scarcer and more expensive.

It also explains why a long document is not a sign of a serious writer. The reader cannot tell
from the length whether the extra pages carry anything, so they skim. **Length is a cost you
impose, and it has to buy something.**

## Most readers skim, so write for the skim

Nielsen Norman Group's eye-tracking studies of web pages found that people scan rather than read:
their eyes run along the first lines and down the left edge, in what the researchers called an
F-shaped pattern. Work documents are read the same way, by people deciding whether this one
deserves their attention.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A page drawn as bars. The title, the three headings and the first line of each paragraph are highlighted: that is what a skimmer reads. The remaining lines are grey: they are read only if the skim persuaded the reader to come back.\"><defs><marker id=\"skim-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"380\" height=\"288\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"60\" y=\"40\" width=\"300\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"74\" width=\"170\" height=\"9\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"94\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"107\" width=\"330\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"120\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"133\" width=\"250\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"158\" width=\"170\" height=\"9\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"178\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"191\" width=\"330\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"204\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"229\" width=\"170\" height=\"9\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"249\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"262\" width=\"330\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"275\" width=\"340\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"60\" y=\"288\" width=\"250\" height=\"7\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><path d=\"M450 46 L426 46\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#skim-ah)\"></path><text x=\"458\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the title: read by nearly everybody</text><path d=\"M450 98 L426 98\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#skim-ah)\"></path><text x=\"458\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">headings and each first sentence:</text><text x=\"458\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what the skimmer actually reads</text><path d=\"M450 128 L426 128\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#skim-ah)\"></path><text x=\"458\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the rest: read only if the skim</text><text x=\"458\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">persuaded them to come back</text></svg>", "caption": "Two readers in one person. The skimmer reads the highlighted lines and decides; the reader comes back for the grey ones only if the highlighted lines carried the argument."}
```

So a document has two readers in one person: **the skimmer, who reads the headings and the first
sentence of each paragraph, and the reader, who comes back if the skim persuaded them.** Writing
for both means the first sentence of every paragraph carries the paragraph's claim, and the
headings say something rather than label a topic. "Costs" is a label. "The fix costs six
engineer-weeks and R$ 4,000 a month" is a heading that survives the skim.
