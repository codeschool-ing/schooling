---
title: Avro, and reading with a different schema from the writer's
version: 1
---

**Avro is a binary format in which nothing can be written without a schema, and nothing can be
read without the schema it was written with.** The schema is JSON: a record with a name and a list
of fields, each with a type. The data is not JSON. It is the values one after another, with no
field names and no punctuation, in the order the schema lists them.

That second half is where Avro differs from what most people expect. In JSON, `{"qty": 2}` says
which field the 2 belongs to. In Avro the 2 is just a number at a position, and only the schema
says that position is `qty`. So a reader holding the wrong schema does not get a missing field:
it gets nonsense, or an error. Avro's answer to that is to make the **writer's schema** something
a reader always has, and to let the reader bring **its own schema** as well, and then work out
the difference between the two.

## One sale, three schemas

`fastavro` is a Python implementation of Avro. Install it now; the next section's install line
names it again, which costs nothing:

```sh
pip install fastavro==1.13.1
```

This program writes one sale with a first schema, then reads it back with two others. Save it as
`~/work/avro_demo.py`:

```schooling-example
{
  "file": "avro_demo.py",
  "language": "python",
  "parts": [
    {
      "code": "\"\"\"avro_demo.py: one sale written with one schema and read with others.\"\"\"\nimport io\nimport json\n\nimport fastavro\n\n\ndef schema(*fields):\n    return fastavro.parse_schema({\"type\": \"record\", \"name\": \"Sale\",\n                                  \"namespace\": \"pontofinal\", \"fields\": list(fields)})\n\n\nBASE = [{\"name\": \"sale\", \"type\": \"string\"}, {\"name\": \"shop\", \"type\": \"string\"},\n        {\"name\": \"book\", \"type\": \"string\"}, {\"name\": \"qty\", \"type\": \"int\"}]",
      "note": "`parse_schema` checks a schema and prepares it. Every version here is the same record, `pontofinal.Sale`, with the same first four fields; what differs is the end."
    },
    {
      "code": "V1 = schema(*BASE, {\"name\": \"cents\", \"type\": \"long\"})\nV2 = schema(*BASE, {\"name\": \"amount\", \"type\": \"long\", \"aliases\": [\"cents\"]},\n            {\"name\": \"till\", \"type\": \"string\", \"default\": \"unknown\"})\nV3 = schema(*BASE, {\"name\": \"cents\", \"type\": \"long\"}, {\"name\": \"till\", \"type\": \"string\"})\n",
      "note": "**v1** is what the tills write. **v2** renames `cents` to `amount`, keeping the old name as an alias, and adds `till` with a default. **v3** adds `till` with no default."
    },
    {
      "code": "sale = {\"sale\": \"nat-000002\", \"shop\": \"natal\", \"book\": \"bk-08\", \"qty\": 2, \"cents\": 17980}\nout = io.BytesIO()\nfastavro.schemaless_writer(out, V1, sale)\nbody = out.getvalue()\nprint(\"json:\", len(json.dumps(sale)), \"bytes\")\nprint(\"avro:\", len(body), \"bytes:\", body.hex(\" \"))\n",
      "note": "The sale is written with v1, without the container file Avro also defines, as Kafka messages are. Its size is printed beside the same sale's size in JSON."
    },
    {
      "code": "print(\"read with v2:\", fastavro.schemaless_reader(io.BytesIO(body), V1, V2))\ntry:\n    fastavro.schemaless_reader(io.BytesIO(body), V1, V3)\nexcept Exception as e:\n    print(\"read with v3:\", type(e).__name__, e)",
      "note": "**Reading takes two schemas**: the one the bytes were written with, and the one the reader wants. Avro resolves the difference field by field."
    }
  ]
}
```

```
ubuntu@stream:~/work$ python avro_demo.py
```

@@BYTES@@

## What resolution does

When the reader's schema differs from the writer's, Avro matches the fields **by name** and
applies a short list of rules:

| the difference | what happens |
|---|---|
| the writer has a field the reader does not | it is skipped |
| the reader has a field the writer did not, with a default | the default is used |
| the reader has a field the writer did not, with no default | the read fails |
| the reader renames a field and lists the old name in `aliases` | the old one is read under the new name |
| a type changes to a wider one, `int` to `long` | it is promoted |

The second and third rows are the run above: `till` came back as `unknown` under v2, and v3 could
not be read at all. **A default is what makes adding a field safe**, and it is worth reading that
the other way: a field added without one is a field no old message can satisfy.

The fourth row is the rename the last section's till needed, done properly: the reader declares
that `amount` used to be `cents`. It is also the rule people remember wrongly. An alias is the
reader's knowledge of the past, so it only helps a reader that has been upgraded; a reader still
on v1 that receives a message written with v2 looks for `cents`, finds `amount`, and fails. Which
side upgrades first is a question with an answer, and the last two sections of this lesson give
it.

The other thing the run shows is the cost of carrying names. The same sale is 82 bytes as JSON
and 27 as Avro, because the Avro body is the values and nothing else. On a topic of a hundred
million sales, that difference is most of the disk.
