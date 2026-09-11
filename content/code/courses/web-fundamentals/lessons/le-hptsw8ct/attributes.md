---
title: The words after the value
version: 1
---

A cookie is a name and a value, and then a list of attributes that most tutorials skip. They are
not decoration. Three of them are the difference between a session and somebody else's session.

```
Set-Cookie: session=8f3c1a9e; Max-Age=3600; Path=/; Secure; HttpOnly; SameSite=Lax
```

## How long it lives

`Max-Age` is a number of seconds; `Expires` is a date. Set neither and you have a **session
cookie**, which the browser keeps until the window closes — a poorly chosen name, because it has
nothing to do with the sessions two readings from now.

The choice is not only technical. A cookie that survives a closed browser is the difference between
*stay signed in* and signing in again every morning, and on a shared machine those are meaningfully
different promises. Sites that handle money usually pick the short one on purpose.

Deleting one is the same mechanism backwards: send the cookie again with a date in the past, and
the browser drops it. There is no *delete* instruction, which is why logging out is something the
server has to do deliberately.

## `Secure`

Send this cookie over HTTPS and never over plain HTTP.

Without it, one request to a plain address — a typed link, an old bookmark, a redirect that has not
been cleaned up — sends the value across the network in the clear, for anybody on the path to
read. The connection that leaked it does not have to be one that mattered; it just has to happen
once.

## `HttpOnly`

The browser hides this cookie from scripts. `document.cookie` will not show it, so a script cannot
read it, copy it or send it anywhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A script injected into a page reads the session cookie and sends it elsewhere. With HttpOnly set, the same script runs and the cookie is invisible to it.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">without HttpOnly</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">an injected script runs on the page</text> <rect x=\"20\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document.cookie — readable</text> <rect x=\"20\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the value leaves, and so does the account</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">with HttpOnly</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the same script runs on the page</text> <rect x=\"380\" y=\"86\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document.cookie — empty</text> <rect x=\"380\" y=\"136\" width=\"320\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a defaced page instead of a stolen one</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">it does not stop the script; it removes what the script was there for</text> <text x=\"360\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the browser still sends the cookie on requests — it just refuses to show it to the page</text> </svg>", "caption": "Two outcomes of the same attack, separated by one word in one header."}
```

This exists because of one attack, and it has taken a great many accounts. Somewhere on the site is
a place where text from one visitor is shown to another — a comment, a name, a search term echoed
back. If that text is put into the page without being escaped, a visitor can leave a script there,
and the script runs in the next visitor's browser with all the authority of that page. The first
thing such a script does is read the session cookie and send it away. From then on, whoever
receives it is that person.

`HttpOnly` does not prevent the script running. It makes the most valuable thing on the page
unreadable to it, and turns a stolen account into a defaced page.

The rule is short: **the cookie that identifies the visitor is `HttpOnly`, always.** If code on the
page needs to know who is signed in, ask the server; do not keep the answer somewhere a script can
take it.

## `SameSite`

The newest of them, and the one that needs a story.

Your browser attaches cookies for a site to any request going to that site — including requests
that some *other* site's page caused. A page anywhere can contain an image whose address is your
bank, or a form that submits to it, and historically the browser would attach your cookies to that
request, because the rules in the previous section never mentioned where the request came from.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Another site's page causes a request to your bank. Under the old rules the browser attaches your cookies to it. With SameSite set to Lax it does not, while a link you click still arrives signed in.\"> <rect x=\"20\" y=\"30\" width=\"220\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"130\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">some other page,</text> <text x=\"130\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">open in another tab</text> <path d=\"M246 56 L436 56\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"341\" y=\"42\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">causes a request</text> <rect x=\"442\" y=\"30\" width=\"258\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"571\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your bank, where you are signed in</text> <rect x=\"20\" y=\"108\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"185\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the old rules</text> <text x=\"185\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">cookies attached: it is authenticated</text> <rect x=\"370\" y=\"108\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"535\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SameSite=Lax</text> <text x=\"535\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no cookies: it is a stranger</text> <text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and a link you click through to the bank still arrives signed in</text> <text x=\"360\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is the difference between Lax and Strict, and why Lax is the one in use</text> </svg>", "caption": "The defence used to be the application's job. This moved it into the browser, and made it the default."}
```

So a page you visit while signed in somewhere else could quietly make a request on your behalf,
authenticated as you. It is called cross-site request forgery, and defending against it used to be
entirely the application's job.

`SameSite` moves the defence into the browser.

`Strict` means the cookie is attached only to requests from your own site. Safe, and it has an
edge: follow a link to your own site from anywhere else — an email, a search result — and the
cookie is not sent, so you arrive signed out.

`Lax` is the middle, and the default in current browsers. The cookie is sent when you **navigate**
to the site by clicking a link, and not on background requests another site's page makes. That
keeps the link from an email working and closes the forgery.

`None` means the old behaviour, and browsers accept it only with `Secure`. It is a real requirement
for a few things — payment flows that leave and return, a widget embedded in somebody else's site —
and it is a decision to make deliberately rather than a value to copy from a search result.

## `Domain`, and widening on purpose

Left out, a cookie goes back to exactly the host that set it. Add `Domain=codeschool.ing` and it
goes to that host **and every subdomain of it** — `app.`, `api.`, `console.`, and anything created
next year.

That is occasionally what you want and is a larger decision than it looks. A cookie shared across
subdomains is readable by whatever is running on the least careful of them, and subdomains are
exactly the things that get handed to a contractor, a marketing tool or a status page.

The related trap has a name worth recognising: a subdomain that stops being used, whose name still
points at a provider where anybody can claim it, becomes a page on your domain run by a stranger —
holding your widened cookies. It is called a subdomain takeover, and it is a good reason to widen
nothing without a reason.

## Two prefixes that enforce the rest

A small, recent and genuinely useful mechanism: if a cookie's **name** begins with `__Host-`, the
browser refuses to accept it unless it is `Secure`, has `Path=/`, and has no `Domain` at all.
`__Secure-` is the weaker one, requiring only `Secure`.

It reads like a trick and it solves a real problem. Everything else in this reading is an attribute
the server sets, so a mistake is silent — the cookie works, with less protection than intended.
A prefix moves the requirement into a place the browser checks, which turns *we forgot* into *it
did not work*, and those are very different bugs to have.

## The combination to remember

For the cookie that says who somebody is: `Secure`, `HttpOnly`, `SameSite=Lax`, a `Max-Age` you
chose on purpose, and a value that is an identifier rather than information.

Each of those four closes something that has cost real people their accounts, and none of them
costs anything to write.
