---
title: The first rule of ARIA
version: 1
---

**ARIA, Accessible Rich Internet Applications, is a set of attributes that change what the accessibility
tree says about an element.** `role` changes what it is, `aria-label` and `aria-labelledby` change its
name, and the states, `aria-expanded`, `aria-checked`, `aria-current` and the rest, say what condition it
is in. **ARIA changes only what is announced, never what the element does.** A `div` given
`role="button"` is announced as a button and still ignores Enter, as lesson 11 showed.

The W3C's own guide to using ARIA opens with five rules, and the first is the one most worth keeping:

1. **If a native HTML element has the meaning and the behaviour you need, use it** instead of giving
   another element a role.
2. Do not change the meaning of a native element unless you have to: a heading that is also a tab should
   be a heading inside a tab, not a heading given `role="tab"`.
3. Every interactive ARIA control must work from the keyboard.
4. Never put `role="presentation"` or `aria-hidden="true"` on an element that can take the focus, or the
   focus lands on something the reader says does not exist.
5. Every interactive element must have an accessible name.

**No ARIA is better than bad ARIA.** WebAIM checks a million home pages every year, and every year it finds
more detected errors on the pages that use ARIA than on the pages that do not. That is not ARIA's fault; it
is what happens when it is used to patch what the right element would have done for nothing. A wrong
`role` is worse than none, because it makes the reader say something false with confidence.

## What the planner uses, and why

| attribute | where | why it is there |
|---|---|---|
| `aria-hidden="true"` | the back link's arrow | the word says it; the arrow would be read as a symbol's name |
| `role="status"` | the message after adding a session | there is no element whose meaning is *announce this politely*; the next section |
| none | everything else | a `button`, an `a`, a `label`, an `h1` and a `ul` say what they are |

Two attributes in the whole app, and each for something HTML cannot say. That is roughly the right amount.
