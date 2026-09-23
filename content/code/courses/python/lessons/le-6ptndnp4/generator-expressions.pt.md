---
title: A compreensão com parênteses
version: 2
---

```python
[x * 2 for x in xs]       # a list, built now
(x * 2 for x in xs)       # a generator, built never
```

A mesma sintaxe, delimitadores diferentes, comportamento completamente diferente. A primeira
percorre `xs` e devolve uma lista. A segunda devolve um gerador que não fez nada.

## Onde isso poupa alguma coisa

```python
total = sum(int(row["amount"]) for row in rows)
```

Nenhuma lista de um milhão de números existe em momento nenhum. Quando a chamada já tem
parênteses próprios, o par extra é desnecessário — `sum(x for x in xs)` em vez de
`sum((x for x in xs))`.

## Onde isso não poupa nada

```python
names = [p["name"] for p in people]        # you want the list
```

Se você vai guardá-la, indexá-la, ou percorrê-la duas vezes, construa a lista. Um gerador no qual
você chama `list()` na hora seguinte é uma compreensão de lista com palavras a mais.

**O teste é o que acontece em seguida.** Direto para um `sum`, `max`, `any`, `all`, `"".join`,
outro gerador, ou um `for` que roda uma vez — gerador. Qualquer outra coisa — lista.

## `any` e `all`

```python
if any(r["city"] == "Porto" for r in rows):
```

Os dois fazem curto-circuito, então isto para na primeira coincidência em vez de conferir um
milhão de linhas. Com uma compreensão de lista dentro, ele construiria a lista inteira antes e só
então pararia no primeiro item — que é a mesma resposta e nenhuma das economias.

## O que morde

```python
gen = (x for x in rows)
print(len(gen))          # TypeError
```

Um gerador não tem comprimento, porque ele não sabe nenhum. `sum(1 for _ in g)` o conta — e o
gasta, que é a outra metade da aula.
