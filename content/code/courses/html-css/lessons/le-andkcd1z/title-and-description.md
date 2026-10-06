---
title: The title, the description and what other programs read
version: 1
---

The rest of the head is information for programs that are not the browser window: the tab bar, the search engine, the chat app that turns a pasted link into a preview. None of it is drawn on the page, and all of it is read by somebody. Here is the head of the bookshop's events page:

```schooling-example
{"language": "html", "file": "head.html", "parts": [
 {"code": "<!doctype html>\n<html lang=\"en\">\n  <head>\n    <meta charset=\"utf-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"},
 {"code": "    <title>Events · Andorinha Books</title>", "note": "Shown on the tab, saved as the bookmark's name, read first by a screen reader, and usually the link text in search results. The specific part first: several tabs from one site are told apart by their first words."},
 {"code": "    <meta name=\"description\" content=\"Readings, signings and a monthly swap at a second-hand bookshop in Pinheiros, São Paulo.\">", "note": "A sentence about the page. Search engines often show it under the title, and they rewrite it when they think theirs is better."},
 {"code": "    <link rel=\"icon\" href=\"icon.svg\" type=\"image/svg+xml\">", "note": "The small picture on the tab. An SVG stays sharp at every size a browser asks for."},
 {"code": "    <link rel=\"canonical\" href=\"https://andorinha.example/events\">", "note": "Which address is the real one, when the same page answers at several. Search engines count it once instead of splitting it."},
 {"code": "    <meta property=\"og:title\" content=\"Events at Andorinha Books\">\n    <meta property=\"og:image\" content=\"https://andorinha.example/share.png\">", "note": "Open Graph: the title and picture a chat app or social network shows when somebody pastes the link."},
 {"code": "  </head>\n  <body>\n    <h1>Events</h1>\n  </body>\n</html>"}
]}
```

## The title is the one that matters most

Of all of these, **`<title>` is the only one a page must have**: a document without one is invalid HTML, and the validator in section 11 says so. It is the first thing a screen reader announces when the page opens, and it is how somebody with twenty tabs open finds yours. `probe` reads it the way the browser does:

```
ana@laptop:~/site$ probe head.html title
title: "Events · Andorinha Books"
```

A good title is specific and short. "Events · Andorinha Books" names the page first and the site second, so that three tabs from the same site read *Events*, *Order a book* and *Opening hours* rather than three identical *Andorinha Books…*. A title that says "Home" or "Untitled Document" on every page tells nobody anything.

## Description, icon and the rest

The description does not change how a page ranks. It is what a search result may show under the title, so it is written for a person deciding whether to click: what is on the page, in one sentence. The icon is cosmetic and it is also how people find your tab among twenty. The `canonical` link and the Open Graph properties matter once the site is public and shared, and a page without them still works.

## Where the title of a page comes from in a big site

On a site with hundreds of pages, nobody writes the head by hand: a template writes it, and the title and description are fields somebody fills in for each page. That is worth knowing because the most common defect in real sites is a template that gives every page the same title. It is invisible while you look at one page at a time, and obvious the moment you see a list of tabs or a page of search results.
