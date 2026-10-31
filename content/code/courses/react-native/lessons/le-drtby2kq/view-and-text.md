---
title: View and Text
version: 1
---

**Two components carry nearly every screen: `View` is a box, and `Text` is the only place text may
live.** Everything else in this lesson is one of them with a particular job.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-tree\" aria-label=\"The planner's first screen as a tree of components, and what each becomes on Android and on iOS. ScrollView becomes a native scroll view; View becomes a ViewGroup or a UIView; Image becomes an ImageView or a UIImageView; Text becomes a TextView or a UILabel; Pressable becomes a native view that receives touches.\"><defs><marker id=\"l04-tree-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"130\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">your components</text><text x=\"450\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">Android</text><text x=\"620\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">iOS</text><rect x=\"30\" y=\"36\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;ScrollView&gt;</text><path d=\"M200 51 L370 51\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"36\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ScrollView</text><rect x=\"550\" y=\"36\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"51.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIScrollView</text><rect x=\"60\" y=\"78\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"145.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;View&gt;</text><path d=\"M230 93 L370 93\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"78\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ViewGroup</text><rect x=\"550\" y=\"78\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIView</text><rect x=\"90\" y=\"120\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Image&gt;</text><path d=\"M260 135 L370 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"120\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ImageView</text><rect x=\"550\" y=\"120\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIImageView</text><rect x=\"90\" y=\"162\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Text&gt;</text><path d=\"M260 177 L370 177\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"162\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">TextView</text><rect x=\"550\" y=\"162\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UILabel</text><rect x=\"90\" y=\"204\" width=\"170\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"175.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;Pressable&gt;</text><path d=\"M260 219 L370 219\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-tree-ah-paper-dim)\"></path><rect x=\"370\" y=\"204\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"450.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ViewGroup + touch</text><rect x=\"550\" y=\"204\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">UIView + touch</text></svg>", "caption": "Each component in your tree is one native view on each platform, created by Fabric on the main thread."}
```

## View, the box

A `View` is a rectangle that contains other things, lays them out and can be styled: a background, a
border, padding, a size. It becomes an `android.view.ViewGroup` on Android and a `UIView` on iOS. It
has no meaning of its own, which is why a screen reader passes over it unless you give it one; the
`role` prop does that, and the last section of this lesson gives the course list `role="list"`.

**A View lays its children out in a column by default**, top to bottom, which is the opposite of a
`<div>` with `display: flex` on the web. Lesson 5 is about why, and about everything else Flexbox does
here.

## Text, the only home for a string

A `Text` displays a string, and it is the only component that can. It becomes a `TextView` on Android
and a `UILabel` on iOS, and it does things a `View` cannot: it wraps lines, it can be selected, and it
measures itself by its content.

`Text` elements nest, and **nesting is the one place style is inherited in React Native**. An inner
`Text` takes its parent's font and colour and adds its own changes, which is how a bold word sits in
the middle of a sentence:

```tsx
<Text style={{ fontSize: 16 }}>
  This week: <Text style={{ fontWeight: "700" }}>75</Text> of 125 minutes
</Text>
```

The inner `Text` is not a separate box. The whole sentence is one native text view with a bold run in
it, so it wraps as one paragraph and a screen reader reads it as one.

A `View` inside a `Text` is allowed, and rarely worth it; a `Text` inside a `View` is the ordinary case.
What is **never** allowed is the next section's subject.

## Accessible by default, mostly

A `Text` is read aloud by a screen reader as it is. A `View` that holds several `Text` elements is
read as several separate items, and VoiceOver and TalkBack users move through them one at a time.
When a group of texts is one thing, a card with a title and a count, `accessible` on the `View` makes
the screen reader treat it as a single element and read all its text together. The `Pressable` of the
last-but-one section does that by itself, which is part of why it is the right element for a row you
can press.
