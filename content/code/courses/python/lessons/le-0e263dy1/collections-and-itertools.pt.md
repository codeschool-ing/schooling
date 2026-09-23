---
title: Quatro contêineres e quatro laços que você não escreve mais
version: 2
---

## `Counter`

```python
from collections import Counter

counts = Counter(words)
counts["python"]              # 0 if absent, rather than a KeyError
counts.most_common(3)
```

Contar é o laço mais escrito que existe, e isto é ele numa linha. O `most_common` é a ordenação que
você escreveria depois, e a subtração e a soma de dois `Counter` funcionam como você esperaria.

## `defaultdict`

```python
from collections import defaultdict

by_city = defaultdict(list)
for person in people:
    by_city[person["city"]].append(person)
```

Agrupar, sem a linha `if chave not in d`. O argumento é uma FUNÇÃO chamada para criar o valor que
falta — `list`, `int`, `set` — que é o "uma função é um valor" da aula 5 trabalhando.

**O `dict.setdefault` faz a mesma coisa para uma busca**, e um `defaultdict` fica mais claro no
momento em que há duas.

## `namedtuple`

```python
from collections import namedtuple
Point = namedtuple("Point", "x y")
p = Point(1, 2)
p.x
```

Uma tupla cujas posições têm nomes. O `@dataclass(frozen=True)` da aula 6 faz mais e se lê melhor;
o `namedtuple` é o que você vai encontrar em código antigo, e continua sendo o jeito mais leve de
parar de escrever `row[2]`.

## `deque`

```python
from collections import deque
recent = deque(maxlen=100)
recent.append(item)            # the oldest falls off the end
```

Uma lista é lenta para remover da FRENTE — todos os outros itens deslizam. Um `deque` não é, e o
`maxlen` dá de graça uma janela de tamanho fixo com as últimas n coisas.

## Quatro `itertools` que ganham a importação

```python
from itertools import product, chain, groupby, islice

product(sizes, colours)          # every pair, without the nested loop
chain(a, b, c)                   # iterate three lists as one
islice(rows, 10)                 # the first ten of anything, without a list
groupby(sorted(rows, key=k), k)  # runs of equal keys — SORT FIRST
```

O `groupby` é o que pega as pessoas: ele agrupa chaves iguais CONSECUTIVAS, então uma entrada
desordenada dá a mesma chave várias vezes e ninguém diz nada. Ordenar pela mesma chave antes não é
opcional.

Os quatro devolvem iteradores — o assunto da aula 11 — que é por que `islice(rows, 10)` num
arquivo de um milhão de linhas lê dez linhas em vez de um milhão.
