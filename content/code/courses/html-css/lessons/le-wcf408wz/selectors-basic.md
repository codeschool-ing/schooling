---
title: Choosing elements: type, class, id and attribute
version: 1
---

A selector is a pattern, and the browser tests it against every element in the page. Five kinds of simple selector cover most of what you write:

| selector | example | matches |
| --- | --- | --- |
| type | `h2` | every element of that name |
| class | `.featured` | every element whose `class` contains that word |
| id | `#events` | the one element with that `id` |
| attribute | `[href]`, `[type="email"]` | elements with that attribute, or that value |
| universal | `*` | every element |

Here are four of them tested against the events page, `events.html`, with `probe match`, which lists what a selector picks and the start of each element's text:

```
ana@laptop:~/site$ probe events.html match h2 match .featured match '#events' match '[href]'
h2  matches 3
  h2  "Poetry reading: Hilda Hilst"
  h2  "Book swap"
  h2  "Bookbinding class"
.featured  matches 1
  article.event.featured  "Book swap Saturday 10 October, from…"
#events  matches 1
  main#events  "Events Everything here is free unle…"
[href]  matches 2
  link  ""
  a.more  "How the swap works"
```

`h2` found the three event headings. `.featured` found the one article that has `featured` among its classes: `class="event featured"` holds two classes, separated by a space, and the element matches `.event` and `.featured` alike. `#events` found the `<main>`.

**`[href]` found two elements, and one of them is not on the page.** The `<link>` in the head has an `href` too. A selector matches what it says and not what you meant, and this is the first lesson in reading one literally: to mean "links in the page", write `a[href]`.

## Classes are the workhorse

Most CSS selects by class. A class is a name you choose for a kind of thing, `event`, `note`, `featured`, and it can go on any element, any number of times, and combine with others on the same element. An id names exactly one element per page; it is right for a link target like `#events` and too strong for styling, for reasons section 08 counts.

Two selectors written together with no space between them must both match the same element: `p.note` is a paragraph with the class `note`, and `.event.featured` is an element with both classes. Two selectors written with a comma between them are two selectors sharing one block: `h1, h2 { … }` styles both. The space is the next section, and it means something quite different.
