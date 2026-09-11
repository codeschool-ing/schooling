---
title: Three versions, one meaning
version: 1
---

There are three versions of HTTP in daily use, and the most important thing about them is what did
**not** change. The methods are the same, the codes are the same, the headers are the same. A `GET`
that returns `404 Not Found` means what it meant in 1999.

What changed is how those things are written down and how many of them can be in flight at once.
Everything in this lesson so far survives all three versions intact.

## 1.1, and the queue

HTTP/1.0 opened a connection, sent one request, read one answer and closed. Each image on a page
paid a fresh connection, and — after the last lesson — you know what a connection costs.

HTTP/1.1 fixed the obvious part: keep the connection open and send the next request down the same
one. It also required `Host`, which turned one machine into many sites, and added the chunked
encoding that lets a server start sending before it knows the size.

What it did not fix is the queue. On one connection, requests are answered in order, so a slow one
holds up everything behind it even if those are ready.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"On one HTTP 1.1 connection four requests are answered one after another, and a slow second one delays the two behind it. On HTTP 2 the same four share one connection at the same time and the slow one delays only itself.\"> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/1.1 — one connection, one at a time</text> <rect x=\"20\" y=\"34\" width=\"90\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"65\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">page</text> <rect x=\"112\" y=\"34\" width=\"300\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"262\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a slow one</text> <rect x=\"414\" y=\"34\" width=\"90\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"459\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">style</text> <rect x=\"506\" y=\"34\" width=\"90\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"551\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logo</text> <text x=\"20\" y=\"88\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">the last two were ready early and waited anyway</text> <text x=\"20\" y=\"134\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/2 — one connection, all at once</text> <rect x=\"20\" y=\"144\" width=\"90\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"65\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">page</text> <rect x=\"20\" y=\"174\" width=\"300\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"170\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">a slow one, delaying nobody</text> <rect x=\"20\" y=\"204\" width=\"90\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"65\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">style</text> <rect x=\"122\" y=\"204\" width=\"90\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"167\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">logo</text> <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">same requests, same answers, same meaning — only the arrangement in time is different</text> </svg>", "caption": "Nothing about the requests changed between these two pictures. What changed is whether they have to queue."}
```

Browsers worked around this by opening six connections to each host, which is six handshakes and
six of everything. And developers worked around it too, in ways that shaped how sites were built
for a decade: dozens of small images combined into one big one to be cut up with stylesheets, every
script concatenated into a single file, assets spread over `static1`, `static2`, `static3` so the
six-connection limit applied three times.

All of that was work done to defeat a limitation of the protocol, and all of it made the sites
harder to change.

## 2, and one connection with many lanes

HTTP/2 kept every meaning and replaced the encoding. The text became a binary format — no longer
something you can read off the wire by eye, which is a real loss — and that format carries numbered
frames, so many exchanges can share one connection at the same time.

Requests no longer wait for each other. A hundred small files arrive over one connection, in any
order, and the slow one delays only itself.

Headers are compressed too, and with a table of what was already sent: the twenty headers a browser
repeats on every request stop being sent twenty times.

Two consequences worth carrying. Every workaround from the previous section became
counterproductive — one enormous concatenated file is now worse than the small ones it replaced,
and spreading assets over three hostnames costs three connections for nothing. And a page assembled
from many hosts loses most of the benefit, because the multiplexing is per connection and each host
is a different one.

The version also shipped a feature for pushing files the client had not asked for. Browsers removed
it. It turned out to send things the browser already had, more often than not, and the bandwidth it
wasted exceeded the latency it saved — a good reminder that a plausible optimisation is a
hypothesis until somebody measures it.

## 3, and the layer underneath

HTTP/2 removed the queue at its own layer, and uncovered one beneath it.

TCP delivers bytes in order. If one packet is lost, everything behind it waits — including bytes
belonging to completely different exchanges that arrived perfectly. The streams are independent to
HTTP and not independent to the layer carrying them, which is the cost of layering from lesson five
appearing in the place you would least expect it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"One packet is lost. On HTTP 2 over TCP every stream waits for it because the transport delivers in order. On HTTP 3 only the stream the packet belonged to waits, and the others continue.\"> <text x=\"20\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/2 over TCP — one packet of stream A is lost</text> <rect x=\"20\" y=\"34\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream A — waiting for the missing piece</text> <rect x=\"20\" y=\"66\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream B — arrived, and waiting anyway</text> <rect x=\"20\" y=\"98\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream C — arrived, and waiting anyway</text> <text x=\"480\" y=\"82\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">TCP hands over in order</text> <text x=\"20\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">HTTP/3 — the same packet is lost</text> <rect x=\"20\" y=\"162\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"240\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream A — waiting for the missing piece</text> <rect x=\"20\" y=\"194\" width=\"440\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"240\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">stream B — delivered</text> <text x=\"480\" y=\"196\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">each stream ordered</text> <text x=\"480\" y=\"214\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">on its own</text> </svg>", "caption": "HTTP/2 removed the queue at its own layer and uncovered the one below it. That is what HTTP/3 went after."}
```

Fixing that means changing the transport, and changing the transport means the boxes in the middle.
HTTP/3 is built on a new protocol carried over UDP, in which each stream has its own ordering, so a
lost packet stalls only the exchange it belonged to. It also folds the encryption agreement into the
connection setup, so a secure connection costs one round trip rather than two, and it identifies a
connection by something other than the four numbers of address and port — which means moving from
Wi-Fi to mobile does not drop it.

And it had to be carried over UDP for a reason you already know. A genuinely new protocol beside
TCP would meet the middleboxes of lesson five — the ones reaching up into headers whose shape they
assumed — and be dropped by networks that have no idea they are the cause. UDP already passes. The
newest transport on the internet is wearing a disguise, and the layer violation from two lessons
ago is why.

## What you actually do about it

Very little, which is the point.

You do not choose a version in your code. Browser and server agree on the best they both speak,
and the agreement is part of the connection setup you saw in the previous section. Your handlers,
your methods and your status codes are identical either way.

What changes is what is worth optimising. The rule is short: **on HTTP/1.1, fewer requests; on 2
and 3, fewer connections.** Which of those you are on is something the browser's developer tools
will tell you in a column that is hidden by default, and that this course turns on in its last
lesson.
