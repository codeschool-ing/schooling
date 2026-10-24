---
title: What the Vite planner sends
version: 1
---

**Everything the Vite planner shows is drawn in the browser, by JavaScript, after the page has
arrived.** That is *client-side rendering*, CSR, and lessons 1 to 17 never needed a name for it,
because there was nothing to compare it with. Build it and ask its preview server for a course page,
the way a program that runs no JavaScript would:

```
ana@dev:~/vue/planner$ curl -s http://localhost:4173/courses/spanish
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8">
    <link rel="icon" href="/favicon.ico">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Study planner</title>
    <script type="module" crossorigin src="/assets/index-CNeZWQJG.js"></script>
    <link rel="stylesheet" crossorigin href="/assets/index-BWz-O59j.css">
  </head>
  <body>
    <div id="app"></div>
  </body>
</html>
```

**The whole answer is the empty `<div id="app">` and a script.** It is the same for every address, as
lesson 17 showed, and the course, the sessions and the totals exist only once `index-….js` has been
downloaded, parsed and run, and has fetched `courses.json` in turn. A browser with JavaScript turned
off sees exactly that:

```
ana@dev:~/vue/planner$ look http://localhost:4173/ --no-js --text body
== the text of body
```

Nothing at all. Few people turn JavaScript off, so that is not the cost. The costs are three:

- **Time to the first word.** Until the script has run, the page is blank. On a fast computer that is
  a fraction of a second; on a cheap phone on a slow network, the 47 kB of lesson 17's bundle and
  then the data are seconds of white screen.
- **Programs that read pages without running them.** A link pasted into a chat is turned into a
  preview by a program that reads the HTML; so is much of what a search engine sees first. Both find
  the empty `<div>`.
- **Nothing is drawn if the script fails.** An error at start-up, or a blocked file, and the reader
  gets the blank page and nothing else.

None of it matters much for the planner, a tool used every day by the person whose data it holds.
It matters a lot for a page whose job is to be found and read, a course description, an article, a
shop. The rest of this lesson is the other ways of making a page, and what each one trades.
