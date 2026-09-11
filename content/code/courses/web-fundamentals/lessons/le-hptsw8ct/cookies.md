---
title: A small piece of text that comes back
version: 1
---

A cookie is a string the server gives the browser and the browser gives back, on every subsequent
request, without being asked again. That sentence is the whole mechanism. Everything else about
cookies is rules about when the giving back happens.

## Setting one, and getting it back

The server adds a header to a response:

```
Set-Cookie: session=8f3c1a9e; Path=/; Max-Age=3600
```

The browser stores it. From then on, every request to that site carries:

```
Cookie: session=8f3c1a9e
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"The server sends a Set-Cookie header once. The browser stores the value and attaches it to every following request to that site, without being asked.\"> <rect x=\"20\" y=\"30\" width=\"300\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"170\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the first response, once</text> <rect x=\"20\" y=\"76\" width=\"300\" height=\"34\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"170\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Set-Cookie: session=8f3c1a9e</text> <path d=\"M326 93 L394 93\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"400\" y=\"76\" width=\"300\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"550\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the browser writes it down</text> <text x=\"20\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">and then, on its own, with nothing on the page deciding:</text> <rect x=\"20\" y=\"158\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Cookie: session=8f3c1a9e — on the next page</text> <rect x=\"20\" y=\"194\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Cookie: session=8f3c1a9e — and on the stylesheet</text> <rect x=\"20\" y=\"230\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"245\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Cookie: session=8f3c1a9e — and on each of the sixty images</text> </svg>", "caption": "Handed over once, returned for ever, on everything. Which is why a large cookie is a tax on every request."}
```

Two things about that second line are worth noticing straight away.

It is sent **automatically**, by the browser, with no code involved and nothing on the page
deciding. A cookie set on Monday is attached to a request on Friday because the browser has been
holding it, not because anything asked.

And it is sent on **every** request that matches the rules — the page, the stylesheet, each image,
every call a script makes in the background. A cookie of two kilobytes on a page with sixty
resources is a hundred and twenty kilobytes of uploads that carry no information anybody wanted.
That is the first practical rule: **cookies are small on purpose, and the limit is about four
kilobytes each.**

## Which requests get it

Three things decide, and mixing them up is the usual source of *why is my cookie not being sent*.

**The name of the site.** By default, a cookie set by `codeschool.ing` goes back to
`codeschool.ing` and to nothing else. A cookie may be widened to cover subdomains, with a `Domain`
attribute, and it may never be widened to a site that is not yours — a rule enforced by the browser
against a published list of what counts as a public suffix, which is why nobody can set a cookie
for `.com`.

**The path.** `Path=/admin` means the cookie is attached under `/admin` and nowhere else. It is a
tidiness feature rather than a security one, because a page at `/` can still reach `/admin` in a
browser tab.

**Whether it has expired**, which is the next section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three tests a browser applies before attaching a cookie: the site name, the path, and whether it has expired. Three things it does not test: the method, whether a script or a link caused the request, and which page the request came from.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">what the browser checks</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">is this the site that set it?</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">is the path under its Path?</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">has it expired?</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">what it does not check</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">which method the request uses</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">whether a script or a click caused it</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">which page the request came from</text> <text x=\"360\" y=\"200\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the right-hand column is the whole reason the attributes exist</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and the last row of it is what SameSite was added to answer</text> </svg>", "caption": "The default rules are about where the cookie is going. Nothing in them is about where the request came from."}
```

Notice what is *not* on that list: the method, whether the request came from a link or a script,
and whether the page the request came from belongs to you. Those omissions are the whole reason
the attributes in the next section exist.

## Cookies you set from the page

A script running on the page can read and write cookies too, through `document.cookie`, and it is
worth knowing this exists so you can recognise it and, usually, not use it.

Anything a script can write, another script on the same page can read — including a script that
arrived inside an advertisement or a third-party library. The most important cookie on most sites
is the one that says who you are, and the whole of the next section is about keeping scripts away
from it.

## First-party, third-party, and the one everybody argues about

A cookie belongs to whoever set it, and whether that is the site in the address bar decides what
people call it.

A **first-party** cookie is set by the site you are looking at. The session that keeps you signed
in, the one holding your language choice on this site — those.

A **third-party** cookie is set by something *embedded* in the page and loaded from somewhere else:
an advertisement, an analytics script, an embedded video. Its own host sets its own cookie, and
here is the part that made it valuable: that same host is embedded on thousands of other sites, so
it sees the same browser arriving at all of them and can join the visits together into one record
of where somebody has been.

Nobody designed that. It falls out of two ordinary rules — a page may load things from elsewhere,
and a host may set a cookie for itself — meeting each other. It is the most consequential
accidental feature in the history of the web.

Browsers have been closing it for years, at different speeds and with different compromises, and
the practical position today is that a third-party cookie is something you should expect not to
work. If a feature you are building depends on one, it is on a schedule somebody else controls.

## The banner

Since this is where they come from, it is worth saying what the consent banners actually are.

European law — and Brazil's own data protection law alongside it — requires consent before storing
things on somebody's device for purposes they did not ask for. A cookie that keeps you signed in is
not one of those: it is necessary for something the visitor requested, and needs no banner. A
cookie that exists to build a profile of where you go does need one.

That distinction is why a well-built banner has a *reject* that is as easy as the accept, and why
so many are built badly. It is also the reason to know which of your own cookies is which: the ones
the site cannot work without are yours to set freely, and the rest are a decision about somebody
else's data rather than a technical detail.

## The size problem, seen once properly

There is a failure mode worth recognising because the error message points at the wrong thing.

Cookies accumulate. Analytics adds one, a test framework adds two, the application adds three, an
old feature left one behind. They are all sent on every request, all counted against a server limit
on the total size of the headers, and one day a request crosses it.

What the visitor sees is a `400` about a header being too large, on every page, with no way to
navigate out of it — because every request they make carries the same pile. The site is not down
for anybody else, and clearing the cookies fixes it instantly, which is a thing almost no visitor
will discover on their own.

The lesson is in what to store: **an identifier, and the state behind it on the server.** That is
the next reading but one, and it is the arrangement that keeps a cookie at thirty bytes for as long
as the site exists.
