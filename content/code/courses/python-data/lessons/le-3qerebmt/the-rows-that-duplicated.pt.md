---
title: As linhas que duplicaram
version: 1
---

**Quando uma chave aparece mais de uma vez do outro lado, cada linha é pareada com todas as
correspondências, e o resultado tem mais linhas que qualquer das duas tabelas.** O pandas não levanta
erro, porque às vezes é exatamente isso que se quer. Quando não é, os números montados sobre o
resultado saem errados, e parecem certos.

As viagens com o nome da estação de partida, do jeito óbvio:

```python
named = trips.merge(stations, left_on="start_station", right_on="station_id")
len(trips), len(named)
```

```
(33337, 35973)
```

**2.636 linhas a mais que viagens.** Nada foi acrescentado aos dados; algumas viagens agora aparecem
duas vezes. Quais:

```python
named.groupby("start_station").size().loc[["S06", "S07", "S08"]]
```

```
start_station
S06     789
S07    5272
S08    1871
dtype: int64
```

`S07` tem o dobro das suas viagens, porque o `stations.csv` tem duas linhas para `S07`: a estação foi
renomeada em julho, e a aula 9 viu as duas linhas. Toda viagem da `S07` casou com as duas e saiu uma
vez com cada nome. A contagem de viagens por estação agora está errada para uma estação; a soma de
minutos está errada; a fração de bicicletas elétricas continua certa, porque as duas cópias têm a
mesma bicicleta, e é assim que uma junção duplicada se esconde.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Três viagens, duas da S07 e uma da S05, unidas a uma tabela de estações com duas linhas para a S07. Cada viagem da S07 casa com as duas linhas da S07, então o resultado tem cinco linhas: cada viagem da S07 aparece duas vezes, uma como Rua da Hora e outra como Espinheiro.\" data-fig=\"fanout\"><defs><marker id=\"fanout-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"90\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">viagens</text><text x=\"360\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">estações</text><text x=\"615\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">resultado</text><rect x=\"20\" y=\"44\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1  S07</text><rect x=\"20\" y=\"94\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2  S07</text><rect x=\"20\" y=\"144\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3  S05</text><rect x=\"265\" y=\"44\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S07  Rua da Hora</text><rect x=\"265\" y=\"94\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S07  Espinheiro</text><rect x=\"265\" y=\"144\" width=\"190\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">S05  Praça do Derby</text><line x1=\"164\" y1=\"60\" x2=\"261\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"60\" x2=\"261\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"110\" x2=\"261\" y2=\"60\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"110\" x2=\"261\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><line x1=\"164\" y1=\"160\" x2=\"261\" y2=\"160\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line><rect x=\"520\" y=\"40\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1  Rua da Hora</text><rect x=\"520\" y=\"78\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1  Espinheiro</text><rect x=\"520\" y=\"116\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2  Rua da Hora</text><rect x=\"520\" y=\"154\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2  Espinheiro</text><rect x=\"520\" y=\"192\" width=\"190\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3  Praça do Derby</text><text x=\"360\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">3 viagens entram, 5 linhas saem</text><line x1=\"459\" y1=\"110\" x2=\"516\" y2=\"110\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#fanout-ah)\"></line></svg>", "caption": "Duas linhas para uma chave à direita: toda viagem com essa chave sai duas vezes."}
```

## A relação, por escrito

Entre viagens e estações a relação deveria ser **muitos para um**: muitas viagens por estação, uma
estação por código. O `validate` confere:

```python
trips.merge(stations, left_on="start_station", right_on="station_id", validate="many_to_one")
```

```
MergeError: Merge keys are not unique in right dataset; not a many-to-one merge

Duplicates in right:
 station_id
       S07 ...
```

O merge falha, e a mensagem nomeia a chave duplicada, `S07`. Esse é todo o valor do argumento: ele
transforma uma tabela com um excesso silencioso num erro com endereço. Os quatro valores são
`"one_to_one"`, `"one_to_many"`, `"many_to_one"` e `"many_to_many"`, e o último não confere nada.

A outra conferência é ainda mais barata, e funciona depois de qualquer junção:

```python
len(named) == len(trips)
```

```
False
```

**Conte as linhas antes e depois de todo merge.** Uma junção left numa chave única do lado direito
mantém a contagem de linhas exata; qualquer outro número é uma pergunta a responder antes de seguir.

O que fazer com a `S07` depende do que as duas linhas querem dizer. Não são um erro a apagar: dizem
que o nome mudou numa data. A próxima seção une cada viagem à linha que era verdadeira quando ela
aconteceu.
