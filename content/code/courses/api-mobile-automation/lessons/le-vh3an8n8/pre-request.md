---
title: Scripts that run before the request
version: 1
---

**A pre-request script runs before the request is built, so it can make a value the request needs.**
A test reads an answer; a pre-request script prepares a question. The collection has two of them,
and each solves a problem the chaining of section 04 left open.

Order matters here. For each request Postman runs the collection's pre-request script, then the
folder's, then the request's own, and only then resolves the variables and sends. So a value set in a
pre-request script is already in place when `{{name}}` is replaced.

## A fresh key for every order

**Create order** and **Order seats** each run one line before sending:

```js
pm.variables.set('idempotencyKey', pm.variables.replaceIn('{{$guid}}'));
```

`{{$guid}}` is one of Postman's *dynamic variables*: every time it is resolved it produces a new
random identifier. `replaceIn` resolves it now, and `pm.variables.set` keeps the
result in the local scope, which lives for this one request. The request's header
`Idempotency-Key: {{idempotencyKey}}` then sends it.

The key is the client's promise that a repeated request is the same request. boxoffice remembers a
key with the reply it gave. A second request with that key gets the first reply again, and no second
seat is sold. **That is exactly why a test must not reuse one.** A collection with a fixed key in
its header would create an order on its first run. On every later run against the same boxoffice it
would be handed the first run's order back: every test passing, no new order made. Lesson 13 tests
idempotency itself, including a defect in how boxoffice keeps its promise.

## A token, only when needed

The collection's own pre-request script, the first `event` in the file, runs before every request.
Most of the time it does nothing:

```js
const expires = Number(pm.collectionVariables.get('tokenExpires') || 0);
if (!pm.collectionVariables.get('token') || Date.now() >= expires) {
```

It asks for a token only when there is none, or when the time saved by **Get token** has passed.
`pm.sendRequest` sends that request from inside the script: the same `POST /oauth/token`, with the
client's id and secret from the environment. Its callback saves the answer exactly as Get token
does. If the answer is not a `200`, it throws, and the error names the status.

Two runs show why it is there:

- Running a folder on its own. The `seat rules` folder in section 06 runs without the `auth`
  folder before it, so nothing would have fetched a token. The run you saw in section 02 started with
  a `POST /oauth/token` line under **List shows** that no request asked for: that was this script.
- A Postman session that lasts. Collection variables keep their value in the app between sends.
  A token saved at nine o'clock has expired by a quarter past, and without the expiry check every
  order request would answer `401` until somebody ran Get token again.

The thirty seconds taken off the expiry are a margin. A token that expires while a request is on its
way is refused, and a margin costs one extra token request now and then.

**A pre-request script is code in your test that nobody tests.** Keep it short and keep it in one
place, the collection rather than a copy per request. Make it fail loudly, as this one does with
`throw`. A script that swallowed a refused token would send every order without one and leave you
reading a column of `401`s for the cause.
