---
title: Named slots
version: 1
---

**A component can have several slots, each with a name, and the parent fills each one with a
`<template>` naming it.** The usual case is a frame with more than one place for content: a panel with
a header, a body and a footer, where each part is the parent's to write.

```html
<!-- src/demos/TitledPanel.vue -->
<template>
  <section class="panel">
    <header>
      <slot name="header">Untitled</slot>
    </header>
    <slot />
    <footer v-if="$slots.footer">
      <slot name="footer" />
    </footer>
  </section>
</template>
```

```html
<!-- src/demos/NamedSlots.vue -->
<script setup>
import TitledPanel from './TitledPanel.vue'
</script>

<template>
  <TitledPanel>
    <template #header><h2>This week</h2></template>
    <p>Five sessions planned.</p>
    <template #footer>75 of 195 minutes done</template>
  </TitledPanel>
  <TitledPanel>
    <p>A panel with no header and no footer.</p>
  </TitledPanel>
</template>
```

This time the HTML is the evidence, so `look` prints it:

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=NamedSlots' --html '#app' --text -
[vite] connecting...
[vite] connected.
== the HTML of #app
<div id="app" data-v-app=""><section class="panel"><header><h2>This week</h2></header><p>Five sessions planned.</p><footer>75 of 195 minutes done</footer></section><section class="panel"><header>Untitled</header><p>A panel with no header and no footer.</p><!--v-if--></section></div>
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The NamedSlots demo. On the left, what the parent writes between the first TitledPanel&#x27;s tags: a template named header holding an h2, This week; a paragraph outside any template; and a template named footer holding 75 of 195 minutes done. On the right, TitledPanel&#x27;s three slots: the slot named header, the slot with no name, called default, and the slot named footer. An arrow joins each piece to its slot. Below, the second panel, which filled nothing: its header drew the fallback, Untitled, and where the footer would be there is only a v-if comment.\"><text x=\"145\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the parent writes</text><text x=\"560\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">TitledPanel.vue</text><rect x=\"420\" y=\"30\" width=\"280\" height=\"160\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"20\" y=\"36\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">#header</text><text x=\"145\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;h2&gt;This week&lt;/h2&gt;</text><rect x=\"435\" y=\"36\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot name=\"header\"&gt;</text><line x1=\"272\" y1=\"57\" x2=\"431\" y2=\"57\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"431.0,57.0 423.6,60.1 423.6,53.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"20\" y=\"88\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">outside any template</text><text x=\"145\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;p&gt;Five sessions planned.&lt;/p&gt;</text><rect x=\"435\" y=\"88\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot /&gt;</text><line x1=\"272\" y1=\"109\" x2=\"431\" y2=\"109\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"431.0,109.0 423.6,112.1 423.6,105.9\" fill=\"var(--phosphor)\"></polygon><rect x=\"20\" y=\"140\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"145\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">#footer</text><text x=\"145\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">75 of 195 minutes done</text><rect x=\"435\" y=\"140\" width=\"250\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"560\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">&lt;slot name=\"footer\" /&gt;</text><line x1=\"272\" y1=\"161\" x2=\"431\" y2=\"161\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"431.0,161.0 423.6,164.1 423.6,157.9\" fill=\"var(--phosphor)\"></polygon><text x=\"20\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">second panel, nothing filled:</text><rect x=\"230\" y=\"208\" width=\"210\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"335\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;header&gt;Untitled&lt;/header&gt;</text><rect x=\"460\" y=\"208\" width=\"130\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"525\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;!--v-if--&gt;</text><text x=\"600\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no footer</text></svg>", "caption": "Each template fills the slot it names, the rest goes to default, and an unfilled slot draws its fallback."}
```

**`<template #header>` filled the slot named `header`.** `#header` is short for `v-slot:header`, as `@`
is for `v-on`. Content outside any `<template #…>`, the paragraph, went into the slot with no name,
which is called `default`. The `<template>` element itself leaves nothing on the page.

**The second panel had no header and drew the fallback, `Untitled`. And it had no footer, so it has no
`<footer>` element at all**, only the `<!--v-if-->` placeholder. That is what `v-if="$slots.footer"`
is for: `$slots` holds a function for each slot the parent actually filled, so the panel can ask whether
there is a footer before drawing an empty box with a border around nothing.

## When a slot counts as empty

A fallback is drawn when the parent's content for that slot is empty, and **content that is only a
`v-if` that came out false counts as empty**: it rendered nothing but a placeholder comment. The
planner's panel at the end of this lesson relies on exactly that. It is also where `$slots` can
mislead: `$slots.footer` is truthy whenever the parent wrote a `#footer`, even one whose only content is a
`v-if` that came out false, so the panel would draw an empty footer. For that case the fallback is the
better tool than `$slots`.

## Order and spelling

The order of the `<template>`s in the parent does not matter; the child's template decides where each
slot goes. A slot's name is a plain string, so `#footer` in the parent must match `name="footer"` in the
child exactly. A misspelt slot name fills nothing and warns about nothing: the content just does not
appear, which is the one silent failure of slots. If something you wrote between a component's tags
is missing from the page, compare the names first.
