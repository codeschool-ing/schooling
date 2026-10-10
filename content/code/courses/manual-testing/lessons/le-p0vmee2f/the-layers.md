---
title: The layers of testing
version: 1
---

A common belief among people starting in testing is that unit tests are the developers' business,
written in a language the tester does not read, and that nothing about them changes a manual
tester's day. The first half is roughly true. The second is not: **the layers below yours decide
what your manual tests should spend their time on**, and they explain a defect in a way the screen
cannot. This lesson reads them as a tester who will not write them for a living but will work
beside the people who do.

## Four layers, one application

Every layer asks the same question, "does this do what it should?", about a bigger piece of the
program. `qa-fundamentals` named them as levels of the V model; here they are on boxoffice.

**A unit test** checks one small piece on its own: a function, with no server, no browser and no
network. `discount(student, member, tickets)` is the obvious unit in boxoffice. It takes three
facts and returns a percentage, so a test can call it with a student and one ticket and check that
50 comes back. It runs in a thousandth of a second and nothing else has to be running.

**An integration test** checks that pieces work together. Booking in boxoffice involves the form,
the code that reads it, the check on the quantity, the call to `discount`, the arithmetic of the
total and the order page that shows it. A test that posts the form to the running application and
reads the total back crosses all of them, and finds the defects that live in the joins: a field
read under the wrong name, a percentage applied twice.

**A system test** checks the whole application as a user meets it, in a real browser on a real
screen. That is what every lesson of this course has done so far, by hand.

**An acceptance test** asks whether the client can run their business with it. Lesson 12 was
about that, and its criteria were written in the theatre manager's words, not the code's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l13-reach\" aria-label=\"Five boxes in a row, in the order a booking travels: browser, HTTP server, book, which reads the form, discount, which gives the percentage, and the order page. Below them three brackets. The unit test, test_discount.py, covers discount alone. The integration test, test_booking.py, covers everything from the HTTP server to the order page. The system test, a person in a browser, covers all five.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">browser</text><path d=\"M138.0 52.0 L155.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"158.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">HTTP server</text><path d=\"M276.0 52.0 L293.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"296.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"354.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">book</text><text x=\"354.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reads the form</text><path d=\"M414.0 52.0 L431.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"434.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"492.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">discount</text><text x=\"492.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the percentage</text><path d=\"M552.0 52.0 L569.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"572.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">order page</text><path d=\"M438.0 94.0 L438.0 104.0 L546.0 104.0 L546.0 94.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"492.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">unit test</text><text x=\"492.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test_discount.py</text><path d=\"M162.0 146.0 L162.0 156.0 L684.0 156.0 L684.0 146.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"423.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">integration test</text><text x=\"423.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test_booking.py</text><path d=\"M24.0 198.0 L24.0 208.0 L684.0 208.0 L684.0 198.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"354.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">system test</text><text x=\"354.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a person in a browser</text></svg>", "caption": "What each layer of test reaches in boxoffice. The lower the layer, the less it crosses, the faster it runs and the more exactly a failure points at its cause."}
```

## Why the bottom is wide

The usual picture is a pyramid, often credited to Mike Cohn: **many unit tests at the bottom,
fewer integration tests above them, and a few tests through the user interface at the top**. The
shape follows from cost. A unit test of `discount` runs in milliseconds and points at one function
when it fails. A test that drives a browser through sign-up, booking and payment takes seconds,
needs a running server and a browser, breaks when somebody renames a button, and when it fails it
says only that something, somewhere, went wrong.

The shape is advice, not a law, and teams argue about it. What matters for you is the reasoning
behind it: **a check belongs on the lowest layer that can see the problem**. Whether a student
pays half is a rule inside one function, and a unit test is the cheapest place to hold it. Whether
the total shows up on the order page in reais, with a comma, is something only a layer that renders
the page can see.

## What this changes for a manual tester

Three things, none of which needs you to write code.

**You learn what is already covered.** If the developers' unit tests run every row of the
discount table on every change, then your manual time on discounts is better spent on what those
tests cannot see: the order page, the student box on a phone, a member who forgot to confirm.
Asking "what do the unit tests cover?" in a planning meeting is a fair question, and the answer
changes the plan of lesson 1.

**You read a failure more precisely.** A unit test that fails names a function and a line, and a
defect report that can say "the student rule fails in the unit tests too" saves the developer an
afternoon.

**You recognise what a layer cannot catch.** Every unit test of `discount` can pass while the page
shows the wrong total, because the form sends the box under another name. Those defects are the
ones left for the upper layers, and for you.

The next three sections show each layer on boxoffice with a real test file, short enough to read
whole. You are not expected to write one; you are expected to read one, run it, and say what its
result means.
