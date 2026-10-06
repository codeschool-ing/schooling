---
title: Testing at every width
version: 1
---

A responsive page has to be checked at more than the width of the screen you build it on. Three habits find most problems.

**Drag the width.** In DevTools, the **device toolbar** (the phone-and-tablet icon, or Ctrl+Shift+M) lets you set the viewport to any width, or drag it. Drag slowly from wide to narrow and watch: the breakpoints are where things move, and the problems are usually just before a breakpoint, where the old layout is at its tightest. The toolbar's device list is a set of shortcuts, not the widths that matter.

**Check 320.** WCAG's success criterion 1.4.10, **Reflow**, asks that content can be read at a width of **320 CSS pixels** without scrolling in two directions, with exceptions such as tables and maps, which is why the table's own scrolling in section 09 is acceptable and the page's was not. The 320 is not a particular phone: it is what a 1280 window becomes when a reader zooms to 400%. A page that works at 320 works for people who zoom, and `probe --width 320 PAGE overflow` is the quick check that this course has been using.

**Check the reader's settings.** Zoom to 200% and look at the text, section 06. Turn on reduced motion and the dark scheme, section 08 and lesson 10. Use the page with the keyboard at a narrow width, where menus and order change.

::: track qa
In `web-automation` these become tests. A test sets the viewport to a list of widths, 320 among them, and at each one asserts what this lesson measured by hand: that the document is no wider than the window, that the menu is reachable, that a sidebar is below the content and not beside it. A screenshot compared against a reference at each width catches the rest, the way this repository's own graph and landing tests do.
:::

::: track frontend
In `front-delivery` the same checks run on every pull request. A breakpoint is easy to break from a file that seems unrelated: a component that gets a fixed width, a table added to a page that never had one. A check at 320 in CI finds it before a reader with a phone does.
:::

::: track *
When a page scrolls sideways, find the element that is too wide before changing anything. In the Elements panel, the widest element is usually a table, a long string, an image with a fixed width, or something with `width: 100vw`, lesson 6 section 10.
:::
