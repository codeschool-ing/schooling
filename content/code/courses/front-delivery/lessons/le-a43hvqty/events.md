---
title: Events across the boundary
version: 1
---

**An element talks back to the page the way a built-in one does: by dispatching events.** `<button>` fires
`click`; `<planner-session>` fires `session-done` when its button is pressed, with the row's id in
`detail`. The page listens for it like any other event, and the demo page's one listener writes the line
under the rows.

```typescript
this.dispatchEvent(new CustomEvent("session-done", { bubbles: true, detail: { id: this.id } }));
```

- **`CustomEvent`** carries data in `detail`, any value at all. Here it is the id, so a page listening once
  on `document` can tell which row was marked.
- **`bubbles: true`** lets the event travel up from the element through its ancestors to `document`. A
  listener on the row itself would work without it; the demo's listener on `document` would never hear it.
- **The name** is the element's own. A lowercase name with a hyphen cannot collide with a future built-in
  event, and it is the form every framework can bind to, as the last section shows.

## Retargeting

The button's own `click` starts inside the shadow tree, and a built-in event like that is **composed**: it
crosses the boundary and keeps bubbling through the page. But a listener in the page that reads
`event.target` gets the `<planner-session>` element, not the button. The browser **retargets** the event
at each boundary it crosses, so the page sees the outermost element it is allowed to see, and the inside
stays private. `event.composedPath()` lists the whole path, shadow tree included, for an open root.

## Why `composed` is not set

`CustomEvent` is not composed unless you ask, so an event dispatched from inside a shadow tree stops at
its root and the page never hears it. This element does not need the option, because it dispatches on
**`this`, the host**, which is already in the page's tree. Had it dispatched on the button,

```typescript
this.#root.querySelector("button")!.dispatchEvent(new CustomEvent("session-done", { bubbles: true }));
```

the event would bubble to the shadow root and stop there, and the demo's line would never change.
`composed: true` would fix that, and would also let the event out of every shadow tree above it, in a page
where the row sits inside another component. Dispatching on the host is the simpler rule: **the host is
the element's public face, so its events start there.**

## Properties first, then the event

The click handler sets `this.done = true` before it dispatches. A listener that reads the row when the
event arrives therefore finds it already done, attribute included, and the test in a later section checks
both in that order.
