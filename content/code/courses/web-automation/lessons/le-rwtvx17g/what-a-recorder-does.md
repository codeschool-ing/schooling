---
title: What a recorder writes down
version: 1
---

A recorder watches you use a page and writes down what you did, as a list of steps a machine can
repeat. **The common belief is that the list is a test. It is a transcript of one visit**: what you
clicked, in what order, on the page as it was at that moment. A test is a claim about the shop that
has to hold on every visit, and this lesson is about the distance between the two.

## Three moves, in every recorder

Every recorder this lesson meets does the same three things, whatever it costs and wherever it runs.

- **It listens.** A script the recorder puts into the page hears each click, each key and each
  change of a field, the same events `javascript` lesson 11 attaches listeners to.
- **It names the element.** "A click" is useless until it says on what, so the recorder runs a
  **locator builder**: a ranked list of ways to name an element, from a test attribute or an `id`
  down to a position in the tree. It keeps the first name that finds that element and no other.
- **It saves a step.** A command, the target the builder chose, and a value where there is one,
  such as the text typed into a field.

Replaying is the same list read the other way: find the target, do the command, go to the next
line.

%%FIG pipeline%%

**The weak point is the middle move.** The builder chooses a name on one page, at one moment, by
rules written for every page in the world. Lesson 2 showed what that costs on this shop: Playwright's
own strict-mode error offered `#card-NNNN > button` as a way to find a button, and the number in it
is drawn again every time the shop loads. A recorder meets the same page, and the next two sections
show, from their source code, when it picks a name like that and when it does not.

## What leaves no event

Anything you did without the mouse or the keyboard is missing from the recording, and four of those
things are what make a check into a test.

1. **The state you started from.** You opened a shop with an empty basket. Nothing in the
   recording says it has to be empty, because emptying it was never a click. That is lesson 15's
   subject, and the third section of this lesson runs into it.
2. **What you waited for.** You saw the count change before you clicked again; your eyes did the
   waiting. A recording either replays as fast as the tool can go, or carries a fixed pause that
   somebody added after the first replay went wrong. Lesson 3 measured what a fixed pause buys:
   sleeping one second still read a stale answer.
3. **What you were checking.** A recorder saves an assertion only when you ask for one, from a menu,
   on the element you point at, with the text that element had at that moment.
4. **Why.** "Two fruit make two items" is the reason for the test. The recording has no place for
   it, so it holds a list of clicks and a test name such as `test`.

**None of this makes a recorder useless.** It makes it a fast way to produce a first draft, and the
last section of this lesson says when a draft is all you need.

## Where a recorder sits

Lesson 11 drew browser testing in layers: a runner, a library, a protocol and a browser. A
recorder writes for one of those libraries. Selenium IDE's recordings are replayed through
`selenium-webdriver`, which speaks WebDriver, the protocol of lesson 8; Playwright's recorder writes
Playwright code. BugBug and Ghost Inspector keep the recording in their own service and replay it on
their own browsers, so the layers are theirs and you see only the result.

That makes the comparison in this lesson fair in one direction and not in the other. What the
recording **says** can be read and run here, because the two formats are open. How a vendor's
service **behaves** can only be read about, and the section on those two says so.
