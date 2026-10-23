---
title: Four kinds of document, which decay differently
version: 1
---

**A documentation set fails its readers when one page tries to teach, instruct, list and explain at
the same time.** Daniele Procida's **Diátaxis** framework separates technical documentation into
four kinds by what the reader is doing, and the separation turns out to matter for keeping pages
alive as much as for reading them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l11-diataxis\" aria-label=\"The four kinds of document as a two-by-two grid. Across: practical steps on the left, theoretical knowledge on the right. Down: learning or studying at the top, working at the bottom. Tutorial: learning, practical. Explanation: studying, theoretical. How-to guide: working, practical. Reference: working, theoretical. Each cell carries a Carcará example.\"><rect x=\"160.0\" y=\"40.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"84.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Tutorial</text><text x=\"295.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">trace a purchase in</text><text x=\"295.0\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your first week</text><rect x=\"440.0\" y=\"40.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"84.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Explanation</text><text x=\"575.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">why boarding</text><text x=\"575.0\" y=\"115.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">works offline</text><rect x=\"160.0\" y=\"170.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.0\" y=\"214.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">How-to guide</text><text x=\"295.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">add a payment</text><text x=\"295.0\" y=\"245.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">method</text><rect x=\"440.0\" y=\"170.0\" width=\"270.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"575.0\" y=\"214.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Reference</text><text x=\"575.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the container</text><text x=\"575.0\" y=\"245.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">catalogue</text><text x=\"295.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">practical steps</text><text x=\"575.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">theoretical knowledge</text><text x=\"150.0\" y=\"100.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">learning, studying</text><text x=\"150.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">working</text><text x=\"435.0\" y=\"310.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reference decays silently: generate it or check it</text></svg>", "caption": "A page that tries to be all four at once is the one that dies first, because no single kind of upkeep fits it."}
```

| kind | the reader is… | an architecture example at Carcará | how it decays |
| --- | --- | --- | --- |
| **tutorial** | learning, by doing a guided exercise | *your first week: trace a ticket purchase through the system* | when a step stops working; the newcomer finds it on day one |
| **how-to guide** | working, and needs to reach a goal | *how to add a payment method* | when the procedure changes; the person following it finds it |
| **reference** | working, and needs to look something up | the container catalogue; the event formats | silently: nobody reads it end to end, so wrong entries survive |
| **explanation** | studying, and wants to understand why | *why boarding works offline*; the decision records | slowly: the reasons stay true longer than anything else |

## Why the kind decides the upkeep

The right-hand column is what Carcará used. **Each kind gets the maintenance its decay needs**:

- **Tutorials and how-to guides fail loudly**, because somebody follows them step by step. They need
  an owner who answers when a newcomer says *step four does not work*, and not much else.
- **Reference fails silently**, and is therefore the kind most worth **generating** from the source
  of truth, or **checking** against it automatically. The container catalogue at Carcará is generated
  from the deployment configuration; the event formats from the schemas in the code.
- **Explanation ages best**, but each piece carries a date, because a reason is true *as of* the
  moment it was written. Decision records are explanation, which is why lesson 5 froze them.

## Splitting a mixed page

Carcará's most-read page was called *Boarding*. It began with an overview of why boarding works
offline (explanation), then gave the steps to set up a test phone (how-to), then listed the sync
endpoints (reference), then walked a new engineer through a scan (tutorial). It was 14 screens long
and its reference section was two endpoints out of date. Split into four, each part found its owner
and its upkeep, and the endpoint list became generated. **Nothing new was written; the page was just
cut along the lines of what its readers were doing.**
