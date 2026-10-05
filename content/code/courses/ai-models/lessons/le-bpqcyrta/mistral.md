---
title: Mistral's line-up
version: 1
---

Mistral is the one company in this directory that sells closed models through an API and also
publishes open weights for many of its models, and it is based in France, which matters to some
buyers for lesson 2 section 07's reason. Its current entries in the sheet, in rough order of size:

```
ana@desk:~/desk$ sheet compare mistral/ministral-3b-latest mistral/ministral-8b-latest mistral/mistral-small-latest mistral/mistral-medium-latest mistral/mistral-large-latest mistral/magistral-medium-latest mistral/devstral-latest
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
mistral/ministral-3b-latest                     131,072   131072      0.1      0.1  VFS...
mistral/ministral-8b-latest                     262,144   262144     0.15     0.15  VFS...
mistral/mistral-small-latest                    262,144   262144     0.15      0.6  VFS.R.
mistral/mistral-medium-latest                   262,144   262144      1.5      7.5  VFS.R.
mistral/mistral-large-latest                    262,144   262144      0.5      1.5  VFS...
mistral/magistral-medium-latest                 262,144   262144      1.5      7.5  VFS.R.
mistral/devstral-latest                         256,000   256000      0.4        2  .FS...
```

Read the table by name, because Mistral names by purpose more than by size:

- **Ministral 3B and 8B**: small models, priced the same in and out, $0.10 and $0.15. Small enough
  to run on modest hardware in their open-weight releases (lesson 3).
- **Mistral Small, Medium and Large**: the general line. Small at $0.15 and $0.60 is the cheapest
  of ana's lesson 4 candidates, $2.45 a month for drafting with the cache.
- **Magistral**: the reasoning models, with an `R` in the last column.
- **Devstral** (and Codestral in the full list): models for code.

One thing in the table looks wrong and is a good test of lesson 2's reading: **Large costs less than
Medium**, $0.50 against $1.50. The numbered entries in the sheet agree (`mistral-large-3` at $0.50,
`mistral-medium-3.5` at $1.50), so this is not an alias pointing somewhere unexpected. It is a
reminder that **the size word in a name is a place in a line, not a price rank and not a quality
rank**: the two were released at different times and priced by Mistral for reasons the sheet does
not record. Which is better for ana's e-mail is lesson 5's question, and the cheaper one does not
win it by being called Large.

## Open weights, one model at a time

Lesson 2 section 04 used Mistral's inference repository as its example of a licence that covers the
code and not the weights. The practical consequence is here: **whether a Mistral model may be
downloaded and run is a property of that model**, stated on its own page. Some are released under
Apache 2.0, some under licences with conditions, and the commercial ones not at all. For ana, the
option lesson 3 asked her to keep open, prefer a model whose weights exist, has to be checked per
model rather than per company.
