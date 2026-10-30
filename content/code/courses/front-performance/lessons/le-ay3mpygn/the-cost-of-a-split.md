---
title: What a split costs
version: 1
---

**Splitting moves code off the pages that do not need it, and every split has a price.** Three, and
each has shown up already in this course.

## A request, and a chain

Every chunk is a request. A page that loads six chunks makes six requests, and HTTP/2 and HTTP/3, which
carry many requests on one connection, make each one cheap but not free. The real cost is the chain: a
chunk found only when another runs is a round trip after it, as the chart was. **A split that adds a step
to the first page a person sees is a split that made that page slower**, whatever it saved elsewhere.

So the first screen's code stays in the files the HTML names, and what is split off is what that screen
does not draw. When code that loads later is needed in a hurry, the browser can be told early, with
`modulepreload` or with a warning like the last section's.

## Too many small chunks

**A bundler splits where the code says to**, at each `import()`, and at every module that two chunks
share, as `planner` was. A large application with hundreds of `import()` calls can end up with hundreds of
chunks of a few kilobytes each, every one a request with headers and a compression of its own, and
compression works worse on small files. Vite's build options can group modules into chosen chunks, and
the frameworks set their own defaults; the measure is the waterfall, not the count.

## And one thing it buys besides size

**A chunk is cached on its own.** Vite names each file after a hash of its contents, the letters after `chart-` in the build's list,
so a file that did not change keeps its name from one build to the next. Change the home page, and the
chart chunk is the same file, still in every returning visitor's cache. One file for everything would have
changed name, and been downloaded again whole. That is lesson 9's subject, and the reason split files and
long cache lifetimes go together.
