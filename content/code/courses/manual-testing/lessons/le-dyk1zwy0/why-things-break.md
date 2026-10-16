---
title: Why things that worked stop working
version: 1
---

A change to a program is usually pictured as local: the developer edits the lines that were wrong,
those lines are now right, and the rest of the program is as it was. **If that were true, checking
the fix would be the whole of testing a release**, and lesson 9's sanity check of boxoffice 1.1
would have been enough. It is not true often enough to rely on, and the defect it produces has a
name of its own.

A **regression** is a defect in something that used to work, brought in by a change. **Regression
testing** runs again the tests of what already worked, on the new build, to find those defects.
It is not the retest of lesson 9, which runs the one case that failed before; it runs the cases
that passed before, expecting them to pass again.

## Four ways a change reaches further than its lines

**Shared code.** One function serves many features, and an edit made for one caller changes what
every other caller gets. In boxoffice, `discount` decides the price of every order the theatre
sells: members, large orders, students, everybody. Lesson 5's defect was about one combination,
a member booking five or more, and the fix went into the function all the others pass through.

**A rewrite instead of a patch.** A patch changes one line and leaves the rest alone. A rewrite
says everything again from scratch, and has to restate every case the old code handled, including
the ones nobody remembers asking for. Rui's notes say `discount` was rewritten. Nothing about that
is wrong in itself, and it is exactly the kind of change after which a tester checks every case
the old version handled.

**Assumptions somewhere else.** Other parts of a program were built around how the changed part
used to behave. Before 1.1 the most one order could take from a show was five seats; now it is six.
The seat count never saw an order of six before this release, and nothing in Rui's notes says
anybody looked at it. Most of the time an assumption like this holds; the regression suite is
where somebody checks that it did.

**Nothing in the program changed at all.** A new version of Python, a browser update, another operating
system or a different server can break a program nobody touched. These are regressions too,
because something worked and stopped, and lesson 21 is about the environments that cause them.

And one more, which is common enough to name: **an old defect comes back.** A developer works on a
copy of a file made before the fix, or undoes a change to solve a different problem, and the fix
quietly leaves with it. This is why the retest of every fixed defect joins the regression suite
once it passes, which section 05 of this lesson does for 1.1.

## A regression needs a before

When a case fails on a new build, three different things can be going on, and they are reported
differently:

| the case | on the last build | on this build | what it is |
|---|---|---|---|
| tests something that already existed | passed | fails | a **regression** |
| tests something that already existed | failed, and was reported | fails | a known defect, still open |
| tests something new in this build | did not exist | fails | a new defect, not a regression |

The first row is the one regression testing exists for, and the word says what it needs: an earlier
result. "It fails now" is a finding; "it passed on 1.0 and fails on 1.1" is a regression, and the
difference changes how urgent it is and who looks at it first, because something customers relied on
has just been taken away. So a regression claim is checked against the earlier build when it still
exists, which is why lesson 9 asked you to keep `boxoffice-1.0.py`.

The second row matters as much in practice. Rui's notes list two defects as known and not fixed:
the error page for a tickets field that is not a number, and a used order that can still be
refunded. A regression run on 1.1 meets both of them again and they fail again. **A known failure
is a result to record, and not a defect to report a second time**: the report already exists, and
a second one costs somebody an hour finding out that it is the first.

Section 03 of this lesson decides which cases to run on 1.1, and section 04 runs them.
