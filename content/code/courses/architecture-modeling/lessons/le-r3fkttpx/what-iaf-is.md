---
title: What IAF is
version: 1
---

**IAF, the Integrated Architecture Framework, is Capgemini's framework for enterprise and solution
architecture, developed from the 1990s and used in its consulting work since.** It is less famous
than TOGAF and appears in fewer job descriptions, but it turns up in the documents of any
company Capgemini's architects have worked with, and its central idea is one of the clearest in the field.

## A grid, not a cycle

Where TOGAF's centre is a process, the ADM cycle of lesson 8, IAF's centre is a **grid**:

- **four abstraction levels**, which are four questions asked in order: *why?*, *what?*, *how?* and
  *with what?*;
- **four aspect areas**, the parts of the enterprise being described: business, information,
  information systems and technology infrastructure;
- two **cross-cutting** concerns that apply to every cell: **security** and **governance**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l09-grid\" aria-label=\"IAF's grid. Four rows are the abstraction levels, asked in order: contextual, why; conceptual, what; logical, how; physical, with what. Four columns are the aspect areas: business, information, information systems and technology. The information systems column is highlighted, the column the lesson walks down. Two vertical bands on the right, security and governance, cut across every row.\"><text x=\"207.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Business</text><text x=\"322.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Information</text><text x=\"437.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Information systems</text><text x=\"552.5\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">Technology</text><rect x=\"20.0\" y=\"54.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Contextual</text><text x=\"80.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">why?</text><rect x=\"154.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"54.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20.0\" y=\"106.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Conceptual</text><text x=\"80.0\" y=\"137.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">what?</text><rect x=\"154.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"106.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20.0\" y=\"158.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Logical</text><text x=\"80.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">how?</text><rect x=\"154.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"158.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"20.0\" y=\"210.0\" width=\"120.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Physical</text><text x=\"80.0\" y=\"241.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">with what?</text><rect x=\"154.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"269.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"384.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><rect x=\"499.0\" y=\"210.0\" width=\"107.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"614.0\" y=\"54.0\" width=\"50.0\" height=\"200.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"668.0\" y=\"54.0\" width=\"50.0\" height=\"200.0\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"639\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\" transform=\"rotate(-90 639 154)\">security</text><text x=\"693\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\" transform=\"rotate(-90 693 154)\">governance</text></svg>", "caption": "Each cell is justified by the one above it. A product choice in the bottom row with nothing above it in its column is visibly floating."}
```

Every piece of architecture work has a place in the grid. *Why are we changing boarding?* is the
contextual level of the business area. *Which applications will validate tickets, and how do they
interact?* is the logical level of information systems. Placing a question in its cell tells you
what it depends on (the cells above it) and what depends on it (the cells below).

## The idea that makes it worth knowing

IAF's central rule is that **the levels are answered in order, and each one is justified by the
level above it**. A product choice at the physical level must trace to a logical design, which must
trace to a conceptual requirement, which must trace to a contextual reason. That is lesson 6's
traceability, built into the shape of the framework.

The rule catches the most common failure of architecture work, which is **starting at *with what?***:
choosing a product, a cloud service or a vendor, and then writing the reasons backwards. In IAF's
grid, a decision with nothing above it in its column is visibly floating.

## What it does not have

IAF has no published standard comparable to TOGAF's: its detailed material has been Capgemini's own,
taught in its training and in *Integrated Architecture Framework Explained*, the book its authors
published in 2010. So it has no public
certification market and a smaller community. That is also why it is worth learning as a **way of
thinking** rather than as a body of rules. The next two sections take its two axes in turn.
