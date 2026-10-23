---
title: What a framework is for
version: 1
---

**Lesson 5's server is about 110 lines, and most of them are not about links.** They route, write
replies, read bodies, and turn errors into responses: the same work every HTTP service does, written
again. A framework is that work written once, by people who have met every edge case of it, so that
your code is left holding only what is particular to your service.

**Express** is the oldest and most used of them in Node. It is small on purpose: it routes, it chains
middleware, it adds helpers to the request and the response, and it leaves the rest to you. Version 5,
which this course installed in lesson 4, is the current one; most tutorials online were written for
version 4, and the sections on path syntax and errors say where the two differ.

Here is lesson 5's file, piece by piece, against what replaces it:

| lesson 5 wrote | Express gives |
|---|---|
| the `if` on the number of path parts and the method | `app.get("/links/:code", …)`, and `Router` to group them |
| `decodeURIComponent` on each part, and the `URIError` | `req.params`, already decoded, and a 400 for a bad encoding |
| `send(res, status, body, headers)` | `res.status(201).location(…).json(link)` |
| `readJson`, with its type check and its limit | `express.json({ limit: "1kb" })` |
| the edge that caught every error | error-handling middleware, and errors from `async` handlers caught for you |
| the final 404 | a 404 when no route matched, which you replace with your own |

## What it does not give you

Two things lesson 5 did and Express does not, which is worth knowing before it surprises you:

- **no 405.** A path that exists with a method nobody wrote answers 404, the mistake lesson 5's
  section on routing warned about. The section on unmatched routes adds the 405 back.
- **no validation.** `req.body` is whatever JSON the client sent, and `req.params.code` is whatever
  text was in the path. Checking them is still yours, and lesson 7 does it.

And nothing about structure: Express will run a thousand-line `app.js` as happily as five small
files. The layout from lesson 3 is a decision this course makes, and the last section of this lesson
builds it.
