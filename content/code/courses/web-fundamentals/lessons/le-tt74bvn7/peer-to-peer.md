---
title: Where the model does not hold
version: 1
---

A model earns trust by being clear about where it stops. Client and server is not the only way
machines talk, and knowing the alternative sharpens the original rather than complicating it.

## Peer-to-peer

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
