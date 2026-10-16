---
title: Where TDD struggles
version: 1
---

**TDD assumes you can say what the code should do before it exists, in an example a machine can
check, in a few seconds.** Where that assumption holds, the method is hard to beat. Where it fails,
forcing the loop costs time and produces tests that say little. Knowing which is which is part of
using it well, and the honest list is longer than enthusiasts admit.

## When you do not know what you want yet

A first attempt at an unfamiliar library, a prototype of a screen, a question like "can SQLite do
this fast enough?": the answer to *what should the test assert?* is the thing you are trying to find
out. Beck's own advice is a **spike**: write throwaway code to learn, without tests, then delete it
and start again test-first with what you learned. The deleting is the part people skip, and a spike
that ships becomes untested code that nobody designed.

## When the right output cannot be written down beforehand

Some results are recognised rather than predicted. A page layout looks right or does not. A
recommendation list is good or poor. A numerical simulation produces a curve whose exact values
nobody knew before running it. You cannot write `assertEqual(result, ...)` first when you do not
know the right-hand side. These areas use other checks instead: a property that must always hold (a
total fine is never negative), a recorded output approved once by a person and compared on every
later run, or a tolerance around a known result.

## When the code has no seams

TDD on new code is pleasant because the tests shape the code. In an old codebase the code is already
shaped, often around globals, hidden clocks and database calls inside loops, the very things the
earlier section on design shows a test pushing out. You cannot write a small failing test for a
function you cannot call on its own. The way in is to pin the current behaviour first, with
characterisation tests, and to cut seams one at a time under their protection. Lesson 14 does
exactly that to a legacy report.

## When the failure does not repeat

A race between two threads shows up once in a thousand runs, on a loaded machine, and never when
you are watching. A test that fails one time in a thousand is not a red step you can act on, and a
green run proves almost nothing. Concurrency needs design that makes the race impossible, which is
lesson 18's subject, more than it needs a cleverer test.

## When the tests are welded to the implementation

The previous section showed one way this happens: mocks that copy the code's assumptions. The
broader shape is a suite that asserts *how* rather than *what*, private methods tested directly,
call counts checked, internal data structures inspected. **Such a suite makes refactoring slower,
not safer**, because every structural change turns tests red without any behaviour having changed.
That is the opposite of what the third step needs.

## What the measurements say

TDD has been studied more than most practices, and the results are mixed in a way that is worth
knowing precisely. In 2008 Nachiappan Nagappan and colleagues followed four teams at Microsoft and
IBM that adopted it. Their pre-release defect density fell by 40 to 90 per cent against comparable
projects, and their managers estimated that development took 15 to 35 per cent longer. Other studies,
many of them with students on small tasks, found smaller effects or none.

One later result explains part of the disagreement. Davide Fucci and colleagues, studying
professionals in 2017, found that the order of writing test and code did not explain the
differences in quality or productivity. What did was working in short, steady steps. Read that
way, the most valuable part of the method may be the rhythm of small verified steps, and the
test-first rule is the most reliable way anyone has found to keep to it.

| where TDD fits | where something else leads |
|---|---|
| domain rules with clear examples: fines, due dates, limits | exploring an unfamiliar library or idea: spike first |
| a bug report, written as a failing test before the fix | layout, visual output: approval and review |
| new code with collaborators you control | legacy code with no seams: characterisation tests first |
| code that will be changed often by several people | races and timing: design them out (lesson 18) |

The left column is most of what a back-end developer writes on an ordinary day, which is why the
method has lasted.
