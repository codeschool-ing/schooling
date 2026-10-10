---
title: JAMstack, where the build is what you test
version: 1
---

**JAMstack** is a name for a way of delivering a site: JavaScript, APIs and Markup. The pages are
built **ahead of time** into plain HTML files by a generator, those files are served from a content
delivery network, a **CDN**, and anything that has to change per visitor, a basket or a search, is
fetched from an API by JavaScript in the browser. The name is heard less than it was; the shape is
everywhere, in documentation sites, shop fronts and marketing pages. Where a page gets its HTML,
the browser or the server, is lesson 6. This section is about what the delivery changes for a test.

The belief to drop is that the site you test while developing is the site that ships. In this
shape it is not, and three things follow.

## The build output is the thing tested

What reaches users is the folder the build wrote, served as files. During development the same
pages come from a development server, which rebuilds on every save and is often kinder than
production. **A SPA's deep links are the classic case**: Vite's development server, its
documentation says, answers unknown addresses with the app's page by default, so a suite run
against it never meets the 404 from two sections back. The suite that counts runs against the built
folder, served by a static server that knows nothing the production host does not. Quitanda's
`app/public/` is the same idea at its smallest: files, served as they are.

## Preview deploys

Static hosts commonly build every pull request and publish it at an address of its own, a
**preview deploy**. That gives a suite somewhere real to run before anything is merged, against the
same kind of host as production. It also changes the configuration: the address is different on
every pull request, so it comes from an environment variable rather than from a `webServer` the
suite starts itself. Lesson 10 is about Playwright's configuration, and how one suite runs against
several addresses.

## A CDN in front

A CDN keeps copies at many edges, close to users, and a deploy reaches them over time rather than
at once. That is lesson 4's cache one layer further away, and it has the same consequence: a test
run against production a moment after a deploy can meet the previous build. A test that has to know
which build it is talking to needs the build to say so, a version in a header or in the page,
rather than a guess based on the time.

There is a second consequence, about data. **What was baked in at build time is as old as the
build.** A price the API changed this morning is still yesterday's price in a page generated
yesterday, until the next build. A test that checks a price against the API can be right about both
and still fail; `manual-testing` lesson 20 is about choosing test data that does not move under a
test.

None of this ran for the course: there is no static host or CDN behind these lessons, so the
section shows no transcripts, only the questions to ask of the one you meet.
