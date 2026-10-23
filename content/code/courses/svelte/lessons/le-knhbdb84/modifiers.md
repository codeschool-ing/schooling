---
title: Modifiers, written as code
version: 1
---

**Svelte 4 had event modifiers, written after a bar: `on:click|preventDefault|once`. Svelte 5 has none,
and each one is now a line of JavaScript in the handler.** The previous section met the most common,
`preventDefault`, as `event.preventDefault()` at the top of `submit`. The rest follow the same idea,
and having them in the handler means everything a handler does is in one place, instead of split
between the handler and its attribute.

| Svelte 4 modifier | what it did | in Svelte 5 |
|---|---|---|
| `preventDefault` | stop the browser's own action | `event.preventDefault()` in the handler |
| `stopPropagation` | stop the event reaching parents | `event.stopPropagation()`, with the delegation caveat of "Events are attributes" |
| `once` | handle the first event only | a handler that removes itself, or a flag the handler checks |
| `self` | only when the element itself was the target | `if (event.target !== event.currentTarget) return;` |
| `capture` | listen on the way down rather than up | the attribute with `capture` on the end: `onclickcapture` |
| `passive` | promise not to call `preventDefault`, for smooth scrolling | the browser already assumes it for touch and wheel listeners on the window and document; elsewhere, `on(…, { passive: true })` from `svelte/events` |
| `trusted` | ignore events made by scripts | `if (!event.isTrusted) return;` |

A small helper covers `once` without repeating yourself, and shows the shape of all of them, a
function that wraps a handler:

```javascript
// once.js: a handler that runs the first time and then does nothing.
export function once(handler) {
	let done = false;
	return (event) => {
		if (done) return;
		done = true;
		handler(event);
	};
}
```

`onclick={once(save)}` reads as clearly as `on:click|once={save}` did, and it is ordinary JavaScript
you can test, read and change.

Two of the rows deserve a sentence each. **`capture` is the one modifier that survived as syntax**,
because it changes how the listener is registered rather than what the handler does; there was no way
to write it inside the handler. And **`passive` mostly no longer matters**: its job was to tell the
browser it could scroll without waiting for the handler, and browsers now assume that for the scroll
and touch listeners where it made a difference.
