---
title: Host, node, endpoint
version: 1
---

The last section was about *roles*. This one is about the *things* playing them, and about three
words that get used for those things almost interchangeably — but not quite.

Getting these three straight is worth the effort for a practical reason: when something is broken,
the first useful question is always **which of these three is broken**, and you cannot ask it
without the words.

## Host

A **host** is a machine on a network that can be reached: it has an address, and something on it is
prepared to talk.

The word is older than the web and it means what it sounds like. A host is a machine that hosts —
that holds things and receives visitors. Your laptop is a host. A phone on mobile data is a host. A
rented machine in a data centre is a host. A printer with a network cable in it is a host.

What makes something a host is **being addressable**, not being important.

A host does not have to be a whole physical computer, and increasingly is not. One physical machine
may run twenty virtual ones, each with its own address, each a host in its own right and unaware of
the others. From the outside there is no way to tell, and no reason to care — which is the point of
the arrangement.

## Node

A **node** is anything on the network at all, including the machinery that only moves traffic
along — routers, switches, the boxes between you and everything else.

So every host is a node, and plenty of nodes are not hosts. The router in your home is a node: it
is very much on the network, but you do not visit it, it does not hold your files, and it exists to
pass packets from one side to the other.

When somebody says node, they are usually thinking about the **shape of the network** — the
diagram, the path, the hops between here and there. When somebody says host, they are usually
thinking about **a machine you could talk to**. Same equipment, different question being asked
about it.

## Endpoint

An **endpoint** is one specific place you can send a request to and get an answer from.

This is the narrowest of the three, and the difference matters: a host is a machine, but a machine
runs many things at once. One host can be:

- a web server, answering page requests;
- a mail server, accepting mail;
- an SSH server, accepting logins.

Three endpoints, one host. Each one is a different destination even though they share an address.

### What separates them is the port

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"A large rectangle is one host with one address. Inside it, three smaller boxes are endpoints, on ports 443, 22 and 25. An arrow arrives from outside addressed to the address followed by colon 443, and reaches only the first box.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"196\" y=\"30\" width=\"510\" height=\"150\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect>\n  <text x=\"212\" y=\"50\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--paper-dim)\">ONE HOST</text>\n  <text x=\"212\" y=\"66\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">203.0.113.7</text>\n\n  <rect x=\"216\" y=\"84\" width=\"150\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"291.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">web server</text><text x=\"291.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:443</text>\n  <rect x=\"382\" y=\"84\" width=\"150\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"457.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">SSH</text><text x=\"457.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:22</text>\n  <rect x=\"548\" y=\"84\" width=\"142\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"619.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">mail</text><text x=\"619.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:25</text>\n\n  <path d=\"M20 121 L210 121\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <text x=\"20\" y=\"112\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">203.0.113.7:443</text>\n  <text x=\"20\" y=\"142\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one request</text>\n  <text x=\"196\" y=\"206\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Three endpoints. One host. One address. The number is what chose.</text>\n</svg>", "caption": "The address finds the machine. The port finds the program. The other two are listening the whole time and are not what the request was for."}
```

An address gets a request to the right **machine**. A **port** — a number carried alongside the
address — gets it to the right **program on that machine**.

The convention is that certain numbers mean certain services, so that a client knows where to knock
without being told:

| port | what usually waits there |
|---|---|
| 80 | a web server, unencrypted |
| 443 | a web server, encrypted — the one nearly everything uses now |
| 22 | SSH, for logging in to the machine itself |
| 25 | mail being handed between servers |
| 5432 | a PostgreSQL database |

These are conventions, not laws. A web server can listen on 8080, or 3000, or 61234 — which is
exactly what happens when you run something locally and open `localhost:3000`. The number after the
colon *is* the port, and you are typing it because your development server did not take the
conventional one.

You will meet ports properly in the next lesson, alongside sockets. For now the useful idea is
this: **"the machine" and "the thing on the machine that answers" are not the same object**, and
almost every confusing failure lives in the gap between them.

## One host, many names — and many hosts, one name

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" aria-label=\"Two panels. On the left, three different domain names point at a single address holding one web server. On the right, a single name points at three addresses in different cities, and the one that is chosen depends on where the asker is.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">MANY NAMES → ONE HOST</text>\n  <line x1=\"348\" y1=\"8\" x2=\"348\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></line>\n  <text x=\"368\" y=\"18\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--paper-dim)\">ONE NAME → MANY HOSTS</text>\n\n  <rect x=\"14\" y=\"42\" width=\"122\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"75\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop.example</text>\n  <rect x=\"14\" y=\"86\" width=\"122\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"75\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">blog.example</text>\n  <rect x=\"14\" y=\"130\" width=\"122\" height=\"26\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"75\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">api.example</text>\n\n  <path d=\"M136 55 L204 96\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M136 99 L204 101\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M136 143 L204 106\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n\n  <rect x=\"210\" y=\"76\" width=\"118\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"269.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">one host</text><text x=\"269.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">203.0.113.9</text>\n  <text x=\"269\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the web server reads</text>\n  <text x=\"269\" y=\"165\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">which name you asked for</text>\n\n  <rect x=\"368\" y=\"76\" width=\"118\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"427.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">one name</text><text x=\"427.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cdn.example</text>\n\n  <path d=\"M486 90 L546 58\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M486 102 L546 102\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <path d=\"M486 114 L546 146\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n\n  <rect x=\"554\" y=\"44\" width=\"152\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"630\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">198.51.100.4 · Paris</text>\n  <rect x=\"554\" y=\"88\" width=\"152\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n  <text x=\"630\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">203.0.113.7 · S. Paulo</text>\n  <rect x=\"554\" y=\"132\" width=\"152\" height=\"28\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect>\n  <text x=\"630\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">192.0.2.31 · Tokyo</text>\n\n  <text x=\"630\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">you get the one nearest you</text>\n  <text x=\"360\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the name is a label somebody resolves — the address is where the packets go</text>\n</svg>", "caption": "Both directions exist, and they are the same question asked backwards. A name is not an address: it is a label somebody resolves, and the answer may differ per visitor."}
```

