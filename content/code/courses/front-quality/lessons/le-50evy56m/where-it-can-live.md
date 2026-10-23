---
title: Six places a browser can keep a secret
version: 1
---

**Wherever a token is kept in the browser, the question that decides whether it is safe is the same:
which code can read it?** The page's own scripts are many people's code. The planner loads only its
own, and a real app loads a framework, a dozen libraries, an analytics tag and whatever a support
widget pulls in, and each of them runs with exactly the rights the page has. Lesson 9 adds the worst
case: text that a person typed, turned into a script by one careless line.

| where | lives until | a script on the page can read it | sent to the server |
|---|---|---|---|
| a variable in memory | the tab is closed or reloaded | only code that can reach the variable, which on one page is any code that tries hard enough | by your code |
| `sessionStorage` | the tab is closed | yes, any script on the same origin | by your code |
| `localStorage` | someone deletes it | yes, any script on the same origin, in every tab, for ever | by your code |
| IndexedDB | someone deletes it | yes, as `localStorage` | by your code |
| a cookie without `HttpOnly` | its `Max-Age`, or the browser closes | yes, through `document.cookie` | by the browser, with every request to its site |
| a cookie with `HttpOnly` | its `Max-Age`, or the browser closes | **no** | by the browser, with every request to its site |

**Only the last row keeps the secret from the page's own scripts**, and that is the property worth
paying for. Everything else is a question of how long the secret lies around for a script to find:
`localStorage` keeps it until somebody clears it, which is the reason so many breaches of single-page
apps begin there.

## What the last row costs

An `HttpOnly` cookie is sent by the browser automatically, and that is its weakness: a request another
site makes the browser send carries it too. That attack is cross-site request forgery, and `SameSite`,
in a section of this lesson, and lesson 9's checks are the answer to it. **The trade is a good one.**
The attack on a cookie is narrow and has standard defences; the attack on a readable token is any
script on the page, and the defence is that there must never be one.
