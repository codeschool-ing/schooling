---
title: The shape of an exchange
version: 1
---

One side asks, the other answers. Now look closely at the asking and the answering, because they
have a shape that repeats everywhere — in HTTP, which you meet in lesson 6, but also in database
queries, in the calls your phone makes to check for mail, and in protocols that were designed
before the web existed.

## Four things a request carries

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

One last property, and it is the one that makes people redesign things.

An exchange cannot be faster than the time it takes to get there and back. If the machine you are
asking is 9,000 km away, the answer cannot arrive in less than about 60 milliseconds no matter how
fast either side is, because that is roughly how long light takes to make the trip through fibre —
and real networks are slower than light.

So an operation built as ten exchanges in a row, each waiting for the last, has a floor of ten
round trips. The same operation built as one exchange that asks for everything has a floor of one.
This is why "chatty" is an insult in this field, and why lesson 3 spends its time on the difference
between how *much* you can send and how *long* it takes to hear back.
