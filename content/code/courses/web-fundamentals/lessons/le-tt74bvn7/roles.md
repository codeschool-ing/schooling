---
title: The two roles
version: 1
---

Almost everything that happens on the internet is a conversation between two parties, and the two
parties have fixed jobs. The **client** asks. The **server** answers.

That is not a simplification you will outgrow. It is the actual shape, and it holds from the
smallest exchange to the largest — from a phone checking whether a message was delivered to a bank
settling a payment.

## The roles belong to the moment, not to the machine

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Three machines in a row: browser, web server, database. Four numbered arrows in time order — the browser asks the server, the server asks the database, the database answers, the server answers. The middle machine is the server in the first exchange and the client in the second.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"14\" y=\"96\" width=\"162\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Browser</text><text x=\"95.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">always a client</text>\n  <rect x=\"279\" y=\"96\" width=\"162\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Web server</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">both, here</text>\n  <rect x=\"544\" y=\"96\" width=\"162\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625.0\" y=\"121.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Database</text><text x=\"625.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">always a server</text>\n\n  <path d=\"M176 116 L273 116\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"224\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 · asks</text>\n  <path d=\"M441 116 L538 116\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"489\" y=\"107\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 · asks</text>\n\n  <path d=\"M538 140 L444 140\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"491\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 · answers</text>\n  <path d=\"M273 140 L179 140\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"226\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 · answers</text>\n\n  <rect x=\"196\" y=\"196\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".13\" stroke=\"var(--phosphor-dim)\"></rect>\n  <text x=\"271\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SERVER in exchange 1+4</text>\n  <rect x=\"374\" y=\"196\" width=\"150\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\"></rect>\n  <text x=\"449\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CLIENT in exchange 2+3</text>\n  <path d=\"M300 196 L330 164\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path>\n  <path d=\"M420 196 L390 164\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path>\n  <text x=\"360\" y=\"250\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">one machine · one second · two roles</text>\n</svg>", "caption": "One machine, one second, both parts. The numbers are the order of time: exchange 4 cannot happen until 3 has come back."}
```

This is the sentence worth reading twice, because almost every later confusion comes from getting
it wrong.

"Server" is not a kind of computer. It is not a black rack in a cold room, and it is not something
you buy. **It is the part a machine is playing in one particular exchange**, and the same machine
plays a different part in the next one.

Consider a web server building a page. To build it, it needs data it does not have, so it asks a
database for that data:

- to your browser, it is the **server** — you asked, it answered;
- to the database, it is the **client** — it asked, the database answered.

Same machine. Same second. Two roles, because there are two exchanges.

The laptop you are reading this on is a client right now. It is also, at this moment, very
probably running a server: if you have ever opened `localhost:3000` while building something, that
was your own machine answering its own question. One computer, both roles, no contradiction.

## Watch one page load

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A timeline of a page loading. One long bar at the start is the HTML document; fourteen shorter bars begin after it and overlap each other; a lone bar later is the notification count. Two dashed bars at the foot are exchanges you never see, between the server and its database.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <line x1=\"118\" y1=\"30\" x2=\"118\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <line x1=\"700\" y1=\"30\" x2=\"700\" y2=\"196\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n  <text x=\"118\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 ms</text>\n  <text x=\"700\" y=\"22\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">~1200 ms</text>\n\n  <rect x=\"118\" y=\"34\" width=\"150\" height=\"13\" rx=\"2\" fill=\"var(--phosphor)\"></rect>\n  <text x=\"112\" y=\"44\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">the document</text>\n\n  <text x=\"112\" y=\"76\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">what it asked for</text>\n  <rect x=\"272\" y=\"52\" width=\"112\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"272\" y=\"64\" width=\"186\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"276\" y=\"76\" width=\"141\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"281\" y=\"88\" width=\"98\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"285\" y=\"100\" width=\"223\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"290\" y=\"112\" width=\"76\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"294\" y=\"124\" width=\"167\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n  <rect x=\"299\" y=\"136\" width=\"89\" height=\"9\" rx=\"2\" fill=\"var(--paper)\"></rect>\n\n  <rect x=\"470\" y=\"152\" width=\"118\" height=\"11\" rx=\"2\" fill=\"var(--phosphor-dim)\"></rect>\n  <text x=\"470\" y=\"148\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">a script asks, later</text>\n\n  <line x1=\"118\" y1=\"180\" x2=\"700\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line>\n  <rect x=\"150\" y=\"188\" width=\"64\" height=\"9\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 2\"></rect>\n  <rect x=\"150\" y=\"200\" width=\"47\" height=\"9\" rx=\"2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 2\"></rect>\n  <text x=\"112\" y=\"203\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">you never see</text>\n  <text x=\"228\" y=\"197\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">server → database, server → ads</text>\n  <text x=\"118\" y=\"236\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Your browser is not one client. It is a client fifteen times over, most of them at once.</text>\n</svg>", "caption": "What looks like loading a page is fifteen exchanges or more, nearly all overlapping — plus two on the far side that never touch your computer."}
```

