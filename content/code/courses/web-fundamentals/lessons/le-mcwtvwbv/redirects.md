---
title: Somewhere else, and for how long
version: 1
---

A `3xx` response is a server saying *not here — there*. It carries a `Location` header with the new
address, and the browser goes, usually without showing anybody that it happened.

That much is simple. The part worth a section is that there are several of these codes, they differ
in ways that do not show up while you are testing, and one of them is close to irreversible.

## Permanent, temporary, and who is allowed to remember

| code | how long | what happens to the method |
|---|---|---|
| `301` | permanent | historically turned into a `GET` |
| `302` | temporary | historically turned into a `GET` |
| `303` | see this other thing | deliberately becomes a `GET` |
| `307` | temporary | kept as it was |
| `308` | permanent | kept as it was |

Two axes, and both are about what somebody else may now assume.

**Permanent or temporary** decides who may remember. A `302` is an instruction for this request:
ask again next time and you might be sent somewhere different. A `301` is a statement about the
world — *this address has moved* — and everything that hears it is entitled to write it down. The
browser does. Caches do. Search engines move their index and stop visiting the old address.

**The method** is the second axis, and the history is ugly. `301` and `302` were specified to keep
the method, browsers changed `POST` to `GET` anyway, enough software depended on that behaviour
that it could not be fixed, and `307` and `308` were added to mean *what the other two were
supposed to mean*. If a redirect might ever receive something other than a `GET`, use those.

`303` is the odd one that always turns into a `GET`, on purpose, and it solves a real annoyance:
after a form is submitted, answer `303` pointing at a result page, and the browser fetches that
page with a `GET`. Now the address in the bar is a page that can be reloaded, bookmarked and shared
without sending the form again — which is why a shop that says *do not press refresh* is a shop
missing three characters.

## The one that is hard to take back

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"After a temporary redirect the browser asks again on the next visit, so a mistake can be corrected. After a permanent one the browser goes straight to the stored address without asking, so a mistake cannot be reached to correct.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">302, temporary</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">first visit: asks, is sent elsewhere</text> <rect x=\"20\" y=\"90\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">next visit: asks again</text> <rect x=\"20\" y=\"144\" width=\"320\" height=\"62\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">so a wrong redirect can be fixed</text> <text x=\"180\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and the fix reaches everybody</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">301, permanent</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">first visit: asks, is sent elsewhere</text> <rect x=\"380\" y=\"90\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">next visit: does not ask at all</text> <rect x=\"380\" y=\"144\" width=\"320\" height=\"62\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">so a wrong redirect cannot be fixed</text> <text x=\"540\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">for anybody who already has it</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">you cannot serve a correction to a browser that has stopped asking</text> <text x=\"360\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">so: ship it as 302, confirm it, and only then make it 301</text> </svg>", "caption": "The difference between these two is not how long the move lasts. It is who is allowed to write it down."}
```

A `301` is stored by the browser, and for a long time, in some browsers until the profile is
cleared. The next visit to the old address does not produce a request at all: the browser already
knows, and goes straight to the new place.

Which is exactly what you wanted, until the redirect was wrong.

Publish a `301` sending the whole site to an address that turns out to be broken, notice within
five minutes, and fix it — and every visitor who loaded it in those five minutes is still being
sent to the broken address, by their own browser, with no request reaching you to correct. There is
nothing you can serve them, because they are not asking.

The rule that follows costs nothing: **test a new redirect as a `302`, and change it to `301` once
you are sure.** A temporary redirect is not remembered, so a mistake lasts as long as the mistake
does.

## Chains, and what they cost

Each redirect is a full round trip: a request out, a response back, then another request. On a
mobile connection with 120 ms of latency they are visible.

And they gather without anybody deciding to. A site that moved to HTTPS, then to a `www` name, then
to a language prefix, answers three redirects before serving one page.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Four requests in sequence before any content is served: plain HTTP redirects to HTTPS, which redirects to the www name, which redirects to the language prefix, which finally answers with the page.\"> <rect x=\"20\" y=\"30\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">http://example.com/</text> <text x=\"506\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">301 — one round trip</text> <rect x=\"20\" y=\"78\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">https://example.com/</text> <text x=\"506\" y=\"97\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">301 — two</text> <rect x=\"20\" y=\"126\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"34\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">https://www.example.com/</text> <text x=\"506\" y=\"145\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">302 — three</text> <rect x=\"20\" y=\"174\" width=\"470\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"34\" y=\"193\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">https://www.example.com/pt/</text> <text x=\"506\" y=\"193\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">200 — the page</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">on a mobile link at 120 ms, that is a third of a second spent arriving</text> <text x=\"360\" y=\"268\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the fix is to answer the first request with the last address, not to delete any of the rules</text> </svg>", "caption": "Every hop was somebody being reasonable on a different day. The visitor pays for all of them at once."}
```

Three round trips before the first byte of content. Each was reasonable on the day it was added,
and nobody added them at the same time — which is the shape of most of these: no single decision
was wrong, and the total is.

The fix is not to remove them — every one of them is doing a job — but to collapse them, so that
the first server answers with the final address in one step. Typing an address by hand and watching
the chain is a five-minute check most sites have never had done to them.

## Redirects you did not write

A last thing worth knowing, because it is where the surprises live: several layers between the
visitor and your code can issue one, and the code you are reading never mentions it.

The web server may be configured to force HTTPS. A framework may add or remove a trailing slash so
that `/precos` and `/precos/` do not become two addresses. A CDN in front of everything may send
visitors to a regional edge. Each is one line in a file somebody else maintains.

So when a chain is longer than it should be, the useful move is not to read the application. It is
to ask for each address in turn and look at what answers — which is a `curl -I` or two, and settles
in a minute an argument that can otherwise last a week.

A chain can also close into a circle: A sends you to B, B sends you back to A. Browsers stop after
a while and show *too many redirects*, which is a message about a loop rather than about a number.
It is nearly always two rules that are each correct and disagree — one forcing `www` on, another
forcing it off.
