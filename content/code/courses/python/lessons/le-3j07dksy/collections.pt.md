---
title: O que tem dentro, e a tupla que são dois tipos
version: 1
---

```python
def nomes(linhas: list[dict]) -> list[str]: ...
def contagens(palavras: list[str]) -> dict[str, int]: ...
def par() -> tuple[int, str]: ...
def ponto() -> tuple[float, float]: ...
```

Os colchetes dizem o que tem dentro. Um `list` sozinho é uma lista de qualquer coisa, que é a
maior parte do que uma anotação serve para não deixar por dizer.

## `dict[chave, valor]`

```python
dict[str, int]          # palavras para contagens
dict[str, list[dict]]   # aninhando, até onde for
```

Dois parâmetros, nessa ordem, e eles aninham sem limite. O segundo exemplo é a forma do JSON da
aula 9 escrita.

## A tupla que não é como as outras

```python
tuple[int, str]         # exatamente dois itens: um int e um str
tuple[int, ...]         # qualquer quantidade de ints
tuple[int]              # exatamente UM int
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
list[int]               # agora
List[int]               # antes da 3.9, do `typing`
```

Os embutidos minúsculos recebem colchetes direto. Os maiúsculos do `typing` continuam funcionando
e são o que você vai ver em código antigo — e o `from __future__ import annotations` deixa a
sintaxe nova ser usada em qualquer versão, porque a anotação nunca é avaliada.

## O que anotar quando é uma bagunça

```python
def analisar(dados: dict) -> dict: ...           # não diz quase nada
def analisar(dados: dict[str, Any]) -> Linha: ... # diz o que você de fato sabe
```

Se a forma é genuinamente irregular, diga `dict[str, Any]` e siga — e se ela é regular, o
`TypedDict` numa seção adiante lhe dá um nome.
