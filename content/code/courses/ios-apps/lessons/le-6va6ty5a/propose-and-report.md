---
title: Three steps: the parent proposes, the child chooses, the parent places
version: 1
---

**In SwiftUI a parent never sets a child's size. It offers one, and the child decides.** That is the
whole layout system in one sentence, and Apple's documentation for `ProposedViewSize` says it in
nearly those words: during layout, views choose their own size, but they do that in response to a
size proposal from their parent. Three steps happen for every view on the screen:

1. **the parent proposes a size** to the child: this much width, this much height, or "whatever you
   would like";
2. **the child chooses its size**, taking the proposal into account or not, and reports it back;
3. **the parent places the child** somewhere in its own coordinates, and the child's chosen size is
   respected: the parent cannot change it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" data-fig=\"l04-steps\" aria-label=\"Three steps between a parent and a child. Step 1, the parent proposes a size: 360 wide. Step 2, the child chooses its size, 104 wide, and reports it. Step 3, the parent places the child at a position in its own space. The child&#x27;s chosen width is kept; the parent decides only where it goes.\"><defs><marker id=\"l04-steps-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l04-steps-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-steps-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l04-steps-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">parent</text><text x=\"120\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">HStack</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"600\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">child</text><text x=\"600\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Text</text><path d=\"M212 44 L506 44\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-steps-ah-phosphor)\"></path><text x=\"360\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">1  proposes: 360 wide</text><path d=\"M506 70 L214 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-steps-ah-amber)\"></path><text x=\"360\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">2  chooses and reports: 104 wide</text><rect x=\"30\" y=\"130\" width=\"660\" height=\"80\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">3  the parent places the child; the width stays 104</text><rect x=\"50\" y=\"162\" width=\"104\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"102\" y=\"179\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SQL Databases</text><text x=\"420\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the rest of the 360 is the parent's to share out</text></svg>", "caption": "The parent offers, the child decides, and the parent only chooses where the child goes."}
```

The belief to drop comes from layout systems where a container stretches its children to fill it.
Here a `Text` offered the whole screen width takes the width of its words and no more, and the
container centres it in the space by default. **Filling space is something a view chooses to do**,
and only some views do: a `Color`, a `Spacer`, a shape, a `GeometryReader`. Apple's documentation
for `frame(width:height:alignment:)` gives the example: a shape always occupies the space offered to
it, which is why an `Ellipse` with no frame fills whatever its parent offers.

## Why this matters for the planner

The course list's row is `HStack { Text(course.title); Spacer(); Text("\(minutes) min") }`. Read with
the three steps in mind:

- the row is offered the width of the screen by the list;
- the stack offers parts of it to the two texts, and each takes the width of its words;
- the spacer takes whatever is left, which pushes the minutes to the right edge.

Nothing in that row says "right-align the minutes". **The alignment falls out of who chooses what.**
Section 08 runs that arithmetic in plain Swift and prints the numbers. The rest of this lesson takes
the pieces one at a time: stacks, frames, alignment, spacers and padding, and `GeometryReader`, the
view that reads the proposal itself.

Nothing in this section was run for the course; it is written from Apple's documentation for
`ProposedViewSize`, `Layout` and `frame(width:height:alignment:)`, read on 30 October 2026.
