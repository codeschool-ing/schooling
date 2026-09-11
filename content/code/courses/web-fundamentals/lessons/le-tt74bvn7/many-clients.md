---
title: One server, many clients
version: 1
---

Every diagram of a request has one client in it. Real servers never see that picture. **The normal
condition of a server is answering a great many people at once**, and nearly everything that makes
server software complicated comes from that one fact.

## Your request is not special

When you load a page, the machine answering you is, in the same second, answering others. Your
request arrives, waits its turn, gets picked up, gets worked on — possibly alongside hundreds of
others in flight at the same moment — and gets answered.

This reframes a sentence you have said and heard:

> "The site is slow."

Almost always this means one of:

- **the server is busy** — more requests are arriving than it can finish, so yours waits longer;
- **the server is waiting on something else** — it asked a database and is stuck as a client;
- **the network between you and it is slow** — the server is fine and the distance is not;
- **the answer arrived quickly and your machine is slow to draw it** — nothing was wrong at all.

Four different problems, four different fixes, one symptom. Lesson 3 gives you the numbers to tell
the first three apart and lesson 10 explains the fourth.

## Why one machine can serve thousands

Because most of a request's life is spent **waiting**, not computing.

Follow one request through a server and time it honestly. Perhaps two milliseconds are spent
reading it and working out what is wanted. Then the server asks a database and **waits forty
milliseconds** — doing nothing, holding the request, while another machine does the work. Then a
further three milliseconds turning the result into a page. Five milliseconds of work, forty of
waiting.

During those forty milliseconds a server that could only do one thing at a time would be idle. So
server software is built not to be: it keeps many exchanges in flight and works on whichever one is
ready, in whatever order they become ready.

The consequence is that **capacity is rarely "how fast is the processor"**. It is closer to *how
many exchanges can be in flight before something runs out* — memory to hold them, connections to
the database, file handles, or the patience of the people waiting.

### Doing many things at once, and doing many things simultaneously

These are different, and the difference explains why adding processors sometimes helps and
sometimes does nothing.

**Many at once** means the server has a hundred exchanges open and is making progress on whichever
one can move. Most of them are waiting on something else; one is being worked on. A single
processor does this perfectly well, because there is only ever a little work to do at any instant.

**Many simultaneously** means genuinely computing several answers in the same instant, which needs
several processors.

Most web work is the first kind, which is why one modest machine can serve a surprising number of
people, and why doubling the processors on a server that is waiting on a database changes nothing
at all. Work out which kind of busy you have before buying the other kind of machine.

## The queue, and what happens when it fills

Requests that cannot be worked on yet wait in a queue. That queue is the single most useful thing
to picture, because everything a server does under stress is about it.

While arrivals are slower than departures, the queue stays short and nobody notices anything. The
moment arrivals exceed departures — even slightly — the queue grows, and it does not grow gently.
Each request now waits behind everything ahead of it, so **the response time everybody sees gets
worse much faster than the load gets worse**. A server at 90% of its capacity is not 10% slower
than one at 80%; it can easily be several times slower.

This is why sites do not degrade gracefully on their own. They are fine, and then they are not.

Two mechanisms exist to stop it, and both look like failures from the outside:

**Timeouts.** A request that has waited beyond some limit is abandoned. This seems wasteful — the
work is thrown away — and it is the right thing to do, because an answer nobody is still waiting
for has no value, and holding it costs the ones that do.

**Refusal.** Past some point the server stops accepting new requests, or accepts them only to
answer immediately with "not now". Being refused quickly is far better for you than being accepted
and made to wait five minutes, and it is much better for everybody else, because it stops one
enthusiastic client from consuming the capacity of a hundred ordinary ones.

Both have names and status codes in HTTP, and you meet them in lesson 6. What matters here is that
**a server refusing you may be a server working correctly**.

## One slow dependency stalls everything

Here is the failure that surprises teams, and it follows from what is above.

Suppose a server can hold two hundred exchanges in flight, and one of the things it asks — a search
service, say — becomes slow. Not broken: slow. Requests that need search now hold their slot for
four seconds instead of forty milliseconds.

Within a minute, every one of the two hundred slots is occupied by a request waiting on search. The
server is not busy in any meaningful sense — it is idle, holding two hundred conversations that are
all waiting on somebody else. And now requests that have **nothing to do with search** cannot get
in either, because there are no slots.

A slow dependency became a total outage, and every measurement of the server itself looks healthy.
This is the single most common shape of large failures, and the defences against it — limits per
dependency, timeouts, giving up early — are the subject of much of an engineer's later career. You
do not need them yet. You need to recognise the shape.

## What it means for you as the client

Three things worth carrying forward.

**You cannot assume the server is idle.** Sending a hundred requests as fast as you can is not free
for it, and a well-run server will start refusing you rather than fall over. Ask for what you need,
and if you are writing something that loops, put a limit in it.

**You cannot assume your requests arrive in order.** If you send two at once, the second may be
answered first — they are separate exchanges and nothing promises to sequence them. Any time order
matters, something has to enforce it, and that something is usually you: wait for the first answer
before sending the second, or make the operations safe to apply in either order.

**A retry is not free either.** When something fails, trying again immediately is the natural
instinct and often the wrong one — if the server is struggling, a thousand clients all retrying at
once is precisely the extra load that keeps it down. The habit worth building early is to wait a
little longer before each attempt, rather than hammering.
