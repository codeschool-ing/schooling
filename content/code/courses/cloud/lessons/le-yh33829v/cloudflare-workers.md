---
title: "Cloudflare Workers: functions at the edge"
version: 1
---

Lambda runs your function in a region you choose, such as `sa-east-1`, and a user in Lisbon reaches
it across an ocean. **Cloudflare Workers run the function in Cloudflare's own network of edge
locations, the same places that serve cached content for its CDN, so the code runs close to
whoever sent the request.** By default there is no region to pick: a deployed Worker answers from
the location that received the request. Lesson 9 measures what distance costs in latency; this is a
platform built to spend less of it.

## Isolates, not virtual machines

The larger difference is how a copy of the function is made. **Lambda gives each execution
environment a small virtual machine of its own. Workers run many scripts inside one process, each in
a V8 isolate.** V8 is the JavaScript engine inside Chrome, and an isolate is its unit of separation:
one piece of code with its own memory and no way to reach another's. Creating an isolate is far
cheaper than starting even a small virtual machine, so a Worker starts almost at once, and cold
starts mostly stop being a subject.

The same greeting as a Worker looks like this. This course did not run it, because running it needs
a Cloudflare account:

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);
    const name = url.searchParams.get("name") ?? "world";
    return Response.json({ message: `hello, ${name}` });
  },
};
```

**The shape is the web platform's rather than a vendor's**: a `Request` in and a `Response` out, the
same objects a browser's `fetch` uses, where Lambda hands over an event dict and expects a
status-code dict back.

## What the design costs

The isolate brings three costs with it:

- The runtime is JavaScript's. Code written in JavaScript or TypeScript runs as it is, and other
  languages arrive compiled to WebAssembly. It is not Node.js: a Worker gets the web platform's APIs
  and a subset of Node's, so a library that expects all of Node may not run.
- The limit that matters is CPU time. A Worker waiting on another service is not using the
  processor; one crunching numbers is, and reaches its limit far sooner. The limits differ by plan
  and are on Cloudflare's pages, and this course does not quote them.
- There is no disk of your own. Storage is a separate product the Worker calls: a key-value store
  (KV), object storage (R2), a SQL database (D1), and Durable Objects for state that needs a single
  place to be coordinated.

**The billing follows the same choice.** Cloudflare's paid plan counts requests and CPU time, not the
time a Worker spends waiting, which is the opposite of Lambda's GB-seconds, where waiting on a
database is billed like working.

## Where it fits

**A Worker is best at small, fast work that should happen near the user**: redirects, rewriting
headers, checking a token before a request reaches the origin, choosing between two versions of a
page, a small API over Cloudflare's own storage.

It is a poor fit for long computation, for libraries that need a full Node.js or native code, and,
less obviously, for anything that calls one database in one region on every request. **A Worker in
Lisbon that asks a database in Virginia three questions per request has moved the code to the user
and left the data an ocean away**; the edge saved nothing.
