---
title: What a report carries
version: 1
---

**A good report has what is needed to find the cause and nothing that is not.** The planner's carries six
fields, and each one earns its place:

| field | from | why |
|---|---|---|
| `message` | the error | what went wrong, in a line, and what reports are grouped by first |
| `stack` | the error | where, once a map has turned it back |
| `source` | the planner | which part caught it: a listener, or one of the planner's own `catch`es |
| `release` | the build | which maps to read the stack with |
| `path` | `location.pathname` | which screen, without the query string |
| `at` | the collector | when, by a clock the team trusts |

## What a hosted service adds

The services in a later section add more, and most of it is useful:

- **Breadcrumbs**: the last few things that happened before the error, such as clicks, navigations,
  requests and console lines. *Pressed Mark done, then a `POST /graphql` answered 502* explains a report
  that the stack alone does not.
- **The environment**: browser, version, operating system. A bug that only one browser shows is found by
  this column.
- **Grouping**: reports with the same message and the same top frames are one **issue**, counted, rather
  than ten thousand lines. A service calls that a fingerprint.
- **Sampling**: keeping one report in ten, or a hundred, when a large site would otherwise send millions.

## What it leaves out, on purpose

`path` is `location.pathname`, not `location.href`. The part after `?` is where addresses carry things
like a search term, a token from an e-mail link, or an e-mail address itself, and none of that is needed
to find a bug. The same goes for the values of form fields, the contents of the page, and anything that
identifies the person: **the planner sends no user id, no name and no e-mail address.** The next section
is about why that is also a legal question.
