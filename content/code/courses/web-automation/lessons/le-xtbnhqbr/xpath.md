---
title: "XPath: walking the tree in any direction"
version: 1
---

**XPath is a language for paths through a tree**, written for XML and understood by every browser
for HTML too. It reads like a path to a file: steps separated by slashes, each step a tag, and
conditions in square brackets. Where CSS can only look down from the element it starts at, XPath
can step to a parent, an ancestor or a sibling, and it can compare **text**. That is the one thing
it does that CSS cannot, and it is also where most of its breakages come from.

## The pieces

| expression | means |
|---|---|
| `//li` | every `li`, at any depth |
| `/html/body/main` | from the root, one child at a time |
| `//li[h2="Mango"]` | an `li` with an `h2` child whose text is `Mango` |
| `.` | the node's whole text, its descendants' included |
| `text()` | only the node's own text nodes, one at a time |
| `contains(., "Man")` | true when the first string contains the second |
| `..` or `parent::*` | one step up |
| `ancestor::li` | any `li` above, at any height |
| `following-sibling::button` | a `button` after this node, under the same parent |
| `[2]` | the second, counted among the siblings the step selected |

`count.mjs` passes any string that starts with `//` to Playwright as XPath. One that starts with a
bracket has to say so with `xpath=` in front, or Playwright reads it as CSS.

## Up, across and by text

```
%%CAP count-xpath%%
```

All four find one element, and each finds it through the word *Mango*. The first is the heading
itself. `//li[h2="Mango"]//button` is the sentence CSS could not write: the button inside the card
whose heading says Mango. The last two take other routes to the same place, from the heading
**across** to its sibling button, and from the buttons **up** to the one card around them that
has that heading.

That is the case for XPath, and it is narrower than it used to be. In Playwright you seldom need
it, because Playwright's own locators filter by text and chain, as the last reading section of this
lesson shows. In Selenium, which lesson 8 adds to the project, XPath is still the usual way to
find an element by its text.

## Why it breaks

The same power makes expressions that break, or that match the wrong thing, for reasons nobody
would guess from reading them:

```
%%CAP count-xpath-brittle%%
```

- **`//p[text()="R$ 5,90"]` finds nothing**, and the screen shows that price. Two reasons, both
  invisible: the space after `R$` is the non-breaking one, and the price's own text node is
  `R$ 5,90` followed by an ordinary space, because the `small` begins after it. `text()` compares
  that string exactly, character by character;
- **`//p[contains(., "5,90")]` finds two.** The Banana's `R$ 5,90` and the Cashew fruit's
  `R$ 15,90`, which also contains `5,90`. Loosening the comparison fixed the first problem and
  bought a worse one: the expression is now correct only while no other price contains those
  four characters, which is not something anybody checks when prices change;
- **`/html/body/main/ul/li[1]/button` finds the Banana's button**, and it names every tag from the
  root down, and a position. Wrap the list in a `div` and it finds nothing. This is the shape Chrome's
  **Copy full XPath** gives you, on the element's right-click menu in the Elements panel, and it
  is the shape to rewrite before it reaches a test;
- **`(//li)[2]//h2` finds Mango because Mango is second.** It says nothing about mangoes.

**An XPath expression that compares text is only as stable as the text**, and it compares more of
the text than the reader of the expression sees. When you do use one, compare the whole of `.`
rather than `text()`, prefer a word that only one element has, and count the matches before
trusting it.
