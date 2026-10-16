---
title: A linha que era verdadeira na época
version: 1
---

**O `pd.merge_asof` pareia cada linha com a última linha do outro lado cuja chave não é posterior a
ela.** É uma junção no tempo: cada viagem recebe a linha de estação cujo `valid_from` é o último igual
ou anterior ao início da viagem. É isso que o `stations.csv` quer dizer, então é a junção que responde
à pergunta dele.

Vale nomear antes as correções rápidas, porque as duas tentam e as duas estão erradas.
`stations.drop_duplicates("station_id", keep="last")` fica com `Espinheiro` e o dá às viagens de
janeiro, quando a estação tinha outro nome. `keep="first"` faz o contrário com as viagens de dezembro.
Qualquer uma devolve a contagem de linhas e muda a história em silêncio.

O `merge_asof` precisa das duas tabelas ordenadas pela chave de tempo, e da chave como datetime dos
dois lados:

```python
history = stations.assign(valid_from=pd.to_datetime(stations["valid_from"], format="%Y-%m-%d"))
named = pd.merge_asof(
    trips.sort_values("started_at"),
    history.sort_values("valid_from"),
    left_on="started_at", right_on="valid_from",
    left_by="start_station", right_by="station_id",
)
len(named)
```

```
33337
```

Tantas linhas quanto viagens. `left_on` e `right_on` são os tempos comparados; `left_by` e `right_by`
dizem que só linhas da **mesma estação** podem ser pareadas, então uma viagem da `S03` nunca pega uma
`S07` renomeada. Dentro de uma estação, cada viagem fica com a última linha cujo `valid_from` é igual
ou anterior ao seu início.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Uma linha do tempo de 2025 para a estação S07. Uma linha de estação começa em 1º de janeiro com o nome Rua da Hora, outra em 1º de julho com o nome Espinheiro. Uma viagem em março olha para trás até a linha de janeiro; uma viagem em setembro olha para trás até a linha de julho.\" data-fig=\"asof\"><defs><marker id=\"asof-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"120\" x2=\"680\" y2=\"120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"60.0\" y1=\"114\" x2=\"60.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"66.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">jan</text><line x1=\"215.0\" y1=\"114\" x2=\"215.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"221.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abr</text><line x1=\"370.0\" y1=\"114\" x2=\"370.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"376.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">jul</text><line x1=\"525.0\" y1=\"114\" x2=\"525.0\" y2=\"126\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"531.0\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">out</text><rect x=\"50.0\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"135.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Rua da Hora</text><text x=\"135.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">valid_from 2025-01-01</text><rect x=\"360.0\" y=\"40\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Espinheiro</text><text x=\"445.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">valid_from 2025-07-01</text><line x1=\"60.0\" y1=\"84\" x2=\"60.0\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><line x1=\"370.0\" y1=\"84\" x2=\"370.0\" y2=\"116\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><rect x=\"183.16666666666666\" y=\"164\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"189.16666666666666\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem em março</text><path d=\"M181.16666666666666 170 Q124.58333333333333 205 64.0 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#asof-ah)\"></path><rect x=\"493.1666666666667\" y=\"164\" width=\"12\" height=\"12\" rx=\"6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"499.1666666666667\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">viagem em setembro</text><path d=\"M491.1666666666667 170 Q434.58333333333337 205 374.0 128\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#asof-ah)\"></path></svg>", "caption": "Cada viagem pega a última linha de estação cujo valid_from é igual ou anterior ao seu início.", "same": ["Espinheiro", "Rua da Hora"]}
```

As viagens da `S07` agora carregam o nome do seu dia:

```python
s07 = named[named["start_station"] == "S07"]
s07.groupby(s07["started_at"].dt.month)["name"].first().loc[[5, 6, 7, 8]]
```

```
started_at
5    Rua da Hora
6    Rua da Hora
7     Espinheiro
8     Espinheiro
Name: name, dtype: str
```

```python
s07["name"].value_counts()
```

```
name
Espinheiro     1374
Rua da Hora    1262
Name: count, dtype: int64
```

Junho é o último mês de `Rua da Hora` e julho o primeiro de `Espinheiro`, e as duas contagens somam as
2.636 viagens que o merge simples duplicou.

Uma coisa que o `merge_asof` não mantém é a ordem original: ele devolve as viagens ordenadas por
`started_at`, que não é bem a ordem do `trips.csv`. Reordene pela chave que importa,
`named.sort_values("trip_id")`, antes de comparar linha a linha com qualquer outra coisa.
