---
title: Which one, for which page
version: 1
---

**The four answers of this lesson are four points on one line, from "decided once, at the build" to
"decided at every request".** Each step along it trades some cost at the build for some cost at the
request, and the page's data decides where on the line it belongs.

| | rendered | wrong for at most | the server does per request | good for |
|---|---|---|---|---|
| static generation | at the build | until the next build | hands out a file | pages that change with a release: help, documentation, a landing page |
| regeneration by age | at the build, then when old and asked for | the age you set, plus one request | hands out a file; sometimes renders one | catalogues, listings, prices that may lag a little |
| regeneration on demand | at the build, then when the data changes | the time between the change and the call | hands out a file; renders after a change | content edited by people, who press a button that can make the call |
| server rendering | at every request | never | renders the page | pages that differ per person, or that must never lag |

## Three questions that place a page

1. **Is it the same for everybody?** If not, it is server rendering, or client rendering, and
   nothing in this lesson applies. A cache of one person's page served to another is a leak, and
   lesson 9 shows the header that prevents it.
2. **How long may it be wrong?** Zero means server rendering. A release cycle means static
   generation. Anything between is regeneration, by age when nobody can say when the data changes,
   on demand when somebody can.
3. **Can whatever changes the data call an address?** An editor's save, a webhook from a payments
   provider, an import job: each can, and then on demand is exact. Data that changes behind the
   site's back, such as a feed read from somebody else's server, can only be caught by an age.

## The planner, placed

The home page and the course pages are the same for everybody while the planner has no accounts,
and they change when the plan does. A person adding a session is the only thing that changes the
plan, and the code that saves the session could make the call. **On-demand revalidation fits the
planner exactly**, with an age of an hour as a safety net in case a call is lost. The day the planner
gets accounts, every page becomes one person's, and all of them move to the last row.

Hosting such a site is the subject of `front-delivery` lesson 1, which deploys a static build and a
server build to four hosts. Lesson 9 of this course is the other half: the cache headers that decide
how long the browser and a CDN keep what the server handed out.
