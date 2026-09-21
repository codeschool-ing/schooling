---
title: Comparações encadeadas, e `==` contra `is`
version: 1
---

## Os operadores

`==` `!=` `<` `>` `<=` `>=`, e funcionam em números, strings e qualquer coisa que os defina.

**Strings comparam por ponto de código**, então `"apple" < "banana"` é `True` e `"Z" < "a"` também é
`True`, porque as maiúsculas vêm antes. Para ordenar texto que uma pessoa vai ler, `key=str.lower` em
geral é o que se queria.

## Encadear

```python
if 0 <= indice < len(itens):
```

Isso é uma expressão só e significa o que parece. A maioria das linguagens não faz isso; em Python
`a < b < c` é `a < b and b < c`, com `b` avaliado uma vez.

## `==` contra `is`

```python
>>> a = [1, 2]
>>> b = [1, 2]
>>> a == b
True
>>> a is b
False
```

**O `==` pergunta se os valores são iguais. O `is` pergunta se são o mesmo objeto.**

Use `is` para `None`, `True` e `False` — existe exatamente um de cada — e `==` para todo o resto. O
`is` em strings ou números pequenos às vezes responde `True` porque o interpretador os reaproveita, o
que faz parecer que funciona até o dia em que não funciona.

## `in`

```python
>>> "ada" in "ada lovelace"      # trecho
True
>>> 3 in [1, 2, 3]               # pertinência
True
>>> "nome" in pessoa             # as CHAVES de um dicionário
True
```

Um operador, três contêineres, e num dicionário são as chaves e não os valores. A tabela da aula 3
tem o custo de cada um.

## Comparando tipos diferentes

`1 == 1.0` é `True`; `1 == "1"` é `False` e não levanta erro. Mas ordenar levanta:

```python
>>> 1 < "1"
TypeError: '<' not supported between instances of 'int' and 'str'
```

**Igualdade responde; ordem recusa.** Essa assimetria é deliberada: dois valores de tipos diferentes
certamente não são iguais, e não há resposta honesta para qual deles é maior.
