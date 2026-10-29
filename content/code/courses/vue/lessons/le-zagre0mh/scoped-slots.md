---
title: Scoped slots
version: 1
---

**A scoped slot is a slot that hands values back to the content filling it.** The child writes props on
its `<slot>` element, and the parent's content receives them. It is how a component that owns the
*structure*, a list, a table, a loop, lets the parent decide how each *item* is drawn, which is the one
thing the scope rule of the section on the default slot otherwise makes impossible.

```html
<!-- src/demos/SessionTable.vue -->
<script setup>
defineProps({ sessions: { type: Array, required: true } })
</script>

<template>
  <ol>
    <li v-for="(session, index) in sessions" :key="session.id">
      <slot name="row" :session="session" :position="index + 1">
        {{ session.id }}
      </slot>
    </li>
  </ol>
</template>
```

```html
<!-- src/demos/ScopedSlots.vue -->
<script setup>
import SessionTable from './SessionTable.vue'

const sessions = [
  { id: 's2', course: 'statistics', minutes: 45, done: true },
  { id: 's5', course: 'guitar', minutes: 20, done: false },
]
</script>

<template>
  <SessionTable :sessions="sessions" />
  <SessionTable :sessions="sessions">
    <template #row="{ session, position }">
      {{ position }}. {{ session.course }}, {{ session.minutes }} minutes {{ session.done ? '(done)' : '' }}
    </template>
  </SessionTable>
</template>
```

```
ana@dev:~/vue/sandbox$ look 'http://localhost:5173/?demo=ScopedSlots'
[vite] connecting...
[vite] connected.
== the text of #app
s2
s5
1. statistics, 45 minutes (done)
2. guitar, 20 minutes
```

**The first table was given nothing and drew its fallback for each row, the id.** The second filled the
`row` slot with a template that receives `{ session, position }` and drew each row its own way. The
`<ol>`, the loop and the key stayed in `SessionTable`; only the inside of each `<li>` came from the
parent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two boxes. On the left, the child SessionTable owns the list element, the loop and each list item; inside each item is a slot. On the right, the parent&#x27;s template for the row slot. An arrow from the slot to the parent carries the slot props, session and position. An arrow back carries the markup the parent&#x27;s template made, which is drawn inside the item.\"><rect x=\"20\" y=\"20\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the child: SessionTable</text><text x=\"40\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;ol&gt;</text><text x=\"55\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&lt;li v-for=\"session in sessions\"&gt;</text><rect x=\"70\" y=\"108\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"185\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">&lt;slot name=\"row\"</text><text x=\"185\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">:session :position&gt;</text><text x=\"55\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/li&gt;</text><text x=\"40\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/ol&gt;</text><rect x=\"420\" y=\"60\" width=\"280\" height=\"130\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the parent's template</text><text x=\"560\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">#row=\"{ session, position }\"</text><text x=\"560\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{{ position }}. {{ session.course }}</text><line x1=\"302\" y1=\"122\" x2=\"418\" y2=\"112\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"418.0,112.0 410.9,115.7 410.4,109.5\" fill=\"var(--amber)\"></polygon><text x=\"360\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">slot props</text><line x1=\"418\" y1=\"160\" x2=\"302\" y2=\"156\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></line><polygon points=\"302.0,156.0 309.5,153.1 309.3,159.4\" fill=\"var(--phosphor)\"></polygon><text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">markup</text></svg>", "caption": "The child keeps the structure and lends the item; the parent draws the item and returns it."}
```

## Reading the syntax

- In the child, **`<slot name="row" :session="session" :position="index + 1">`** binds two slot props,
  exactly like props on a component. They can be any values, including functions.
- In the parent, **`<template #row="{ session, position }">`** receives them as one object, the slot
  props, which the curly braces destructure. Without destructuring it reads `#row="props"` and then
  `props.session`.
- For the default slot of a component that has no other slots, the template can be skipped and
  `v-slot` written on the component itself: `<SessionTable v-slot="{ session }">`. The next section's
  demo does that.

## The scope is still the parent's

The content in `#row` sees two things: the parent's own variables, as any slot content does, and the
slot props the child chose to pass. Nothing else of the child's. The child decides exactly what it
shares, which is the same discipline as a component's emits: a short, named list.

The common use is a list component that handles the hard parts, sorting, loading, an empty state,
paging, keyboard navigation, and lets each page that uses it decide what an item looks like. A table
of sessions on one screen and a list of the same sessions on another can share the component and
differ only in their `#row` templates.
