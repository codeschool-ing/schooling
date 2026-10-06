---
title: Section and article
version: 1
---

Two elements group content inside `<main>`, and the difference between them is the question to ask before using either.

**`<article>` is content that would make sense on its own**, taken out of the page: a blog post, a news story, a product card, a comment, an event listing. The test is whether you could put it in a feed, an email or another page and it would still be complete. Each event on the bookshop's pages is an article.

**`<section>` is a part of something bigger**: a thematic group of content that would appear in the outline, which is why it should have a heading. The months on the events page are sections: *October* is not a thing on its own, it is a part of the list of events.

Here they are together, with an article inside a section and a header and a footer inside the article:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Events · Andorinha Books</title>
  </head>
  <body>
    <header>
      <p>Andorinha Books</p>
    </header>
    <main>
      <h1>Events</h1>
      <section aria-labelledby="october">
        <h2 id="october">October</h2>
        <article>
          <header>
            <h3>Poetry reading: Hilda Hilst</h3>
            <p><time datetime="2026-10-08T19:00">8 October, 7 pm</time></p>
          </header>
          <p>Three readers, one hour, and a glass of wine afterwards.</p>
          <footer>Free entry. No booking needed.</footer>
        </article>
      </section>
      <section aria-labelledby="november">
        <h2 id="november">November</h2>
        <p>Nothing is planned yet.</p>
      </section>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe sections.html tree
- banner:
  - paragraph: Andorinha Books
- main:
  - heading "Events" [level=1]
  - region "October":
    - heading "October" [level=2]
    - article:
      - 'heading "Poetry reading: Hilda Hilst" [level=3]'
      - paragraph:
        - time: 8 October, 7 pm
      - paragraph: Three readers, one hour, and a glass of wine afterwards.
      - text: Free entry. No booking needed.
  - region "November":
    - heading "November" [level=2]
    - paragraph: Nothing is planned yet.
```

Three things in that tree are worth reading slowly.

**The page's `<header>` became a banner, and the article's did not.** The `<header>` inside the article is just a group with the article's heading and its date in it. Its `<footer>` is the same: *Free entry. No booking needed.* is ordinary text, not a contentinfo landmark. The previous section's rule, made visible.

**The sections became regions only because they have names.** `aria-labelledby="october"` points at the heading's `id`, so the section is named by its own heading, and the tree calls it *region "October"*. Without a name, a `<section>` has no role in the tree at all, and is just a group, which is fine; it then serves the outline only through its heading.

**The headings follow the nesting.** The page's `<h1>` is *Events*, each section opens with an `<h2>`, and the article inside a section has an `<h3>`. Nothing in the elements does that for you: you choose each level for its place, as section 03 said.

## When to use neither

If you are grouping things only so CSS can find them, two cards in a row for example, the element is `<div>`, which says nothing and is right precisely because there is nothing to say. Section 10 is about that. **A `<section>` with no heading is usually a `<div>` that was given a more important-sounding name.**
