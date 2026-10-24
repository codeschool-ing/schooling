---
title: What a keyboard does on a page
version: 1
---

**Everything a page lets somebody do with a mouse, it has to let them do with a keyboard.** That is
criterion 2.1.1 *Keyboard*, level A, and it is the first one in this course with nothing a machine can
check: axe reads the page, and it never presses a key.

The people who need it are more than the people who cannot hold a mouse. A screen reader is driven from
the keyboard, so every blind user of the planner is a keyboard user. So is anyone with a tremor, or using
a switch, a single button that a device turns into *next* and *press*, or speaking commands that are
turned into keys. And so is the developer who does not want to leave the keyboard.

## The keys, and what they are expected to do

| key | what it does |
|---|---|
| **Tab**, **Shift+Tab** | move the **focus**, the one element that receives keys, to the next or the previous element that can take it |
| **Enter** | follows a link; presses a button; in a form, submits it |
| **Space** | presses a button; ticks a checkbox; anywhere else, scrolls the page |
| **arrow keys** | move *inside* one control: between radio buttons, through a select, between the parts of a date |
| **Escape** | closes what was opened: a menu, a dialog, a picker |

**What takes the focus without any help** is a short list: a link with an `href`, a `button`, an `input`,
a `select`, a `textarea`, a `summary`, and anything with a `tabindex` of zero or more. A `disabled`
control does not. Everything else, a `div`, a `span`, an `li`, is skipped by Tab whatever happens when it
is clicked, and that is the root of most keyboard failures.

## The criteria this lesson tests

| criterion | level | it asks |
|---|---|---|
| 2.1.1 Keyboard | A | everything works from the keyboard |
| 2.1.2 No Keyboard Trap | A | the focus can always leave what it entered |
| 2.4.3 Focus Order | A | the focus moves in an order that keeps the meaning |
| 2.4.7 Focus Visible | AA | the focused element can be seen |
| 2.4.11 Focus Not Obscured (Minimum) | AA | the focused element is not hidden behind something else |
| 2.4.13 Focus Appearance | AAA | the indicator is large enough and contrasts enough to be seen |

## Try it first

Before any test, use the planner as somebody without a mouse. Start the dev server, open
`http://localhost:5173/#/course/javascript`, put the mouse aside and press Tab a few times, then Enter on
the **Done** button. Two things go wrong, and you will see the first at once: you cannot tell where you
are. Write down what you notice, because the next four sections turn each finding into a test.
