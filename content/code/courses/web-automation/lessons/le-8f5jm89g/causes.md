---
title: Six causes, each with a case
version: 1
---

**A flaky test has a cause, and the cause is almost always one of six.** The common belief is
that flakiness is weather: the browser was slow, the machine was busy, it happens. Busy machines
are real, but they only matter when something in the test or the page depends on timing that
was never guaranteed. Naming the cause is what turns *it happens* into a fix. Each one below
carries one case from this shop and one from the platform you are studying on, whose own suites
went through every one of them.

| cause | what varies between runs | the shop | the platform |
|---|---|---|---|
| timing | which finishes first, the page or the check | lesson 3's search | a course card read too early |
| shared state | what another test did meanwhile | the one basket | two test packages, one database |
| order | what an earlier test left behind | a basket nobody emptied | screenshots taken in a different order |
| environment | what the machine can reach or has installed | none yet | fonts from a CDN |
| the test itself | a random value or the clock, in the test | lesson 2's card id | a one-in-a-million code |
| the application | the page really behaves differently | the search, typed at 145 ms | the drill's shuffle |

## Timing

The test looks at the page while the page is still on its way somewhere. Lesson 3 is the whole
story for this shop: the test that slept half a second passed, the one that slept a whole second
failed, and the one that read at once found nothing. Each of those verdicts depended on how long
the server took that day.

The platform had the same race in a test that visits every course and checks what the course card
at the foot of the page offers. The interface moves between courses by changing the part of the
address after `#`, which loads no new page: Playwright's `goto` returns as soon as the address has
changed, and the screen is redrawn a moment later. **Read in that gap, the card belongs to the
previous course.** The suite once reported a course with no exam as offering one, because it was
reading the card of the course before it. It had passed in CI on a fixture of a handful of courses,
where the race was won, and lost the race on the real catalogue. The fix waits for the heading to
name the course it asked for, the same move lesson 3 made with `aria-busy`.

## Shared state

Two tests touch the same thing at the same time, and each is right on its own. Lesson 6's
`tests/ssr.spec.js` empties the basket with `POST /api/reset`, adds a banana and expects a count of
1. Lesson 10's `tests/waiting.spec.js` also starts with a reset, adds a mango, and checks only the
message that says so. Each file has one test; `--repeat-each 10` runs each test ten times. With one
worker the twenty runs take turns:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --workers 1 | grep -E '^  [0-9]+ (failed|flaky|passed)'
  20 passed (1.0m)
```

With two workers, two of them run at once against the one basket:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/waiting.spec.js --repeat-each 10 --workers 2 | grep -E '^  [0-9]+ (failed|flaky|passed)|Expected:|Received:'
    Expected: "1"
    Received: "2"
    Expected: "1"
    Received: "2"
    Expected: "1"
    Received: "2"
  3 failed
  17 passed (43.0s)
```

Nothing in either file changed. A count of 2 means the mango landed between the ssr test's reset
and its check. **Passing alone and failing together is the signature of shared state**, and
changing `--workers` is how you see it. Lesson 15 gives each test data of its own, which is the
fix; lesson 19 is about running the suite in parallel on purpose.

The platform met this in its Go tests, which run many packages at once against one database. Two
packages each inserted a school with the same fixed name, `code`, and the unique index let only one
of them in. Which one lost was a matter of timing. It passed on a laptop and then reached CI as a
duplicate key raised in two packages at once. The repository's rule since then is that a test
never seeds a fixed unique value and only asserts about rows it wrote itself.

## Order

A test passes or fails depending on what ran before it. The reset at the top of every basket test
here exists for that reason: lesson 6's `tests/ssr.spec.js` says so in its comment, *the basket is
shared, so every test starts by emptying it*. Without it, a test expecting a count of 1 passes only
when it happens to run first. The reset fixes order; as the capture above shows, it does nothing
for two tests running at the same moment.

The platform's case had nothing to do with a browser. Pictures of terminal programs in its courses
are taken by a tool that opens the program and types at it, and `vim` keeps a file in the home
directory that sends it back to the line you last had open. So each screen depended on which
screens had been taken before it, and in what order. When they all had to be taken again, a check
holding each recipe to its published picture found four wrong recipes, and that file was the cause
nobody had guessed.

## Environment

The same code and the same test give a different verdict on a different machine. The platform's
graph test draws every track at six window sizes and fails if a line crosses a card. It failed on
the build machine at two sizes and on none in the development sandbox. The interface loaded its
fonts from a font CDN: the build machine could reach it and the sandbox could not, so **the two
machines measured the cards in different fonts**. It cost three rounds of guessing before anybody
asked which fonts had loaded. The fonts are now served by the platform itself, and the test still
prints which ones it got on its first line, so the question is answered before anybody has to ask
it. The shop has no such case yet, and `manual-testing` lesson 21 is about environments in general.

## The test itself

The test carries its own randomness or its own clock. Lesson 2's test used a card id copied from
DevTools, and the shop draws a new random id on every load: the test failed on its first run, and
would pass only on the rare load that drew the same number again.

The platform keeps one of these on purpose. A test of the second factor at sign-in enrols with the
code `000000` and expects it to be refused. Every enrolment makes a fresh secret, and `000000` is
the right code for it roughly once in a million, and the comment beside it says a failure there *is a
lottery win rather than a defect*. **A rate that was worked out and written down is a decision.**
A rate nobody measured is what the rest of this lesson is about.

## The application

Sometimes the page itself does different things on different runs, and the test is right to fail
when it does. This is the case where a retry does the most damage, because the flake is the
defect showing.

The platform's accessibility suite checks the practice screen in both of its outcomes, right and
wrong. Which one appeared used to depend on the order in which the questions were shuffled, so a
colour that was too faint on one of them was reported about one run in three and passed the
rest. The suite now asks for each outcome by name, and the defect shows on every run. The shop's
case is the search from lesson 3, typed slightly faster than a person types, and the next section
measures it.
