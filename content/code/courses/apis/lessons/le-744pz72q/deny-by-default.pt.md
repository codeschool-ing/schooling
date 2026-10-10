---
title: Negar por padrão
version: 1
---

**Uma API deve recusar tudo o que não mandaram ela permitir.** O projeto oposto lista o que é
proibido e deixa o resto passar, e ele falha na pior direção: todo papel, rota ou ação que alguém
esqueceu de mencionar fica aberto.

A diferença aparece melhor em duas versões da mesma checagem. A primeira é uma lista de recusas:

```python
def allowed(role, action):
    if role == "customer" and action in ("orders:refund", "people:read"):
        return False
    return True
```

A segunda é uma lista de concessões:

```python
def allowed(role, action):
    return action in ROLES.get(role, set())
```

As duas concordam em todo caso em que o autor pensou, e discordam em todo o resto. Um papel novo
`auditor` acrescentado no banco, uma ação nova `orders:export` acrescentada no código, um nome de
papel digitado com um erro: a primeira função responde `True` aos três e a segunda responde `False`.
Uma dessas falhas é um colega perguntando por que não consegue exportar. A outra é um estranho que
consegue, e ninguém fica sabendo.

**Negar por padrão atravessa todas as camadas do `orders.py`**, e cada camada tem o seu jeito de
dizer não:

| o que falta | o que quem chamou recebe |
|---|---|
| um token, ou um token que a API nunca emitiu | 401, para todo endereço, real ou não |
| uma rota para aquele endereço | 404 |
| uma rota para aquele método naquele endereço | 405 |
| a permissão da rota, no conjunto de quem chamou | 403 |
| o papel de quem chamou, na tabela `ROLES` | um conjunto vazio de permissões, então 403 em tudo |

A última linha é a que mais se escreve ao contrário. `ROLES.get(role, set())` dá a um papel para o
qual ninguém escreveu permissões nenhuma permissão. `ROLES[role]` teria derrubado a requisição com
um `KeyError`, que pelo menos faz barulho, e um padrão de "tudo" teria tornado todo papel digitado
errado um administrador. A tabela de pessoas tem um papel assim de propósito: a Eva é `auditor`, e
"A API de pedidos" mostra o que ela recebe.

A mesma regra vale para uma rota. Cada linha de `ROUTES` nomeia a permissão de que precisa, e uma
linha escrita com o nome errado, `order:read` no lugar de `orders:read`, é uma rota que ninguém
consegue chamar. É um bug que alguém acha no primeiro minuto. O contrário, uma rota que não precisava
de permissão nenhuma porque ninguém escreveu uma, é um bug que ninguém acha.
