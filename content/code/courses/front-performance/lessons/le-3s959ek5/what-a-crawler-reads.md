---
title: What a crawler reads
version: 1
---

**A program that reads your page without running its scripts sees exactly what `look.ts --no-js`
printed.** For the client-rendered planner that is nothing; for the server-rendered one it is the
whole page. Which programs those are, and how much it matters, is less settled than it is often
made to sound, so this section separates what is documented from what is folklore.

## Search engines

The folklore is that search engines cannot index a client-rendered site. **Google's documentation
says Googlebot does run JavaScript**: it fetches the page, puts it in a queue for rendering, renders
it with a recent Chromium, and indexes the result. What the same documentation also says is that
the rendering is a second step that can come later than the first fetch, and that server-side
rendering or pre-rendering is still a good idea, because it makes the site faster for people and
for crawlers. Other search engines document less, and a crawler that does not run scripts sees an
empty `<main>`.

So the honest position is this: a client-rendered page can be indexed by the largest search
engine, and every crawler that reads the first response sees a server-rendered page immediately.
**If being found matters, render on the server or at build time**, and nothing about the page
depends on a crawler's patience.

## Link previews

When a link is pasted into a chat app or a social network, a program on that company's servers
fetches the page and looks for a title, a description and an image to show. These are written as
`<meta>` tags in the `<head>`, usually in the Open Graph vocabulary:

```html
<meta property="og:title" content="Git · Study planner">
<meta property="og:description" content="2 sessions planned this week">
```

**These programs do not run JavaScript.** A preview of a client-rendered page shows whatever the
static `index.html` says, the same for every address on the site. A server-rendered page can put a
title and a description for each address in the response, because it knows which address it is
drawing. The planner's `server.ts` replaces only the `<main>`; doing the same for the `<title>` and
these tags is a second `replace` on the same string.

## Everything else that reads HTML

Screen readers and browser extensions read the page after scripts have run, so rendering location
does not change what they see once the page has loaded. A reading mode, a translation service and
a program saving the page for later may read the first response. And a person on a train going
through a tunnel sees the first response for as long as the script takes. That last reader is the
one the next section measures.
