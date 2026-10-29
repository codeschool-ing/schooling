---
title: The build is the render
version: 1
---

**Static generation renders every page once, while the site is being built, and writes each one to
a file.** From then on a request is answered by handing out that file. No program runs per request,
nothing is read from a database, and the server in front of the files can be the simplest thing a
host offers. It is the third answer to lesson 1's question of where the HTML is made: on your
computer or in CI, before anybody asked.

The usual picture is that static sites are for blogs and documentation, and real apps need a
server. The line is not the kind of site. It is **whether a page can be the same for everybody for
some period**. A course catalogue, a product page, a pricing page and a help article all qualify,
even inside a large app; a page that shows one signed-in person their own data never does.

## What a static page buys

Each item below is something lesson 1 measured or named, now at its cheapest:

- **the first response carries the page**, as with server rendering, so crawlers, link previews and
  a slow phone all get the content at once;
- **the time before the first byte is the time to read a file**, with no rendering in it;
- **any cache can keep it**, because the same address gives the same bytes to everybody, which is
  what lesson 9 builds on;
- **hosting is a folder of files**, which every host serves and many serve for free.

## What it costs

**A static page is a photograph of the data at the moment of the build.** Change the data and the
page is wrong until the site is built again. Every technique after the first two sections of this
lesson is about that one cost: how long a page may be wrong, how much rebuilding it takes to fix
it, and who notices first.

The other cost is the build itself, which renders every page, every time. Three pages take
nothing. A shop with a hundred thousand products takes a long time, and the section "What goes
stale, and what a rebuild costs" measures how the time grows with the number of pages, on the
planner.

## The vocabulary

The same idea has several names, and they are worth separating before the frameworks use all of
them:

| term | what it means here |
|---|---|
| **static generation**, SSG | rendering pages at build time into files |
| **prerendering** | the same, said of one page or route; what the four frameworks call it in their options |
| **regeneration** | rendering a static page again after the build, while the site is running |
| **incremental static regeneration**, ISR | regenerating one page at a time, when it is requested after a set age, and serving the old copy meanwhile |
| **on-demand revalidation** | regenerating because something said the data changed, rather than because time passed |

The two after the first are the reason this lesson exists. They let a page stay a file and still
not be wrong for long.
