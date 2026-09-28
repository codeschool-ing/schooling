---
title: The edge is not a region
version: 1
---

Content delivery networks advertise hundreds of locations, and the easy conclusion is that a provider
with hundreds of locations has hundreds of places to run your application. **An edge location is not
a region.** It is a small site, often a rack of machines inside somebody else's datacentre or an
internet exchange, placed close to where users are. It does two things well: it keeps copies of
content, and it runs small pieces of code. It does not hold your database, and it does not offer the
catalogue of services a region does.

These sites go by several names: points of presence, edge locations, network locations. AWS's content
delivery network is CloudFront, and the `GLOBAL` value in `ip-ranges.json`, counted earlier in this
lesson, carried 118 blocks labelled `CLOUDFRONT`: addresses that belong to no single region, because
they answer from many places at once.

## What the edge is for

**A cache near the user turns a long trip into a short one**, for anything that is the same for
everybody. An image, a stylesheet, a script, a video segment, a page that does not change per user.
The first request for a file at an edge location goes back to the **origin**, the region where your
application really runs, and the edge keeps the answer. Every later request from users near that
location is answered from the copy, a short trip away, until the copy expires.

Put a number on it with the floor. A user in São Paulo loading a site whose origin is in Virginia
waits at least 76.6 ms for every file the browser has to fetch from the origin, without a cache. If
there is an edge location in São Paulo, the images and scripts come back from the same city, and only what is personal to that user makes the long trip.

**The edge also runs code.** Lesson 8 met Cloudflare Workers, functions that run in Cloudflare's
network locations rather than in a region. They are good at work that needs no data from far away:
redirecting by country, checking a signed token, rewriting a header, choosing which version of a page
to serve. The user's request is handled a short distance from the user, and nothing crosses the
continent.

## What stays in the region

**Your system of record stays in a region**: the database, the queue, the files that are the
business's own truth. Those need what a region has and an edge location does not: zones to survive a
building's failure, durable storage, a place where the data-residency promise of lesson 2 can be kept.
Edge platforms do sell storage of their own, and whether one fits is a question for the vendor courses;
this lesson's point is that the edge is where copies and small code live, not where the truth lives.

That split has a trap in it, and it is the trap from the section on round trips. Code at the edge that
needs the database has to go back to the region for it. Suppose an edge function in Fortaleza handles
a request by querying a database in Virginia five times, one query after another: **the user saved one
short trip and the function spent five long ones.** Measured end to end, that page is slower than if
the request had gone straight to a server beside the database, which would have made its five queries
across a few metres of cable.

So the rule for the edge is the rule for the whole lesson, applied one more time: put the chatty parts
together. Static content and code that needs nothing from far away belong at the edge. Code that
talks to the database many times belongs beside the database, in the region, and the edge's job for
those requests is to pass them along quickly.
