---
title: What a contract says
version: 1
---

A useful data contract answers the questions a consumer would otherwise ask by message, one at a time,
months apart:

| part | the question | example |
|---|---|---|
| **schema** | which fields, of which types? | `items`, a `bigint` |
| **semantics** | what does each field mean? | units ordered, not lines |
| **quality** | what is guaranteed about the values? | every CEP has the shape `00000-000` |
| **freshness** | when is it ready, and covering what? | by 06:00, the orders of the day before |
| **ownership** | who answers for it? | the head of sales (lesson 9) |
| **privacy** | what personal data, on which basis, kept how long, where? | classes from lesson 6; art. 7, V; 30 days; Brazil |
| **version** | which version of the promise is this? | `1.0.0` |

The first four are what data engineering usually means by a contract. The last three are what this
course adds, and they are not optional extras: a dataset of personal data sent to another company
**is** a sharing of personal data, and the contract is where its purpose, basis and retention are
written for the people on both sides.

## Formats for it

There is no single required format. Some teams use JSON Schema or Avro schemas for the first part and a
document for the rest. The **Open Data Contract Standard** (ODCS), maintained under the Linux
Foundation, puts all of it into one YAML document with agreed field names, which tools can read. The
lab uses plain JSON with the same ideas, so that the checker in section 5 is short enough to read in
full.

What matters more than the format is two properties:

- **the contract lives in a repository**, versioned, reviewed like code, next to whatever produces
  the data;
- **a machine checks it** against what is actually served, every time either changes. A contract that
  is only read by people is documentation, and documentation drifts.
