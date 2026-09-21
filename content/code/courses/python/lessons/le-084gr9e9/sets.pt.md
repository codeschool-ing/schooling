---
title: Pertinência e unicidade, e ordem nenhuma
version: 1
---

```python
langs = {"python", "go", "sql"}
```

Chaves sem dois pontos. **O conjunto vazio é `set()`** — `{}` é um dicionário vazio, que é a única
peça de sintaxe aqui que precisa ser decorada.

## Para que serve

**Unicidade.** Acrescentar duas vezes deixa um:

```python
>>> vistos = set()
>>> vistos.add("ada")
>>> vistos.add("ada")
>>> len(vistos)
1
```

`list(set(itens))` é a linha única para tirar duplicatas, e ela joga a ordem fora. Quando a ordem
importa, `list(dict.fromkeys(itens))` guarda a primeira ocorrência de cada.

**E pertinência.** `x in algum_conjunto` é um passo, como num dicionário e ao contrário de uma lista.

## Os operadores

```python
>>> a = {1, 2, 3}
>>> b = {3, 4}
>>> a | b        # união — em um ou no outro
{1, 2, 3, 4}
>>> a & b        # interseção — nos dois
{3}
>>> a - b        # diferença — em a e não em b
{1, 2}
>>> a ^ b        # diferença simétrica — em um mas não nos dois
{1, 2, 4}
```

Eles substituem laços. *Quais usuários estão nos dois grupos* é `&`. *Quais arquivos são novos* é
`-`. Cada um é uma expressão e cada um é rápido.

## O que ele não faz

**Sem ordem**, logo sem índice: `langs[0]` levanta erro. Imprimir um mostra uma ordem e você não pode
confiar nela.

**Sem duplicatas**, que é o ponto e de vez em quando é a ferramenta errada — contar quantas vezes
cada palavra aparece precisa de um dicionário.

**Só membros hasháveis.** Um conjunto de tuplas serve; um conjunto de listas levanta `TypeError:
unhashable type: 'list'`.

## `frozenset`

A versão imutável, que por isso pode ser chave de dicionário ou membro de outro conjunto. Raro, e
vale reconhecer quando aparecer.
