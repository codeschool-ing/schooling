---
title: What a schema cannot say
version: 1
---

**A schema is the provider's promise about everything it sends. It says nothing about who reads which
part.** `show.json` says a show has five fields. Suppose the boxoffice team wants to rename
`price_cents` to `price`, or drop it from the show and keep it only in orders. The schema can tell
them the new answer breaks the old schema, which is obvious. It cannot tell them whether anybody
would notice, because the schema has no idea which programs read `price_cents` and which never look
at it.

The common belief is that a well-tested provider plus a well-tested client add up to a working pair.
They do not. Each side tests against its own picture of the other: the provider against its schema,
the client against a stand-in that answers the way the client's authors expect. Both suites can be
green while the two pictures disagree, and the disagreement is found in production.

## Contracts written by the consumers

**Consumer-driven contract testing turns the question around.** Each consumer writes down, as an
executable test, exactly what it needs from the provider: which request it sends, which fields it
reads from the answer, which values or types it depends on. The test produces a file, the *contract*
or *pact*. The provider's build then replays every consumer's contract against the real provider and
fails if any of them is not honoured.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 252\" role=\"img\" aria-label=\"A grid of the fields of a show against three columns. The schema, show.json, promises id, title, starts_at, price_cents and seats_left. The Tickets app reads title, starts_at and seats_left. The kiosk reads title and needs a field called venue, which is missing from the show. A field no consumer reads can change; a field one needs is a conversation.\"><text x=\"110\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">field of a show</text><text x=\"275\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">show.json</text><text x=\"425\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">Tickets app</text><text x=\"575\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">kiosk</text><rect x=\"40\" y=\"50\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">id</text><rect x=\"220\" y=\"50\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">promised</text><rect x=\"40\" y=\"80\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">title</text><rect x=\"220\" y=\"80\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">promised</text><rect x=\"370\" y=\"80\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">reads it</text><rect x=\"520\" y=\"80\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">reads it</text><rect x=\"40\" y=\"110\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">starts_at</text><rect x=\"220\" y=\"110\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">promised</text><rect x=\"370\" y=\"110\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">reads it</text><rect x=\"40\" y=\"140\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">price_cents</text><rect x=\"220\" y=\"140\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">promised</text><rect x=\"40\" y=\"170\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">seats_left</text><rect x=\"220\" y=\"170\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">promised</text><rect x=\"370\" y=\"170\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"425\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">reads it</text><rect x=\"40\" y=\"200\" width=\"140\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"110\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">venue</text><rect x=\"520\" y=\"200\" width=\"110\" height=\"24\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"575\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">needs it: missing</text><text x=\"350\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a field no consumer reads can change; a field one needs is a conversation</text></svg>", "caption": "The schema covers every field the provider sends; each consumer’s contract covers only what that consumer reads."}
```

The picture is the reason the idea exists. The schema's column covers every field. The Tickets app
reads three of them. A ticket kiosk the theatre is planning needs a field boxoffice has never had.
From those columns the provider team can read two things no schema shows. **It may change `id` and
`price_cents` freely**, as far as these consumers go: no contract reads them, so renaming them breaks
nobody who wrote one down. And it is being asked for something: the kiosk's `venue` is a request,
found on the provider's side before the kiosk ships, as a failed check rather than as a support
ticket.

## What it costs, and what it does not replace

Contracts only cover consumers who write them. A public API with strangers for clients cannot ask
them all, which is why consumer-driven contracts fit best inside an organisation, where the
consumers are known teams. The contracts also have to travel from the consumers to the provider's
build; teams that use Pact usually run a *Pact Broker*, a server that stores the contracts and the
verification results, or the hosted PactFlow. This course passes the file by hand.

None of it replaces the schema or the end-to-end test. The schema checks everything the provider
sends, the contract checks what each consumer relies on, and lesson 12's integration tests check
that the running pieces work together. Each answers a question the others cannot.
