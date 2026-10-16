---
title: Elasticsearch, OpenSearch or Solr
version: 1
---

All three are built on **Apache Lucene**, the Java library that does the analysing, the inverted index
and the scoring. What differs is everything around it: how a cluster is run, the APIs, the licence and
who sells the managed version.

| | Elasticsearch | OpenSearch | Solr |
| --- | --- | --- | --- |
| origin | Shay Banon, 2010; now Elastic | AWS's fork of Elasticsearch 7.10, 2021 | the Apache Software Foundation, 2006 |
| licence | AGPL, SSPL or Elastic's own, chosen by the user, since 2024 | Apache 2.0 | Apache 2.0 |
| API | JSON over HTTP; the lab's queries are Elasticsearch's syntax | the same syntax, diverging slowly since the fork | its own HTTP API, plus a JSON query language |
| managed | Elastic Cloud, on the three main clouds | Amazon OpenSearch Service, and others | fewer; often run by the team itself |
| strong in | logs and observability (the ELK stack), and search | the same, on AWS especially | enterprise and site search, long-standing installations |

The fork is the part with history. In 2021 Elastic moved Elasticsearch from the Apache licence to
licences that forbid offering it as a managed service without an agreement, aimed at cloud providers;
AWS forked the last Apache-licensed version as OpenSearch, which the Linux Foundation now governs. In
2024 Elastic added the AGPL as an option, making Elasticsearch open source again in the OSI's sense. For
an application the practical difference is small: the queries in this lesson run on both.

And sometimes the right answer is none of them. Quitanda's catalogue has a few hundred products, and
PostgreSQL's full-text search, with `unaccent` for the accents and `pg_trgm` for typos, would serve it
from the database it already runs, with no copy to keep in step. A search engine earns its memory and
its feeder when the catalogue is large, when relevance tuning matters to sales, or when the same cluster
also holds the logs.

When you are done, stop the lab:

```sh
docker compose down -v
```
