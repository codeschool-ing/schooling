---
title: WCAG, and how it is built
version: 1
---

**The Web Content Accessibility Guidelines are the W3C's standard for an accessible page, and the current
version is WCAG 2.2, published in October 2023.** They are written as testable statements, so a page
passes or fails each one, and that is what makes them a standard rather than advice.

They are arranged in four layers:

1. **Four principles**, POUR: a page is **perceivable** (everything can be taken in by some sense),
   **operable** (everything can be done by some means), **understandable** (its content and its
   behaviour make sense), and **robust** (it works with the tools people use to reach it, assistive
   technology included).
2. **Thirteen guidelines** under them, such as *1.4 Distinguishable* or *2.1 Keyboard Accessible*.
3. **Success criteria** under each guideline, the testable statements, numbered by principle and
   guideline: *1.4.3 Contrast (Minimum)*, *2.1.1 Keyboard*, *3.3.2 Labels or Instructions*, the one
   lesson 3 met.
4. **Techniques**, published separately, which show ways to meet each criterion. They are examples, not
   requirements: a page can meet a criterion some other way.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-wcag\" aria-label=\"WCAG 2.2 drawn as four layers, from the top. Four principles: perceivable, operable, understandable, robust. Under them, thirteen guidelines; under perceivable, for instance, 1.4 Distinguishable. Under the guidelines, 86 success criteria, each with a level: under 1.4, 1.4.3 Contrast (Minimum) at level AA and 1.4.6 Contrast (Enhanced) at level AAA. Under the criteria, techniques, which are examples of how to meet them and are not themselves required.\"><defs><marker id=\"l10-wcag-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"14\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4 principles</text><rect x=\"200\" y=\"14\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"453.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">perceivable · operable · understandable · robust</text><path d=\"M99 56 L99 72\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-wcag-ah-paper-dim)\"></path><rect x=\"14\" y=\"72\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">13 guidelines</text><rect x=\"200\" y=\"72\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"453.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1.4 Distinguishable</text><path d=\"M99 114 L99 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-wcag-ah-paper-dim)\"></path><rect x=\"14\" y=\"130\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">86 success criteria</text><rect x=\"200\" y=\"130\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"453.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1.4.3 Contrast (Minimum): AA · 1.4.6 Contrast (Enhanced): AAA</text><path d=\"M99 172 L99 188\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-wcag-ah-paper-dim)\"></path><rect x=\"14\" y=\"188\" width=\"170\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"99.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">techniques</text><rect x=\"200\" y=\"188\" width=\"506\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"453.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">examples of how to meet a criterion, not requirements</text><text x=\"706\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--phosphor)\">the testable layer</text></svg>", "caption": "Only the third layer is tested. A page meets or fails each success criterion, and its level decides whether a page that fails it can still claim A or AA."}
```

**WCAG 2.2 has 86 success criteria.** It added nine to WCAG 2.1's 78, among them 2.4.11 *Focus Not
Obscured* and 2.5.8 *Target Size (Minimum)*, which lessons 11 and 13 use, and it removed one, 4.1.1
*Parsing*, because browsers no longer stumble over the markup it was written for. Version 2.2 is
backwards compatible: a page that meets it meets 2.1 and 2.0 too.

## Reading one criterion

Each criterion page on w3.org has the same parts, and three of them matter when you are fixing a page:
the **criterion itself**, one or two sentences, which is the requirement; **Understanding**, which says
why it exists and whom it helps; and **How to Meet**, the techniques and the common failures. Read the
first to know what must be true, and the second before deciding that your case is an exception.
