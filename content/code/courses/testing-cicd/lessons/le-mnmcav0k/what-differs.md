---
title: The differences that are meant
version: 1
---

Some differences between environments are the whole point of having them. Asked the same question,
the three give two answers:

```
ana@laptop:~/shipquote$ for port in 8100 8200 8300; do curl -s "http://127.0.0.1:$port/quote?cep=01310-100&weight=1200&subtotal=5000"; echo; done
{"cep": "01310-100", "zone": "SP", "cents": 2190, "price": "R$ 21,90"}
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
{"cep": "01310-100", "zone": "SP", "cents": 1860, "price": "R$ 18,60"}
```

Development answered **R$ 21,90**, from the shop's table, because it has no carrier. Staging and
production answered **R$ 18,60**, from their carriers. That is the intended behaviour, and it carries
a warning: **staging only tells you about production to the extent the two are configured alike.**
A test that passes in development tells you nothing about the carrier path, because development
never takes it.

## Legitimate differences

| what | development | staging | production |
|---|---|---|---|
| the artifact | any build, often `dev-…` | a release candidate | the release |
| integrations | none, or fakes | providers' sandboxes | the real providers |
| secrets | throwaway | sandbox credentials | production credentials, tightly held |
| data | seeded, synthetic | seeded, shaped like production | the customers' |
| scale | one process | small | what the traffic needs |
| who can change it | the developer | the team, through the pipeline | the pipeline only |

Every row is a difference somebody chose, and each one is a place where staging can disagree with
production. The sandbox of a carrier is the clearest case: it is the provider's own test system, and
it can accept requests the live API refuses, answer faster than the live API ever does, or lag
behind a change the live API already made. Lesson 2's contract tests are how a team keeps an eye on
that difference.

## Differences that are not meant

The difference that hurts is the one nobody chose: a version of Python, a time zone, a setting
changed on one machine and not another, a file edited by hand. The next three sections are about
those: what *parity* means, what staging can and cannot tell you, and how drift happens and is
found.
