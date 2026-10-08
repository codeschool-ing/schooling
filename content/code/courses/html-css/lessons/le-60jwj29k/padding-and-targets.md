---
title: Padding that makes a target bigger
version: 2
---

Lesson 2 left one axe rule failing on the semantic home page: **target-size**. Each link in the menu was 17 pixels tall, with the next one 18 pixels below, and WCAG 2.2 asks for targets of 24 by 24 pixels, or enough space around a smaller one. That lesson said the fix was padding. Here it is, in `menu.css`, linked from the same page. `menu.html` is lesson 2's `semantic.html` with one line added after its title, `<link rel="stylesheet" href="menu.css">`:

```css
nav ul { list-style: none; padding: 0; }
nav a {
  display: block;
  padding: 12px 0;
}
```

```
ana@laptop:~/site$ probe menu.html axe box 'nav a' tree nav
axe: no violations
a  x 8      y 50     width 1008   height 42
a  x 8      y 92     width 1008   height 42
a  x 8      y 134    width 1008   height 42
- navigation "Main":
  - list:
    - listitem:
      - link "Events":
        - /url: events.html
    - listitem:
      - link "Order a book":
        - /url: order.html
    - listitem:
      - link "Opening hours":
        - /url: hours.html
```

**No violations.** Each link is now 42 pixels tall: the 18 pixels of its line of text plus 12 pixels of padding above and below. Two declarations did it. `padding: 12px 0` grew the box, and the padding is part of the link, so a tap anywhere in it is a tap on the link. `display: block` was needed first, because section 03 showed that an inline box's vertical padding is drawn and pushes nothing away: the links would have overlapped each other's padding. As blocks, they also stretch the full width of the menu, which makes the target wide as well as tall.

`list-style: none` and `padding: 0` on the `<ul>` remove the bullets and the indentation lists have by default, the line lesson 2 promised and one more. The tree after the boxes shows that Chromium still reports a list of three items. Safari is known to drop the list role when the bullets go, and `role="list"` on the `<ul>` is the usual way to keep it there.

## Why padding and not margin

Margin would have spaced the links out just as much, and the space would be dead: a tap between two links would hit neither. **Padding makes the thing bigger; margin moves things apart.** For anything somebody clicks or taps, the bigger target is the kinder one, and for a person with a tremor or a large finger on a small phone it is the difference between hitting the link and hitting its neighbour.

The rest of the page is unchanged: the semantic HTML from lesson 2 and one small stylesheet. That is the division of labour this course started from.
