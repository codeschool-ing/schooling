---
title: Text that means something
version: 1
---

Inside a paragraph, a handful of elements say what a word or a phrase is. Most of them are drawn in a way you would recognise, italic or bold or monospace, and that drawing is a default, just like the size of a heading. The element is chosen for the meaning.

**Emphasis and importance.** `<em>` is stress emphasis, the word you would say louder: *we are open **every** day*. `<strong>` is importance, the part a reader must not miss: a warning, a deadline. Their older cousins `<i>` and `<b>` remain in HTML with narrower meanings: `<i>` for text in a different voice, such as a book title or a word in another language, and `<b>` for a keyword drawn bold with no extra importance. A novel's title in a bookshop listing is `<i>`; *closed on Sunday* in an announcement is `<strong>`.

```html
<p>We are <em>always</em> closed on Sunday.</p>
<p><strong>Orders placed after 5 pm ship the next day.</strong></p>
<p>This week: <i>Grande Sertão: Veredas</i>, first edition.</p>
```

**Dates and times.** `<time>` wraps a date written for people, and its `datetime` attribute carries the same moment written for programs, in a fixed format: `<time datetime="2026-10-08T19:00">Thursday 8 October, 7 pm</time>`. A calendar extension or a search engine reads the attribute; the reader reads the words. The home page's events used it, and the tree marked them as **time**.

**Code, keys and output.** `<code>` for a fragment of code, `<kbd>` for something the user types or a key they press, `<samp>` for what a program printed. This course's own prose is full of the first.

**Quotations.** `<blockquote>` for a quotation set apart as a block, `<q>` for one inside a sentence (the browser adds the quotation marks), and `<cite>` for the title of the work being quoted or referred to.

**Abbreviations and addresses.** `<abbr title="Hypertext Markup Language">HTML</abbr>` expands an abbreviation, although the `title` attribute is not shown to touch or keyboard users, so the first use in the text should still be written out. `<address>` is the contact information of the page's owner or an article's author; it is not for any postal address that appears in the text.

## Line breaks and spacing are not markup

`<br>` is a line break that belongs to the content, such as the lines of a poem or of a postal address. Using several of them to make space between paragraphs puts layout into the HTML, and that is CSS: lesson 6 is about margins. **Empty paragraphs and `&nbsp;` for spacing are the same mistake**, and they also make a screen reader announce blank lines.
