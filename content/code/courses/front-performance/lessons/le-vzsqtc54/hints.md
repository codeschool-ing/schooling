---
title: Telling the browser what is coming
version: 1
---

**Every fix in this lesson so far made a file smaller or took it off the critical path. A resource hint
does neither: it tells the browser about something sooner than it would have found out.** There are
four, and one attribute, and they are easy to overuse.

| hint | what it does | when it is right |
|---|---|---|
| `<link rel="preload">` | downloads a file now, with the priority its `as` gives it | a file the page will need early but finds late: a font, as in the section on fonts, or a picture named only in CSS |
| `<link rel="modulepreload">` | the same, for a JavaScript module, which it also parses | the modules the entry script imports; **Vite writes these itself** when a build has more than one chunk, which lesson 8's will |
| `<link rel="preconnect">` | opens the connection to another server now: DNS, TCP and TLS | a server the page will certainly use soon, such as an image CDN |
| `<link rel="dns-prefetch">` | only looks up the name | a server the page may use; it costs almost nothing |
| `fetchpriority` | raises or lowers the priority of one request | the LCP picture, as in the section "The LCP image" |

## The cost of a hint

**A preload is a promise of bandwidth.** It is requested at high priority, ahead of what the browser
found for itself, so preloading something that is not needed early takes the connection away from
something that is. Two rules keep it honest:

- **preload only what the first screen uses.** The planner preloads two fonts because the first
  screen's text is set in them; a font used only in a footer should be found the ordinary way.
- **measure with and without.** A preload that helps on one page can hurt on another, and a page with
  ten preloads has turned the browser's priorities into a list somebody wrote once. Chrome says so in
  its console when a preloaded file is not used within a few seconds of the load.

A preconnect has a smaller cost of the same kind: each one is a connection held open, and a browser
gives up an unused one after a few seconds. A handful, for servers the page will use at once.

## What the planner needs

Nothing more than it has. Its files all come from its own server, so there is nothing to connect to
early; its fonts are preloaded; its picture has its priority. **The hint that is missing from most
pages is not one of these but the HTML itself**: everything the first screen needs, named in the first
response. Lesson 1's server rendering and this lesson's inlined CSS are that, and a hint is what is left
for the files that cannot be.
