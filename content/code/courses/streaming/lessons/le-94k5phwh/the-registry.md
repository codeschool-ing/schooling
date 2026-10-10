---
title: Subjects, versions and ids
version: 1
---

**A registry stores schemas under names called subjects, numbers each version, and gives every
distinct schema an id.** The three words do different jobs, and mixing them up is how people end
up reading the wrong schema:

| | what it is | example |
|---|---|---|
| **subject** | the name a series of versions is kept under | `sales-avro-value` |
| **version** | the position of a schema in its subject: 1, 2, 3… | version 2 of `sales-avro-value` |
| **id** | a number for the schema itself, the same wherever it is registered | id 1 |

The subject's name follows a convention, not a rule: **the topic's name plus `-value`** for the
schema of the messages' values, and `-key` for their keys. The Python serialiser derives it the
same way, which is why it matters. One subject per topic means every message in a topic follows
one series of versions, and the compatibility check of the next section but one is applied along
that series.

## Registering a schema

The schema of a sale is a file. Save it as `~/work/sale.avsc`:

```json
{
  "type": "record",
  "name": "Sale",
  "namespace": "pontofinal",
  "fields": [
    {"name": "sale", "type": "string"},
    {"name": "shop", "type": "string"},
    {"name": "book", "type": "string"},
    {"name": "qty", "type": "int"},
    {"name": "cents", "type": "long"},
    {"name": "at", "type": "string"}
  ]
}
```

The registry's API takes a schema as a JSON **string** inside a JSON object, which is awkward to
type. This script does the wrapping with `jq` and posts it. Save it as `~/work/register.sh`:

```sh
#!/usr/bin/env bash
# register.sh SUBJECT FILE: offer the schema in FILE as the next version of SUBJECT.
jq -n --rawfile schema "$2" '{schema: $schema}' |
  curl -s -X POST -H 'Content-Type: application/vnd.schemaregistry.v1+json' --data @- \
    "http://localhost:8080/apis/ccompat/v7/subjects/$1/versions"
echo
```

Make it executable with `chmod +x register.sh`. Then, with the registry from the last section
running, register the sale as the first version of the
subject for the topic `sales-avro`, which the next section creates:

```
ubuntu@stream:~/work$ ./register.sh sales-avro-value sale.avsc
```

@@REGISTER@@

## What goes into a message

A message cannot carry its whole schema: at a few hundred bytes, it would be ten times the size of
the sale it describes. It carries the **id** instead, and a consumer that meets an id it has not
seen asks the registry once and keeps the answer. The layout is fixed, and every client that
speaks Confluent's API writes the same five bytes in front of the Avro body:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The layout of one Kafka message value written by a schema-registry serialiser: one magic byte, always 0; then four bytes holding the schema id, 00 00 00 01 for id 1; then the Avro body, the values in the schema's order with no field names. The id points to the schema stored in the registry, which the consumer fetches once and keeps.\" data-fig=\"l6-wire\"><defs><marker id=\"l6-wire-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"30\" y=\"40\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">00</text><rect x=\"104\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"189\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">00 00 00 01</text><rect x=\"278\" y=\"40\" width=\"412\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"484\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">14 6e 61 74 2d 30 30 30 30 30 32 0a …</text><text x=\"65\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">magic byte</text><text x=\"189\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">schema id</text><text x=\"484\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">Avro body</text><text x=\"65\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 byte</text><text x=\"189\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4 bytes, big-endian</text><text x=\"484\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the values, in the schema's order, no names</text><path d=\"M 189 110 L 189 140\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l6-wire-ah-83)\"></path><rect x=\"84\" y=\"144\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"189\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the registry</text><text x=\"189\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id 1 = sale.avsc, version 1</text><text x=\"310\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fetched once, then cached</text></svg>", "caption": "Five bytes in front of every message are enough for any reader to find the schema it was written with."}
```

The first byte is always zero, and it exists so that the format could change one day: a reader
that finds anything else knows it is not reading this layout. **The id is four bytes, in network
byte order**, so the id 1 is `00 00 00 01`. Nothing else is added: no version number, no subject
name. The next section puts real sales on the topic and looks at their bytes.

This is also why **an id must never be reused for a different schema**. A message written today
will be read in a year, by a program that only has the id; if the registry by then gives that id
to something else, the message decodes as nonsense, or as the wrong sale. The registry only ever
adds, which is one more reason a lab registry that keeps its schemas in memory is a lab registry.
