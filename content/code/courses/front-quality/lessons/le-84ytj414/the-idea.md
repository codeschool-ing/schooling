---
title: Find things the way a person finds them
version: 1
---

**Testing Library is a set of functions for finding elements on a page by what a person perceives:
the role of a control, its name, its label, the text on it.** It does not run tests; Vitest still
does that. It replaces the `querySelector(".tick")` of lesson 2 with
`getByRole("button", { name: "Done" })`, and that one change has two consequences.

The first is the one lesson 1 asked for. A class is an implementation detail and a button's name is
not: rename `.tick` to `.done-button` and a test that asks for *the button called Done* still passes,
because nothing a person sees has changed. **A test written in these queries breaks when the
experience breaks**, and survives the refactoring.

The second is the reason this course puts the library here and not only in a testing course. Every
query reads the page the way assistive technology reads it. `getByRole` asks the **accessibility
tree**, the structure a browser builds for screen readers out of elements, roles and names, and
`getByLabelText` finds a field the way a screen reader announces it. **If a test cannot find a
control by its name, neither can somebody who cannot see the screen.** The tests become a first,
free accessibility check, and this lesson finds a real defect in the planner that way.

## Which query to reach for

The library's own documentation ranks them, and the order is worth learning as it is:

| | query | finds |
|---|---|---|
| 1 | `getByRole` | an element by its role and accessible name: `button` "Done", `link` "JavaScript", `heading` "Study planner" |
| 2 | `getByLabelText` | a form field by the text of its `<label>` |
| 3 | `getByPlaceholderText` | a field by its placeholder, when there is no label, which is itself a problem |
| 4 | `getByText` | an element by the text inside it, for what is not interactive |
| 5 | `getByDisplayValue` | a field by the value it currently holds |
| 6 | `getByAltText` | an image by its `alt` |
| 7 | `getByTitle` | an element by its `title` attribute |
| 8 | `getByTestId` | an element by a `data-testid` written only for tests |

Start at the top and go down only when the one above cannot express what you mean. The last one is
an escape hatch: a person never sees a test id, so a test that needs one is testing something no
person can find either.

## Three prefixes

Each query comes in three forms, and the prefix says what happens when nothing matches:

- **`getBy…`** returns the element, and throws if there is none or more than one. Use it for what
  must be there.
- **`queryBy…`** returns `null` when there is none. Use it, and nothing else, to assert that
  something is **not** there.
- **`findBy…`** returns a promise that waits, retrying, until the element appears, or fails after a
  second. Use it for what arrives later, like data from a server.

Each also has an `…All…` form, `getAllByRole` and so on, that returns a list.
