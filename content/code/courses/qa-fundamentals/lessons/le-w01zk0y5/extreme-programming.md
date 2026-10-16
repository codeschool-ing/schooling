---
title: Extreme Programming, the method that made testing a programmer's job
version: 1
---

**Extreme Programming, XP, is an agile method built around engineering practices, and more of them are about
testing than in any other method.** Kent Beck shaped it on a payroll project at Chrysler in 1996 and described
it in *Extreme Programming Explained* in 1999; the second edition, in 2004 with Cynthia Andres, is the one
most teams read now.

Where Scrum says nothing about how to build software, XP says a great deal. Its name comes from taking
practices everybody agreed were good and turning them up as far as they go: if reviewing code is good, review
all of it, all the time; if testing is good, test before writing the code.

## Five values

XP rests on five values: **communication, simplicity, feedback, courage and respect** (the last was added in
the second edition). The one that explains the testing practices is feedback. Every XP practice is a way of
finding out sooner whether something is wrong.

## The practices a tester meets

| practice | what it is | what it does to testing |
|---|---|---|
| **test-first programming** | the programmer writes an automated test before the code that makes it pass | unit checks exist for everything, written by the people who wrote the code |
| **pair programming** | two people at one computer, one typing, one reviewing as it is typed | every line is reviewed while it is written, the cheapest moment there is |
| **continuous integration** | everybody's changes are merged and every check runs several times a day | a regression is found within hours of the change that caused it |
| **ten-minute build** | the whole build and its checks finish in ten minutes | nobody is tempted to skip the checks because they take too long |
| **small releases** | the software reaches its users every few weeks or sooner | real use is feedback too |
| **customer tests** | the customer, with help, writes the tests that say a story is accepted | acceptance criteria become checks that run every day |
| **whole team** | the customer sits with the team, and everyone needed is on it | questions are answered in minutes, not by e-mail next week |

Lesson 15 is entirely about test-first programming, in the form it grew into: test-driven development.

## Feedback in loops

XP's practices nest inside each other, each a loop of a different length, and each catches a different kind of
mistake. The shortest loops catch slips; the longest catch building the wrong thing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 270\" role=\"img\" data-fig=\"l14-loops\" aria-label=\"Six nested loops of feedback in Extreme Programming, from the outside in: release, months; iteration, weeks; customer tests, days; continuous integration, hours; unit tests written test first, minutes; pair programming, seconds. The outer loops catch the wrong thing being built; the inner ones catch a slip in one line.\"><rect x=\"10.0\" y=\"10.0\" width=\"660.0\" height=\"216.0\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"22.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">release</text><text x=\"658.0\" y=\"24.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">months</text><rect x=\"56.0\" y=\"46.0\" width=\"568.0\" height=\"180.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68.0\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">iteration</text><text x=\"612.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">weeks</text><rect x=\"102.0\" y=\"82.0\" width=\"476.0\" height=\"144.0\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"114.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">customer tests</text><text x=\"566.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">days</text><rect x=\"148.0\" y=\"118.0\" width=\"384.0\" height=\"108.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">continuous integration</text><text x=\"520.0\" y=\"132.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">hours</text><rect x=\"194.0\" y=\"154.0\" width=\"292.0\" height=\"72.0\" rx=\"12\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"206.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">unit tests, test first</text><text x=\"474.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">minutes</text><rect x=\"240.0\" y=\"190.0\" width=\"200.0\" height=\"36.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"340.0\" y=\"201.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">pair programming</text><text x=\"340.0\" y=\"214.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seconds</text><text x=\"14.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">← the wrong thing built</text><text x=\"666.0\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">a slip in one line →</text></svg>", "caption": "XP’s practices as loops of feedback. Each one is a way of finding out sooner, and each catches a different size of mistake."}
```

At Cine Aurora, Rafael and Tomás tried XP's practices one at a time. Pairing came first, after the Wednesday
discount: Tomás had reviewed that change on his own a day after it was written, and missed the stacking.
When they paired on the coupon code, Tomás asked "and on a Wednesday?" while Rafael was still typing the line,
and the combination was settled in the five minutes it took to ask Joana.

## Why XP is rarely used whole

Few teams adopt all of XP. Its practices ask a lot of programmers, and some, pairing above all, are hard to
sell to managers who count people at keyboards. What happened instead is that XP's practices spread into
everything else: most Scrum teams use continuous integration, automated unit tests and some form of
acceptance tests without calling any of it XP. A tester is far more likely to meet XP's practices than to meet
a team that says it does XP.
