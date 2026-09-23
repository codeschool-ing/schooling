---
title: `sort`, `sorted`, `key=`, e o que custa
version: 2
---

```python
data.sort()               # sorts in place, returns None
new = sorted(data)        # returns a new list, leaves data alone
```

```sh
>>> d = [3, 1, 2]
>>> d.sort()
>>> d
[1, 2, 3]
```

**O `sort()` devolve `None`.** `x = data.sort()` põe nada em `x`, e é o engano mais comum com
qualquer um dos dois. O `sorted` é o padrão a que recorrer; o `sort` é para quando a lista é
grande e você não precisa da original.

O `sorted` também recebe qualquer iterável e sempre devolve uma lista, que é como se ordena um
set, as chaves de um dict ou um gerador.

## `key=`

```python
rows.sort(key=lambda r: r["cents"])
rows.sort(key=lambda r: (r["country"], -r["cents"]))     # country, then by size
```

A função é chamada **uma vez por elemento**, e os resultados é que são comparados. Uma tupla
ordena pelo primeiro item, depois pelo segundo, que é como uma ordenação secundária se escreve
numa linha — e negar um número inverte aquele componente sozinho.

```sh
sorted with key=lambda,  n=100,000    27.5 ms
sorted with itemgetter,  n=100,000    25.3 ms
sorted, no key,          n=100,000    18.1 ms
```

Uma `key` custa cerca de metade a mais. O `operator.itemgetter` é um pouco mais rápido que uma
lambda e não o bastante para importar.

## Estabilidade

```sh
>>> rows = [("b", 2), ("a", 1), ("b", 1), ("a", 2)]
>>> sorted(rows, key=lambda r: r[0])
[('a', 1), ('a', 2), ('b', 2), ('b', 1)]
```

**Elementos iguais mantêm a ordem original.** `('b', 2)` continua antes de `('b', 1)` porque
estava, e nada na ordenação mexeu nisso.

Isso é uma garantia, e é o que faz duas ordenações funcionarem:

```sh
>>> sorted(sorted(rows, key=lambda r: r[1]), key=lambda r: r[0])
[('a', 1), ('a', 2), ('b', 1), ('b', 2)]
```

Ordene pela chave secundária primeiro, depois pela primária. A segunda ordenação deixa a ordem da
primeira intacta dentro de cada grupo.

## O que custa

`O(n log n)`, medido na seção das curvas: dez vezes os dados, cerca de catorze vezes o trabalho. A
ordenação do Python é o Timsort, que é muito mais rápido em dados já parcialmente ordenados — em
um milhão de floats, ordenar uma lista aleatória leva 344 ms e ordenar uma já ordenada leva 85,
porque ele acha os trechos que já estão em ordem e os mescla.

## Quando você não precisa de uma ordenação

```python
max(rows, key=lambda r: r["cents"])              # O(n), not O(n log n)
heapq.nlargest(10, rows, key=lambda r: r["cents"])
```

```sh
at n = 1,000,000 floats
  sorted(data)[-10:]     349.6 ms
  heapq.nlargest(10, …)   15.2 ms
  max(data)               11.3 ms
```

Ordenar tudo para pegar o maior é `O(n log n)` onde o `max` é uma passagem só. Para os poucos do
topo, o `heapq.nlargest` é vinte e três vezes uma ordenação completa em um milhão de itens.
