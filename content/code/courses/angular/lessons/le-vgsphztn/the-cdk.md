---
title: The CDK, behaviour without a look
version: 1
---

**The CDK is what Material is built from: the behaviours its components share, with no styles of
their own.** A dialog needs an overlay above the page, the focus kept inside it while it is open and
returned when it closes, Escape to close it, and the page behind hidden from screen readers. Material's
dialog gets all of that from the CDK and adds the Material look. An application with its own design
uses the CDK directly, and gets the hard parts right without taking Material's appearance.

| CDK package | gives |
|---|---|
| `@angular/cdk/a11y` | `FocusTrap`, `FocusMonitor`, `LiveAnnouncer`, keyboard navigation of lists |
| `@angular/cdk/overlay` | floating panels positioned against an element: menus, tooltips, pop-ups |
| `@angular/cdk/dialog` | dialogs, with focus trapping and restoring, unstyled |
| `@angular/cdk/drag-drop` | dragging to reorder, with a keyboard alternative to build in |
| `@angular/cdk/layout` | `BreakpointObserver`, to react to the size of the screen |
| `@angular/cdk/table` | a data table's structure, unstyled |
| `@angular/cdk/scrolling` | virtual scrolling, drawing only the rows on screen |

**Accessibility is the part of a control most often left half done**, because it is invisible to
whoever built the control with a mouse and a screen. Focus that escapes a dialog into the page behind
it, a live update nobody announces, a list that only a mouse can reorder: each passes every visual
check. The CDK's a11y package exists so that each of those is solved once, by people who tested it
with screen readers, and not again in every application. The next two sections use two of its
pieces.
