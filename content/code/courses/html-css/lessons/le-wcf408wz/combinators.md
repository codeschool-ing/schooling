---
title: Elements by their relations
version: 1
---

Lesson 1 section 05 named the relations in the tree: parent, child, sibling, descendant. **Combinators** are how a selector uses them. There are four:

| combinator | written | means |
| --- | --- | --- |
| descendant | `main p` | a `p` anywhere inside a `main`, at any depth |
| child | `main > p` | a `p` whose parent is the `main` |
| next sibling | `h2 + p` | the `p` immediately after an `h2`, with the same parent |
| subsequent sibling | `h2 ~ p` | every `p` after an `h2`, with the same parent |

The difference between the first two is the one that bites. On the events page:

```
ana@laptop:~/site$ probe events.html match 'main p' match 'main > p'
main p  matches 5
  p.intro  "Everything here is free unless it s…"
  p  "Thursday 8 October, 7 pm."
  p.note  "Bring a poem of your own."
  p  "Saturday 10 October, from 10 am."
  p  "Cancelled: the teacher is ill."
main > p  matches 1
  p.intro  "Everything here is free unless it s…"
ana@laptop:~/site$ probe events.html match 'h2 + p' match 'h2 ~ p'
h2 + p  matches 3
  p  "Thursday 8 October, 7 pm."
  p  "Saturday 10 October, from 10 am."
  p  "Cancelled: the teacher is ill."
h2 ~ p  matches 4
  p  "Thursday 8 October, 7 pm."
  p.note  "Bring a poem of your own."
  p  "Saturday 10 October, from 10 am."
  p  "Cancelled: the teacher is ill."
```

`main p` found **five** paragraphs: the intro, which is a child of `<main>`, and the four inside the articles, which are grandchildren. `main > p` found **one**, the intro, because only its parent is `<main>`; the others have an `<article>` for a parent.

`h2 + p` found the first paragraph after each heading: three, one per article. `h2 ~ p` found every paragraph after a heading inside the same article, so it added *Bring a poem of your own*, which follows the heading with another paragraph in between.

## Reading a selector from the right

A selector is easiest to read backwards. `.event > p.note` is "a paragraph with the class `note`, whose parent is something with the class `event`". The right-hand part, the **subject**, is what gets styled; everything to the left is a condition on its surroundings. Browsers match selectors the same way, from the right, which is why a long chain to the left costs little.

**Keep selectors short.** `main article.event p.note` and `.note` select the same element on this page; the first breaks the day the note moves out of an article, and it is harder to override, for the reason in section 08. A selector should say as much as it needs to pick the right elements, and no more.
