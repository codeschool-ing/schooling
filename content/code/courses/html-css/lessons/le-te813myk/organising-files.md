---
title: Organising the stylesheet
version: 2
---

A stylesheet that grows without a plan ends up with the same button styled in four places and nobody sure which wins. The fix is an **order**, chosen once, in which the general comes before the specific. A common one has six parts, and the lab's `css/` directory follows it:

```
ana@laptop:~/site$ find css -type f | sort
css/base.css
css/components/event-card.css
css/layout.css
css/main.css
css/reset.css
css/tokens.css
css/utilities.css
```

1. **`reset.css`**: the few rules that undo browser defaults nobody wants: `box-sizing: border-box` for everything, lesson 6, no margin on the body, images as blocks.
2. **`tokens.css`**: the custom properties of section 08, and nothing else.
3. **`base.css`**: the default look of plain elements, by type selector only: the body's font and colour, links, headings, lists. No classes.
4. **`layout.css`**: the large shapes, the page grid and the containers that hold things, lessons 8 and 9.
5. **`components/`**: one file per component, each styling only its own class names: the event card, the menu, the order form.
6. **`utilities.css`**: small single-purpose classes that must win wherever they are put, such as the `visually-hidden` class from lesson 7.

The order is also the order of **increasing specificity and increasing reach**: element selectors, then a few layout classes, then component classes, then utilities that override. Written in that order, the cascade mostly works without anybody fighting it, and section 10 makes that order a rule the browser enforces.

## One file or many

`main.css` brings the others in with **`@import`**, and that has a cost the browser shows:

```
ana@laptop:~/site$ probe site.html fetched
main.css
reset.css
tokens.css
base.css
layout.css
event-card.css
utilities.css
```

That is what the page asked for, in order: `main.css` first, then the six files it imports. The browser cannot know about `reset.css` until it has downloaded and read `main.css`, so the imports are found a round trip late, and nothing is drawn until they have all arrived, lesson 1 section 12. On a site served over a network, that delay is real. So **the files are for the people working on the CSS, and the browser should get one file**: in development `@import` is convenient, and for production a build step joins them into one stylesheet. `front-delivery` is where that build is set up. For a small site with one stylesheet, the parts are simply sections of one file, in the same order.
