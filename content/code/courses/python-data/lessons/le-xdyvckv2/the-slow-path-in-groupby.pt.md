---
title: O caminho lento no groupby
version: 1
---

**Num `groupby`, uma agregação por nome roda em código compilado, uma função roda uma vez por grupo em
Python, e o `apply` roda uma vez por grupo com um DataFrame montado para cada um.** A aula 13 prometeu
uma medição, e é esta. Com poucos grupos a diferença se esconde; com um grupo por dia, não.

A viagem mediana de cada dia, de três jeitos:

```python
trips["day"] = trips["started_at"].dt.normalize()
by_day = trips.groupby("day")["minutes"]

named = by_day.median()
lam = by_day.agg(lambda s: s.median())
named.equals(lam), by_day.ngroups
```

```
(True, 365)
```

As mesmas 365 medianas. O tempo de cada uma:

```python
t_named = %timeit -o -q by_day.median()
t_lam = %timeit -o -q by_day.agg(lambda s: s.median())
t_apply = %timeit -o -q trips.groupby("day")[["minutes"]].apply(lambda g: g["minutes"].median())
round(t_named.average * 1000, 1), round(t_lam.average * 1000, 1), round(t_apply.average * 1000, 1)
```

```
(0.8, 26.0, 46.5)
```

A mediana por nome fica abaixo de um milissegundo. O `lambda` chama uma função Python 365 vezes e
leva dezenas de vezes mais; o `apply` ainda monta um DataFrame para cada grupo e leva mais ainda. A
resposta é a mesma nas três, e é isso que torna fácil manter as lentas sem perceber.

O custo cresce com o **número de grupos**, não com o número de linhas. Por estação, 20 grupos, o
`lambda` custa uns dois milissegundos e ninguém notaria; por viagem, ou por estação e minuto, é o laço
por linha da primeira seção de novo. **Dê ao `agg` e ao `transform` os nomes que eles conhecem**,
`"median"`, `"mean"`, `"sum"`, `"size"`, `"nunique"`, `"first"`, e guarde funções para cálculos que
nenhum nome cobre.
