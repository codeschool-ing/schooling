---
title: Pyramid, cone and trophy
version: 1
---

Three drawings get named whenever a team argues about its tests, and `testing-cicd` lesson 1
introduces all three for a Python project. **Each one is a claim about where the money should go**,
and here the question is narrower: what each says about the layer at the top, the one with the
browser in it.

## The pyramid

Mike Cohn drew the test automation pyramid in *Succeeding with Agile* (2009): a wide base of unit
tests, a middle layer he called service tests, and a thin top of tests through the user interface.
**Its claim is about cost per test**, and it is the claim the previous section measured. A check
that can live lower should, because lower is faster, fails for fewer reasons, and points closer to
the cause.

The usual misreading is that the pyramid fixes a ratio. A post on the Google Testing Blog in 2015
suggested a split of 70, 20 and 10 per cent as a place to start, and the numbers travelled further
than the words around them. **The drawing says the top is narrow; it does not say how narrow.**
Nothing in it tells you whether quitanda wants three browser tests or thirty.

## The ice-cream cone

The pyramid upside down: a few unit tests, some service tests, a wide band of browser tests, and a
scoop of manual testing on top. Alister Scott named it around 2012 as a picture of what to avoid,
and it is what a suite turns into when automation starts after the code is written and the only
door into the product is the screen.

**The cone is a description, not a strategy**: nobody argues for it. Its cost is the one this lesson
measured, paid on every test. A suite of browser tests runs the browser for every check, including
the checks of arithmetic, and the defect in `total()` from two sections back is exactly the kind it
handles badly. The browser test went green on it because it bought one banana.

It is worth recognising for a reason that has nothing to do with blame. **This course has built
one.** Nearly every test you saved since lesson 1 drives a page, because the course is about the
browser layer. A handful in lessons 4, 6 and 15 speak only HTTP, and `unit/total.test.js` is the
first that runs no server at all. That is right for a course on browser automation and wrong for a
product's suite, and the difference is the point of this lesson.

## The trophy

Kent C. Dodds drew the testing trophy in 2018 for JavaScript front ends: a base of static checks
(types and linting), a small layer of unit tests, a **wide band of integration tests**, and a small
cup of end-to-end tests on top. Its argument is that in a front end most defects live in how pieces
fit together, so the band that tests pieces together buys the most confidence per second.

Read carefully, the trophy agrees with the pyramid about the top. Its integration tests render
components in a DOM written in JavaScript, jsdom, which lesson 11 met: no layout, no paint, no real
browser. **The cup of end-to-end tests is small in the trophy too.** Where the two disagree is the
middle, and that is a disagreement about where a product's defects tend to live.

## What the evidence here supports

The two defects of this lesson do not pick a winner, and it would be dishonest to make them. One
lived in a rule (the arithmetic) and the cheapest layer pinned it. The other lived in the seam
between the page and the server (cents shown as reais), and only the layer that crosses that seam
saw it. A product whose defects are mostly of the first kind wants a wide base. One whose defects
are mostly of the second wants a wide middle, and a front end that is mostly glue is that product.

**What every shape agrees on is the top**, and that agreement rests on the measurement, not on the
drawing: the browser layer cost the most per test, and nothing on quitanda will change that. So the
question that matters for a browser tester is not which shape to hang on the wall. It is which
checks have earned a place at the top, and that is the next section.
