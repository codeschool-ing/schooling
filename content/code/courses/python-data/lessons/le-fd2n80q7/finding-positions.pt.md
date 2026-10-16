---
title: De uma máscara de volta às posições
version: 1
---

**Uma máscara diz *se* para cada elemento; às vezes você precisa de *onde*, em números.**
`np.nonzero` transforma uma máscara nas posições dos seus `True`, e `np.flatnonzero` faz o mesmo
para um array plano sem embrulhar a resposta numa tupla:

```python
missing = np.flatnonzero(np.isnan(rain))
missing, dates[missing]
```

```
(array([172, 212, 216, 268, 304, 323]),
 array(['2025-06-22', '2025-08-01', '2025-08-05', '2025-09-26',
        '2025-11-01', '2025-11-20'], dtype='<U10'))
```

Os seis dias sem leitura de chuva, por posição e por data. Posições são o que você precisa para olhar
os vizinhos de um dia, informar um buraco, ou corrigir um valor à mão com um comentário dizendo por
quê.

## O primeiro e o último

`argmax` numa máscara acha o primeiro `True`, como a aula 5 mostrou. O último é a mesma pergunta
feita à máscara invertida:

```python
over_40 = rain > 40
first = np.argmax(over_40)
last = len(over_40) - 1 - np.argmax(over_40[::-1])
dates[first], dates[last], over_40.any()
```

```
(np.str_('2025-03-22'), np.str_('2025-09-03'), np.True_)
```

**Confira `any()` antes de confiar no `argmax` de uma máscara**: numa máscara sem nenhum `True`,
`argmax` devolve 0, o que parece exatamente uma resposta.

## `np.where` com um argumento

`np.where(máscara)` sem o segundo e o terceiro argumentos é `np.nonzero(máscara)`: uma tupla de
arrays de posições, um por eixo. Numa tabela isso dá um array de linhas e um de colunas, emparelhados:

```python
rows, cols = np.where(weeks > 32)
rows, cols, weeks[rows, cols]
```

```
(array([ 7, 10, 30, 36, 36, 48]),
 array([1, 0, 6, 4, 6, 0]),
 array([32.1, 32.1, 32.6, 32.1, 32.1, 32.1]))
```

Cada par `(rows[i], cols[i])` é um dia quente: a semana dele e a posição na semana. Indexar a tabela
com os dois arrays devolve as temperaturas, elemento a elemento, como as listas emparelhadas da seção
anterior.
