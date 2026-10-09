---
title: What a control is called
version: 2
---

Every link, button and form field has an **accessible name**: the words a screen reader says when it reaches it, and the words voice-control users say to activate it. The tree printed them in quotes: `link "Events"`, `button "Reserve (button)"`. The browser works the name out from the markup, and most of the time it is simply the text inside the element.

That is why the text inside a link matters so much. Here are three links and two images inside links, in `names.html`. Any small picture saved beside it as `shelf.png` will do:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Events</h1>
      <p>Poetry reading on Thursday. <a href="poetry.html">Click here</a>.</p>
      <p>Book swap on Saturday. <a href="swap.html">Click here</a>.</p>
      <p><a href="poetry.html">Poetry reading on Thursday</a>.</p>
      <a href="shelf.html"><img src="shelf.png" width="60" height="40"></a>
      <a href="shelf.html"><img src="shelf.png" width="60" height="40" alt="Browse the shelves"></a>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe names.html tree axe
- main:
  - heading "Events" [level=1]
  - paragraph:
    - text: Poetry reading on Thursday.
    - link "Click here":
      - /url: poetry.html
    - text: .
  - paragraph:
    - text: Book swap on Saturday.
    - link "Click here":
      - /url: swap.html
    - text: .
  - paragraph:
    - link "Poetry reading on Thursday":
      - /url: poetry.html
    - text: .
  - link:
    - /url: shelf.html
    - img
  - link "Browse the shelves":
    - /url: shelf.html
    - img "Browse the shelves"
image-alt (critical, 1 element): Images must have alternative text
link-name (serious, 1 element): Links must have discernible text
```

## Click here

The first two links are both called **"Click here"**. Read in the flow of the paragraph they make sense; but screen reader users often pull up a list of all the links on a page, and that list reads *Click here, Click here, Poetry reading on Thursday*. Two of the three say nothing about where they go. The third link carries its own meaning: **write the words that say where the link goes, and make those words the link.**

## An image in a link

When a link's only content is an image, the image's `alt` text becomes the link's name. The first image link has no `alt`, so the link has no name at all: the tree prints a bare `link`, and axe reported two rules for that one element, **image-alt** for the image and **link-name** for the link. The second has `alt="Browse the shelves"`, and the link is named by it. Lesson 4 is about `alt` in general; inside a link, the rule is that the `alt` describes **where the link goes**, not what the picture shows.

## When there is no visible text

Sometimes a control has no words on it: a magnifying glass for search, a cross that closes a dialog. Then it needs a name from an attribute: `aria-label="Search"` gives one directly, and `aria-labelledby` points at the `id` of an element whose text should be used, as the sections in section 05 did with their headings. Use them where there is no visible text to name the control with, and not to override text that is there: a button showing *Reserve* and named *Book now* by `aria-label` says one thing to the eye and another to the ear, and voice-control users saying "click Reserve" get nowhere.