Abstractions are easier to trust once you have counted something. Open any news site and a rough
version of this happens:

1. Your browser asks for the page at that address. One exchange. It gets back a document — a few
   dozen kilobytes of HTML, and **no images, no styling, no code**.
2. Reading that document, the browser discovers it needs a stylesheet, four scripts, a font and
   nine images. It asks for each of them. **Fourteen more exchanges**, most of them started before
   the first one has finished being read.
3. One of those scripts, once running, asks for your notification count. **Another exchange**, this
   one to a different machine entirely.
4. Meanwhile the server that answered step 1 asked a database for the headlines, and asked a second
   service for the advertisement. **Two more exchanges you never see**, because they happened on
   the far side.

What felt like "loading a page" was somewhere between fifteen and a hundred separate exchanges,
each one with an asker and an answerer, each one complete in itself.

Two things follow:

**Your browser is not one client, it is a client many times over.** It holds a dozen exchanges open
at once and assembles a page out of the answers as they arrive, in whatever order they arrive.

**Most of the exchanges are invisible to you.** The ones between the server and the machines behind
it never touch your computer. When something is slow, the cause is very often in a conversation you
cannot see — which is exactly why the vocabulary in this lesson is worth having.

## What each side is responsible for

The asymmetry between the two roles is not about power or size. It is about who starts and who
waits.

| | client | server |
|---|---|---|
| starts the exchange | **yes** | no |
| waits, doing nothing, until spoken to | no | **yes** |
| decides *what* to ask for | **yes** | no |
| decides *whether and how* to answer | no | **yes** |
| has to be reachable at a known address | not usually | **always** |
| can refuse the other party | not meaningfully | **yes, and does** |

Two rows deserve more than a cell.

### "Has to be reachable at a known address"

**A server has to be findable.** It sits at an address that other machines already know, or can
look up, and it waits there. A client does not need a fixed address in the same way — it goes out,
asks, and comes back with an answer.

This is why "the server went down" is a sentence people say and "the client went down" is not. If a
client stops, one person is inconvenienced. If a server stops, everybody who was going to ask it
anything finds nobody home.

It is also why running a server on your home laptop is harder than it sounds. Your laptop's address
changes, it sits behind equipment that does not forward incoming requests by default, and it goes
to sleep. None of those matter for a client. All of them are fatal for a server. Lesson 4 explains
the addressing part and lesson 9 explains what people rent to avoid the whole problem.

### "Can refuse"

The server decides whether to answer, and refusing is a normal, healthy thing for it to do — not a
malfunction. It may refuse because you are not allowed, because you asked for something that does
not exist, because you are asking too often, or because it is protecting itself from work it cannot
finish.

The client's power is the opposite one: it decides *whether to ask at all*, and it can walk away
before the answer arrives. Nothing obliges a client to wait, and this is why "cancel" works.

## The word "server" in the wild

You will meet the word used three different ways, and the ambiguity is real rather than something
you are failing to understand:

1. **The role** — "at that instant it is the server". This is the meaning this lesson is about.
2. **The program** — "we run an Nginx server on that machine". A piece of software whose whole job
   is to wait for requests and answer them.
3. **The hardware** — "we bought two servers". A physical machine bought to run programs of the
   second kind.

When someone says "server" and you cannot tell which one they mean, the useful question is: *is
this a thing that could be playing a different part in the next exchange?* If yes, they mean the
role. If it is bolted into a rack, they mean the metal.

## Three confusions worth clearing now

**"Client" does not mean "browser".** A browser is one kind of client. So is a mobile app, a
command-line tool like `curl`, a script that runs at three in the morning, a smart television, and
a payment terminal in a shop. If it asks, it is a client. This matters because a great deal of
traffic on the internet is machines talking to machines, with nobody watching.

**"Client and server" is not the same axis as "frontend and backend".** Frontend and backend
describe *where code runs and who wrote it* — the interface a person touches, against the system
behind it. Client and server describe *the part something plays in one exchange*. They line up
often enough to be confusing and they are not the same distinction: the backend is a server to the
browser and a client to the database, all while remaining, in every sentence, the backend.

**A server is not necessarily a big machine.** It is whatever is waiting to answer. A twenty-euro
computer the size of a credit card, sitting on a shelf and serving your photographs, is a server in
the fullest sense of every one of the three meanings above. Size is a consequence of how many
people ask, not of the role itself.

## What to carry into the rest of the course

Everything else in `web-fundamentals` is an answer to some part of one question: **how do the two
sides find each other, and how do they understand what was said?**

- Lessons 2 to 5 are about *finding* — packets, addresses and the layers that carry them.
- Lesson 6 is about *understanding* — the language the two sides speak.
- Lessons 8 and 9 are about *being findable* — names, and where a server lives.
- Lessons 10 and 11 are about what the client does with the answer once it has it.

Hold on to the shape and the rest hangs off it.
