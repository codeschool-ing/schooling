---
title: What refactoring is, and what it is not
version: 1
---

**"We are refactoring the payments module" usually means somebody is rewriting it, and the
program will not work properly for a fortnight.** That is not refactoring, and the confusion costs
more than vocabulary. Martin Fowler's definition, from the second edition of *Refactoring* (2018),
is narrow on purpose: a change to the internal structure of software that makes it easier to
understand and cheaper to modify, **without changing its observable behaviour**. The program
before and the program after give the same answers to the same questions.

Two consequences follow, and they are what make the definition useful rather than pedantic.

**Refactoring happens in small steps, and the code works after every one of them.** Rename a
variable, run the tests. Pull four lines into a function, run the tests. Each move is small enough
that a mistake is obvious and cheap to undo. A large change is reached as a chain of small ones,
and at any point in the chain you can stop, commit and go home with a working program. That is the
difference from a rewrite, which is a single large step whose result nobody can run until it is
finished.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l14-moves\" aria-label=\"Two ways of reaching the same restructured code, drawn along a time axis. Above, a refactoring: ten small moves such as rename, extract and move, each followed by a dot for a passing test run, so the program works at every point and any dot is a place to stop and commit. Below, a rewrite: one long bar labelled &quot;nothing runs&quot; covering almost the whole time, ending in a cluster of failures at the first run.\"><defs><marker id=\"l14-moves-dp-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"60.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">refactoring: small moves, a passing run after each</text><path d=\"M60.0 70.0 L690.0 70.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"123.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"91.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">rename</text><circle cx=\"186.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"154.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">extract</text><circle cx=\"249.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"312.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"280.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">extract</text><circle cx=\"375.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"438.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"406.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">move</text><circle cx=\"501.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"564.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"532.5\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new class</text><circle cx=\"627.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><circle cx=\"690.0\" cy=\"70.0\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"375.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">any dot is a working program: stop, commit, go home</text><path d=\"M375.0 86.0 L375.0 79.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#l14-moves-dp-ah-paper-dim)\"></path><text x=\"60.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">rewrite: one big step</text><rect x=\"60.0\" y=\"167.0\" width=\"516.6\" height=\"26.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"318.3\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">nothing runs</text><circle cx=\"592.6\" cy=\"180.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"606.6\" cy=\"171.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"606.6\" cy=\"189.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"620.6\" cy=\"180.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"634.6\" cy=\"171.0\" r=\"5\" fill=\"var(--amber)\"></circle><circle cx=\"634.6\" cy=\"189.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"686.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">first run: many failures at once</text><path d=\"M60.0 245.0 L690.0 245.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l14-moves-dp-ah-paper-dim)\"></path><text x=\"690.0\" y=\"258.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Both end with the same code. Only one of them works on every day in between."}
```

**You need a way to know the behaviour has not changed.** In practice that means tests, run after
every move. Without them, a "refactoring" is an edit you hope was harmless. The next section builds
that net around a file that has none, which is the situation refactoring is most needed in.

## Two hats

Kent Beck describes development as wearing one of two hats. With the first, you add behaviour: you
write a new test and make it pass. With the second, you refactor: you change structure and add no
test, because nothing new should happen. **You can swap hats every few minutes, and you never wear
both at once.** A commit that renames half a module and also changes how fines are calculated
cannot be reviewed, and if it breaks something nobody can tell which half did it.

The TDD cycle of lesson 13 is the two hats on a timer: the green step wears the first, the refactor
step the second. Refactoring is not limited to TDD, though. The commonest moment for it is just
before a feature: when the change you need is hard to make in the code as it stands, you refactor
until it is easy, then make the easy change. Beck's version is *make the change easy, then make
the easy change*, with the warning that the first half may be hard.

## Smells: the signals that a move is needed

Beck and Fowler's catalogue names the symptoms before the cures. A **smell** is a surface feature
of code that usually points at a deeper problem: not a bug, and not always wrong, but worth a look.
Each smell has one or two refactorings that usually fix it. This lesson works through the five
below on one legacy file, in this order:

| smell | what it looks like | the usual move | section |
|---|---|---|---|
| long function | one function you have to scroll, doing several jobs | extract function | long-function |
| duplicated code | the same expression or block in two places | extract function, then call it twice | duplication |
| primitive obsession | an `int` that is really money, a tuple that is really a record | replace primitive with object | primitive-obsession |
| data clumps and feature envy | three fields always passed together; a function more interested in another object's data than its own | introduce a class; move function | feature-envy-and-data-clumps |
| repeated switches | the same `if kind == ...` chain in more than one place | replace conditional with polymorphism | switch-on-type |

The catalogue is longer: Fowler's has about two dozen smells and over sixty refactorings. These
five are the ones a back-end developer meets weekly. **A smell is a reason to look, not an order to
act.** A long function that nobody will touch again can stay long; the case for refactoring is
always the next change somebody has to make.

## Why it matters to design

Every pattern in this course is easier to reach by refactoring than to design up front. Nobody
writes the strategy of lesson 6 on day one; they write an `if`, then a second `if`, and at the
third they refactor towards a strategy, because by then they know what varies. **Refactoring is how
a design is allowed to arrive late**, when the problem is understood, instead of being guessed early
and defended afterwards.
