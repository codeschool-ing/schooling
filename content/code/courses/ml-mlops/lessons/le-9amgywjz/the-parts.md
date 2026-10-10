---
title: The parts every feature store has
version: 1
---

Feature stores differ in how they are built, from a product with a web console to a few tables and
a library. **They agree on a vocabulary**, and learning it once makes all of them readable:

| part | what it is | in this lesson |
| --- | --- | --- |
| **entity** | the thing features describe, with its key | a member, `member_id` |
| **feature view** | a set of features computed together, from one source, by one piece of code | the ten columns `features.py` builds |
| **event timestamp** | the moment a value was true | `as_of`, the snapshot day |
| **offline store** | every value ever computed, with its timestamp | the `offline` table in `features.db` |
| **materialisation** | computing values and writing them to a store | `snapshot` and `backfill` |
| **online store** | the latest value per entity, indexed for one-row reads | the `online` table |
| **point-in-time join** | for each row asked about, the newest value on or before that row's own moment | `historical` |
| **time to live** | how old a value may be and still be served | `MAX_AGE`, seven days |

Two of these carry most of the weight. **The event timestamp is what turns a table into history**:
without it, a store holds values but cannot say when they were true, which is exactly the summary
table of lesson 3. **The point-in-time join is what uses that history correctly**: it is the one
query that makes leakage from the future impossible by construction rather than by care.

Labels are not in the list. A label is the outcome after the moment, the one thing a feature store
must not hold beside its features, and the store below drops it before writing anything.
