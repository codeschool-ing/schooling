---
title: Four questions, and only the last one knows
version: 1
---

You typed a name. Before any of lesson six can happen — before a connection, before a request —
something has to turn that name into an address. Here is exactly what, in order.

## The cast

**Your machine** holds a small piece of software that knows how to ask and nothing else. It does no
searching; it asks one server and waits.

**A recursive resolver** is the one that does the work. It is a server whose job is to chase the
answer through however many steps it takes and hand you a single result. Yours came from the router
that gave you an address in lesson four, unless you changed it.

**The root servers** know one thing: who runs each top-level domain.

**The TLD servers** — the ones for `ing`, for `com`, for `br` — know which servers were named as
answering for each domain registered under them.

**The authoritative servers** for a domain hold the actual records. They are the only machines in
this list that know the answer.

## The walk

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"The resolver asks a root server, which names the servers for the top level domain; asks one of those, which names the servers for the domain; and asks one of those, which finally answers with an address.\"> <rect x=\"20\" y=\"30\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"100\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your machine</text> <path d=\"M186 52 L254 52\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"260\" y=\"30\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the resolver — it does the walking</text> <rect x=\"180\" y=\"100\" width=\"360\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a root server</text> <text x=\"560\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">ask the ing servers</text> <rect x=\"180\" y=\"160\" width=\"360\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a server for ing</text> <text x=\"560\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">ask codeschool's</text> <rect x=\"180\" y=\"220\" width=\"360\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"242\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">an authoritative server for codeschool.ing</text> <text x=\"560\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">203.0.113.7</text> <text x=\"100\" y=\"122\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">step 1</text> <text x=\"100\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">step 2</text> <text x=\"100\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">step 3</text> <text x=\"360\" y=\"294\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the first two answer not me, them — from a list they already hold</text> <text x=\"360\" y=\"314\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">nobody looks anything up for anybody, which is why no step of this is a bottleneck</text> </svg>", "caption": "Four questions and one answer. Everything before the last step is a referral rather than a lookup."}
```

Your machine asks the resolver: *what is the address of `app.codeschool.ing`?*

The resolver asks a root server. The root does not know, and says so usefully: *ask the servers for
`ing`, here they are.*

The resolver asks one of those. It does not know either: *ask the servers for `codeschool.ing`,
here they are.*

The resolver asks one of those, and this one knows, because somebody put the record there. It
answers with the address.

The resolver hands you that address, and the connection of lesson six can begin.

Notice the shape. Nobody chases anything on your behalf except the resolver, and nobody along the
way looks anything up for it — each server answers *not me, them* from a list it already has. That
is why the whole system costs so little to run and why no step of it is a bottleneck.

## Almost none of that usually happens

The walk above is the cold case. In practice most questions are answered long before the root.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Four caches in order: the browser's own, the operating system's, the resolver's, and only then the walk to the root. Most questions stop at the third.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect> <text x=\"200\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the browser's own cache</text> <text x=\"520\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nothing leaves the process</text> <rect x=\"20\" y=\"80\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"200\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the operating system's</text> <text x=\"520\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nothing leaves the machine</text> <rect x=\"20\" y=\"126\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".14\" stroke=\"var(--phosphor)\"></rect> <text x=\"200\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the resolver's — the busy one</text> <text x=\"520\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a few milliseconds away</text> <rect x=\"20\" y=\"172\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"200\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and only then, the walk</text> <text x=\"520\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">possibly another continent</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the bottom row is what happens for the first person to ask</text> <text x=\"360\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">how long each row keeps an answer is a number you choose, and it is the next reading</text> </svg>", "caption": "Four places an answer can come from, in order. Most questions never reach the fourth."}
```

There are caches at every level: in the browser, in the operating system, in the resolver, and the
resolver's is the one doing the heavy lifting. A resolver serving a hundred thousand people has
been told where `ing`'s servers are, and where `codeschool.ing`'s servers are, within seconds of
the first person asking.

So a popular name costs one question and one answer, both to a machine a few milliseconds away.
The four-step walk is what happens for the first person, and for names nobody has asked for lately.

This is also where the next reading begins, because the length of time each cache holds an answer
is a number you choose, and it decides how long your changes take to appear.

## What it costs when it is cold

Put it beside lesson three. A cold lookup is a handful of round trips to servers that may be on
other continents, and it happens **before** the connection, which is before the encryption, which
is before the request.

For a page that pulls resources from five hosts, that is potentially five cold lookups, each
serialised in front of everything else that host will do. It is a common and invisible cause of a
slow first visit, and it is the reason the browser's own hints — asking it to resolve a name early,
before the page needs it — exist at all.

## Where your resolver comes from, and what changing it means

Lesson four's `DHCP` handed you a resolver along with your address, and for most people it is one
their provider runs.

You can change it, and the public ones are well known — a pair of eights, a pair of ones. What that
actually changes is worth being honest about. Sometimes it is faster and sometimes it is slower,
depending on where you are and how good your provider's is. It moves the record of every name you
look up from one company to another rather than removing it. And it bypasses whatever your provider
was doing at that layer, which on some networks is filtering you wanted and on others is filtering
you did not.

## The question itself is usually in the open

Historically this whole exchange runs over UDP, on port 53, in plain text: one small question, one
small answer, no connection, exactly as lesson six predicted it would.

Plain text means anybody on the path sees every name you ask for — which, after the HTTPS reading,
is the gap in the picture. The connection is encrypted; the question about where to connect was
not.

Two arrangements close it. **DNS over TLS** puts the same exchange inside an encrypted connection
on a port of its own. **DNS over HTTPS** puts it inside ordinary HTTPS traffic, so it is not only
unreadable but indistinguishable from anything else. Browsers ship this and some enable it by
default.

It is genuinely contested rather than simply better, and the argument is worth knowing. Moving
every lookup inside HTTPS to a handful of large providers concentrates in a few hands a record that
used to be spread across thousands of ISPs. And it takes the lookups out of sight of network
operators who were using them to block malware and to enforce rules a school or a parent asked for.
Both halves of that are true at once.
