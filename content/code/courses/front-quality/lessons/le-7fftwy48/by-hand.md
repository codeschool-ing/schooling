---
title: The walk a person still has to take
version: 1
---

**The tests in this lesson check four things a machine can be told to look for.** They do not know
whether the order *makes sense*, only that it is the one written down; they do not see a focus ring that
is there but the same colour as the page behind it; and they only test the pages they were pointed at.
So once per change to a screen, somebody takes the walk by hand.

## Before the walk: let the browser reach everything

On a Mac, two browsers do not take Tab to links by default. **Safari** skips links unless *Press Tab to
highlight each item on a webpage* is ticked in Safari's settings, under Advanced; Option+Tab reaches them
either way. **Firefox** on macOS follows the system's *Keyboard navigation* setting, in System Settings,
under Keyboard. Chrome reaches links as it is. On Windows and Linux every browser does.

## The walk

Put the mouse out of reach and go through each screen:

1. **Tab from the address bar to the end of the page.** Every control is reached, each one is visibly
   focused, and the order follows the reading order.
2. **Shift+Tab back to the start.** The same stops in reverse; nothing is reachable in one direction only.
3. **Use each control from the keyboard.** Enter on links and buttons, Space on buttons and checkboxes,
   the arrow keys inside a select or a group of radio buttons.
4. **After every action, find the focus.** It is somewhere that makes sense, never back at the top.
5. **Open whatever opens, and leave it.** Escape closes it, and the focus goes back to what opened it.

For the planner after this lesson, the walk finds one thing the tests do not: Tab crosses the date field
in four presses, which is the browser's decision and fine. Write down what you found and when, so the
next walk can be compared with this one.

## What is still missing

The planner can now be used from the keyboard, and the focus is always visible and always somewhere
sensible. **What a screen reader says at each stop is still wrong in places**: the back link is read as
*left-pointing arrow*, adding a session changes the page in silence, and the page has no landmarks to
jump between. That is lesson 12.
