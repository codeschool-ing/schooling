---
title: Writing a comment worth reading
version: 1
---

Ana has three things to say about #31, and they are not equally serious. The first thing a good comment
does is **say which kind it is**, so Bruno knows what must change before the merge and what is up to him:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four kinds of review comment, from most to least serious. Blocking: an empty pickup time still submits, add required? It is fixed before the merge. Question: can a customer pick 03:00, when we are closed? It is answered before the merge. Nit: Place order says more than Order. The author decides. Let go: I would have used a list of times instead. It is never written.\"><defs><marker id=\"ld-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">how serious</text><text x=\"150\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the comment</text><text x=\"520\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">what happens to it</text><rect x=\"20\" y=\"42\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">blocking</text><rect x=\"150\" y=\"42\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">An empty pickup time still submits. Add required?</text><path d=\"M506 60 L516 60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">fixed before the merge</text><rect x=\"20\" y=\"104\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">question</text><rect x=\"150\" y=\"104\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Can a customer pick 03:00, when we are closed?</text><path d=\"M506 122 L516 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">answered before the merge</text><rect x=\"20\" y=\"166\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nit</text><rect x=\"150\" y=\"166\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"162\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nit: Place order says more than Order.</text><path d=\"M506 184 L516 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the author decides</text><rect x=\"20\" y=\"228\" width=\"110\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"75\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">let go</text><rect x=\"150\" y=\"228\" width=\"350\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"162\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">I would have used a list of times instead.</text><path d=\"M506 246 L516 246\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"520\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">never written</text></svg>", "caption": "Saying how serious a comment is lets the author spend their afternoon on the first row and not the third."}
```

Many teams use exactly these words as a prefix, `blocking:`, `question:`, `nit:` (for *nitpick*, a small
point). The words matter less than the habit: **a reader should never have to guess how much you care.**

## What goes into one

Compare two comments on the same line:

> This is wrong.

> **blocking:** with the field empty, *Order* still submits, so we could get an order with no pickup
> time. Adding `required` to the input would stop that.

The second one does four things the first does not:

- **It says what happens**, not what the reviewer feels about it. Bruno can check the claim in ten seconds.
- **It says why it matters**: an order with no time, which the bakery cannot fulfil.
- **It suggests a fix**, which Bruno is free to take or to do differently.
- **It is about the code.** *"You forgot the validation"* is the same fact aimed at a person; *"the input has
  no validation"* is aimed at the line.

## Questions are real questions

*"Can a customer pick 03:00?"* is a question because Ana does not know the answer. Maybe the backend refuses
it, and then the answer is one line and nothing changes. Asking is not a softened order: if you are sure, say
so, and if you are not, ask and mean it. **A question that is secretly a demand** (*"Why didn't you just use a
list?"*) makes the author guess which it is, and that is the uncomfortable part of review for most people.

## Say what is good, specifically

*"LGTM"* (looks good to me) is a fine approval. But when something in a change is well done, a reviewer
who says so, specifically, teaches as much as one who points out a flaw: *"Linking it from the home page
was a good call; I would not have thought of it."* It also makes the blocking comment easier to read, because
it shows the reviewer read the whole thing.
