---
title: Which one, or none
version: 1
---

**The meta-framework to use is almost always the one that belongs to the UI framework you already
use.** Next.js if the app is React, Nuxt if it is Vue, SvelteKit if it is Svelte, and Angular's own
server rendering if it is Angular. Switching UI framework to get a different meta-framework is
rewriting every component, and nothing in this lesson's measurements is worth that on its own.

So ask a different question: does this app need a meta-framework at all?

## When the plain app is enough

The planner of lesson 1 renders on a server, hydrates, and has client-side navigation, with no
framework, in about a hundred lines. That stops being a good idea at a size that is easy to
recognise:

- **many routes with parameters**, each needing its own data before it can render;
- **pages that must work before the script arrives**, forms included, which means handling a form
  post on the server as well as in the browser;
- **a mixture of rendering modes**, some pages built ahead and some per request;
- **more than one person** writing it, who need conventions they did not invent.

Each item on that list is something every meta-framework already does, tested by many more users
than one app will ever have. Below that size, a plain app or a client-rendered one built with Vite
alone is smaller, faster to build, and has nothing in it you did not write. A site with no data at
all, only pages of text, needs neither: lesson 3 builds one from files.

## What to compare, if the choice is open

When a team truly starts from nothing and may choose, these are the things that differ in practice,
in order of how often they decide it:

1. **Where it will be deployed.** Every one of the four runs as a Node server and as static files.
   Some hosts support one of them better, with regeneration, image optimisation or streaming built
   into the platform. `front-delivery` lesson 1 is about four of those hosts.
2. **What the team already knows.** Covered above, and it is usually the answer.
3. **How the framework decides what is static.** The section "Rendering mode, per route" showed one
   that decides from the code and three that decide from configuration. Teams that want to read a
   site's rendering in one place prefer the second.
4. **The weight of the runtime**, measured in the section "The same page, four ways". It matters
   most for pages that are visited once, from a search, on a phone, which is exactly the visitor
   lessons 5 and 6 measure.

## The rest of this course

From lesson 3 on, the plain planner is the app that gets measured and changed, and the four
projects come back only where a technique is something the framework does for you: static
generation and regeneration in lesson 3, hydration and streaming in lesson 4, splitting the code in
lesson 8. Every technique in lessons 5 to 11 works the same whichever of them a site is built with,
because it happens in the browser, in the HTTP headers or in a file the server sends, which is
where the frameworks end.
