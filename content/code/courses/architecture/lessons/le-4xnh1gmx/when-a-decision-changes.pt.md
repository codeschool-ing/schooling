---
title: Quando uma decisão muda
version: 1
---

O ADR 2 estava certo quando foi escrito. Depois o tráfego cresceu, o serviço de estoque deixou a loja
inteira lenta duas vezes num mês, e a equipe construiu o que a aula 9 construiu: a loja mantém uma cópia do
estoque, alimentada por eventos. O registro da decisão antiga **não é editado**. Um registro novo diz o que
mudou e por quê, e aponta para o que ele substitui:

`docs/adr/0005-keep-a-copy-of-the-stock.md`:

A decisão que substitui o ADR 2, o arranjo que a aula 9 construiu: a loja escuta em vez de perguntar.

```
# 5. Keep a copy of the stock in the shop

Date: 2026-10-05

## Status

Accepted. Supersedes [2](0002-ask-the-stock-service-synchronously.md).

## Context

Product pages now make up most of the stock service's traffic, and a slow stock service made the whole
shop slow twice last month (lesson 12). Customers do not need the exact count on a product page; the
checkout does, and asks the stock service directly.

## Decision

The stock service publishes an event with the full count and a version whenever a count changes. The
shop keeps its own copy from those events, ignores any event older than the version it holds, and shows
"only a few left" rather than an exact number below ten.

## Consequences

Product pages no longer depend on the stock service being up. The number shown can be a few seconds
old, so the checkout keeps asking the stock service, as ADR 2 did for every page. The shop now runs a
consumer that must be monitored for lag.
```

O registro antigo muda em exatamente uma linha, o status, para quem o encontrar ser mandado à decisão em
vigor. Mude-a, e imprima o log de novo:

```
ana@vm:~/lab/adr$ sed -i 's/^Accepted$/Superseded by [5](0005-keep-a-copy-of-the-stock.md)./' docs/adr/0002-ask-the-stock-service-synchronously.md
ana@vm:~/lab/adr$ bash adr-index.sh
1. Record architecture decisions              Accepted
2. Ask the stock service synchronously        Superseded by [5](0005-keep-a-copy-of-the-stock.md).
3. Charge cards idempotently                  Accepted
4. No SELECT * in application code            Accepted
5. Keep a copy of the stock in the shop       Accepted. Supersedes [2](0002-ask-the-stock-service-synchronously.md).
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Dois registros ao longo do tempo. O ADR 2, aceito em março, decide que a loja pergunta ao serviço de estoque em toda página. Em outubro o ADR 5 é aceito e o substitui. O ADR 2 não é apagado nem reescrito: só o status muda, para substituído pelo 5, e os dois continuam no log.\"><defs><marker id=\"l20-supersede-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"50\" width=\"280\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ADR 2: perguntar de forma síncrona</text><text x=\"180\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">março: aceito</text><text x=\"180\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">outubro: substituído pelo 5</text><rect x=\"400\" y=\"50\" width=\"280\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"540\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">ADR 5: manter uma cópia</text><text x=\"540\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outubro: aceito</text><text x=\"540\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">substitui o 2</text><path d=\"M398 95 L322 95\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l20-supersede-ah-phosphor)\"></path><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">os dois ficam no log; nenhum é reescrito</text></svg>", "caption": "Uma decisão que muda é um registro novo. O antigo fica, marcado como substituído, para o log contar a história inteira de como o sistema chegou aqui."}
```

Os dois registros ficam. O log agora diz que a loja perguntou ao serviço de estoque por sete meses, por que
isso estava certo, o que mudou, e o que se decidiu em vez disso, e um leitor que se pergunta "por que não
simplesmente chamar o serviço de estoque?" descobre que alguém chamou, e por que parou. Um log em que
decisões antigas são reescritas para combinar com o presente parece dizer que o sistema sempre foi
projetado assim, o que nunca é verdade e esconde exatamente as lições que uma equipe pagou para aprender.
