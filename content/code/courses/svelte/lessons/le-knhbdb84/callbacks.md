---
title: Callbacks between components
version: 1
---

**A component tells its parent that something happened by calling a function the parent passed in as
a prop.** That is all a component event is in Svelte 5, and the planner has three of them: `WeekNav`
calls `onchange`, `CourseList` used to call `onselect` before lesson 5 bound it instead, and
`AddSession` calls `onadd`. This section collects the conventions that keep such callbacks easy to
read, because a component's callbacks are most of what its parent needs to know about it.

## Conventions worth keeping

**Name them `on` and a verb**, `onchange`, `onadd`, `onremove`. The name says it is a callback, matches
the event attributes of the previous sections, and reads naturally at the call site:
`<AddSession onadd={add} />`.

**Pass what happened, not the browser's event.** `AddSession` calls `onadd({ date, minutes })`, not
`onadd(event)`. The parent should not have to know that the date lives in an input inside a form inside
the child; if the form one day becomes a dialog, the parent's `add` does not change.

**Make a callback optional when the component is useful without it.** A component that may be used
read-only calls `onchange?.(next)`, so a parent that does not listen is not an error. `WeekNav` without
`onchange` would show a week and its buttons would do nothing, which is a fair reading of "nobody is
listening".

**Let the parent decide.** The callback reports a request; the parent's state changes only if the
parent's function changes it. That is why `AddSession` does not clear the page's sessions, and why
`WeekNav` does not move the week itself: lesson 5's "A prop is not yours to change" was the long
version of this rule.

## Passing every other attribute through

A small wrapper component often wants to accept any attribute its element accepts, handlers included,
without listing them. `Panel` could pass everything it does not use on to its `<section>`:

```html
<script>
	let { title, children, ...rest } = $props();
	const id = $props.id();
</script>

<section aria-labelledby={id} {...rest}>
	<h2 {id}>{title}</h2>
	{@render children()}
</section>
```

Now `<Panel title="…" onkeydown={…} class="wide">` works, and the handler lands on the section, because
in Svelte 5 a handler is an attribute and spreading attributes spreads handlers too. In Svelte 4 that
needed `on:keydown` forwarded by name, one event at a time.

## And from outside the component tree

Two last tools, for code that is not markup:

- **`on(element, type, handler, options)`**, from `svelte/events`, adds a listener the same way the
  compiler does, delegation included, and returns a function that removes it. Use it in an effect
  instead of `addEventListener`, for the reason in "Events are attributes": it plays well with
  delegated handlers.
- **`createEventDispatcher`**, which lesson 4 met in `WeekNav`'s Svelte 4 version, still works and is
  deprecated. New components use callback props.
