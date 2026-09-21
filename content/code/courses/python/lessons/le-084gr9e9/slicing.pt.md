---
title: `[início:fim:passo]`, e a cópia que ele faz
version: 1
---

```python
>>> letras = ["a", "b", "c", "d", "e"]
>>> letras[1:3]
['b', 'c']
```

**O fim é exclusivo.** `[1:3]` são as posições 1 e 2. Isso parece arbitrário até você reparar no que
compra: `len(xs[a:b])` é `b - a`, e `xs[:n] + xs[n:]` é a coisa inteira sem sobreposição e sem buraco.

## Deixando partes de fora

```python
>>> letras[:2]     # do começo
['a', 'b']
>>> letras[2:]     # até o fim
['c', 'd', 'e']
>>> letras[:]      # tudo — e uma lista NOVA
['a', 'b', 'c', 'd', 'e']
```

## O passo

```python
>>> letras[::2]
['a', 'c', 'e']
>>> letras[::-1]
['e', 'd', 'c', 'b', 'a']
```

`[::-1]` inverte. Funciona em strings também — `"ada"[::-1]` é `'ada'`, que é como se testa um
palíndromo numa expressão.

## Uma fatia nunca levanta erro

```python
>>> letras[10:20]
[]
```

Onde `letras[10]` levanta `IndexError`, a fatia simplesmente te dá o que existe. É conveniente e é
também um lugar onde um defeito se esconde: um resultado vazio pode significar *nada casou* ou *meus
índices eram absurdos*, e a fatia não vai dizer qual.

## Ela é uma cópia

```python
>>> a = [1, 2, 3]
>>> b = a[:]
>>> b.append(4)
>>> a
[1, 2, 3]
```

`a[:]` é um dos três jeitos de copiar uma lista — os outros são `list(a)` e `a.copy()`, e os três são
**rasos**, que é do que a seção `copying` trata.

## Atribuindo a uma fatia

```python
>>> a = [1, 2, 3, 4]
>>> a[1:3] = ["x"]
>>> a
[1, 'x', 4]
```

A substituição não precisa ter o mesmo comprimento. Raramente é o que se quer, e vale reconhecer ao
ler.

## Em strings

A sintaxe é idêntica, porque fatiar pertence a sequências e uma string é uma. A diferença é que uma
fatia de string é uma string nova e não se atribui a ela — strings são imutáveis.
