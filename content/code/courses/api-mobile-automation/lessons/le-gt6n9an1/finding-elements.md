---
title: How a test finds a button it cannot see
version: 1
---

**A mobile test cannot look at the screen; it asks Android what is on it.** Every element an app
draws is a node in a tree that Android keeps for its accessibility services, the screen readers
and switch controls people use to operate a phone without seeing or touching it. Appium reads
that tree from outside; Espresso walks the app's own views from inside. Either way, a test is only
as reliable as the handle it uses to pick one node out of the tree.

In order of preference, the handles a test can use on Android:

| handle | in the app | in a test | breaks when |
|---|---|---|---|
| **resource id** | `android:id="@+id/refresh"` in the layout | Espresso `withId(R.id.refresh)`; Appium `id`: `example.tickets:id/refresh` | somebody renames the id, which a developer seldom does by accident |
| **content description** | `android:contentDescription="Refresh the list"` | Espresso `withContentDescription(...)`; Appium `accessibility id` | the description is reworded; it is also what a screen reader says |
| **text** | `android:text="@string/refresh"` | Espresso `withText("Refresh")`; Appium by text | the copy changes, or the phone is set to Portuguese |
| **position in the tree** | nothing written | an XPath such as `//android.widget.Button[1]` | anything moves, in any layout, ever |

**The resource id is the first choice**, and it is why every element of the two Tickets screens a
test touches has one: `banner`, `refresh`, `error` and `shows` on the list, `title`, `time`,
`price`, `seats`, `remind` and `remind_denied` on a show. An id is a promise between the people who
build the app and the people who test it, and it does not change when a word does.

**Text is the trap.** `withText("Refresh")` reads naturally and passes on the day it is written. It
fails the day the button becomes *Reload*, or the day the suite runs on a phone set to Portuguese
and the button says *Atualizar*. Text belongs in an assertion (*the banner says Offline*), not in
the handle that finds the banner.

**Position is the last resort**, and `web-automation` will have said the same about XPath on the
web. An XPath that counts buttons describes today's layout; a designer who adds an icon breaks
every test that counted.

## What the tree looks like

Appium asks Android for this tree as XML and searches it, and lesson 15 shows how to ask for it. Each node is
an element with its class, its resource id, its text, its content description and its bounds on
the screen in pixels, so a test that says "the element whose resource id is
`example.tickets:id/refresh`" is asking for exactly one node of it. The resource id carries the
package name in front, `example.tickets:id/`, because two apps on one screen, such as Tickets and
the permission dialog Android draws over it, can each have an element called `refresh`.

## Testability is accessibility

An element with no id, no description and no text is invisible to a test and to a blind person
alike, for the same reason: the tree has nothing to say about it. An icon-only button with no
content description is the commonest case, and the fix is the same line for both. **When a test is
hard to write because an element cannot be found, file it as an accessibility defect**, because it
is one, and that is the argument most likely to get it fixed.
