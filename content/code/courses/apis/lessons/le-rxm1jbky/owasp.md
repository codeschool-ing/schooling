---
title: The OWASP API Security Top 10
version: 1
---

**OWASP, the Open Worldwide Application Security Project, publishes a list of the ten risks it sees
most often in real APIs, and the 2023 edition is the current one.** It is not a list of attacks to
memorise. Each entry is a mistake in how an API was designed or deployed, and each has a defence that
this course has already built or named.

| risk | what goes wrong | the defence | lesson |
|---|---|---|---|
| API1 Broken Object Level Authorization | a client asks for `/v1/orders/1042` and gets it, though order 1042 is somebody else's | check, on every request, that this caller may have **this object**, not only this kind of object | 11 |
| API2 Broken Authentication | passwords sent or stored badly, tokens that never expire, sign-in with no limit on attempts | standard mechanisms, implemented by a library, never invented | 7, 8, 9, 10 |
| API3 Broken Object Property Level Authorization | the answer carries fields the caller should not see, or a write accepts fields the caller should not set, such as `role` | the representation built field by field, unknown fields refused, writable fields checked per role | 1, 2, 11 |
| API4 Unrestricted Resource Consumption | one client sends enough requests, or asks for enough rows, to slow the API for everyone or run up its bill | limits per client, on rate and on size | 12 |
| API5 Broken Function Level Authorization | an ordinary account calls an administrator's endpoint and it works | every function checks the caller's role or scope, the administrative ones above all | 11 |
| API6 Unrestricted Access to Sensitive Business Flows | a legitimate flow, buying, booking, signing up, run by a program a thousand times | limits that follow the business, per account and per flow | 12 |
| API7 Server Side Request Forgery | the API fetches an address a client supplied, and the client supplies an internal one | an allowlist of destinations, and addresses checked before connecting | this one |
| API8 Security Misconfiguration | a permissive CORS, missing headers, plain HTTP, verbose errors, a version in `Server` | a configuration decided once and applied to every answer | this one |
| API9 Improper Inventory Management | an old version or a forgotten test endpoint still answering, unpatched | a written contract of every endpoint and version, and old versions retired | 1, 6 |
| API10 Unsafe Consumption of APIs | the API trusts what a partner's API sends it more than what users send | the partner's answers validated like any input | this one |

The names keep OWASP's American spelling, because they are names.

## What the list says about where the danger is

**Three of the ten are authorisation at three different depths**: the object (API1), the properties
of the object (API3), and the function (API5). The first of them heads the whole list, and the three
share a cause: authentication answered "who is this?", and nobody then asked "and may they do
*this*?". Authentication itself, API2, is a fourth. That is why lessons 7 to 11 are half of this
course.

**Two are about volume** rather than about a single request: API4 is too much of anything, API6 is
too much of something that is allowed. A rate limit defends both, and API6 also needs a decision only
the business can make, such as how many tickets one account may buy.

**API8 is this lesson's subject.** Everything the earlier sections did to `secure.py` is
configuration: which origins may read, which headers go out, whether the connection is encrypted,
what an error says about the server. None of it is an algorithm, and each piece is a line that is
easy to leave out.

**API9 is the one that hides.** An inventory is a list of every endpoint and every version that
answers, and lesson 6's OpenAPI document is that list when it is kept true. Lesson 1's `/v2` route
for a book is the case in miniature: once `/v2` exists, `/v1` stays reachable until somebody decides
to retire it, and an endpoint nobody remembers is an endpoint nobody patches.

API7 and API10, the other two marked "this one", are the next section's subject: in both of them
the API is the one making a request.
