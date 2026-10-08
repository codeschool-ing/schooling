---
title: Exatamente uma vez é pelo menos uma vez, tornada inofensiva
version: 1
---

As pessoas pedem um pipeline que processe cada registro **exatamente uma vez**. Nenhuma máquina
consegue prometer isso quando há uma rede entre duas delas: um passo que manda algo e não ouve
resposta não tem como saber se o outro lado recebeu. Se mandar de novo, o registro pode chegar duas
vezes; se não mandar, pode nunca chegar. A busca de preços da lição 10 é essa situação, e a resposta
dela foi tentar de novo.

Então sistemas de verdade prometem **pelo menos uma vez** — nada se perde, e algumas coisas chegam
mais de uma vez — e tornam as duplicatas inofensivas do lado de quem recebe. Esse par é o que
*exatamente uma vez* quer dizer na prática:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l15-once\" aria-label=\"Pelo menos uma vez mais escritas idempotentes. Quem envia tenta de novo até ouvir uma resposta, então um registro pode chegar duas vezes. Quem recebe escreve pela chave, então a segunda cópia não muda nada. O resultado é o mesmo que se ele tivesse chegado uma vez.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"70.0\" width=\"130.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">quem envia</text><rect x=\"400.0\" y=\"70.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">quem recebe</text><path d=\"M150.0 84.0 L398.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><text x=\"275.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">registro 42</text><path d=\"M150.0 108.0 L398.0 108.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"275.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">registro 42, de novo</text><text x=\"275.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">retry: nenhuma resposta ouvida</text><path d=\"M550.0 95.0 L588.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"590.0\" y=\"70.0\" width=\"116.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"648.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a mesma linha</text><text x=\"648.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma vez</text><text x=\"475.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escrito pela chave</text></svg>", "caption": "Nada se perde, e uma duplicata não custa nada."}
```

O curso já construiu cada peça disso:

- **Retries e clears** (lição 10) tornam a entrega pelo menos uma vez: um passo que falhou roda de
  novo até funcionar.
- **Cargas idempotentes** (esta lição) fazem a segunda execução de um passo deixar o que a primeira
  deixou.
- **Deduplicação por um identificador** (lição 6) faz o mesmo para registros que chegam duas vezes: o
  coletor do site entregou alguns eventos mais de uma vez, e o staging guarda uma linha por
  `event_id`, então uma duplicata não muda nada.

A regra por baixo é a espinha do curso, e é curta: **projete todo passo como se ele fosse rodar duas
vezes, porque ele vai.** Aí um retry é seguro, um clear é seguro, um backfill sobre dias carregados é
seguro, e levar um pipeline de um orquestrador para outro — lição 13 — muda o jeito como ele roda e
nada do que ele produz.
