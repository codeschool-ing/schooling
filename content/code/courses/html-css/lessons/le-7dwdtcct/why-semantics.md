---
title: Two pages that look the same
version: 1
---

**Semantic HTML** means choosing each element for what the content is, so that the markup says the meaning out loud. The opposite has a name too, **div soup**: a page built out of `<div>` elements with class names, where the meaning lives in the class names and the CSS, and the HTML says nothing at all.

Here is the bookshop's home page written as div soup:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
    <link rel="stylesheet" href="soup.css">
  </head>
  <body>
    <div class="top">
      <div class="logo">Andorinha Books</div>
      <div class="menu">
        <div class="item"><a href="events.html">Events</a></div>
        <div class="item"><a href="order.html">Order a book</a></div>
        <div class="item"><a href="hours.html">Opening hours</a></div>
      </div>
    </div>
    <div class="content">
      <div class="title">This week</div>
      <div class="event">
        <div class="event-title">Poetry reading: Hilda Hilst</div>
        <div>Thursday 8 October, 7 pm. Free entry.</div>
      </div>
      <div class="event">
        <div class="event-title">Book swap</div>
        <div>Saturday 10 October, from 10 am.</div>
      </div>
    </div>
    <div class="bottom">Rua dos Pinheiros, 1000 · São Paulo</div>
  </body>
</html>
```

With a few lines of CSS for the bold and the sizes, it looks like a perfectly reasonable page. Now the same content, with each part in the element that says what it is:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Andorinha Books</title>
  </head>
  <body>
    <header>
      <p class="logo">Andorinha Books</p>
      <nav aria-label="Main">
        <ul>
          <li><a href="events.html">Events</a></li>
          <li><a href="order.html">Order a book</a></li>
          <li><a href="hours.html">Opening hours</a></li>
        </ul>
      </nav>
    </header>
    <main>
      <h1>This week</h1>
      <article>
        <h2>Poetry reading: Hilda Hilst</h2>
        <p><time datetime="2026-10-08T19:00">Thursday 8 October, 7 pm</time>. Free entry.</p>
      </article>
      <article>
        <h2>Book swap</h2>
        <p><time datetime="2026-10-10T10:00">Saturday 10 October, from 10 am</time>.</p>
      </article>
    </main>
    <footer>
      <address>Rua dos Pinheiros, 1000 · São Paulo</address>
    </footer>
  </body>
</html>
```

Open both and you see the same picture. The difference is in what the browser hands to everything else that reads the page. Lesson 1 section 05 introduced the **accessibility tree**, the version of the page that screen readers and other assistive technology use, and `probe tree` prints it. For the soup:

```
ana@laptop:~/site$ probe soup.html tree
- text: Andorinha Books
- link "Events":
  - /url: events.html
- link "Order a book":
  - /url: order.html
- link "Opening hours":
  - /url: hours.html
- text: "This week Poetry reading: Hilda Hilst Thursday 8 October, 7 pm. Free entry. Book swap Saturday 10 October, from 10 am. Rua dos Pinheiros, 1000 · São Paulo"
```

Three links survive, because `<a>` is a link whatever surrounds it. Everything else collapsed into one line of text: the heading, both events and the address, with nothing to say where one stops and the next begins. For the semantic version:

```
ana@laptop:~/site$ probe semantic.html tree
- banner:
  - paragraph: Andorinha Books
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
- main:
  - heading "This week" [level=1]
  - article:
    - 'heading "Poetry reading: Hilda Hilst" [level=2]'
    - paragraph:
      - time: Thursday 8 October, 7 pm
      - text: . Free entry.
  - article:
    - heading "Book swap" [level=2]
    - paragraph:
      - time: Saturday 10 October, from 10 am
      - text: .
- contentinfo: Rua dos Pinheiros, 1000 · São Paulo
```

Now there is a **banner** with the site's name and its **navigation**, named *Main*, holding a list of three links. There is **main**, with a level-1 heading and two **articles**, each with its own level-2 heading. The dates are marked as **time**, and the address sits in **contentinfo**. Every one of those words comes from an element; none of them was written as an attribute.

## What the reader of that tree can do

A screen reader user does not listen to a page from top to bottom any more than you read one that way. They skim: they ask for a list of headings and jump to one, skip straight to the main content, or move from one landmark to the next. On the semantic page that works. On the soup there is one heading-shaped thing in the picture and none in the tree, so there is nothing to skim by.

The soup also has a cost for people who can see it. A search engine weighs headings when it decides what a page is about; a browser's reader mode uses `<main>` and `<article>` to decide what to keep; and the next developer who opens the file has to read the CSS to learn that `.title` is a heading. **Semantic HTML is not extra work added for accessibility.** It is the same number of elements, chosen differently, and the rest of this lesson is how to choose them.
