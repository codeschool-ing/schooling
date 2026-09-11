---
title: Where the model does not hold
version: 1
---

A model earns trust by being clear about where it stops. Client and server is not the only way
machines talk, and knowing the alternative sharpens the original rather than complicating it.

## Peer-to-peer

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two arrangements side by side. On the left one server and many clients, every arrow meeting at the server. On the right, machines exchanging pieces directly with one another, every machine both asking and answering.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <text x=\"14\" y=\"24\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"700\" letter-spacing=\"1\" fill=\"var(--paper-dim)\">CLIENT AND SERVER</text>\n  <rect x=\"76\" y=\"52\" width=\"120\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"136.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">one server</text>\n  <g stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" opacity=\".65\" fill=\"none\">\n    <path d=\"M136 106 L44 176\"></path><path d=\"M136 106 L82 182\"></path><path d=\"M136 106 L120 188\"></path>\n    <path d=\"M136 106 L160 188\"></path><path d=\"M136 106 L198 182\"></path><path d=\"M136 106 L236 176\"></path>\n  </g>\n  <text x=\"136\" y=\"214\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">capacity ÷ 1000</text>\n  <text x=\"136\" y=\"232\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">more popular, worse served</text>\n\n  <line x1=\"360\" y1=\"30\" x2=\"360\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1\"></line>\n\n  <text x=\"404\" y=\"24\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"700\" letter-spacing=\"1\" fill=\"var(--paper-dim)\">PEER TO PEER</text>\n  <g fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\">\n    <circle cx=\"452\" cy=\"76\" r=\"17\"></circle><circle cx=\"556\" cy=\"60\" r=\"17\"></circle>\n    <circle cx=\"656\" cy=\"94\" r=\"17\"></circle><circle cx=\"470\" cy=\"160\" r=\"17\"></circle>\n    <circle cx=\"574\" cy=\"168\" r=\"17\"></circle><circle cx=\"662\" cy=\"176\" r=\"17\"></circle>\n  </g>\n  <g stroke=\"var(--phosphor)\" stroke-width=\"1\" opacity=\".6\" fill=\"none\">\n    <path d=\"M469 76 L539 61\"></path><path d=\"M573 60 L639 92\"></path><path d=\"M452 93 L470 143\"></path>\n    <path d=\"M487 160 L557 167\"></path><path d=\"M591 168 L645 176\"></path><path d=\"M556 77 L574 151\"></path>\n    <path d=\"M466 91 L559 155\"></path><path d=\"M649 108 L580 156\"></path>\n  </g>\n  <text x=\"556\" y=\"214\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"12\" font-weight=\"700\" fill=\"var(--phosphor)\">capacity × 1000</text>\n  <text x=\"556\" y=\"232\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each downloader is also a source</text>\n</svg>", "caption": "The inversion is the whole appeal. On one side popularity divides the load; on the other it multiplies it."}
```

In a **peer-to-peer** network there is no permanent asker and no permanent answerer. Every machine
is a **peer**: it holds some of what the network has, it asks others for what it lacks, and it
serves others what it holds.

BitTorrent is the example everyone knows. When you download a large file, you are not pulling it
from one machine — you are pulling pieces from many machines that already have those pieces, and
while you do it, you are handing out the pieces you have already got. Nobody is in charge, and
there is no single machine whose failure ends the transfer.

The arithmetic is what makes it attractive. In the client-and-server shape, a thousand people
downloading a file means one machine sends it a thousand times, and its capacity is divided a
thousand ways — **the more popular something is, the worse it serves**. In peer-to-peer, each new
downloader is also a new source, so a thousand people is a thousand machines helping. **The more
popular something is, the better it serves.** That inversion is the whole appeal, and it is why
this shape is used for exactly the things that get very popular very suddenly: film releases,
operating system images, game updates.

## The roles survive anyway

Here is the part that matters for this lesson, and it is easy to miss.

**Peer-to-peer does not abolish the two roles. It abolishes the two *jobs*.** Look at any single
exchange between two peers and one of them asked and the other answered — client and server, for
that exchange. What changes is that no machine holds either role permanently: a peer is a client
for a piece it wants and a server for a piece it has, thousands of times a minute.

Which is exactly the point of `roles`: the role is the position in an exchange. **P2P is the case
that proves it**, because it is where the role changes fastest. If the roles were properties of
machines, peer-to-peer would be unintelligible. As positions in an exchange, it is ordinary.

## How does a peer find other peers?

This is the question the shape has to answer, and the honest answer is uncomfortable for anyone who
likes the idea of no central anything.

**Somebody has to hand out the first address.** A machine that has just joined knows nothing and
nobody. It cannot ask the network where the network is.

Three answers are used, and none is as pure as the slogan:

- **A tracker** — a server, in the plainest sense, whose job is to hold the list of who has what.
  You ask it, it answers. It is a single point of failure sitting in the middle of an architecture
  whose selling point is not having one.
- **A distributed table** — the list itself is spread across the peers, so no one machine holds it.
  Better, and it still requires **bootstrap nodes**: a handful of well-known addresses, baked into
  the software, that a newcomer contacts to be introduced. Fewer central points. Not zero.
- **Local discovery** — shouting on the local network to see who is nearby. Works only for peers on
  the same network, which is rarely where the file is.

So real peer-to-peer systems are **hybrids**, and it is worth saying plainly: the parts that
discover, coordinate and authenticate tend to look like servers, and the parts that carry bulk data
tend to look like peers. Very few working systems are one thing all the way down.

## Why the web is not peer-to-peer

The web could have been built this way and was not, for reasons that are mostly about **trust and
findability** rather than technology:

- **Somebody has to be authoritative.** When you ask your bank for your balance, you need the
  answer to come from the bank, not from whichever peer claims to have a copy. Peer-to-peer is
  excellent at distributing a file that is the same for everyone and has no answer to the question
  "who is allowed to see this?"
- **Somebody has to be findable.** A peer that is offline is simply absent. That is tolerable for a
  film, where you wait or find another source, and intolerable for a shop, which has to be open
  when a customer arrives.
- **Publishing has to be controllable.** In peer-to-peer, what spreads is what people choose to
  keep copying. Nobody can take it back, correct it, or update it — and "nobody can take it back"
  is a feature and a catastrophe depending on what was published.
- **Most content is not popular.** The arithmetic above only works when many people want the same
  thing at the same time. For a page eleven people read this month there are no peers to share it,
  and a server is simply the right answer.

## The middle ground you actually use every day

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A drawing in two zones. Above, inside a box marked as the server role, a tracker at a known address. Below, inside a box marked as exchange between peers, four peers trading pieces of a file with each other in every direction. Dotted arrows rise from each peer to the tracker.\"><defs>\n<marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker>\n<marker id=\"ahs\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker>\n<marker id=\"ahv\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker>\n<marker id=\"ahn\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\">\n  <path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker>\n</defs>\n  <rect x=\"14\" y=\"14\" width=\"692\" height=\"96\" rx=\"4\" fill=\"var(--phosphor-dim)\" fill-opacity=\".13\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></rect>\n  <text x=\"28\" y=\"34\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--phosphor-dim)\">DISCOVERY · the server role, whatever it is called</text>\n  <text x=\"28\" y=\"62\" font-family=\"Archivo, sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">every peer asks it, once, on joining:</text>\n  <text x=\"28\" y=\"78\" font-family=\"Archivo, sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">who is here, and who holds what?</text>\n  <rect x=\"430\" y=\"40\" width=\"168\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"514.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">tracker</text><text x=\"514.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"JetBrains Mono, monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a known address</text>\n\n  <path d=\"M84 176 L470 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M268 176 L500 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M452 176 L528 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n  <path d=\"M636 176 L558 100\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\" marker-end=\"url(#ahv)\"></path>\n\n  <rect x=\"14\" y=\"140\" width=\"692\" height=\"126\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\".13\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect>\n  <text x=\"28\" y=\"160\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" font-weight=\"700\" fill=\"var(--phosphor)\">TRANSFER · peers, and this is what makes it peer-to-peer</text>\n  <rect x=\"16\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer A</text><rect x=\"200\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"268.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer B</text><rect x=\"384\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"452.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer C</text><rect x=\"568\" y=\"178\" width=\"136\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">peer D</text>\n  \n  <path d=\"M154 192 L194 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M194 208 L154 208\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M338 192 L378 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M378 208 L338 208\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M522 192 L562 192\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M562 208 L522 208\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M84 224 Q268 258 446 224\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <path d=\"M268 226 Q452 262 630 226\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah)\"></path>\n  <text x=\"360\" y=\"290\" text-anchor=\"middle\" font-family=\"Archivo, sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the tracker holds no files, and it is still being asked and still answering</text>\n</svg>", "caption": "The hybrid, which is what almost everything is in practice. Finding out who exists is an exchange with a server; moving the data is not. Different questions, so they are allowed different shapes."}
```

