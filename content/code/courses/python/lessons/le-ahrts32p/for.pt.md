---
title: Itere a coisa, não o índice
version: 2
---

```python
for lang in langs:
    print(lang)
```

Sem contador, sem comprimento, sem índice. O laço pede os itens à coleção e a coleção os entrega.

**Isto não é preferência de estilo.** Contar significa um índice, um índice significa um erro de um a
mais, e um erro de um a mais num laço é o defeito mais comum que existe. Iterar a coisa tira a
oportunidade.

## Quando você precisa da posição

```python
for i, lang in enumerate(langs):
    print(i, lang)
```

O `enumerate` dá os dois, e aceita `start=1` quando a numeração é para uma pessoa.

**Quase todo `for i in range(len(xs))` é isto disfarçado.** Se você se pegar escrevendo um, a
pergunta é se você quer `enumerate` ou se queria os itens desde o começo.

## Duas coleções juntas

```python
for name, score in zip(names, scores):
```

O `zip` para na mais curta, em silêncio. Tudo bem quando você sabe que elas casam e é um buraco
quando não sabe — `zip(a, b, strict=True)` levanta erro em vez disso, e vale a palavra a mais.

## O que pode ser iterado

Listas, tuplas, conjuntos, strings, dicionários, arquivos, e qualquer coisa que a aula 11 chame de
iterador.

```python
for ch in "ada":          # characters
for key in person:        # a dictionary's KEYS
for k, v in person.items():
for line in open("f.txt"):  # one line at a time
```

**Um dicionário itera as chaves**, o que pega quem esperava pares.

## `range`

```python
range(5)          # 0 1 2 3 4
range(1, 6)       # 1 2 3 4 5
range(0, 10, 2)   # 0 2 4 6 8
```

O fim é exclusivo, como numa fatia, pelo mesmo motivo: `range(n)` tem `n` itens.

**O `range` é para quando você quer números mesmo** — um número fixo de tentativas, uma grade — e não
como jeito de indexar uma lista.

## `break`, `continue`, e o `else` que ninguém espera

```python
for item in items:
    if matches(item):
        break
else:
    print("nothing matched")
```

O `break` sai do laço; o `continue` pula para o próximo item. **O `else` roda quando o laço terminou
sem um `break`** — é genuinamente útil para busca, é lido errado por quase todo mundo, e um
comentário ao lado vale as duas palavras.
