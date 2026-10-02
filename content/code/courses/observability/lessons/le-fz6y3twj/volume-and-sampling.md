---
title: Volume, and sampling the lines nobody reads
version: 1
---

The shop at five requests a second is a small shop, and its four services wrote this much in one
minute:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | wc -l
1065
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | wc -c
260212
```

**1065 lines and 260 KB in a minute**, about 245 bytes a line. Kept up, that is some 375 MB a day,
for a shop that would fit in a corner of a real one. And almost all of it is the same four events:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix --since 60s storefront orders payments mailer | jq -r .message | sort | uniq -c | sort -rn
    273 order stored
    273 checkout finished
    273 charge decided
    258 confirmation sent
```

Four messages, each written once per checkout, and every one of them an `INFO` that says the
checkout went normally. **The lines that matter in an incident are a tiny share of the volume**, and
the volume is what lesson 10's bill is made of.

There are three answers, in the order to reach for them. **Do not write what nobody reads**: a line
per successful step is often a line per request too many, when the trace already records every step
and a metric counts them. **Write one line per request, with all its fields**, rather than one per
step: the storefront's *checkout finished* already carries the order, the product and the outcome.
And **sample what is left**: keep every warning and error, and a fraction of the rest. `sampled.py`
does that with a logging filter, keeping one `INFO` in ten and every `WARNING`:

```python
import logging
import random

from common import logs


class OneIn(logging.Filter):
    """Keep every WARNING and above; keep one INFO or DEBUG line in `n`."""

    def __init__(self, n):
        super().__init__()
        self.n = n

    def filter(self, record):
        return record.levelno >= logging.WARNING or random.random() < 1 / self.n


log = logs.setup()
logging.getLogger().handlers[0].addFilter(OneIn(10))
random.seed(1)
for n in range(1000):
    if n % 100 == 99:
        log.warning("payments slow", extra={"fields": {"n": n}})
    else:
        log.info("checkout finished", extra={"fields": {"n": n}})
```

```
ana@obs:~/shop$ docker compose run --rm -e PYTHONPATH=/app sandbox python sampled.py 2>/dev/null | jq -r .level | sort | uniq -c
     95 INFO
     10 WARNING
```

**95 of 990 `INFO` lines kept, and all 10 warnings.** The sample is random, so 95 rather than 99, and
that is the property to remember: a sampled log is good for *what kinds of things happen* and *how
often, roughly*, and useless for *what happened to order 5011*. That is why sampling comes last, why
it never touches errors, and why the trace, sampled by its own rules in lesson 12, carries the trace
id that finds a request's lines when they were kept.
