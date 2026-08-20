---
title: Metadata that makes a difference
---

The `<head>` does not appear on screen and decides a great deal of what happens there.

- `<meta charset="UTF-8">` — without it, accented characters turn into symbols. It comes first, because the browser needs to know the encoding before interpreting the rest.
- `<meta name="viewport" content="width=device-width, initial-scale=1">` — without it, the phone pretends to be 980px wide and draws the page in miniature. It is the line separating "responsive" from "a desktop page squeezed".
- `<title>` — it goes in the tab, in the bookmark and in the search result.
- `<meta name="description">` — the paragraph the search engine shows under the title.

The *viewport* one hurts most when missing, because the page seems to work on the computer and is born broken on the phone — which is where most visitors are.
