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

Because "the server is down" is three different problems, they are fixed by different people, and
**they look different from the outside**:

| what is wrong | what you see |
|---|---|
| the **host** is unreachable — off, or the network to it is broken | the attempt hangs, then gives up: a timeout |
| the host is fine, the **endpoint** is not — nothing is listening on that port | an immediate, definite refusal |
| both are fine and the **answer is an error** | a fast, well-formed response that says it went wrong |

The difference between the first two is worth internalising because it is so useful. **A timeout
means nobody was there to say no.** Your request went out and nothing came back — the machine is
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
