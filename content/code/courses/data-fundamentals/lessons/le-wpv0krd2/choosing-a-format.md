---
title: Choosing a format
version: 1
---

**There is no best format, only a format that fits who writes the data, who reads it, and whether
they handle it one record at a time or one column across many.** The question "which format is
best?" has the same answer as "which vehicle is best?", and it is not an answer.

Put what this lesson measured side by side:

| | CSV | JSON Lines | Avro | Parquet | ORC |
|---|---|---|---|---|---|
| layout | rows | rows | rows | columns | columns |
| types | none | six | rich, with logical types | rich | rich |
| the schema lives | nowhere, or in a document | nowhere | in the file's header | in the file's footer | in the file's footer |
| a person can read it | yes | yes | no | no | no |
| append one record | cheap | cheap | cheap | rewrite a row group | rewrite a stripe |
| read one column | read everything | read everything | read everything | read that column | read that column |
| split for many workers | if not gzipped | if not gzipped | yes, at sync markers | yes, at row groups | yes, at stripes |
| this month of rides, uncompressed | 2,858,966 bytes | 8,208,898 bytes | 1,552,466 bytes | 1,287,381 bytes | 1,061,077 bytes |

## Four questions, in order

1. **Who else has to open it?** A partner, a spreadsheet, a regulator or a system somebody wrote in
   2003 decides the matter: CSV, in UTF-8, with a header, and the delimiter and the date format
   written down. Being readable everywhere is worth more there than anything on the rest of the list.
2. **Is it written one record at a time?** Events from an app, readings from a dock sensor and
   messages between services are row-shaped when they are born. JSON Lines when people need to
   read them and the volume is modest; Avro when programs read them, the volume is large, or the
   schema will change under readers you do not control.
3. **Is it read by column, many rows at a time?** That is every table kept for analysis, and the
   answer is columnar, with a fast codec. Parquet, unless the platform around it is built on Hive,
   in which case ORC.
4. **Will the schema change?** It will. Prefer a format that carries its schema, and a rule for
   adding a field with a default. Where CSV cannot be avoided, read it by header name, never by
   position.

## What Roda Livre does

At Roda Livre the answers come out differently for each source, which is normal:

| data | arrives as | kept as | why |
|---|---|---|---|
| the app's daily ride export | CSV | Parquet, after landing | the app team's tool exports CSV; Marta's questions read columns |
| dock sensor events | one small message per reading | Avro on the stream, Parquet once a day | written one at a time; analysed by the month |
| the mechanics' spreadsheet | CSV with semicolons | Parquet | written by people, read by programs |
| the monthly report for the city | made here, from Parquet | CSV, UTF-8 | read by somebody else's spreadsheet |

The raw file is kept exactly as it arrived, as lesson 3 does with every source, and the converted
copy is what everything downstream reads. A format is chosen at each step, for the reader of that
step, and converting between them is a few lines of the kind this lesson has been writing.
