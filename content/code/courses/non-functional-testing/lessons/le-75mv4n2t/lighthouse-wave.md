---
title: Lighthouse, WAVE and the browser's own panel
version: 1
---

axe in a script is one way to run an automated audit. There are three others a tester meets every
week, and **each one is a different window onto mostly the same rules**: Lighthouse, which runs
axe and turns the result into a score; WAVE, which draws its findings on the page itself; and the
accessibility panel in the browser's developer tools, which shows what the browser has told
assistive technology about each element.

## Lighthouse's accessibility category

Lesson 10 ran Lighthouse for performance. The same command, with a different category, runs its
accessibility audits, which are axe rules underneath. The `CHROME_PATH` line lesson 10 added to
`~/.profile` is still in force, and so is `--no-sandbox`, for the reason lesson 10 gave: a test
browser, opening only your own page on this machine.

```
ana@nft:~/a11y$ lighthouse http://localhost:8000/book.html --only-categories=accessibility --output=json --output-path=book.json --chrome-flags="--headless=new --no-sandbox" --quiet
ana@nft:~/a11y$ jq -r ".categories.accessibility.score" book.json
0.55
ana@nft:~/a11y$ jq -r ".audits[] | select(.score == 0) | .id + \": \" + .title" book.json
color-contrast: Background and foreground colors do not have a sufficient contrast ratio.
html-has-lang: `<html>` element does not have a `[lang]` attribute
image-alt: Image elements do not have `[alt]` attributes
label: Form elements do not have associated labels
landmark-one-main: Document does not have a main landmark.
tabindex: Some elements have a `[tabindex]` value greater than 0
```

**55 out of 100**, and six failing audits. Four are the ones `audit.js` found. The other two are
rules `audit.js` left out on purpose, because they are tagged `best-practice` rather than WCAG:
`landmark-one-main`, since the page has no `<main>`, and `tabindex`, which is defect 6. Lighthouse
runs best-practice rules, so on this page it saw one defect more than the WCAG-only script. The
same run against the fixed page:

```
ana@nft:~/a11y$ lighthouse http://localhost:8000/book2.html --only-categories=accessibility --output=json --output-path=book2.json --chrome-flags="--headless=new --no-sandbox" --quiet
ana@nft:~/a11y$ jq -r ".categories.accessibility.score" book2.json
0.9
ana@nft:~/a11y$ jq -r ".audits[] | select(.score == 0) | .id + \": \" + .title" book2.json
landmark-one-main: Document does not have a main landmark.
tabindex: Some elements have a `[tabindex]` value greater than 0
```

**90, from four fixes.** The score is a weighted average of the audits that applied, and it is a
useful thing to watch move. It is a poor thing to set a requirement on. A page at 90 can be
unusable for a keyboard user, and `book2.html` is: the `<div>` that cannot be reached weighs
nothing in the score, because no audit measured it.

The JSON report says so itself. Beside the audits it ran, it lists the ones it could not:

```
ana@nft:~/a11y$ jq -r ".audits[] | select(.scoreDisplayMode == \"manual\") | .title" book2.json
Custom controls have associated labels
Custom controls have ARIA roles
User focus is not accidentally trapped in a region
Interactive controls are keyboard focusable
Interactive elements indicate their purpose and state
The page has a logical tab order
The user's focus is directed to new content added to the page
Offscreen content is hidden from assistive technology
HTML5 landmark elements are used to improve navigation
Visual order on the page follows DOM order
```

**Those ten are Lighthouse's own list of what a person has to check**, and half of them are what
lesson 14 tests by hand: whether the controls take the focus, whether the order makes sense,
whether focus is trapped anywhere. In the HTML report they sit under *Additional items to manually
check*, collapsed, below a green number. That layout is a fair summary of how often they are read.

## WAVE

**WAVE** is WebAIM's evaluation tool: a site, `wave.webaim.org`, where you type an address, and an
extension for Chrome, Firefox and Edge that runs on the page in front of you. It was not run for
this lesson, because it runs in a desktop browser and the lab has none. To try it on the booking
page, start the box office with `BOXOFFICE_HOST=0.0.0.0` as lesson 1 explains, open `book.html`
from the VM's address in your own browser, and press the extension's button. The site version
cannot help here: it fetches the page from WebAIM's servers, and they cannot reach a VM on your
computer.

What makes WAVE different is where it puts the answer. **It draws an icon on the page, next to
each element it has something to say about**, and lists them in a side panel in categories:
errors, contrast errors, alerts, features, structural elements and ARIA. *Errors* are close to
axe's violations. *Alerts* are things WAVE suspects and cannot confirm, such as a link that only
says "click here" or text that looks like a heading and is not marked as one; they are the same
idea as axe's `incomplete`. *Features* and *structure* are the useful surprise: WAVE shows what is
right as well, every `alt`, every label, every heading level, so that a tester can see the page's
outline the way a screen reader moves through it. Its *No Styles* view switches the CSS off and
shows the reading order the markup actually has.

## The developer tools

**Chrome's DevTools have an accessibility pane** in the Elements panel, beside Styles. Select an
element and it shows that element's place in the accessibility tree, its computed role, its
accessible name and where the name came from, and its states. It is the quickest way to answer
"what will a screen reader say this is?" for one element, without a screen reader. Firefox has
the same in its Accessibility Inspector, with a contrast check and a tab-order overlay that draws
numbers over every focusable element. Lessons 14 and 15 capture the same information from a
script, and lesson 15 reads the whole tree.

Lighthouse also has a panel in DevTools, which runs the same audits as the command line above.
None of these were run here, for the same reason as WAVE.
