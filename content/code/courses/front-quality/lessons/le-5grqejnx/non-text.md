---
title: Contrast that is not text
version: 1
---

**Text is not the only thing that has to be seen.** 1.4.11 *Non-text Contrast*, level AA, asks for 3:1 against what is next to it for two kinds of thing. One
is a control: the parts that say it is a control, such as a field's border or a checkbox's box, and its
states, such as the focus ring. The other is the part of a graphic needed to understand it, such as the
lines of a chart.

**axe does not measure any of it.** A border, an outline and the stroke of an SVG are not text, and its
`color-contrast` rule only reads text. So 1.4.11 is checked the way this section checks it: by naming each
non-text thing a person must see, and measuring it.

| in the planner | against | ratio, light | ratio, dark | needs |
|---|---|---|---|---|
| the focus ring, `--link` | the page | 5.99:1 | 8.71:1 | 3:1 |
| the fields' and buttons' borders | the page | the browser's own | the browser's own | 3:1 |
| the line between rows, `--line` | the page | 1.36:1 | 1.59:1 | nothing: it separates, it does not identify |

The browser draws the fields and buttons itself, in both schemes, because of `color-scheme`, and WCAG
leaves a control the page has not styled to the browser: its contrast is the browser's responsibility,
not the page's. A stylesheet that restyles them takes the duty over. The line between rows is the interesting case: it fails 3:1 and needs nothing, because a
person who cannot see it loses nothing. Each row is still a row.

## Colour alone

1.4.1 *Use of Color*, level A, asks that colour is never the **only** way something is said. The planner's
done sessions are grey, and they also end in the word *done*; somebody who cannot tell the grey from the
black still reads the word. A link inside a paragraph is the classic failure: a green word among black
ones, with no underline, is a link only to the people who can see green. The planner's links stand on
their own lines and keep the browser's underline, and that is enough.