Two arrangements that surprise people, and both are ordinary:

**One host can answer to many names.** A single machine at a single address routinely serves
hundreds of different websites. The request carries the name the client asked for, the server reads
it, and answers with the right site. Nothing about the address or the port distinguishes them —
only the name inside the request. This is why cheap hosting is cheap.

**One name can point at many hosts.** A large site's name resolves to different machines for
different people, chosen by where they are or which machines are healthy right now. "The server"
for such a site is not a machine at all; it is a changing set of them.

So "which host answered me?" is a real question with a real answer, and it is not always the answer
you would guess from the address bar. Lesson 8 covers the machinery that makes both of these work.

## Why the distinction earns its keep

```schooling-figure
{"svg": "<svg viewBox=\"0 0 744 282\" role=\"img\" aria-label=\"Three attempts drawn one above the other. The first is a dashed arrow that reaches nothing and ends in a crossed circle. The second is an arrow out and an immediate arrow back. The third is a complete exchange whose answer carries a box marked error.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"24\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"700\" letter-spacing=\"1.2\" fill=\"var(--paper-dim)\">WHAT COMES BACK</text>\n\n  <text x=\"14\" y=\"60\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">host unreachable</text>\n  <path d=\"M196 54 L520 54\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"5 4\"></path>\n  <circle cx=\"536\" cy=\"54\" r=\"10\" fill=\"var(--amber)\" fill-opacity=\".13\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></circle>\n  <path d=\"M531 49 L541 59 M541 49 L531 59\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></path>\n  <text x=\"558\" y=\"58\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">nothing comes back · timeout</text>\n\n  <text x=\"14\" y=\"140\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">nothing listening</text>\n  <path d=\"M196 128 L300 128\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M300 150 L199 150\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ahv)\"></path>\n  <text x=\"316\" y=\"145\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor-dim)\">refused, immediately · the host is alive</text>\n\n  <text x=\"14\" y=\"222\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">both fine</text>\n  <path d=\"M196 210 L520 210\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M520 232 L392 232 M326 232 L199 232\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#ahs)\"></path>\n  <rect x=\"330\" y=\"220\" width=\"58\" height=\"22\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect>\n  <text x=\"359\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">error</text>\n  <text x=\"540\" y=\"228\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the exchange worked</text>\n  <text x=\"14\" y=\"270\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Nothing is “down” in the third one. Something is wrong.</text>\n</svg>", "caption": "Three failures the same sentence hides. A timeout is nobody there to say no; a refusal is somebody saying it, and is the healthiest of the three; an answered error is the whole exchange working and the content being wrong."}
```

Because "the server is down" is three different problems, they are fixed by different people, and
**they look different from the outside**:

| what is wrong | what you see |
|---|---|
| the **host** is unreachable — off, or the network to it is broken | the attempt hangs, then gives up: a timeout |
| the host is fine, the **endpoint** is not — nothing is listening on that port | an immediate, definite refusal |
| both are fine and the **answer is an error** | a fast, well-formed response that says it went wrong |

The difference between the first two is worth internalising. **A timeout means nobody was there to
say no.** Your request went out and nothing came back — the machine is
off, or something between you and it is dropping traffic silently.

**A refusal means something was there and said no.** The machine is up, the network reached it, and
its operating system answered "nothing is listening on that port". That is a *healthier* failure
than a timeout, because it tells you the host is alive and narrows the problem to the program.

The third is different in kind: the exchange completed perfectly and the content of the answer is a
complaint. Nothing is down. Something is wrong.

A large part of diagnosing anything is knowing which of those three you are looking at. In the last
lesson of this course you will do exactly that with real tools; the vocabulary you need to tell
them apart starts here.

## A note on "the cloud"

None of this changes when the machine is rented rather than owned. A cloud server is a host: it has
an address, it runs programs that listen on ports, and it can be unreachable, or reachable with
nothing listening, or answering with an error.

What renting buys is that somebody else deals with the electricity, the hardware and the building,
and that you can have another one in ninety seconds. It does not buy a different model of how
machines talk, and anybody who tells you the cloud is a fundamentally different thing is selling
something. Lesson 9 is about the shapes you can rent and what each one actually takes off your
hands.
