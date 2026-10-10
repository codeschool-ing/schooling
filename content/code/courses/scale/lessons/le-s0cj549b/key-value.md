---
title: Key-value, the simplest shape
version: 1
---

A **key-value store** holds values under keys, and the only question it answers quickly is "what is
the value under this key?". Get, put, delete, and little else. The value is opaque to the store: a
string, a number, a blob of JSON that it does not look inside.

That is a severe limit and it is also the source of everything the family is good at:

- **Every operation is one lookup.** A hash of the key finds the value, in memory for the fastest
  stores, so an operation costs microseconds and the store answers tens of thousands per second on
  one processor.
- **Partitioning is trivial.** The key's hash decides the server, as in lesson 2, and no operation
  ever needs two servers, because no operation involves two keys.
- **Expiry is natural.** A key can carry a lifetime, after which it disappears by itself.

What it cannot do is anything that is not about one key. "Every seat on hold for show 1" is not a
question a key-value store can answer, unless the program has also kept a list under another key,
which is denormalisation again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A key goes through a hash function, which gives a number, and the number picks one of four buckets or servers. Every operation names one key, so every operation goes to exactly one bucket.\"><rect x=\"20\" y=\"80\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">hold:show:1:seat:42</text><path d=\"M190 100 L250 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M250 100 L243.7 103.0 L243.7 97.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"250\" y=\"80\" width=\"110\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"305\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">hash(key)</text><path d=\"M360 100 L420 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M420 100 L413.7 103.0 L413.7 97.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><text x=\"390\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">% 4</text><rect x=\"430\" y=\"20\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"37\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bucket 0</text><rect x=\"430\" y=\"62\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bucket 1</text><rect x=\"430\" y=\"104\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">bucket 2</text><rect x=\"430\" y=\"146\" width=\"150\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"505\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">bucket 3</text><path d=\"M420 100 L430 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M430 118 L424.3 114.0 L429.6 111.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\"></path><text x=\"650\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">&quot;ana&quot;</text><path d=\"M580 117 L625 117\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "One key, one hash, one place. No operation ever needs two."}
```

## Where it fits

- **Caches**: the result of an expensive query, kept under a key built from the query, for a few
  seconds or minutes. `servers-cache` lessons 8 and 10 built exactly that with Redis.
- **Sessions**: the user's login and cart, under the session's id, which lets the copies of
  lesson 1 stay stateless.
- **Short-lived locks and holds**: "seat 42 is held by Ana for ten minutes".
- **Counters and rate limits**: a number per key, increased atomically. Lesson 9 limits each buyer's
  requests this way.

Redis, Memcached and Valkey are the in-memory members of the family. DynamoDB, in lesson 5, began
as a key-value store and grew towards documents, which is a common path: a pure key-value store is
almost always one part of a system rather than the whole of it.
