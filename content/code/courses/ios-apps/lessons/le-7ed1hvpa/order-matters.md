---
title: The order matters, because each wrapper sees only what is inside it
version: 1
---

**`.padding().background(.yellow)` and `.background(.yellow).padding()` draw different things.** The
first paints yellow behind the padded text, so the yellow reaches past the words on every side. The
second paints yellow behind the text alone, then adds empty space around the yellow. The words are
the same and the screen is not.

```swift
VStack(spacing: 24) {
    Text("50 min")
        .padding()
        .background(.yellow)

    Text("50 min")
        .background(.yellow)
        .padding()
}
```

The reason is the wrapping of section 02, read from the inside out. A background is exactly as big as
the view it wraps. **In the first chain it wraps the padding**, so it is as big as text plus padding.
**In the second it wraps the text**, so it is as big as the text, and the padding outside it adds
space that nothing paints. Section 08 runs the same two chains through a model in plain Swift and
prints the size each layer reports.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l05-order\" aria-label=\"Two chains side by side, each drawn as nested boxes. Left, text then padding then background: the background box, drawn in amber, is the outer box, 80 by 52, and the padding and the text sit inside it. Right, text then background then padding: the outer box is the padding, 80 by 52, unpainted; the amber background box inside it is only 48 by 20, the size of the text.\"><defs><marker id=\"l05-order-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l05-order-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l05-order-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l05-order-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"50\" width=\"290\" height=\"150\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"100\" y=\"90\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"185\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">50 min</text><text x=\"185\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outer: 80 by 52</text><rect x=\"390\" y=\"50\" width=\"290\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><rect x=\"450\" y=\"90\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"535\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">50 min</text><text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">outer: 80 by 52</text><text x=\"185\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.padding().background(.yellow)</text><text x=\"535\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">.background(.yellow).padding()</text><text x=\"185\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">background: 80 by 52</text><text x=\"185\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">padding inside</text><text x=\"535\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">padding: nothing painted</text><text x=\"535\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">background: 48 by 20</text></svg>", "caption": "The same three pieces in two orders. The background is the size of whatever it wraps, so the order decides how much yellow there is."}
```

## Three orders worth knowing by heart

| chain | what you get |
|---|---|
| `.padding()` then `.background(…)` | a coloured box with room around the content |
| `.background(…)` then `.clipShape(…)` | the background cut to the shape too, rounded corners and all |
| `.frame(width: 200)` then `.background(…)` | the colour fills the whole 200-point frame |
| `.background(…)` then `.frame(width: 200)` | the colour hugs the content, which sits centred in an uncoloured 200-point frame |

**A tap target follows the same rule.** `.onTapGesture` attached before `.padding()` responds only on
the content; attached after, it responds on the padded area too. A button whose label is small and
whose padding is outside its gesture is the classic "I tapped it and nothing happened".

Nothing in this section was run for the course. The listings are written from Apple's documentation
for `padding(_:_:)`, `background(_:ignoresSafeAreaEdges:)` and `frame(width:height:alignment:)`, read
on 30 October 2026, and no screenshot is shown, because none was taken.
