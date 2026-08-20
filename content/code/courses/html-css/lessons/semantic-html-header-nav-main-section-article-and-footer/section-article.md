---
title: section, article or div?
---

The most common question in semantic HTML has a short ruler.

- **`<article>`** — it makes sense on its own, outside the page. A post, a news item, a comment, a product card. The test: could you publish this in an RSS feed?
- **`<section>`** — a thematic block **inside** something larger, and one that has a heading. If you cannot give it a heading, it is probably not a `section`.
- **`<div>`** — it means nothing, and that is fine. It is the element for grouping on purely visual grounds: a container that exists only to receive a `display: flex`.

`<div>` is not a defeat. Using `<section>` where all you needed was layout is worse: it creates false semantic structure, and the screen reader announces a region that does not exist.
