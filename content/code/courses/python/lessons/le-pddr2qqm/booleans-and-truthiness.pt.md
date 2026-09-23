---
title: O que conta como falso, e o `and` que devolve uma string
version: 2
---

`True` e `False` são os dois booleanos, e por baixo eles são **inteiros**: `True + True` é `2`, e
`sum([True, False, True])` é `2` — que é um jeito genuinamente útil de contar quantas coisas de uma
lista satisfazem alguma condição.

## Veracidade

Todo valor pode ser usado onde se espera uma condição. Estes são os falsos, e a lista é curta o
bastante para aprender:

| | |
|---|---|
| `False` | |
| `None` | |
| `0`, `0.0` | qualquer zero |
| `""` | a string vazia |
| `[]`, `()`, `{}`, `set()` | qualquer contêiner vazio |

**Todo o resto é verdadeiro** — inclusive `"False"`, `"0"` e `[0]`, cada um deles uma coisa não
vazia.

Então o idioma é este:

```python
if items:
    ...
```

em vez de `if len(items) > 0`. Lê melhor e é a convenção.

**E é uma armadilha exatamente uma vez**, quando zero é um valor de verdade:

```python
if count:          # skips the case where count is 0
if count is not None:   # what you meant
```

## `and` e `or` não devolvem booleanos

```python
>>> "ada" or "nobody"
'ada'
>>> "" or "nobody"
'nobody'
>>> "ada" and "lovelace"
'lovelace'
```

O `or` devolve o primeiro operando verdadeiro, ou o último. O `and` devolve o primeiro falso, ou o
último. Os dois têm **curto-circuito**: o lado direito não é avaliado se o esquerdo já decidiu.

É isso que torna isto seguro:

```python
if user is not None and user.name == "Ada":
```

O `user.name` nunca é alcançado quando `user` é `None`.

E é de onde vem o velho idioma de valor padrão:

```python
name = supplied or "anonymous"
```

Que é elegante, e silenciosamente errado quando `""` ou `0` é um valor que você queria manter. `if
fornecido is None` diz o que você quis dizer.

## `not`

O `not` devolve um booleano de verdade, sempre: `not ""` é `True`, `not [1]` é `False`.
