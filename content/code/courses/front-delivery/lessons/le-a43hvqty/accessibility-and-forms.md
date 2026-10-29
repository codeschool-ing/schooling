---
title: Accessibility and forms
version: 1
---

**The shadow tree is in the accessibility tree like the rest of the page, so an element built from real
HTML elements is mostly accessible for free.** The row's button is a `<button>`: it has the button role,
it is reached with Tab, Enter and Space press it, and a screen reader announces it as *Mark done, button*.
None of that needed a line of code, and all of it would have to be rebuilt by hand on a `<div>` with a
click listener.

What the boundary changes is the part of HTML that works by reference.

## References do not cross

`<label for="x">`, `aria-labelledby="x"` and `aria-describedby="x"` all point at an id, and an id is
private to its tree. A label in the page cannot name an input inside a shadow tree, and a description
inside the tree cannot be pointed at from the page.

There are three answers, in order of preference:

1. **Keep the reference on one side.** Put the label and what it labels in the same tree. The planner's
   button carries its own text, so it needs no reference at all.
2. **Let the host carry the name.** `aria-label` on `<planner-session>` names the host element, and a
   page can write it like any attribute.
3. **Set it from inside.** The element knows what it shows, so it can label its own pieces.

The planner's button shows the third case is not academic. Each row's button is called *Mark done*, so a
screen-reader user tabbing through a week hears the same name twice with nothing to tell the rows apart.
axe does not flag that, since every button has a name. A fix inside `#render` would be a line such as
``button.setAttribute("aria-label", `Mark ${course} ${date} done`)``. The element in this lesson does not have that
line; adding it, with a test that asks for the new name, is a good first change to make to it.

## Focus

A host element is not focusable itself. When an element wraps one input, `attachShadow({ mode: "open",
delegatesFocus: true })` makes focusing the host, by a click on its padding or by `element.focus()`, move
the focus to the first focusable element inside, and lets the page style the host with `:focus-within`.
The row has nothing to delegate to before its button, so it does not use the option.

## Forms

**An `<input>` inside a shadow tree is not part of the page's `<form>`.** Submitting the form leaves it
out, and `form.reset()` does not touch it. An element that is meant to be a form field says so, and takes
part through an object the browser gives it, `ElementInternals`:

```typescript
class PlannerMinutes extends HTMLElement {
  static formAssociated = true;
  #internals = this.attachInternals();

  set value(minutes: number) {
    this.#internals.setFormValue(String(minutes));
    this.#internals.setValidity(minutes > 0 ? {} : { rangeUnderflow: true }, "Plan at least one minute");
  }
}
```

With `formAssociated`, the element can be named by a page's `<label for>`, it submits the value given to
`setFormValue` under its `name` attribute, and `setValidity` makes the form refuse to submit and show the
message, as a built-in field would. This class is an illustration and is not in the library; the planner
has no form of this kind.
