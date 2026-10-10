---
title: Who upgrades first
version: 1
---

**Every compatibility mode is also an instruction about the order in which programs are
upgraded**, and that instruction is the part teams forget. The registry checks the schemas; it
cannot check that the consumers were redeployed before the producers, and a mode followed in the
wrong order breaks a reader as surely as no mode at all.

| mode | who upgrades first | why |
|---|---|---|
| `BACKWARD` | the **consumers** | a new reader can read old data, so the readers move first and the old data never surprises them |
| `FORWARD` | the **producers** | an old reader can read new data, so the writers move first and the old readers keep up |
| `FULL` | either, in any order | each side can read the other's data |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Two deployments over time. Under BACKWARD, the consumers move to version 2 first, so for a while new readers read old version 1 data, which a backward-compatible schema allows; then the producers move. Under FORWARD, the producers move first, so old readers read new version 2 data, which a forward-compatible schema allows; then the consumers move.\" data-fig=\"l6-upgrade-order\"><defs><marker id=\"l6-upgrade-order-ah-8343\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">BACKWARD</text><text x=\"150\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumers</text><rect x=\"170\" y=\"40\" width=\"160\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"330\" y=\"40\" width=\"360\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"150\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">producers</text><rect x=\"170\" y=\"70\" width=\"350\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"520\" y=\"70\" width=\"170\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"425.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">new readers, old data</text><line x1=\"330\" y1=\"94\" x2=\"520\" y2=\"94\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><text x=\"20\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">FORWARD</text><text x=\"150\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">producers</text><rect x=\"170\" y=\"140\" width=\"160\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"250.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"330\" y=\"140\" width=\"360\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"150\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumers</text><rect x=\"170\" y=\"170\" width=\"350\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">v1</text><rect x=\"520\" y=\"170\" width=\"170\" height=\"20\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">v2</text><text x=\"425.0\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">old readers, new data</text><line x1=\"330\" y1=\"194\" x2=\"520\" y2=\"194\" stroke=\"var(--amber)\" stroke-width=\"1\"></line><line x1=\"170\" y1=\"222\" x2=\"690\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" marker-end=\"url(#l6-upgrade-order-ah-8343)\"></line><text x=\"686\" y=\"210\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "The mode decides which side may run the new version while the other still runs the old one."}
```

The wrong picture is that `BACKWARD` lets you change the producer freely because the registry
approved the schema. Approve a version 2 that removes a field under `BACKWARD`, deploy the
producer first, and every consumer still on version 1 meets messages without a field it
requires. The registry did its job; the deploy went the other way round.

## Both directions, on one topic

Version 2 only added a field with a default, which is allowed under every mode: it is a `FULL`
change, and either side may move first. Send five sales written with it, with a different seed so
they are new sales:

```
ubuntu@stream:~/work$ python avro_tills.py --schema sale-v2.avsc --count 5 --seed 2
```

@@MIXED@@

**A Kafka topic is not migrated when its schema changes.** The ten old messages are still written
with version 1 and will be for as long as the topic keeps them, which is the reason readers have to
cope with every version still on the topic, not only the newest. Retention, from lesson 3, is what
decides how long "every version" reaches back.

## Avro is not the only choice

The registry stores two other kinds of schema, with the same subjects, ids and compatibility
modes:

- **JSON Schema** keeps the messages as JSON, which people and `jq` can read, and adds the
  checks JSON lacks. It pays for that in size: the field names are still in every message.
- **Protocol Buffers** identifies fields by **number** rather than name, so a rename is free and
  reusing a number is the mistake to avoid. It is common where the same messages also travel
  over gRPC.

The choice between the three matters less than having one. The till in the first section did
not fail because JSON is a bad format; it failed because nothing stood between a programmer's
better name and every reader of the topic.
