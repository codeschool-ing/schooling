---
title: What a smoke test is
version: 1
---

Smoke testing is sometimes described as a few minutes of clicking around a new build to see whether
it feels all right, and sometimes as a small regression suite. Both miss what makes it useful. **A
smoke test is a short, fixed list of checks, run on every new build before any other testing,
that touches each major part of the product once on its main path and answers one question: is
this build stable enough to be worth testing at all?** It does not look for defects in detail. It
looks for the kind of failure that would waste every other test run on the build.

The name is usually traced to hardware: switch a new circuit board on, and if smoke comes out there
is no point measuring anything else. The same idea goes by other names in software teams, a build
verification test or an intake test, and the shape is the same under each of them.

## Wide, shallow and quick

Three properties make a check list a smoke test.

It is **wide**: every major area of the product is touched, because a build that broke one area
completely is not worth a full round of testing even if the rest works. For boxoffice the areas are
the server itself, the list of shows, sign-up, booking and the outbox.

It is **shallow**: each area is touched once, on its main path, with ordinary data. Smoke books two
tickets as a member; it does not try six, or a student, or a show that has closed. Those are cases,
and lessons 4 and 5 are about choosing them.

It is **quick**, measured in minutes by hand and seconds as a script, because it runs on every
build, including the third build of a bad afternoon. A smoke test that takes an hour gets skipped
on exactly the day it was needed.

Its result is a gate rather than a score. All the checks pass, and testing starts; one fails, and
testing waits. Nothing in between.

## What it saves

Picture a build of boxoffice in which booking crashes, and no smoke test. Ana starts where the plan
from lesson 1 says, on risk A, the price. Her first discount case fails at its first step, with an
error page. So does the second, and the third. By the time she sees the pattern she has written
three defect reports about one fault, and Rui has three reports to read and close as duplicates,
which lesson 16 is about.

The same build with a smoke test: a minute after it arrives, the line for booking says `FAIL`, Ana
sends Rui one message with that line in it, and turns to something else until a new build comes.
**Smoke costs a minute on every good build to save an hour on every bad one**, and in a project
with a build a day, bad ones come often enough to pay for it many times over.

## Where it sits in the plan

Lesson 1's plan for boxoffice has an entry criterion, "the build starts and `/health` answers", and
a suspension criterion, "the build does not start, or a quarter of one area's cases fail". A smoke
test is how those two sentences are checked in practice on each build: its first check is the entry
criterion word for word, and a failing smoke run is the clearest case of the suspension criterion
there is. Section 05 of this lesson follows a failed run through it.

Two neighbours are easy to confuse with it. A **sanity test** is narrow and deep where smoke is wide
and shallow: it checks that one specific change, such as a fix, does what it was meant to, and
lesson 9 is about it. A **regression suite** is broad and deep, rerunning the cases that already
passed to find what a change broke, and lesson 10 is about that. Smoke runs before both, because
neither is worth starting on a build that does not come up.
