---
title: O que dá para percorrer duas vezes, e o que não dá
version: 1
---

**Um ITERÁVEL consegue produzir um iterador.** Uma lista, uma tupla, uma string, um dicionário, um
conjunto.

**Um ITERADOR produz valores, uma vez.** O que o `iter()` dá, o que um gerador é, o que o `zip` e
o `map` devolvem no Python 3.

```python
xs = [1, 2, 3]
sum(xs)      # 6
sum(xs)      # 6 — um iterador novo a cada vez

g = (x for x in [1, 2, 3])
sum(g)       # 6
sum(g)       # 0 — e nada diz por quê
```

## Esse zero é a armadilha

Não é um erro. O `sum` pediu valores, não recebeu nenhum, e devolveu o valor inicial dele. A mesma
coisa com o `max` levanta `ValueError`, com o `"".join` dá uma string vazia, e com um laço `for`
simplesmente não roda o corpo.

**Um resultado que é zero, vazio ou ausente, vindo de um código que funcionava semana passada, é
isto** — e a linha a olhar é onde o gerador foi consumido pela primeira vez.

## Um iterador também é um iterável

```python
iter(it) is it       # True
```

Que é por que você põe um gerador direto num laço `for`. Isso também quer dizer que uma função que
recebe "um iterável" não tem como saber se pode percorrê-lo duas vezes — e uma função que percorre
o argumento dela duas vezes é uma que quebra em silêncio com um gerador.

## Se você precisa dele duas vezes

```python
linhas = list(linhas)        # deliberadamente, e agora cabe na memória ou não cabe
```

Não existe como rebobinar um iterador. O `itertools.tee` existe e não compra nada quando as duas
cópias são consumidas inteiras — ele guarda o que uma viu e a outra não, que é uma lista com
passos a mais.

A outra resposta é voltar à fonte: abrir o arquivo de novo, rodar a consulta de novo. Para algo
grande essa é a resposta correta, e não a preguiçosa.
