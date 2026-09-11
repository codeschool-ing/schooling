---
title: Address plus port
version: 1
---

A packet arrives at the right machine. It has crossed a dozen routers, been wrapped and unwrapped
a dozen times, and it is finally where it was addressed to.

Now what? That machine is running a web server, a mail server, a database, a program you left open
yesterday and forgot about, and the operating system itself. The packet says which machine. It has
not yet said **which of those**.

That is what a port is for.

## The address finds the machine, the port finds the program

A **port** is a number that travels alongside the address, and it says which program on that
machine the data is for.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"One machine with a single address, drawn as a large panel. Inside it four programs, each sitting on a different port number. An incoming request labelled with address and port 443 is drawn arriving at only the web server, while the other three programs remain idle.\"><rect x=\"264\" y=\"26\" width=\"444\" height=\"128\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"486\" y=\"18\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">203.0.113.7 — one machine, one address</text><rect x=\"282\" y=\"52\" width=\"98\" height=\"82\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"331\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web server</text><text x=\"331\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">:443</text><rect x=\"390\" y=\"52\" width=\"98\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"439\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">SSH</text><text x=\"439\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:22</text><rect x=\"498\" y=\"52\" width=\"98\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"547\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">mail</text><text x=\"547\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:25</text><rect x=\"606\" y=\"52\" width=\"88\" height=\"82\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"650\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">database</text><text x=\"650\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">:5432</text><text x=\"126\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">203.0.113.7:443</text><text x=\"126\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one request</text><path d=\"M196 86 L278 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the address found the machine; the port chose which of the four</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the other three were listening the whole time and this was not theirs</text></svg>", "caption": "An address is a building. A port is a door in it, and every door has somebody different behind it."}
```

Address and port together are written with a colon: `203.0.113.7:443`. That pairing has a name —
a **socket** — and it is the full answer to *where is this going*.

## What "listening" actually means

The word *listening* sounds passive, as though a program were watching traffic go by. It is not
that at all. It is a claim.

When a program starts up and listens on port 443, it is telling the operating system: **anything
that arrives here is mine.** From then on, the operating system delivers to that program and to no
other.

Two consequences follow, and both are things you will hit.

**Two programs cannot claim the same port.** The second one to try is refused, and the error
message says so — *address already in use*. If you have ever started a development server and been
told the port was taken, that was this: something else had already claimed it, possibly a copy of
the same program you forgot to stop.

**Nothing listening means nothing to deliver to.** If a packet arrives for port 8080 and no
program has claimed it, the machine does not hold on to it hopefully. It answers immediately:
nothing here. That is the fast refusal you saw in lesson one — *refused in under a millisecond* —
as opposed to a request that hangs, which means nobody even said no.

## Numbers people agreed on

Certain numbers mean certain services, by convention, so that a client knows where to knock
without being told.

| port | what usually listens there |
|---|---|
| `80` | a web server, without encryption |
| `443` | a web server, encrypted — what nearly everything uses |
| `22` | SSH, for getting into the machine itself |
| `25` | mail being passed between servers |
| `53` | DNS, which lesson 8 is about |
| `5432` | a PostgreSQL database |

These are conventions and not laws. A web server can listen on 8080, or 3000, or 61234 — which is
exactly what happens when you run something locally and open `localhost:3000`. The number after
the colon is the port, and you are typing it because your development server did not take the
conventional one.

## Four numbers, not two

Now the part that explains something you have done a hundred times without wondering about it.

Open the same website in two tabs. Both send requests to the same address, on the same port, from
the same machine. The answers come back — and they do not get mixed up.

They do not get mixed up because a connection is not identified by two numbers. It is identified
by **four**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 238\" role=\"img\" aria-label=\"Two rows comparing two simultaneous connections from one laptop to one server. Both rows share the same source address, destination address and destination port; only the source port differs, 51188 in the first and 51203 in the second, and that difference is highlighted.\"><rect x=\"14\" y=\"56\" width=\"692\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"30\" y=\"44\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">tab one</text><text x=\"30\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">from 192.168.1.24</text><rect x=\"190\" y=\"62\" width=\"128\" height=\"42\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect><text x=\"254\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">port 51188</text><text x=\"350\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">to 203.0.113.7</text><text x=\"530\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">port 443</text><rect x=\"14\" y=\"140\" width=\"692\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"30\" y=\"130\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">tab two</text><text x=\"30\" y=\"164\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">from 192.168.1.24</text><rect x=\"190\" y=\"146\" width=\"128\" height=\"42\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect><text x=\"254\" y=\"169\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">port 51203</text><text x=\"350\" y=\"164\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">to 203.0.113.7</text><text x=\"530\" y=\"164\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">port 443</text><text x=\"254\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">one number differs, and that is the whole of it</text><text x=\"560\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">three of the four are identical</text></svg>", "caption": "Two connections that agree about everything except where the answer goes back to."}
```

Source address, source port, destination address, destination port. Your machine picks a different
source port for each connection it opens — a high, arbitrary number nobody has to agree on — and
that is enough to keep any number of simultaneous conversations with the same server distinct.

It is also how one server holds thousands of connections on a single port. Port 443 is not a queue
anybody takes turns in. Every connection to it is a different set of four numbers, and the server
keeps them apart by that.

## Which is what a connection is made of

And here the pieces of this lesson start to close.

A packet, you read at the start, carries no connection. Nothing in it says *this belongs to the
conversation we have been having*. That was true and it is still true.

So where does a connection exist? **In the memory of the two machines at the ends, and nowhere
else.** Each of them keeps a record: these four numbers, this much data sent, this much
acknowledged, this is what we are waiting for. When a packet arrives, its four numbers are matched
against those records and it is filed against the right one.

Nothing in the middle has any idea. The routers you met two sections ago do not know a connection
exists, would not be told if one ended, and are forwarding packets on the destination alone. A
connection is an agreement between two parties conducted entirely by post, and it is real only
because both of them are keeping notes.

That is also why a server that restarts drops every connection it had. The notes were in memory.
Nothing on the network was holding them.

## Where this leaves you

An address gets a packet to a machine; a port gets it to a program; the two together are a socket.
Listening is a claim rather than a habit, so two programs cannot claim one port and an unclaimed
port refuses instantly. A connection is four numbers, which is why two tabs do not collide — and
it lives in the memory of the ends, because the network holds nothing on your behalf.

What has not been said yet is what those notes are actually **for**. Keeping a record of what was
sent and what was acknowledged is work, and one of the two ways of using the network does not
bother. That is the last reading of this lesson.
