---
title: The shape of an exchange
version: 1
---

One side asks, the other answers. Now look closely at the asking and the answering, because they
have a shape that repeats everywhere — in HTTP, which you meet in lesson 6, but also in database
queries, in the calls your phone makes to check for mail, and in protocols that were designed
before the web existed.

## Four things a request carries

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two large boxes side by side. The left one, labelled REQUEST, holds four stacked bands: what is being asked about, what kind of asking it is, the context, and an optional body. The right one, labelled RESPONSE, holds three: how it went, what came with it, and the content. Two arrows join them, one in each direction.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"14\" y=\"30\" width=\"310\" height=\"228\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n  <text x=\"26\" y=\"50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--paper)\">REQUEST</text>\n  <rect x=\"26\" y=\"62\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"38\" y=\"78\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what is being asked about</text>\n  <text x=\"38\" y=\"93\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">/orders/1183</text>\n  <rect x=\"26\" y=\"110\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"38\" y=\"126\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what kind of asking</text>\n  <text x=\"38\" y=\"141\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a reading, or a changing</text>\n  <rect x=\"26\" y=\"158\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"38\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">context to decide with</text>\n  <text x=\"38\" y=\"189\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">who you are · what you already hold</text>\n  <rect x=\"26\" y=\"206\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect>\n  <text x=\"38\" y=\"222\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">a body, when there is one</text>\n  <text x=\"38\" y=\"237\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">only a changing carries one</text>\n\n  <path d=\"M328 132 L388 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <text x=\"358\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"700\" fill=\"var(--paper)\">asks</text>\n  <path d=\"M388 166 L328 166\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <text x=\"358\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"700\" fill=\"var(--paper-dim)\">answers</text>\n\n  <rect x=\"396\" y=\"30\" width=\"310\" height=\"228\" rx=\"4\" fill=\"var(--phosphor-dim)\" fill-opacity=\".13\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n  <text x=\"408\" y=\"50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--paper)\">RESPONSE</text>\n  <rect x=\"408\" y=\"62\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect>\n  <text x=\"420\" y=\"78\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">how it went</text>\n  <text x=\"420\" y=\"93\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">first, so you can stop reading here</text>\n  <rect x=\"408\" y=\"110\" width=\"286\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"420\" y=\"126\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what came with it</text>\n  <text x=\"420\" y=\"141\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the kind of content · how long it keeps</text>\n  <rect x=\"408\" y=\"158\" width=\"286\" height=\"88\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"420\" y=\"176\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the content itself</text>\n  <text x=\"420\" y=\"191\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the largest part, and the last to matter</text>\n  <text x=\"420\" y=\"212\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a failure is allowed to carry one too,</text>\n  <text x=\"420\" y=\"226\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">and a good one explains itself</text>\n\n  <text x=\"360\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the status is at the top because it is what the asker acts on</text>\n</svg>", "caption": "What each side carries, and why the order matters: the status line comes before the content so the asker can act without reading the rest."}
```

Whatever the protocol, a request has to say four things, or the other side cannot act on it:

1. **Who it is for** — the address, and the endpoint on it.
2. **What is wanted** — an identifier for the thing being asked about.
3. **What kind of asking this is** — am I reading something, or changing something?
4. **Anything the other side needs in order to decide** — who is asking, what format they can read,
   what they already have.

Item four is where most of the size of a real request lives, and it is the part beginners are most
surprised by. Asking for a page is rarely just "give me the page". A typical request from a browser
carries a dozen or more pieces of context: which languages you read, whether you accept compressed
responses, what identified you last time, which page you were on when you clicked.

### Reading and changing are not the same kind of asking

Item three deserves more attention than its one line suggests, because it is the distinction that
almost every design decision on top of it depends on.

Some requests **only read**. They can be repeated with no consequence, they can be cached, a
browser can make them again when you press back, and a machine that is unsure whether one arrived
can simply send it again.

Some requests **change something**. Sending one twice may charge a card twice, post a comment
twice, or delete something that was already gone. Nothing about these can be repeated casually,
nothing about them can be cached, and "did that go through?" becomes a genuinely hard question.

The vocabulary for this arrives in lesson 6 with real names. The idea is worth having now, because
it explains something you have experienced: **why a page sometimes warns you before reloading.**
The browser knows the last request changed something, and it knows it cannot repeat it on its own
authority.

## Three things a response carries

1. **How it went** — succeeded, failed, failed in a way you can fix, failed in a way you cannot.
2. **What kind of thing is coming back** — a page, a picture, a piece of data, nothing at all.
3. **The thing itself**, if there is one.

Notice that "how it went" is separate from "the thing itself", and that it comes first. That
ordering is deliberate and it is everywhere: **a response says whether before it says what**, so
the asker can decide what to do without reading the whole answer.

A failure with a body full of apology text is still a failure, and the client should be able to
know that from the first line. This is what lets a browser show an error page instead of rendering
a server's internal complaint, and what lets a script retry without parsing anything.

### The categories of "how it went"

Without teaching the exact codes yet, the families are worth knowing because they divide
responsibility:

- **It worked.** Here is what you asked for.
- **Look elsewhere.** What you asked for is somewhere else now; ask again over there.
- **You got it wrong.** The request was malformed, or asked for something that does not exist, or
  was not allowed. *Fixing this is the client's job.*
- **I got it wrong.** Something failed on my side. *Fixing this is the server's job, and asking
  again may simply work.*

That last split is the useful one. The difference between "you got it wrong" and "I got it wrong"
tells a client whether retrying is sensible or futile, and it tells a person which team to talk to.

## The exchange is complete when the answer arrives

One request, one response. Then it is over.

This sounds obvious and it has a consequence that surprises everybody the first time: **the server
does not, by default, remember you.** The exchange ended. The next request you send arrives as if
from a stranger.

Think about what that means for something as ordinary as a shopping basket. You add an item — one
exchange, over. You browse to another page — a second exchange, and as far as the plain shape is
concerned this is a completely unrelated stranger asking for a page. Something has to carry the
knowledge "this is the same person, and they have a basket" from the first exchange to the second,
and nothing in the shape does it for free.

The machinery that solves this is lesson 7's whole subject. What this lesson asks you to notice is
that **it has to exist at all** — that staying logged in is built rather than natural, and that the
forgetting is the default rather than a bug somebody failed to fix.

There is a real benefit hiding in the forgetting, incidentally. Because each exchange stands alone,
any machine that can answer it can answer it — which is what allows a busy site to have twenty
identical servers and send your requests to whichever is free. A server that remembered you would
have to be *the same server* every time, and that constraint is expensive.

## The server never speaks first

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 336\" role=\"img\" aria-label=\"Three timelines. In the first the client asks four times and three answers say nothing changed. In the second the client opens a line once and the server sends along it whenever it likes. In the third, crossed out, the server tries to speak to a client that has asked for nothing, and there is nowhere to send it.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"20\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">1 · KEEP ASKING</text>\n  <line x1=\"120\" y1=\"42\" x2=\"700\" y2=\"42\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"120\" y1=\"84\" x2=\"700\" y2=\"84\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"112\" y=\"46\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">client</text>\n  <text x=\"112\" y=\"88\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">server</text>\n  \n  <path d=\"M136 44 L170 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M176 82 L210 46\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 2\" marker-end=\"url(#ah)\"></path>\n  <text x=\"173\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"400\" fill=\"var(--paper-dim)\">nothing changed</text>\n  <path d=\"M280 44 L314 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M320 82 L354 46\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 2\" marker-end=\"url(#ah)\"></path>\n  <text x=\"317\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"400\" fill=\"var(--paper-dim)\">nothing changed</text>\n  <path d=\"M424 44 L458 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M464 82 L498 46\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 2\" marker-end=\"url(#ah)\"></path>\n  <text x=\"461\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"400\" fill=\"var(--paper-dim)\">nothing changed</text>\n  <path d=\"M568 44 L602 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M608 82 L642 46\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\"  marker-end=\"url(#ahv)\"></path>\n  <text x=\"605\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">at last — something changed</text>\n\n  <text x=\"14\" y=\"150\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">2 · ASK ONCE, LEAVE THE LINE OPEN</text>\n  <line x1=\"120\" y1=\"172\" x2=\"700\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"120\" y1=\"222\" x2=\"700\" y2=\"222\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"112\" y=\"176\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">client</text>\n  <text x=\"112\" y=\"226\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">server</text>\n  <path d=\"M136 174 L176 218\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <text x=\"136\" y=\"244\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"700\" fill=\"var(--paper)\">the client still opened it — once</text>\n  <rect x=\"196\" y=\"188\" width=\"494\" height=\"10\" rx=\"5\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect>\n  <text x=\"443\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">and then the server sends along it, whenever it likes</text>\n  <path d=\"M330 220 L330 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M470 220 L470 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M610 220 L610 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n\n  <text x=\"14\" y=\"266\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper)\">3 · THE ONE THAT DOES NOT EXIST</text>\n  <line x1=\"120\" y1=\"284\" x2=\"700\" y2=\"284\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"120\" y1=\"326\" x2=\"700\" y2=\"326\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"112\" y=\"288\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">client</text>\n  <text x=\"112\" y=\"330\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">server</text>\n  <path d=\"M220 324 L220 286\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ahn)\"></path>\n  <path d=\"M211 306 L229 324\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></path>\n  <path d=\"M229 306 L211 324\" stroke=\"var(--amber)\" stroke-width=\"2.4\"></path>\n  <text x=\"248\" y=\"310\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">nothing was asked, so there is nowhere to send it</text>\n</svg>", "caption": "The two ways a page updates by itself, and the one that does not exist. In both that work the client opened the exchange — the difference is how many times."}
```

