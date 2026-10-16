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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 318\" role=\"img\" aria-label=\"Four boxes in a row. The page: a click on the banana's button, which is an event and nothing more. The recorder's script listens in the page and hears the click on this element at this moment. The locator builder tries names in order, test attribute, id, name, CSS path, XPath by position, and keeps the first that is unique. The saved step: command click, target css=#card-4821 &gt; button, value empty, one line of the file. A dashed arrow returns from the saved step to the page: replay finds the target, does the command and goes to the next line. Below, a dashed box lists what is never an event and so never in the recording: the empty basket, what you waited for, what you checked, and why.\"><rect x=\"10\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"95.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the page</text><text x=\"95.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a click on the</text><text x=\"95.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">banana's button</text><text x=\"95.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\"></text><text x=\"95.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an event, nothing more</text><path d=\"M180 115.0 L198 115.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M198 115.0 L191.6 117.7 L191.6 112.3 Z\" fill=\"var(--wire)\"></path><rect x=\"200\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"285.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the recorder's script</text><text x=\"285.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">listens in the page</text><text x=\"285.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">hears: click</text><text x=\"285.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">on this element</text><text x=\"285.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">at this moment</text><path d=\"M370 115.0 L388 115.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M388 115.0 L381.6 117.7 L381.6 112.3 Z\" fill=\"var(--wire)\"></path><rect x=\"390\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"475.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the locator builder</text><text x=\"475.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tries names in order:</text><text x=\"475.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">test attribute, id,</text><text x=\"475.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">name, CSS path,</text><text x=\"475.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">XPath by position;</text><text x=\"475.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">keeps the first that is unique</text><path d=\"M560 115.0 L578 115.0\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M578 115.0 L571.6 117.7 L571.6 112.3 Z\" fill=\"var(--wire)\"></path><rect x=\"580\" y=\"40\" width=\"170\" height=\"150\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"665.0\" y=\"62\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the saved step</text><text x=\"665.0\" y=\"88\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">command: click</text><text x=\"665.0\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">target: css=#card-4821 &gt; button</text><text x=\"665.0\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">value: (empty)</text><text x=\"665.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one line of the file</text><path d=\"M665 190 L665 218 L95 218 L95 194\" stroke=\"var(--wire)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M95 200 L95 192\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><path d=\"M95 192 L97.7 198.4 L92.3 198.4 Z\" fill=\"var(--wire)\"></path><text x=\"380\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">replay: find the target, do the command, next line</text><rect x=\"10\" y=\"238\" width=\"740\" height=\"70\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-dasharray=\"5 4\"></rect><text x=\"380\" y=\"260\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">never an event, so never in the recording</text><text x=\"102.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the empty basket</text><text x=\"287.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what you waited for</text><text x=\"472.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">what you checked</text><text x=\"657.5\" y=\"286\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">why</text></svg>", "caption": "A recorder in three moves. Everything it saves passes through the locator builder, and everything that matters to a test without passing through the mouse is left below the line."}
```

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
