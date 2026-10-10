---
title: "Avro: rows, with the schema at the top"
version: 1
---

**Avro is a row format with a binary encoding, and every Avro file begins with its own schema,
written as JSON.** It came out of the Hadoop project, and it was built for the opposite job from
Parquet: writing records one at a time, quickly, and reading them back whole, while the schema
changes underneath.

The schema is a JSON document that names a record and lists its fields, each with a type. The types
are richer than JSON's: `int` and `long` are separate, `float` and `double` are separate, there is
`bytes` for binary data, and a **logical type** can say that a `long` is really a timestamp in
milliseconds. A record on disk is then its values in the order the schema lists them, with no names
and no separators: the names are in the schema, once.

## An Avro file

An Avro file is a **container**: a header, then blocks of records. The header holds four magic bytes,
the schema, the name of the compression codec, and a random 16-byte **sync marker**. Every block
ends with that marker, so a reader dropped anywhere in the middle of a large file can scan forward to
the next marker and start reading from there. That makes an Avro file splittable, which section
"compression" explains.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 238\" role=\"img\" aria-label=\"An Avro file drawn as three rows. The header holds the magic bytes Obj and 1, the metadata with avro.schema and avro.codec, and a 16-byte sync marker. Each block holds a count of records, its size in bytes, the records with their values in schema order and no field names, and the sync marker again, which lets a reader that starts in the middle of the file find the next block.\" data-fig=\"avro-file\"><defs><marker id=\"avro-file-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"37\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">header</text><rect x=\"112\" y=\"20\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"147.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Obj 1</text><rect x=\"188\" y=\"20\" width=\"180\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"278.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">avro.schema: {…}</text><rect x=\"374\" y=\"20\" width=\"130\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"439.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">avro.codec: null</text><rect x=\"510\" y=\"20\" width=\"86\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"553.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sync marker</text><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">block 1</text><rect x=\"112\" y=\"88\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"147.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">count</text><rect x=\"188\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">size</text><rect x=\"258\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ride</text><rect x=\"328\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ride</text><rect x=\"398\" y=\"88\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ride</text><rect x=\"468\" y=\"88\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"488.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"514\" y=\"88\" width=\"86\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"557.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sync marker</text><text x=\"20\" y=\"173\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">block 2</text><rect x=\"112\" y=\"156\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"147.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">count</text><rect x=\"188\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">size</text><rect x=\"258\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"290.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ride</text><rect x=\"328\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ride</text><rect x=\"398\" y=\"156\" width=\"64\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"430.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ride</text><rect x=\"468\" y=\"156\" width=\"40\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"488.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">…</text><rect x=\"514\" y=\"156\" width=\"86\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"557.0\" y=\"173.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sync marker</text><text x=\"112\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a ride: its values in schema order, no names</text><text x=\"112\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the same marker after every block: a reader that starts mid-file scans to the next one</text></svg>", "caption": "An Avro container file: the schema once in the header, then blocks of records, each ending in the same sync marker."}
```

Save this as `formats/as_avro.py`. It declares the schema of a ride, writes the month of rides, and
reads the file back:

```schooling-example
{"language": "python", "file": "formats/as_avro.py", "parts": [{"code": "# formats/as_avro.py\nfrom fastavro import parse_schema, reader, writer\nfrom rides import make\n\nSCHEMA = parse_schema({\n    \"type\": \"record\", \"name\": \"Ride\", \"namespace\": \"roda\",\n    \"fields\": [\n        {\"name\": \"ride_id\", \"type\": \"string\"},\n        {\"name\": \"bike_id\", \"type\": \"string\"},\n        {\"name\": \"start_station\", \"type\": \"string\"},\n        {\"name\": \"end_station\", \"type\": \"string\"},\n        {\"name\": \"started_at\",\n         \"type\": {\"type\": \"long\", \"logicalType\": \"timestamp-millis\"}},\n        {\"name\": \"minutes\", \"type\": \"int\"},\n        {\"name\": \"member\", \"type\": \"boolean\"},\n    ],\n})\n\n", "note": "The schema, as a Python dictionary that is also valid JSON. `started_at` is a `long` with the logical type `timestamp-millis`; `minutes` is an `int`, and `member` a `boolean`. `parse_schema` checks it before anything is written."}, {"code": "if __name__ == \"__main__\":\n    with open(\"rides.avro\", \"wb\") as f:\n        writer(f, SCHEMA, make(50_000))\n    with open(\"rides.avro\", \"rb\") as f:\n        rides = reader(f)\n        print(\"fields:\", [field[\"name\"] for field in rides.writer_schema[\"fields\"]])\n        print(\"codec:\", rides.codec)\n        first = next(rides)\n    print(\"first ride:\", first[\"ride_id\"], first[\"started_at\"], first[\"minutes\"])\n", "note": "Writing is one call: the file, the schema and the rides. Reading opens the file and finds the schema in its header, with no schema passed in; then `next` takes the first ride."}]}
```

```
ana@lab:~/roda/formats$ python as_avro.py
fields: ['ride_id', 'bike_id', 'start_station', 'end_station', 'started_at', 'minutes', 'member']
codec: null
first ride: R000001 2025-09-01 09:01:23+00:00 5
```

The fields came back from the file, not from the program: `writer_schema` is the schema in the
header. `codec: null` means the blocks are not compressed, which is fastavro's default. And the first
ride started at 06:01:23 in Curitiba and came back as 09:01:23 in UTC. That is the same instant,
because `timestamp-millis` stores milliseconds since 1970 in UTC and nothing else; the time zone the
ride was written in is not part of the value. If it matters, it has to be a field of its own.

The schema really is at the top of the file, as text. The first hundred bytes, printed as Python
shows bytes:

```
ana@lab:~/roda/formats$ python -c "print(open('rides.avro', 'rb').read(100))"
b'Obj\x01\x04\x14avro.codec\x08null\x16avro.schema\xf2\x05{"type": "record", "name": "roda.Ride", "fields": [{"name": "ride'
```

`Obj` and a byte of value 1 are the magic, then the two metadata entries, `avro.codec` and
`avro.schema`, with the schema itself starting in plain JSON.

## Where it is used

Avro's strength is the single record. A ride encoded on its own is a few dozen bytes with no names
in it, which suits a message on a stream, where events are sent one at a time and read by programs
written at different times by different teams. On streaming platforms such as Apache Kafka, the
schema is often kept in a **schema registry**, a service that stores each version once, and each
message carries a short id pointing at the version it was written with. Lesson 8 is about streams.
And because both schemas are always known, the writer's and the reader's, Avro has precise rules
for reading old data with a new schema. Section "schema-evolution" runs them.
