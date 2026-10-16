---
title: Condições sem apply
version: 1
---

**O `apply` mais comum em notebooks de verdade é um `if` dentro de uma função: um valor cai numa de
poucas faixas.** O pandas e o NumPy têm formas vetorizadas exatamente disso, e a aula 5 já mostrou a
do NumPy.

Viagens em faixas por duração, do jeito que costuma ser escrito da primeira vez:

```python
trips["minutes"] = (trips["ended_at"] - trips["started_at"]).dt.total_seconds() / 60

def band(m):
    if pd.isna(m):
        return "lost"
    if m < 10:
        return "short"
    if m < 30:
        return "normal"
    return "long"

banded = trips["minutes"].apply(band)
banded.value_counts()
```

```
minutes
normal    21473
short      8686
long       3032
lost        146
Name: count, dtype: int64
```

O primeiro teste importa. `pd.isna(m)` pega as bicicletas perdidas antes de qualquer comparação,
porque `nan < 10` é `False` e uma duração faltante passaria por todos os testes e sairia `"long"`. É a
armadilha da aula 5 de novo, e a mesma ordem de testes tem que sobreviver à reescrita.

O `np.select` recebe uma lista de condições e uma lista de valores, conferidas em ordem, com um
padrão:

```python
selected = np.select(
    [trips["minutes"].isna(), trips["minutes"] < 10, trips["minutes"] < 30],
    ["lost", "short", "normal"],
    default="long",
)
(banded == selected).all()
```

```
np.True_
```

A mesma resposta para toda viagem. O `pd.cut` é o outro caminho, quando as faixas são intervalos de um
número, e ele devolve uma categórica com as faixas em ordem, que a aula 12 mostrou ser o que um
gráfico e um `groupby` querem:

```python
cut = pd.cut(trips["minutes"], bins=[0, 10, 30, np.inf], right=False,
             labels=["short", "normal", "long"])
cut.value_counts(dropna=False)
```

```
minutes
normal    21473
short      8686
long       3032
NaN         146
Name: count, dtype: int64
```

`right=False` faz cada faixa incluir a borda da esquerda, então uma viagem de exatamente 10 minutos é
`normal`, como na função. As bicicletas perdidas ficam `NaN` em vez de `"lost"`: o `cut` não tem faixa
para um valor faltante, o que é honesto, e um rótulo para elas está a um `cat.add_categories` e um
`fillna` de distância, se um relatório pedir.

Os três, cronometrados:

```python
looped = %timeit -o -q trips["minutes"].apply(band)
sel = %timeit -o -q np.select([trips["minutes"].isna(), trips["minutes"] < 10, trips["minutes"] < 30], ["lost", "short", "normal"], default="long")
binned = %timeit -o -q pd.cut(trips["minutes"], bins=[0, 10, 30, np.inf], right=False, labels=["short", "normal", "long"])
round(looped.average * 1000, 1), round(sel.average * 1000, 1), round(binned.average * 1000, 1)
```

```
(9.9, 0.8, 1.1)
```

**`np.select` para condições, `pd.cut` para intervalos de um número**, e `apply` para nenhum dos dois.
A função continua útil como especificação: escreva-a primeiro se isso ajuda a pensar, depois confira a
versão vetorizada contra ela, como `(banded == selected).all()` fez.
