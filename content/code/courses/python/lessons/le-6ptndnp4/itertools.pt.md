---
title: Seis que ganham a importação
version: 2
---

```python
from itertools import islice, chain, groupby, count, cycle, takewhile
```

## `islice`

```python
islice(rows, 10)          # the first ten
islice(rows, 10, 20)      # the tenth to the twentieth
```

Fatiar para coisas que você não consegue indexar. Num arquivo de um milhão de linhas ele lê dez
linhas, o que `list(rows)[:10]` não faz.

## `chain`

```python
for row in chain(header_rows, body_rows, footer_rows):
```

Três iteráveis, percorridos como um, sem nada concatenado. O `chain.from_iterable(lista_de_listas)`
achata um nível, preguiçosamente.

## `groupby`

```python
for city, group in groupby(sorted(rows, key=city_of), key=city_of):
```

Trechos de chaves iguais CONSECUTIVAS, que é por que a ordenação não é opcional — entrada
desordenada dá a mesma chave várias vezes e não diz nada. A aula 7 encontrou isto; vale encontrar
duas vezes.

## `count` e `cycle`

```python
for i, row in zip(count(1), rows):        # numbering, without len
for row, colour in zip(rows, cycle(["odd", "even"])):
```

Os dois são infinitos, o que está bem porque o `zip` para no mais curto. O `count` é um `range` sem
fim; o `cycle` repete uma sequência para sempre e **guarda uma cópia dela**, o que importa se ela
for grande.

## `takewhile` e `dropwhile`

```python
takewhile(lambda r: r["date"] < cutoff, rows)     # stop at the first that fails
```

O `takewhile` para no primeiro item que falha o teste — ele não filtra, ele ENCERRA. Num arquivo
ordenado essa é a diferença entre ler a parte que você quer e ler tudo.

## E uma regra sobre todos eles

Eles devolvem iteradores. Tudo desta aula se aplica: uma passada, sem comprimento, e nada
calculado até alguém pedir.
