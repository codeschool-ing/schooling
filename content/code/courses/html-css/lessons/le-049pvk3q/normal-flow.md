---
title: The normal flow, and what static means
version: 1
---

Every page in lessons 1 to 6 was laid out in the **normal flow**: block boxes stacked from top to bottom, each as wide as its container, and inline boxes running along the lines inside them from left to right. A box in the flow takes up space, and the boxes after it start where it ends. Make a paragraph longer and everything below it moves down. That is the behaviour you want for nearly all content, because it is the behaviour of reading.

The default value of the `position` property is **`static`**, and it means exactly that: the box is in the normal flow, where the flow puts it. The four other values take a box out of the flow, entirely or partly:

| value | takes up space? | `top` and `left` are measured from |
| --- | --- | --- |
| `static` | yes | nothing: they are ignored |
| `relative` | yes, where it would have been | where it would have been |
| `absolute` | no | its containing block, section 05 |
| `fixed` | no | the window |
| `sticky` | yes | its scroll container, within its parent |

The properties that do the moving are **`top`**, **`right`**, **`bottom`** and **`left`**, called the **inset** properties. On a static box they do nothing at all. The rest of this lesson is the four values, one at a time, measured.

## The rule worth holding before starting

Positioning is for placing a few boxes relative to others: a badge, a menu that drops down, a notice over the page. **It is not how a page is laid out.** A layout of columns built from absolute boxes with fixed coordinates breaks as soon as a text is longer than expected, a window is narrower, or the reader enlarges the font, because nothing in it makes room for anything else. Lessons 8 and 9 lay pages out with Flexbox and Grid, which keep everything in a flow that adapts; positioning is for what sits on top of that flow.
