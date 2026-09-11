---
title: What the S adds
version: 1
---

Everything so far has been readable text travelling over wires you do not own. The café, the
building, the provider, every network between here and the server — all of them handle it, and
nothing in the protocol has stopped any of them reading it.

HTTPS is the same protocol with a layer underneath that fixes this, and it fixes three separate
things. Most people can name one.

## Three promises

**Confidentiality.** Nobody along the path can read what you sent or what came back.

**Integrity.** Nobody along the path can change it without being detected. This is the promise
people forget, and it is the one with the most history behind it: providers have injected
advertising into pages passing through their networks, and networks have rewritten links. Reading
is invisible; changing is what actually reaches the visitor.

**Identity.** The machine answering can prove it controls the name you asked for. Without this the
other two are worthless — an encrypted conversation with whoever intercepted you is still a
conversation with whoever intercepted you.

The third is the one the certificate does, and the video after this section is about the limits of
what it proves.

## What happens before the first request

The connection has to be negotiated before any HTTP is spoken, and the cost of that negotiation is
something you can measure.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The exchanges before a request can be sent. Two round trips are spent agreeing on a cipher, presenting the certificate and establishing a key; only after them does the first HTTP request move.\"> <rect x=\"20\" y=\"26\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"120\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">your browser</text> <rect x=\"500\" y=\"26\" width=\"200\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"600\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the server</text> <path d=\"M120 66 L120 292\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\" fill=\"none\"></path> <path d=\"M600 66 L600 292\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 4\" fill=\"none\"></path> <text x=\"360\" y=\"86\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">these are the versions and ciphers I speak</text> <path d=\"M124 96 L596 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"128\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">this one, then — and here is my certificate</text> <path d=\"M596 138 L124 138\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">checked; here is the material for our key</text> <path d=\"M124 180 L596 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">agreed — everything after this is encrypted</text> <path d=\"M596 222 L124 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"360\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">GET / HTTP/1.1</text> <path d=\"M124 264 L596 264\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path> <text x=\"360\" y=\"306\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">two round trips before a single byte of your request moves — on a 100 ms link, 200 ms</text> </svg>", "caption": "The cryptography is not the part to remember. The round trips are, because they are what you pay."}
```

The two sides agree on which version and which cipher they will use, the server presents its
certificate, the client checks it, and the two establish a key that only they hold. Then everything
after that point is encrypted with it.

The part worth remembering is the shape rather than the cryptography: **this costs round trips**,
and a round trip costs the latency of lesson three. On a link with 100 ms of latency, one extra
exchange is 100 ms during which nothing of yours has moved. The newest version of the protocol was
designed to do it in one exchange rather than two, and has a mode that sends the first request with
no exchange at all when the two have spoken before — which tells you how much that time was worth
to somebody.

Two things follow for the rest of this course. Connections are worth reusing, because the expensive
part happens once per connection. And a page assembled from six different hosts pays this cost six
times.

## What is still visible

Encryption hides the contents of the conversation, and this is where people's mental model is
usually too generous.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two columns listing what an observer on the network path can still see and what the encryption hides. Visible: the address, the site name, the timing and the volume. Hidden: the path, the content, what was typed and what came back.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">still visible to anybody on the path</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the address you connected to</text> <rect x=\"20\" y=\"80\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the site name you asked for</text> <rect x=\"20\" y=\"124\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">when, and for how long</text> <rect x=\"20\" y=\"168\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"180\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">how many bytes moved each way</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">hidden from them</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">which page of it you asked for</text> <rect x=\"380\" y=\"80\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">everything you typed into it</text> <rect x=\"380\" y=\"124\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your cookies, and who you are</text> <rect x=\"380\" y=\"168\" width=\"320\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"540\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the whole of what came back</text> <text x=\"360\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the line runs between which site and which page</text> <text x=\"360\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and most confident advice about this gets the side of that line wrong</text> </svg>", "caption": "Encryption hides the conversation, not the fact that you had it or with whom."}
```

An observer on the path still sees the address you connected to, and — in almost all deployments —
the **name** you asked for, which is sent before the encryption starts so the server knows which
certificate to present. They see when you connected, how long you stayed, and how many bytes moved
in each direction.

That is enough to know you visited a particular site, roughly how much you read, and for how long.
It is not enough to know which page, what you typed, who you are logged in as, or what came back.

The gap between *which site* and *which page* is the whole privacy difference, and it is worth
being precise about, because a great deal of confident advice on the internet is wrong in one
direction or the other.

## When the check fails

A browser refusing a certificate is showing you one of a small number of distinct problems, and
they are not equally serious.

**Expired.** The dates on the certificate have passed. Nearly always an automatic renewal that
stopped working, and nearly always the site's own fault rather than an attack.

**The wrong name.** The certificate is valid and is for a different name — `example.com` presented
for `www.example.com`, most commonly. A configuration mistake, and indistinguishable from the real
thing to a browser, which is why it refuses.

**An issuer it does not know.** The chain ends somewhere that is not in the browser's list. On a
company network this is often deliberate: the employer has installed its own root so that its
equipment can read employees' traffic. On a café network it means something else entirely, and the
difference is not something the browser can work out for you.

The one thing worth taking from this list is that clicking past the warning does not fix anything;
it declines all three promises at once, for that visit.

## The page that is half encrypted

A page served over HTTPS can ask for an image, a script or a stylesheet over plain HTTP, and if it
does, the guarantees are gone for that part of it.

A script is the serious case: whoever can change it in transit can do anything the page can do,
which makes the padlock on the surrounding page an active lie. Browsers now refuse to load that
combination at all, and quietly upgrade or block the gentler ones.

It matters here because it is usually accidental — one address typed with the wrong scheme years
ago, in a file nobody opens.

## Why it became the default

For most of the web's life HTTPS was for payment pages. Certificates cost money and renewing them
was a manual job somebody forgot.

Two things changed. Certificates became free and automatic, so the reason not to bother
disappeared. And browsers began marking plain HTTP as *not secure* in the address bar, which turned
an invisible technical choice into something visitors could see.

Today a site on plain HTTP is treated as a defect by browsers, by search engines and by anybody
looking at the address bar, and the work of fixing it is mostly a configuration file. There is one
more piece of it worth knowing: a site that has moved usually also sends a header asking the
browser to refuse plain HTTP to that name in future, so that even the first redirect stops being an
opportunity for somebody in the middle.