In the plain shape, the server cannot start anything. It has no way to reach into a client that has
not asked it for something.

That is why a page does not update on its own unless something was built to make it. There are two
ways round it, and both are arrangements rather than exceptions:

**The client keeps asking.** "Has anything changed? Has anything changed?" — every few seconds,
forever. Simple, works everywhere, and wasteful: most of the answers are "no", and each one costs a
full exchange.

**The two sides agree to hold a line open.** Instead of one request and one response, they set up a
channel that stays there, and the server can send along it whenever it likes. This is what live
chat and live scores actually use. It costs the server something to hold thousands of these open,
which is why it is not the default for everything.

Both of them start with a client asking. **Nothing arrives that nobody asked for** — the asking is
sometimes just a lot earlier than the arriving.

## Every exchange has a floor

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"The same operation drawn twice. Above, six requests one after another, each waiting for the previous answer, the waits adding up along the line. Below, one request returning everything, over the same distance.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ten exchanges, each waiting on the last</text>\n  <g stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\">\n    <path d=\"M14 44 L74 44 M74 44 L74 56 M74 56 L14 56\"></path>\n    <path d=\"M14 62 L74 62 M74 62 L74 74 M74 74 L14 74\"></path>\n  </g>\n  <g stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" opacity=\".55\">\n    <path d=\"M14 80 L74 80 M74 80 L74 92 M74 92 L14 92\"></path>\n    <path d=\"M14 98 L74 98 M74 98 L74 110 M74 110 L14 110\"></path>\n  </g>\n  <text x=\"90\" y=\"82\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">… ten times …</text>\n  <rect x=\"196\" y=\"44\" width=\"500\" height=\"66\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".13\" stroke=\"var(--amber)\" stroke-dasharray=\"4 3\"></rect>\n  <text x=\"446\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"700\" fill=\"var(--paper)\">10 × round trip</text>\n  <text x=\"446\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">~600 ms before anything can be shown</text>\n\n  <text x=\"14\" y=\"152\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one exchange that asks for everything</text>\n  <path d=\"M14 170 L74 170 M74 170 L74 182 M74 182 L14 182\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path>\n  <rect x=\"196\" y=\"164\" width=\"500\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\"></rect>\n  <text x=\"446\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"700\" fill=\"var(--paper)\">1 × round trip · ~60 ms</text>\n  <text x=\"14\" y=\"222\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">9,000 km is about 60 ms there and back, through fibre, at best. No machine is faster than that.</text>\n</svg>", "caption": "The same operation, two drawings. The distance does not change; the number of times it is paid does."}
```

One last property, and it is the one that makes people redesign things.

An exchange cannot be faster than the time it takes to get there and back. If the machine you are
asking is 9,000 km away, the answer cannot arrive in less than about 60 milliseconds no matter how
fast either side is, because that is roughly how long light takes to make the trip through fibre —
and real networks are slower than light.

So an operation built as ten exchanges in a row, each waiting for the last, has a floor of ten
round trips. The same operation built as one exchange that asks for everything has a floor of one.
This is why "chatty" is an insult in this field, and why lesson 3 spends its time on the difference
between how *much* you can send and how *long* it takes to hear back.
