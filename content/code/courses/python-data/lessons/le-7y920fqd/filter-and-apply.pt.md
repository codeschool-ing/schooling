---
title: filter, e o apply para todo o resto
version: 1
---

**O `filter` mantém ou descarta grupos inteiros por uma condição sobre o grupo.** Ele responde
perguntas como "as viagens das estações com menos de 1.000 viagens", em que a condição é sobre a
estação, não sobre a viagem:

```python
quiet = trips.groupby("start_station").filter(lambda g: len(g) < 1000)
quiet["start_station"].unique().tolist(), len(quiet)
```

```
(['S16', 'S12', 'S06', 'S02', 'S19'], 3834)
```

A função recebe cada grupo como DataFrame e devolve `True` para mantê-lo. O resultado são as linhas
originais dos grupos mantidos, não uma linha por grupo.

## apply, quando nada mais serve

O `apply` passa cada grupo, como DataFrame, a qualquer função, e combina o que voltar. Ele faz coisas
que os outros métodos não fazem, como devolver várias linhas por grupo. As três viagens mais longas de
cada uma de duas estações:

```python
some = trips[trips["start_station"].isin(["S01", "S02"])]
some.groupby("start_station")[["trip_id", "minutes"]].apply(lambda g: g.nlargest(3, "minutes")).round(1)
```

```
                     trip_id  minutes
start_station                        
S01           16380    16381     99.0
              32271    32272     64.9
              6415      6416     59.3
S02           2153      2154     83.9
              13176    13177     65.6
              12811    12812     63.9
```

O resultado mantém a chave do grupo como nível externo do índice e o rótulo original de cada linha
dentro dele. Selecionar as colunas antes do `apply` diz exatamente quais colunas cada grupo recebe.

**O `apply` é o caminho mais lento do `groupby`**: ele chama o Python uma vez por grupo, enquanto
`agg` e `transform` com funções nomeadas rodam em código compilado. Use-o quando o cálculo precisar
do grupo inteiro de uma vez, e em nenhum outro caso. A aula 17 mede a diferença.
