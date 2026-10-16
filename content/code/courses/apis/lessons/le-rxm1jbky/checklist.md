---
title: Before an API goes live
version: 1
---

**A checklist is only worth having if every line on it can be checked.** "The API is secure" cannot
be; "an unknown origin gets no `Access-Control-Allow-Origin`" can, with one curl command. This one
gathers the whole course into lines of the second kind, each with the lesson that built the defence.
Go through it against the deployed API, from outside, the way a client sees it, and not against the
code.

## The contract

| check | how you see it | lesson |
|---|---|---|
| every error is a status code a client can act on, never a 200 with an error inside | send each mistake on purpose and read the code | 1 |
| unknown and wrongly typed fields are refused | a PATCH with an extra field answers 422 | 1, 2 |
| the representation is built field by field, and nothing internal leaks into it | read an answer and ask why each field is there | 2 |
| every endpoint and version that answers is in the written contract | compare the OpenAPI document with what answers | 6 |
| old versions have a date to stop answering, and do stop | ask the retired version, expect a refusal | 1, 6 |

## Who is asking, and what they may do

| check | how you see it | lesson |
|---|---|---|
| every endpoint that is not public refuses a request with no credentials | 401 without them | 7 |
| tokens and sessions expire, and signing out ends them | use one after it should have died | 7, 8 |
| passwords are stored only as a slow, salted hash | read the table: no password, only a hash with its parameters | 10 |
| every object is checked against the caller, not only the kind of object | ask for somebody else's object with a valid token | 11 |
| every administrative function checks the role or scope | call it as an ordinary account | 11 |

## Volume

| check | how you see it | lesson |
|---|---|---|
| each client has a limit, and going over it answers 429 with when to retry | a loop of requests from one client | 12 |
| lists are paged and have a maximum page size | ask for a million rows | 2 |

## Transport and the browser

| check | how you see it | lesson |
|---|---|---|
| HTTPS only, with a certificate from an authority clients already trust | `curl` with no options succeeds; plain `http://` does not serve the API | 13 |
| `Strict-Transport-Security` on every HTTPS answer | the header in `curl -si` on any address | 13 |
| CORS names exact origins, or `*` only for public data with no credentials | an unknown origin and `Origin: null` get no `Access-Control-Allow-Origin` | 13 |
| `Vary: Origin` on every answer that depends on it | look for it on an answer to an origin that is refused | 13 |
| preflights answer 2xx, with the methods and headers the pages really use, `Authorization` included | `curl -X OPTIONS` with the three request headers | 13 |
| the security headers are on every answer, errors included | ask for a missing address and an unknown method | 13 |
| no version in `Server`, no stack trace in an error | the same two requests | 13 |

## When the API is the client

| check | how you see it | lesson |
|---|---|---|
| every address the API fetches is on an allowlist, and private addresses are refused | give it `http://127.0.0.1/` and expect a refusal | 13 |
| every partner's answer is validated before it is used, with TLS verification on | the code that calls the partner, and its tests | 2, 13 |

Two lines the table cannot hold. **Every one of these is checked again after every change**, not once before launch. A header lost in a refactor fails no test and breaks no page, which is why the checks
above are written as requests that can be scripted. And none of it replaces keeping the software up
to date, which is the defence against every flaw nobody has found in your code yet.
