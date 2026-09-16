---
title: Three digits, and whose fault it is
version: 1
---

Every response opens with a three-digit number, and the first digit is the family. Learn the five
families and you can read a code you have never seen before.

| family | means | who is holding the problem |
|---|---|---|
| `1xx` | hold on, this is not the answer yet | nobody; you rarely see these |
| `2xx` | it worked | nobody |
| `3xx` | it is somewhere else | the client, which should go there |
| `4xx` | you asked wrong | the client |
| `5xx` | I broke | the server |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The five families of status code as five bands: one hundred is not the answer yet, two hundred worked, three hundred is elsewhere, four hundred is the caller's mistake and five hundred is the server's failure. Only the last of these should wake anybody.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"60\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">1xx</text> <text x=\"320\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">hold on — rarely seen by anybody</text> <rect x=\"20\" y=\"74\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"60\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">2xx</text> <text x=\"320\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">it worked</text> <rect x=\"20\" y=\"118\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"60\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">3xx</text> <text x=\"320\" y=\"136\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">it is somewhere else — go there</text> <rect x=\"20\" y=\"162\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"60\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">4xx</text> <text x=\"320\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">you asked wrong — the caller fixes it</text> <rect x=\"20\" y=\"206\" width=\"680\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".34\" stroke=\"var(--amber)\"></rect> <text x=\"60\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">5xx</text> <text x=\"320\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">I broke — this is the one that wakes somebody</text> </svg>", "caption": "The first digit answers the only question that decides what happens next: whose problem is this?"}
```

The line between `4xx` and `5xx` is the one that matters most in practice, and it is not about
severity. It is about **whose fault it is**, and therefore who should be woken up. A wall of `404`s
is visitors following stale links; a wall of `500`s is your problem, tonight.

## The ones you will actually meet

Out of dozens defined, a handful account for nearly everything.

`200 OK` — here it is. `201 Created` — done, and the new thing is at the address in the `Location`
header. `204 No Content` — done, and there is deliberately nothing to send back, which is the right
answer to a `DELETE` that succeeded.

`301` and `302` move you somewhere else, and they behave so differently that they have a section of
their own further down this lesson. `304 Not Modified` says *what you already have is still
current*, and is the whole point of the caching in the next lesson.

`400 Bad Request` — I could not make sense of that. `401 Unauthorized` — I do not know who you are.
`403 Forbidden` — I know who you are, and no. `404 Not Found` — nothing here. `405 Method Not
Allowed` — that address exists, that word does not apply to it. `409 Conflict` — somebody changed
it since you read it. `429 Too Many Requests` — slow down, and the `Retry-After` header says by how
much.

`500 Internal Server Error` — something threw and nobody caught it. `502 Bad Gateway` — I am a
proxy and the thing behind me answered with nonsense. `503 Service Unavailable` — I am up and
deliberately not serving, usually overloaded or in maintenance. `504 Gateway Timeout` — I am a
proxy and the thing behind me never answered at all.

Those last three are worth more attention than they usually get, because each names a different
place. `502` and `504` both say the failure is behind the proxy, and they tell you whether it
answered badly or did not answer. Reading them correctly is the difference between restarting the
right service and restarting all of them.

## The three that get confused

`401`, `403` and `404` are, in order: *I do not know you*, *I know you and you may not*, and
*there is nothing here*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three codes distinguished. Four hundred and one means the server does not know who you are and invites you to say. Four hundred and three means it knows and refuses. Four hundred and four means there is nothing at that address, and is sometimes given in place of a refusal so that nothing is confirmed.\"> <rect x=\"20\" y=\"34\" width=\"215\" height=\"126\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"127\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\">401</text> <text x=\"127\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">I do not know you</text> <text x=\"127\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">an invitation: try again</text> <text x=\"127\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">with credentials</text> <rect x=\"252\" y=\"34\" width=\"215\" height=\"126\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"359\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\">403</text> <text x=\"359\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">I know you, and no</text> <text x=\"359\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a refusal: the same</text> <text x=\"359\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">credentials will not help</text> <rect x=\"484\" y=\"34\" width=\"216\" height=\"126\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"592\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">404</text> <text x=\"592\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">there is nothing here</text> <text x=\"592\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and sometimes a refusal</text> <text x=\"592\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">wearing this number</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a 403 confirms the thing exists; a 404 confirms nothing at all</text> <text x=\"360\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is why some systems answer 404 on purpose, and pay for it in their own logs</text> </svg>", "caption": "Two of these are about the caller and one is about the address, and the third is sometimes borrowed to hide the second."}
```

`401` is an invitation — it comes with a header saying how to authenticate, and the expected next
move is to try again with credentials. `403` is a refusal; sending the same credentials again will
not help.

And there is a deliberate use of `404` that is worth understanding. A private document that answers
`403` has confirmed it exists. Depending on what the addresses look like, that can be enough to map
out a system, or enough to reveal that a particular person has an account. So an application that
would rather not confirm anything answers `404` for *you may not see this* as well as for *there
is nothing here*. It is a small lie, told on purpose, and the price is that your own logs become
harder to read.

## The lie that costs the most

The single most common mistake with status codes is answering `200` and putting the error in the
body.

It looks harmless — the client can read the message either way — and it breaks four things at once.
A cache may keep the failure and serve it to everybody. A client library retries on `5xx` and this
is not one, so it will not retry. A monitoring dashboard sees a healthy service. And every piece of
software between you and the caller believes it worked, because the only thing any of them looks
at is the number.

The status line is not a summary for humans. It is the part that machines act on, and there are more
of those between you and your caller than you think.

## Codes you can choose

Some of this is fixed and some is a judgement, and it helps to know which is which.

That a missing page is `404` is not a decision anybody makes. That a form with a valid shape but an
impossible value is `400` or `422` is an argument teams genuinely have, and either answer is
defensible as long as the same choice is made everywhere.

What is not defensible is inconsistency: a client written against an interface that says `400` here
and `422` there for the same class of problem has to handle both and trust neither, which is how a
well-meaning choice becomes somebody else's permanent condition.
