---
title: Choosing, one page at a time
version: 1
---

**The choice is made per page, by asking who the page is for and how often its content changes.**
Asking it for a whole site produces the two classic mistakes: a marketing site rendered in the
browser, which shows nothing to the visitors it exists to win, and a signed-in tool rendered on the
server for every click, which pays a server for work the visitor's browser would have done for
free.

## Four questions

1. **Will somebody arrive at this page from a search or a shared link?** Then its content belongs
   in the first response: render it on the server or at build time.
2. **Is it the same for everybody?** Then it can be built once and served as a file, which lesson 3
   is about. A page that differs per person has to be rendered per request, on the server or in the
   browser.
3. **How often does it change?** Content that changes once a week can be rebuilt once a week.
   Content that changes every minute either needs rendering per request, or a build that refreshes
   itself, which lesson 3 calls incremental regeneration.
4. **Is it used all day, behind a sign-in?** Then the first load is paid once and every click after
   it matters more. Client rendering, or hybrid with most of the work in the browser, fits.

## The planner, page by page

| page | arrives from a link | the same for everybody | changes | a reasonable choice |
|---|---|---|---|---|
| the home page, with the list of courses | yes | yes, while there are no accounts | when the plan changes | build time, rebuilt when the data changes |
| a course page | yes | yes, while there are no accounts | when a session is added | server, or build time with regeneration |
| the form that adds a session | no, it is part of a course page | yes | never | rendered with its page, made to work by the script |

If the planner grew accounts, every page would start showing one person's sessions, the second
column would become "no" throughout, and build time would stop being an option for any of them.
**The choice follows the data, not the framework.** That is why this lesson came before the
frameworks: lesson 2 shows how each one lets you make the choice per route, and it only helps if you
already know what you are choosing.

## Two things that are not a choice

Whatever you choose, **the page must work when the script is late.** A server-rendered page whose
buttons do nothing for three seconds is a page that looks broken for three seconds, and lesson 4 is
about making that window as short as it can be. And a client-rendered page must show *something*
while it waits: an empty white screen and a frame with the heading and a line that says the
sessions are loading are the same speed, and they are not the same experience. Lesson 5 gives that
difference a number.
