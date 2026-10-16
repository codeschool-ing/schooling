---
title: Pedaços, para um arquivo maior que a memória
version: 1
---

**`read_csv(chunksize=n)` lê um arquivo `n` linhas por vez, então um arquivo maior que a memória pode
ser processado um pedaço de cada vez.** Cada pedaço é um DataFrame comum; o que você guarda entre um
pedaço e outro fica por sua conta, e isso decide que perguntas dá para responder assim.

O arquivo grande da última seção, criado de novo para esta e contado por plano, duzentas mil linhas por
vez:

```python
big.to_csv("big.csv", index=False)
total = None
pieces = 0
for chunk in pd.read_csv("big.csv", chunksize=200_000, usecols=["plan"]):
    counts = chunk["plan"].value_counts()
    total = counts if total is None else total.add(counts, fill_value=0)
    pieces += 1
pieces, total.astype(int)
```

```
(6,
 plan
 annual    703140
 day       296970
 Name: count, dtype: int64)
```

Seis pedaços, cinco cheios e um com as 110 linhas que sobraram, e as contagens são trinta vezes as da
aula 13, como deviam ser. Em nenhum momento havia mais que um pedaço na memória, mais o total corrente
de dois números.

O `add(..., fill_value=0)` importa: um plano ausente de um pedaço transformaria o total dele em `NaN`,
a regra de alinhamento da aula 9 trabalhando contra você.

## O que os pedaços respondem

Uma contagem, uma soma, um mínimo e um máximo se combinam entre pedaços: o total dos totais é o total.
Uma média também, se você guardar a soma e a contagem em vez da média. **Uma mediana não**: a mediana
de seis medianas não é a mediana do arquivo, e nenhum resumo corrente pequeno a dá. O mesmo vale para
tudo o que precisa de todos os valores de uma vez, uma ordenação, uma contagem de distintos sobre muitos
valores, um `groupby` com uma chave por linha.

```python
lengths = []
for chunk in pd.read_csv("big.csv", chunksize=200_000, usecols=["started_at", "ended_at"],
                         parse_dates=["started_at", "ended_at"], date_format=fmt):
    minutes = (chunk["ended_at"] - chunk["started_at"]).dt.total_seconds() / 60
    lengths.append(minutes.median())
round(np.median(lengths), 3), round(typed["ended_at"].sub(typed["started_at"]).dt.total_seconds().div(60).median(), 3)
```

```
(np.float64(14.183), np.float64(14.183))
```

Aqui os dois por acaso coincidem até a terceira casa, porque cada pedaço é uma cópia do mesmo ano e a
mediana dele é a mediana do ano. Em dados reais, em que o pedaço de janeiro e o de julho diferem, a
mediana das medianas se afasta da verdadeira, e nada no resultado avisa. **Pedaços servem para
perguntas que se somam.** Para as outras, a próxima seção dá nome às ferramentas.

```python
os.remove("big.csv")
```