Between the two shapes there is an arrangement that borrows from both, and it is the one running
underneath most of the internet you touch: the **content delivery network**.

The idea is to keep the client-and-server shape — one authoritative origin, findable, in charge —
and copy the popular, unchanging parts of what it serves onto machines placed near everybody. When
you ask for a video, you are answered by a machine perhaps fifty kilometres away rather than the
origin nine thousand kilometres off.

It solves the same problem peer-to-peer solves — one machine cannot serve everyone — and it solves
it while keeping somebody authoritative and findable. You are still a client, and it is still a
server. There are just a great many servers, arranged deliberately, all of them under one owner.

Lesson 9 goes into what that costs and when it is worth it.

## "Decentralised" is a different claim

One caution, because the words travel together and mean different things.

Peer-to-peer is a statement about **who holds the data and who answers**. Decentralisation is
usually a statement about **who is in charge** — who can change the rules, remove something, or
shut it down.

A system can be peer-to-peer and effectively controlled by whoever writes the software everyone
runs. A system can be built entirely out of ordinary servers and be genuinely hard for any one
party to control, because there are thousands of independent operators — which is roughly the story
of email. When you meet a claim that something is decentralised, the useful question is not what
shape its traffic has. It is **who could stop it, and how many of them are there.**

## The shape, in one line

**Client asks, server answers, the role belongs to the exchange.**

Everything in the rest of this course — packets, HTTP, DNS, hosting, the browser — is an answer to
some part of the question *how do those two find each other and understand what was said?*
