---
title: Parts that are not elements: pseudo-elements
version: 1
---

A **pseudo-element** selects a part of an element, or adds one, that has no element of its own in the HTML. It is written with two colons: `p::first-line`. Here are two, in `extras.css`:

```css
.featured h2::before { content: "New: "; color: #8a1c1c; }
.note::first-letter { font-weight: bold; }
```

`::before` and `::after` add a box at the start or the end of the element's content, and **`content`** says what goes in it. Without a `content` declaration, they do not exist. Here the featured event gets the word *New:* in red in front of its heading:

```
ana@laptop:~/site$ probe extras.html style '.featured h2::before' content,color text '.featured h2'
h2::before  content: "New: "
h2::before  color: rgb(138, 28, 28)
h2  "Book swap"
```

The `::before` exists with its content and colour, and **the heading's own text is still only *Book swap***. Generated content is not part of the document: it is drawn, it is not in the DOM, a script reading the heading does not see it, and copying the heading's text does not copy it. Screen readers do read most generated text, and inconsistently. So the rule is that `::before` and `::after` carry **decoration**, such as an icon, a quotation mark or a divider, and never information the reader needs; *New:* is in fact borderline, and a page that must say it should say it in the HTML.

## The rest

`::first-letter` and `::first-line` style the first letter or the first line of a block, which is how a drop capital is made: the note on the events page gets a bold first letter. `::marker` styles the bullet or number of a list item, the marker lesson 2 removed with `list-style: none`. `::placeholder` styles a field's placeholder text, lesson 3's grey hint. `::selection` styles text the reader has selected.

A pseudo-element counts in specificity like an element, which section 08 shows, and it can only be the subject of a selector, at the right-hand end: `.featured h2::before` is fine, `.featured::before h2` means nothing.
