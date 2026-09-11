---
title: Where the certificate really ends
version: 1
---

Lesson six explained what a certificate proves. This one is about the part that breaks: who
obtains it, who renews it, and where in the path the encryption actually stops.

## Free and automatic changed everything

Certificates used to be bought, once a year, by somebody filling in a form. The renewal was a
calendar entry, and the calendar entry was the failure.

A free issuing authority with an automated protocol changed the shape of the problem. A program on
your machine proves it controls the name, receives a certificate valid for a short period, and
renews itself long before it expires. Short validity is the point: it forces the automation to
work, because nothing lasts long enough to survive on attention.

Proving control happens one of two ways, and it is worth recognising both.

**Over HTTP** — the authority asks for a specific file at a specific path on your site, over plain
HTTP. Simple, and it requires port 80 to stay reachable, which is why *we redirected everything to
HTTPS and renewal stopped working* is a common and confusing failure.

**Over DNS** — the authority asks you to publish a record, using the previous lesson's mechanism.
Slower, requires your DNS provider to have an interface a program can use, and it is the only way
to obtain a **wildcard** certificate covering every subdomain at once.

## Where it ends, which is the question people skip

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"With nothing in front, the encryption runs end to end. With an edge in front, the connection is terminated there and a second connection is opened to the origin, which may be plain, encrypted, or encrypted and verified.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">nothing in front: one hop, and the padlock describes all of it</text> <rect x=\"20\" y=\"36\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the browser</text> <path d=\"M226 56 L474 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path> <text x=\"350\" y=\"46\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">encrypted, end to end</text> <rect x=\"480\" y=\"36\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"590\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your server</text> <text x=\"20\" y=\"118\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">an edge in front: two hops, and only the first is what the visitor sees</text> <rect x=\"20\" y=\"128\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"105\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the browser</text> <path d=\"M196 148 L274 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path> <rect x=\"280\" y=\"128\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"365\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the edge, holding a certificate</text> <path d=\"M456 148 L534 148\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path> <rect x=\"540\" y=\"128\" width=\"160\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"620\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your server</text> <rect x=\"20\" y=\"190\" width=\"680\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">the second hop is plain, or encrypted, or encrypted and verified — somebody chose</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the padlock describes the hop the browser made, and nothing beyond it</text> </svg>", "caption": "Two hops, and the visitor can only see one of them. The other one is a setting."}
```

If a request goes straight to your server, the encryption is end to end and there is one
certificate to think about.

Put anything in front — a CDN, a load balancer, a platform's router — and the usual arrangement is
that the connection is **terminated** there. The edge decrypts, reads enough to do its job, and
opens a second connection to your origin. There are now two hops, and they are not necessarily
encrypted the same way.

Three arrangements exist, and the names appear in every provider's settings.

**Terminated at the edge, plain to the origin.** Fast to set up. The second hop crosses somebody's
network unencrypted, and the padlock a visitor sees describes the first hop alone.

**Terminated at the edge, encrypted to the origin without checking it.** Better, and it stops
anybody reading the second hop, while proving nothing about who is answering there.

**Terminated at the edge, encrypted and verified to the origin.** The arrangement to aim at, and
the one that needs a certificate on your own server as well.

The instinct worth keeping: **the padlock describes the hop the browser made.** Everything behind
it is a set of choices somebody made in a settings panel, and they are worth looking at once.

## What actually breaks

Four failures, and between them they account for nearly every certificate incident.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four certificate failures: renewal stopped and nobody noticed, the certificate covers the wrong names, it was renewed but the server was never reloaded, and the chain is incomplete so it works in some browsers and not others.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">renewal stopped weeks ago, and the first warning is the expiry</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">it covers one name and the visitor asked for the other</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">renewed on disk, and the running process still holds the old one</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">an incomplete chain: fine on your laptop, broken on a phone</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">alert on days remaining, and check with something that is not your browser</text> </svg>", "caption": "Four failures, and the last one is the worst to find because it works where you are looking."}
```

**Renewal stopped and nobody noticed.** The automation failed weeks ago, quietly, and the first
notification is a browser warning on the day it expires. The fix is not a better calendar; it is
monitoring that alerts on *days remaining*, which is a check any monitoring service offers.

**The wrong names.** A certificate is issued for the names you asked for. `example.com` and
`www.example.com` are two names, and a certificate that covers one of them produces a warning on
the other — which is the name mismatch from lesson six, arriving through a configuration rather
than an attack.

**Renewed and not reloaded.** The new file is on disk and the running process is still holding the
old one in memory. It expires on schedule, with a correct certificate sitting beside it. Whatever
renews has to tell the server to pick it up.

**An incomplete chain.** The server sends its own certificate and leaves out the intermediate one
above it. Browsers that have seen the intermediate elsewhere fill it in and work; others do not.
The result is a site that is fine on your laptop and broken on somebody's phone, which is the worst
possible way for this to present.

## What each hosting arrangement does for you

Worth putting beside the rest of the lesson, because the amount of this that is your problem is
exactly the line the opening video drew.

On **shared hosting**, the panel obtains and renews it, and you do nothing. On a **platform** or
behind a **CDN**, the provider does the same at the edge, and the second hop is the setting above.
On **static hosting**, it is included and invisible.

On a **machine of your own**, all of it is yours: obtaining, renewing, reloading, and the
monitoring that tells you when one of those stopped. It is perhaps twenty minutes of setup and then
nothing for years — right up until the twenty minutes were done by somebody who has left.

That is the whole of the pattern in this lesson, in one small subject: the work does not disappear
when you hand it over, and it does not appear from nowhere when you take it on. It was always
there, and the only question was whose morning it would be.

## Two things to arrange on the first day

**Alert on days remaining**, not on failure. A renewal that fails silently has weeks in which it
could be fixed, and the whole cost of this category is that nobody looks during them.

**Check with a tool that is not your browser.** Your browser has a cache of intermediates, opinions
about which warnings to show, and a memory of this site. A checker that starts from nothing sees
what a stranger sees, which is the only opinion that matters.
