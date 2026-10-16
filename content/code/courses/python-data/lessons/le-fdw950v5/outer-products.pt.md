---
title: Todos os pares, de propósito
version: 1
---

**O `(n, 1)` contra `(n,)` silencioso de duas seções atrás é um defeito quando acontece por acaso e
uma das ferramentas mais úteis do NumPy quando acontece de propósito.** Uma coluna contra uma linha
dá todas as combinações das duas, sem laço e sem escrever as combinações.

As docas de cinco estações, e a pergunta "quantas docas a mais cada estação tem que cada outra":

```python
docks = np.array([14, 20, 12, 17, 10])
difference = docks[:, np.newaxis] - docks
difference
```

```
array([[  0,  -6,   2,  -3,   4],
       [  6,   0,   8,   3,  10],
       [ -2,  -8,   0,  -5,   2],
       [  3,  -3,   5,   0,   7],
       [ -4, -10,  -2,  -7,   0]])
```

A linha `i`, coluna `j`, guarda as docas da estação `i` menos as da estação `j`. A diagonal é
zero, cada estação contra si mesma, e a tabela é antissimétrica: a entrada `(j, i)` é menos a
entrada `(i, j)`. Vinte e cinco números em duas linhas, e o formato diz o que é: **`(5, 1)` contra
`(5,)` é uma tabela 5 × 5 de pares.**

## Uma tabela de contagens esperadas

Pares são como se monta um modelo de "o que você esperaria se duas coisas fossem independentes".
Suponha que as viagens ao longo do dia sigam um formato, a fração de cada período, e que os dias só
difiram em quantas viagens têm. A contagem esperada para cada dia e cada período é um produto:

```python
hour_share = np.array([0.02, 0.10, 0.25, 0.30, 0.23, 0.10])
day_totals = np.array([96, 110, 71])
expected = day_totals[:, np.newaxis] * hour_share
expected.shape, expected.round(1)
```

```
((3, 6),
 array([[ 1.9,  9.6, 24. , 28.8, 22.1,  9.6],
        [ 2.2, 11. , 27.5, 33. , 25.3, 11. ],
        [ 1.4,  7.1, 17.8, 21.3, 16.3,  7.1]]))
```

Três dias por seis períodos do dia, cada linha somando o total do seu dia. A aula 15 monta com o
pandas a tabela real de viagens por dia e hora, e compará-la com uma tabela como esta é como se
acham os horários mais movimentados do que a sua fração.

Os formatos dizem qual é a linha e qual é a coluna. Ponha `day_totals` em segundo, sem expandir, e
os formatos `(6,)` e `(3,)` nem fazem broadcasting, que é a regra protegendo você; dê o eixo novo a
`hour_share`, e você recebe os mesmos números transpostos, seis por três. Decida de que lado quer a
tabela antes de escrever a linha.
