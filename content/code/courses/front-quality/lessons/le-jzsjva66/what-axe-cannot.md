---
title: What no machine can decide
version: 1
---

**An automated check finds what is decidable from the document, and much of accessibility is not.** Deque,
who write axe, measured that their automated rules found about **57%** of the accessibility issues their
auditors found by hand, counted by issue rather than by criterion; by criterion the share is lower, because
many criteria are only partly testable. Either way, a page that passes axe is not therefore accessible,
and a team that treats the green test as the answer has stopped at half.

What axe can decide: a contrast ratio, an image with no `alt`, a field with no label, a button with no
name, a duplicate id, a `role` that does not exist. What it cannot, because the answer is about meaning or
behaviour:

| the question | why a machine cannot answer it | where this course answers it |
|---|---|---|
| does the `alt` say what the image means? | `alt="image"` passes every rule | lesson 12 |
| does the focus move in an order that makes sense? | the order is legal whatever it is | lesson 11 |
| can every control be reached and used by keyboard? | axe looks at the page, it does not press keys | lesson 11 |
| is the focused element visible? | a style removing the outline is valid CSS | lesson 11 |
| is a change on the page announced? | an update nobody hears breaks no rule | lesson 12 |
| does the page still work with animation off, at 200% zoom, at 320 pixels wide? | those are other states of the page | lesson 13 |

**The rest of this course is the second column.** Each of those questions gets a test where a test can
ask it, with Testing Library or Playwright pressing keys and reading the page as assistive technology
reads it, and a manual check where only a person can answer.

## The floor, kept on every page

The platform you are reading this course on runs axe the way this lesson does, with the same five tags,
over every one of its own screens and in both of its colour themes, on every change to its code. Both
themes because contrast is the commonest failure and a dark theme is a different set of colours, which is
lesson 13's subject. And it says, in the same place, what such a check does not find: whether the focus
order makes sense, whether an error is announced, whether a name describes what a control does. **A check
is the floor, not the ceiling.**
