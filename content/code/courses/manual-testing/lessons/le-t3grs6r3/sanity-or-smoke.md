---
title: Sanity or smoke
version: 1
---

The two words are often used as if they meant the same thing, and some glossaries, older editions
of the ISTQB's among them, list *sanity test* as another name for *smoke test*. Teams that keep
both words apart use them for two different questions, and this course does too, because **a
new build raises both questions and they are answered by different checks**.

## Two questions about a new build

**Smoke asks whether the build is worth testing at all.** It is wide and shallow: the application
starts, the home page loads, the main paths answer. Lesson 8 built a smoke list for boxoffice, and
it runs on every build whatever the build claims to contain, in a few minutes. A smoke failure
stops everything, because there is nothing to test on a build that does not come up.

**Sanity asks whether a specific change did what it claimed.** It is narrow and deeper: it looks at
the fix or the small feature the build was made for, and at what sits right beside it, and at
nothing else. It runs after smoke has passed, and only on a build that claims a change. A sanity
failure sends the build back to the developer before anybody spends a day of regression testing on
it.

The difference shows on one picture, with how much of the application a check touches along one
axis and how hard it presses on each part along the other:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" data-fig=\"l09-depth-breadth\" aria-label=\"Two axes, breadth along the bottom and depth up the side. Smoke is a thin band across the whole width at the bottom: everything, lightly. Regression is a wide block of middle height over the same width. Sanity is a narrow, tall column standing on the place where the change was made.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M90.0 240.0 L650.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 240.0 L90.0 34.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"90.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">depth: how hard each part is pressed</text><text x=\"370.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">breadth: how much of the application</text><rect x=\"100.0\" y=\"125.0\" width=\"540.0\" height=\"115.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">regression</text><text x=\"112.0\" y=\"158.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">does what worked before still work?</text><rect x=\"100.0\" y=\"206.0\" width=\"540.0\" height=\"34.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">smoke</text><text x=\"170.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">does the build come up at all?</text><rect x=\"440.0\" y=\"52.0\" width=\"50.0\" height=\"188.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"502.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">sanity</text><text x=\"502.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">did this change work?</text><path d=\"M465.0 260.0 L465.0 243.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"473.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the change</text></svg>", "caption": "Three checks on one new build. Smoke and regression cover the whole application at different depths; sanity covers one change and its neighbours, more deeply than either."}
```

## Retest, and the step beyond it

The core of a sanity check is a **retest**: the steps from the defect report, run again on the new
build, expecting the result the report said was missing. The ISTQB calls this *confirmation
testing*. A defect report is a script with an expected result already written in it, which is why a
good one makes the retest a matter of minutes, and lesson 15 is about writing it that way.

A retest on its own has a blind spot. **It proves the reported case now passes, and says nothing
about the case one step away**, which is exactly where a hurried fix goes wrong. Lesson 4 found that
boxoffice 1.0 refuses six tickets. A fix that accepts six by removing the upper limit altogether
passes the retest and lets somebody book seven hundred. So a sanity check adds the neighbours of
each fix:

- the boundary on the other side: six is now accepted, so seven must still be refused;
- the other branch of the same rule: a member booking five now gets 15%, so a member booking
  four must still get 10%;
- the other way to the same screen: if the report used curl, the browser too, and if a form and
  a link both reach the page, a glance at both.

That is the whole check. It is usually not written as test cases of its own: the defect report is
the script, and the neighbours are a line or two of notes beside it.

## Where it sits

On a build that claims a fix, the three checks run in an order, and each one decides whether the
next is worth its time:

| order | check | the question | when it fails |
|---|---|---|---|
| 1 | smoke | does the build come up at all? | the build goes back; nothing else runs |
| 2 | sanity | did the claimed change work? | the build goes back with the retest result |
| 3 | regression | does what worked before still work? | a report per failure; the build may still ship |

Smoke takes minutes and sanity takes minutes, while a regression run takes hours or days, and that
is why the cheap questions go first. A team that skips sanity finds out in the afternoon that the
fix never worked, after a morning of regression results on a build nobody is going to ship.

**A passed sanity check is narrow on purpose, and so is what it allows you to say.** It says the
two fixes in boxoffice 1.1 work. It says nothing about the rest of the application, including the
rest of the code the fix touched. That second question is regression testing, and lesson 10 asks
it of the same build.
