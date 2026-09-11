---
title: Asking for it in your own language
version: 1
---

One address can have several answers. The same page exists in five languages here; a report exists
as a web page and as a spreadsheet; a photograph exists compressed in three different ways. HTTP
has a mechanism for choosing between them, and the browser has already been using it on your
behalf.

## The asking half

The request carries a short list of `Accept` headers, and each is a ranked preference rather than a
demand.

```
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: pt-BR,pt;q=0.9,en;q=0.8
Accept-Encoding: gzip, br
```

The numbers are the ranking. An item with no `q` is worth 1, the most wanted; `q=0.9` is slightly
less; `q=0.8` less again. So that second line reads: *Brazilian Portuguese if you have it,
otherwise Portuguese of any kind, otherwise English, and if none of those then surprise me.*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The browser sends a ranked list: Brazilian Portuguese first, then Portuguese, then English. The server holds Portuguese, English and Spanish. The first line of the list it can satisfy is Portuguese, and that is what it sends.\"> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">what the browser asked for, in order</text> <rect x=\"20\" y=\"34\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"170\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pt-BR — no q, so the most wanted</text> <rect x=\"20\" y=\"80\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"170\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pt — q=0.9</text> <rect x=\"20\" y=\"126\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"170\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">en — q=0.8</text> <text x=\"400\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">what the server has</text> <rect x=\"400\" y=\"34\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect> <text x=\"550\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">no Brazilian variant</text> <rect x=\"400\" y=\"80\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"550\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Portuguese — held</text> <rect x=\"400\" y=\"126\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"550\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">English — held, and not needed here</text> <rect x=\"20\" y=\"192\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Content-Language: pt — the first line of the list it could satisfy</text> <text x=\"360\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a preference that cannot be met is not an error; the server serves the next one down</text> </svg>", "caption": "The list is ranked, not required. The server walks down it and stops at the first thing it has."}
```

The server holds whatever it holds, walks the list, and serves the best it can match. If it has no
Portuguese it serves English and nobody has failed — negotiation is a preference, and a preference
that cannot be met is not an error.

`Accept-Encoding` is the same mechanism used for something else entirely: compression. The browser
is saying *I can unpack these formats*, and a server that can compress will, typically turning a
page into a quarter of its size. It is the cheapest performance improvement on the whole list and
it is negotiated in one header nobody looks at.

## The answering half, and the header everybody forgets

The server picks, and then it has to say what it picked: `Content-Language: pt-BR`, or
`Content-Encoding: gzip`.

And it has to say something else, which is where this goes wrong in production.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The same cache serving two visitors. Without the Vary header both receive the copy stored for the first visitor. With it, the two are filed separately and each receives the right language.\"> <text x=\"180\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">no Vary header</text> <rect x=\"20\" y=\"34\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">filed under: /precos</text> <rect x=\"20\" y=\"92\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">first visitor asked in Portuguese</text> <rect x=\"20\" y=\"150\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">second asked in English, got Portuguese</text> <text x=\"180\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">one key, two visitors, one of them wrong</text> <text x=\"540\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">Vary: Accept-Language</text> <rect x=\"380\" y=\"34\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">filed under: /precos plus the language</text> <rect x=\"380\" y=\"92\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"114\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">first visitor asked in Portuguese</text> <rect x=\"380\" y=\"150\" width=\"320\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">second asked in English, got English</text> <text x=\"540\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">two keys, two visitors, both right</text> <text x=\"360\" y=\"266\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the defect never reproduces for whoever built it, because they are always the first visitor</text> </svg>", "caption": "A cache files an answer under the address. If the answer depended on a header, the header has to be part of the key."}
```

Between you and the server there are caches, and a cache stores an answer under the address that
was asked for. If one address can produce different answers, a cache that files them all under the
same key will hand the Portuguese page to the next person, whoever they are.

`Vary: Accept-Language` is the instruction that fixes it: *this answer depended on that header, so
file it under both.* Leave it out and the site works perfectly for whoever visits first and is
wrong for everybody after them — which is why this defect is nearly always reported as *the site is
in the wrong language for some people*, and nearly never reproduces for the person who built it.

The same applies to any header a decision was based on. If the answer changes with
`Accept-Encoding`, say so; if it changes with something you invented, say that too.

## Why sites do it a different way

Now the honest part, because most of the sites you use do not choose language this way.

A language chosen from a header is invisible and unshareable. You cannot send somebody a link to
the page as you saw it, because the link carries no language and their browser will ask for theirs.
You cannot easily override it — a Brazilian reading documentation in English is fighting their own
browser settings. And you cannot see, from the address, which version you are looking at.

So the common arrangement uses the header **once**, as a first guess, and then remembers the
choice: `/pt/precos` and `/en/pricing` as separate addresses, or a cookie holding a decision the
visitor made. Each address then has one answer, links are shareable, and the cache problem
disappears because there is nothing left to vary on.

This site does that too. Your first visit is guessed from the browser; after that it is a stored
choice, and the guess is not consulted again.

Negotiation remains the right tool for things the visitor has no opinion about — compression,
image formats — and for interfaces where the caller is a program rather than a person. Which
brings up the last case.

## Images, where it is doing the most work today

The place negotiation earns its keep without anybody thinking about it is pictures.

A browser sends something like `Accept: image/avif,image/webp,image/png,*/*`, and a server that
holds the same photograph in three formats picks the newest one that browser understands. The
image is the same picture and can be half the bytes, and no address changed, no markup changed and
no visitor made a decision.

That is the argument for negotiation in a sentence: it works for things where **there is a right
answer the visitor has no opinion about**, and it degrades quietly when a browser is too old to
take the better one.

Compression is the same story from the previous page. So is the choice between a modern video
codec and an older one. In each case a preference list arrives, the server picks the best it can
serve, and nobody is asked a question they could not have answered.

## When nothing matches

The specification has a code for *I have nothing you said you would accept* — `406 Not
Acceptable` — and in practice it is almost never the right thing to send.

The reason is that the request was a preference, so serving something is nearly always more useful
than serving nothing. A browser asking for Portuguese and offered English can read the English; a
browser offered a `406` gets an error page it cannot do anything with. The rule most servers follow
is to satisfy the list if possible and otherwise send their default, and to keep `406` for the case
where the caller is a program that genuinely cannot parse anything else.

## The same address, HTML or data

`Accept` also chooses format, and this is where you will use negotiation deliberately.

One address for an order can answer `text/html` to a browser and `application/json` to a program,
with the same code deciding what is true and only the last step deciding how to write it down. The
alternative is two addresses that drift apart, which they do.

It is worth knowing the argument against it: a single address with two shapes is harder to cache,
harder to debug — the same link gives different things to different tools — and easy to get wrong
in ways that only appear for one kind of caller. Both arrangements are defensible. What is not is
choosing one by accident, which is what happens when nobody knows the mechanism exists.
