---
title: Events are attributes
version: 1
---

**In Svelte 5 an event handler is an attribute like any other, named `on` followed by the event:**
`onclick`, `oninput`, `onsubmit`, `onkeydown`. Its value is a function, which the browser calls with
the event when it happens. There is no special syntax to learn beyond that, which is the point: a
handler can be passed as a prop, spread with `{...rest}`, chosen with a ternary, or left out, exactly
as `class` or `href` can.

The planner already uses them. `WeekNav`'s buttons have `onclick={() => onchange(addDays(week, -7))}`,
an arrow function that ignores the event; `CourseList` has the same shape. When the function needs the
event, it takes it as its parameter:

```javascript
function report(event) {
	console.log(event.type, event.currentTarget.textContent);
}
```

and is given by name, `onclick={report}`, or by the shorthand `{onclick}` when a variable of that
name holds it. `event.currentTarget` is the element the handler is on; `event.target` is the element
the event started at, which differs when you click a `<span>` inside a button.

## The ones you will use

| attribute | fires when | typical use in the planner |
|---|---|---|
| `onclick` | a button is pressed, by mouse, touch or keyboard | the week buttons, the course buttons |
| `oninput` | a field's value changes, on every keystroke | what `bind:value` uses underneath |
| `onchange` | a field's value is committed: a checkbox ticked, a date picked | what `bind:checked` uses underneath |
| `onsubmit` | a form is submitted, by its button or by Enter in a field | adding a session, in the next section |
| `onkeydown` | a key goes down, on the focused element or the window | the week shortcuts, in "The keyboard, and the elements that answer it" |

**`onclick` on a `<button>` is also the keyboard handler.** A browser fires `click` on a focused
button when Enter or Space is pressed, so a button needs nothing else to be operable from the keyboard.
That is the main reason the planner's controls are buttons, and it is the property the section on the
keyboard depends on.

## Delegation

Lesson 1's compiled counter registered its click with `$.delegated('click', …)` and a single
`$.delegate(['click'])`. For common events, Svelte puts **one** listener on the root of the application
instead of one per element, and dispatches to the right handler itself. A list of three hundred
sessions with a checkbox each costs one listener rather than three hundred.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A click on one of three buttons, with delegation. The buttons have no listeners of their own; their handlers are stored on the elements. The click bubbles up from the button through its list item and the list to the root of the application, where one listener for click finds the handler stored on the button and calls it. A listener added by hand on the list that stops propagation would stop the click before it reached the root.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the root of the application: one listener for click</text><rect x=\"60\" y=\"100\" width=\"600\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"80\" y=\"118\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">&lt;ul&gt;</text><rect x=\"90\" y=\"140\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;button&gt;</text><text x=\"170\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Linear algebra</text><rect x=\"280\" y=\"140\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;button&gt;</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Spanish</text><rect x=\"470\" y=\"140\" width=\"160\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">&lt;button&gt;</text><text x=\"550\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Guitar</text><path d=\"M370 140 C 370 110, 390 100, 390 74\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></path><line x1=\"390\" y1=\"80\" x2=\"390\" y2=\"72\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"390.0,72.0 393.1,79.4 386.9,79.4\" fill=\"var(--amber)\"></polygon><text x=\"400\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the click bubbles up</text><text x=\"360\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the handler is looked up on the button that was clicked, and called</text></svg>", "caption": "Delegation: one listener at the root instead of one per button. The click has to reach it."}
```

You will not notice delegation until you stop an event on its way up. **`event.stopPropagation()` in
an ordinary `addEventListener` handler on a parent element also stops it reaching the root**, where
Svelte's delegated handlers wait, and a button inside that element then does nothing at all. If you
need to stop propagation, do it in Svelte handlers, which know about delegation, rather than in
listeners added by hand.
