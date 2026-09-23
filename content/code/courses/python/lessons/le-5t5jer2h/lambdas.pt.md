---
title: Uma expressão com parâmetros
version: 2
---

```python
square = lambda x: x * x        # don't
def square(x): return x * x     # do
```

Um `lambda` é uma função escrita como uma expressão só. Ela tem parâmetros, devolve o valor da
expressão, e não tem nome próprio.

**Atribuir um a um nome é o caso em que o `def` é estritamente melhor**: mesmo tamanho, dá à função
um nome de verdade para o traceback, e permite uma docstring.

## Onde ele está certo

```python
rows.sort(key=lambda r: r["city"])
max(people, key=lambda p: p["score"])
sorted(words, key=lambda w: (len(w), w))
```

Passado direto para algo que recebe uma função, usado uma vez, e curto o bastante para ler ali
mesmo. Isso é o `key=` quase toda vez — o terceiro exemplo ordena por comprimento e depois
alfabeticamente, e escrevê-lo como função nomeada poria a parte interessante em outra linha.

## Os limites

**É uma expressão só.** Nenhuma instrução cabe dentro: nem atribuição, nem comando `if` (a EXPRESSÃO
condicional cabe), nem laço, nem `try`. Isso não é uma restrição a contornar — é o limite que torna
um lambda seguro de ler no meio de outra linha.

## O `operator`, para os casos comuns

```python
from operator import itemgetter
rows.sort(key=itemgetter("city"))
```

`itemgetter` e `attrgetter` dizem o que fazem e são um pouco mais rápidos. Qualquer um serve; o
lambda é mais óbvio para quem não conhece o `operator`.

## A regra

**Se ele é mais longo que a linha em que está, ou se você quer dar um nome a ele, escreva um
`def`.** Um lambda que cresceu para três cláusulas é uma função se escondendo do próprio nome.
