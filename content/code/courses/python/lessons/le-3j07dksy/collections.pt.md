---
title: O que tem dentro, e a tupla que são dois tipos
version: 2
---

```python
def names(rows: list[dict]) -> list[str]: ...
def counts(words: list[str]) -> dict[str, int]: ...
def pair() -> tuple[int, str]: ...
def point() -> tuple[float, float]: ...
```

Os colchetes dizem o que tem dentro. Um `list` sozinho é uma lista de qualquer coisa, que é a
maior parte do que uma anotação serve para não deixar por dizer.

## `dict[key, value]`

```python
dict[str, int]          # words to counts
dict[str, list[dict]]   # nesting, as deep as it goes
```

Dois parâmetros, nessa ordem, e eles aninham sem limite. O segundo exemplo é a forma do JSON da
aula 9 escrita.

## A tupla que não é como as outras

```python
tuple[int, str]         # exactly two items: an int and a str
tuple[int, ...]         # any number of ints
tuple[int]              # exactly ONE int
```

**A anotação de uma tupla lista toda posição**, porque as posições de uma tupla têm significados.
O `...` é sintaxe literal — três pontos — e é como se diz "mais do mesmo". `tuple[int]` é uma
tupla de um item e quase nunca é o que alguém quis dizer.

## `set` e `frozenset`

```python
set[str]
frozenset[str]
```

A mesma forma, um parâmetro.

## Desde o Python 3.9

```python
list[int]               # now
List[int]               # before 3.9, from `typing`
```

Os embutidos minúsculos recebem colchetes direto. Os maiúsculos do `typing` continuam funcionando
e são o que você vai ver em código antigo — e o `from __future__ import annotations` deixa a
sintaxe nova ser usada em qualquer versão, porque a anotação nunca é avaliada.

## O que anotar quando é uma bagunça

```python
def parse(data: dict) -> dict: ...          # says almost nothing
def parse(data: dict[str, Any]) -> Row: ... # says what you actually know
```

Se a forma é genuinamente irregular, diga `dict[str, Any]` e siga — e se ela é regular, o
`TypedDict`, na seção `your-own-types` desta aula, lhe dá um nome.
