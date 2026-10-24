---
title: Test what the user sees, not how the code does it
version: 1
---

**A good test fails when the planner stops doing its job and passes for as long as it does it,
whatever the code inside looks like.** That sentence decides more about a test suite than the
choice of tool, and it is easy to break without noticing.

Take marking a session done. Here are two tests someone could write, in words:

- *After clicking Done on Thursday's session, the session says "done" and has no button.*
- *After clicking Done, `markDone` was called once with the id 4, and the list item's class is
  `session done`.*

Both pass today. Now rename the class to `is-done` in `view.ts` and `style.css` together, which
changes nothing anybody sees: the second test fails. Then break the click handler so it marks the
wrong session: the first test fails and the second may still pass, if it checks the call and not the
result. **The second test is a description of the current code**, and it fails for refactoring and
passes for bugs, which is the opposite of what a test is for.

## Three habits that follow

**Assert on output, not on calls.** For `planner.ts` the output is a return value, so a test compares
what came back. For `view.ts` the output is what is on the page: text, roles, what a button is called.
Lesson 3 is a library built on exactly this idea, and it is why it finds things by the name a person
would read rather than by a CSS class.

**Pick data that can fail.** A total tested on a week with one session cannot tell adding from copying.
The planner's data puts sessions on the Monday and the Sunday of the week of 19 October and one on
each side of it, so a total for that week is wrong if either end of the week is off by a day. Lesson 2's first test of `weekTotal` is
written against it, and it is not green.

**One reason to fail per test.** A test called *the week's total* that also checks the course list,
the title and the button labels fails for any of them, and its name tells you nothing. Several short
tests with names that are sentences make the failure report read like a list of what is broken.

## And what not to test

Code you did not write is somebody else's to test: that `createElement` makes an element, that Vite
serves `public/`, that `fetch` fetches. A test of those passes forever and slows the suite down.
Test where your decisions are: the rules in `planner.ts`, the wiring in `view.ts`, and the one path
through the browser that proves the pieces meet.
