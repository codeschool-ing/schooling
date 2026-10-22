---
title: When one process is not enough
version: 1
---

Everything in this lesson so far ran in one boxoffice process. Real-time features are where a service
first feels the difference between one process and several, because a connection is a thing that lives
in exactly one of them.

## Two processes, and the news still arrives

Put two copies of boxoffice behind a load balancer. A visitor's stream lands on one copy, and the sale
that changes it lands on the other. **With the design of section 03 this already works**: both copies
run `LISTEN availability`, PostgreSQL delivers every notification to both, and each hub tells its own
visitors. That is the payoff for taking the news from the database rather than from `Sell`. A hub fed
directly by `Sell` would have told only the visitors of the copy that made the sale.

It has limits worth knowing before you lean on it:

- **Every copy holds one connection for `LISTEN`**, taken from its pool for good.
- **A notification is not stored.** A copy whose listening connection dropped for ten seconds missed ten
  seconds of news, and nothing will resend it. boxoffice's `listen` returns on the first error, and
  `main` logs it and carries on. A production version runs it in a loop: wait a little, reconnect,
  `LISTEN` again. Because each message is the whole number of seats, the next sale puts every screen
  right.
- **Payloads stay under 8000 bytes**, and all notifications share one queue in the database. For a
  number per event that is plenty; for a feed of every change to every table, the tool is logical
  replication, not `NOTIFY`.

When the news does not come from the database, as with a chat message that is never stored, the
processes need a broker between them: Redis pub/sub is the common choice, and Centrifugo's Redis engine is
that same arrangement, already built.

## What open connections cost

| what grows | what happens | what to do |
|---|---|---|
| connections per process | each is a goroutine, a socket and its buffers; the process may run out of file descriptors first | raise the open-files limit, and measure memory per thousand connections |
| quiet connections | a proxy or load balancer closes a connection that sends nothing for its idle timeout, often a minute | send something regularly: a comment line `: ping` on a server-sent event stream, a ping frame on a WebSocket |
| slow readers | their buffers fill | drop messages, as section 03's hub does, or close the connection and let it reconnect |
| deploys | every connection on a stopped process is closed at once | clients reconnect with a random delay, so ten thousand do not arrive in the same second |

**boxoffice's two handlers send nothing between sales**, so behind a proxy with a sixty-second idle timeout,
a quiet event's page would lose its connection every minute. `EventSource` would reconnect and the page
would get the current number again, so a viewer sees nothing wrong; but every reconnect is a new request
and a new read of the event. A ticker in the handler's `select` that writes `: ping` every thirty seconds
avoids it, and lines starting with a colon are ignored by `EventSource`. Melody pings every 54 seconds by
default and Centrifugo every 25, for this reason.

**Dropping is right for state and wrong for messages.** Section 03 drops when a watcher falls behind
because the next number replaces the missed one. A chat cannot do that: a dropped message is a lost
sentence. There the choices are a bigger buffer, closing the slow connection so it reconnects and fetches
what it missed, or a system that keeps history to recover from, which is one of the reasons to reach for
Centrifugo.

## Choosing

For boxoffice the hand-written version is the right size: one source of news, one kind of message, a
handful of handlers, and a database that already fans out. **Reach for Centrifugo**, or a service like it,
when connections number in the tens of thousands, when deploys must not drop them, or when clients need
history and presence. **Reach for Melody** when the shape is rooms of people talking to each other and
the connections can live in your process. And before any of them, ask whether polling every thirty
seconds would do; for most screens that nobody stares at, it would.
