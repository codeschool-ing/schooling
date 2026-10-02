---
title: What a log costs
version: 1
---

The shop ran for ten minutes at five requests a second with the Collector sending to Loki and
Elasticsearch, as in lesson 9. What the four services wrote, measured at the source, and what
Elasticsearch holds for it:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 10m storefront orders payments mailer | wc -c
2505605
ana@obs:~/shop$ curl -s 'localhost:9200/_cat/indices/logs-*?h=docs.count,store.size'
10649 2.7mb
```

**2.5 MB written, 2.7 MB stored**, for 10649 lines. Elasticsearch keeps more than it was sent:
every line is stored whole, as the original JSON in `body.text`, again as parsed fields, and once
more in the index that makes each field searchable. Loki compresses its chunks and indexes almost
nothing, and is usually several times smaller than the raw text, but in this lab its chunks were
still in memory and there was nothing on disk to weigh yet.

The arithmetic that decides a budget is short. **2.5 MB in ten minutes is about 360 MB a day**, raw,
for a shop at five requests a second. Multiply by the traffic a real shop has, by the number of
copies a store keeps for safety, often two or three, and by the days it is kept, and the three
numbers that a team controls are clear:

| | what moves it | where this course deals with it |
|---|---|---|
| bytes per request | how many lines, how many fields, how long the message | lesson 8 |
| how it is stored | index everything, or index labels and compress | lesson 9 |
| how long it is kept | retention | the next section |

**A hosted log product bills on the first number**, usually per gigabyte ingested, often with a
second price per gigabyte kept per month. No price is quoted here because they change and differ by
contract, but the shape is the same everywhere: the cheapest byte is the one that was never written.
