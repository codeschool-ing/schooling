---
title: What Node is good at, and what it is not
version: 1
---

**Node runs your JavaScript on one thread, and it is built around never making that thread wait.**
Everything that is good about it on a server, and the one thing it is bad at, follows from that
sentence.

## A server mostly waits

Think about what one request to an online shop's API does. It reads the request, asks a database
for a product, waits for the answer, maybe asks a second service for a price, waits again, and
writes the reply. The code that runs takes very little time. **The waiting is most of the
request's life**, and nothing about waiting needs a processor.

A traditional server gives each request a thread of its own, and a thread that waits sits there
holding memory until the answer arrives. Node does it the other way round. Your code asks for the
database's answer, hands Node a function to call when it comes, and returns. The thread is free at
once to run the code of the next request that has something to do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Three requests over time. Each runs a short piece of JavaScript, waits a long time for the database, then runs another short piece to reply. On the bottom row the one JavaScript thread runs those short pieces one after another, and is free while all three wait.\"><text x=\"20\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request A</text><rect x=\"150\" y=\"28\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><rect x=\"184\" y=\"34\" width=\"232\" height=\"12\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"420\" y=\"28\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><text x=\"20\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request B</text><rect x=\"200\" y=\"78\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><rect x=\"234\" y=\"84\" width=\"142\" height=\"12\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"380\" y=\"78\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request C</text><rect x=\"250\" y=\"128\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><rect x=\"284\" y=\"134\" width=\"232\" height=\"12\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"520\" y=\"128\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><line x1=\"140\" y1=\"172\" x2=\"700\" y2=\"172\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"2 3\"></line><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the one</text><text x=\"20\" y=\"225\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">JavaScript thread</text><rect x=\"140\" y=\"194\" width=\"560\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"150\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><rect x=\"420\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"435.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">A</text><rect x=\"200\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"215.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><rect x=\"380\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">B</text><rect x=\"250\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><rect x=\"520\" y=\"198\" width=\"30\" height=\"24\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">C</text><line x1=\"140\" y1=\"256\" x2=\"700\" y2=\"256\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"700.0,256.0 692.6,259.1 692.6,252.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"700\" y=\"272\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">time</text><rect x=\"150\" y=\"262\" width=\"20\" height=\"12\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"176\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your code running</text><rect x=\"330\" y=\"263\" width=\"30\" height=\"10\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"366\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">waiting for the database</text></svg>", "caption": "Most of a request's life is spent waiting, and waiting needs no thread. The one thread runs whichever piece of code is ready next."}
```

So one Node process can hold thousands of requests that are each waiting on something, with no
thread per request at all. That is the fit: **work that is mostly input and output** — APIs in
front of a database, a service that calls other services, a proxy, a chat server holding open
connections, anything that streams data from one place to another.

## A server that computes

The same picture shows the weakness. If request A's short piece of code is not short, if it
resizes an image, hashes a password with a high cost, or sorts a million rows, the thread is busy
for that whole time and **B and C wait, however ready they are**. Nothing else in the process runs
until A's code returns. Lesson 2 makes a server do this on purpose and measures what it costs the
other requests.

That is not a reason to avoid Node. It is a reason to know where the heavy work goes. Lesson 10
gives Node more than one thread when you need one: worker threads for computing, child processes
for other programs, and cluster mode for one process per processor.

## Two more things it gives you

**One language on both sides.** The browser runs JavaScript and nothing else, so a team that writes
its server in Node writes one language everywhere, can share code that checks a form on both
sides, and moves people between the two halves of an application without a second language to
learn. That is a real advantage and a modest one: the server half still has its own runtime and its
own libraries, which is what the rest of this course is.

**npm.** The registry you met in javascript lesson 21 is where almost every library for Node is
published, from the web framework of lessons 6 and 7 to the database drivers later courses use.
Lesson 4 is about living with it on a server, where the code you install runs with your server's
permissions.

## How this course runs things

Every lesson runs real programs on your computer and shows what they printed. A server in this
course listens on `127.0.0.1`, an address that only your own computer can reach, and you ask it
things with `curl` from a second terminal. Nothing in it is open to the network, and nothing is
needed beyond what the section after next installs.
