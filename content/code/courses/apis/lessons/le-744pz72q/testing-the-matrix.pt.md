---
title: Testando a matriz
version: 1
---

**Autorização é uma tabela, todo chamador contra toda operação, e em cada célula a resposta que deve
voltar.** Então o teste dela também é uma tabela: mandar toda requisição como todo chamador, comparar
cada status com o esperado e falhar em qualquer diferença, nas duas direções.

A outra direção é o motivo de escrever esse teste. Um teste da funcionalidade checa que a Ana
consegue ler o pedido dela. Um teste da autorização checa também que a Ana não consegue ler o do
Bruno. Ninguém escreve essa checagem à mão, porque nada parece quebrado quando ela falha: o pedido
aparece, a página está ótima, e só o Bruno se importaria.

O `matrix.py` é esse teste para o `orders.py`. Ele faz as requisições com o `urllib`, da biblioteca
padrão do Python. Salve em `~/shelf`:

```python
# shelf/matrix.py
"""Every token against every endpoint of orders.py, compared with what should happen.

Run it while orders.py is running: python3 matrix.py
"""
import json
import sys
import urllib.error
import urllib.request

ENDPOINTS = [
    ("GET", "/orders"),
    ("GET", "/orders/1"),
    ("GET", "/orders/3"),
    ("GET", "/orders/99"),
    ("POST", "/orders"),
    ("GET", "/admin/people"),
]

# One row per token, one status per endpoint, in the order above.
EXPECTED = {
    None: [401, 401, 401, 401, 401, 401],
    "demo-ana": [200, 200, 404, 404, 201, 403],
    "demo-ana-app": [200, 200, 404, 404, 403, 403],
    "demo-bruno": [200, 404, 200, 404, 201, 403],
    "demo-carla": [200, 200, 200, 404, 403, 403],
    "demo-dora": [200, 200, 200, 404, 403, 200],
    "demo-eva": [403, 403, 403, 403, 403, 403],
}


def status(method, path, token):
    req = urllib.request.Request("http://127.0.0.1:8000" + path, method=method)
    if token:
        req.add_header("Authorization", "Bearer " + token)
    if method == "POST":
        req.add_header("Content-Type", "application/json")
        req.data = json.dumps({"book_id": 1, "quantity": 1}).encode()
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status
    except urllib.error.HTTPError as e:
        return e.code


for n, (method, path) in enumerate(ENDPOINTS, 1):
    print(f"{n}  {method} {path}")
print()
print(f"{'token':14}" + "".join(f"{n:>6}" for n in range(1, len(ENDPOINTS) + 1)))
wrong = []
for token, expected in EXPECTED.items():
    cells = ""
    for (method, path), want in zip(ENDPOINTS, expected):
        got = status(method, path, token)
        cells += f"{got:>5}" + (" " if got == want else "!")
        if got != want:
            wrong.append(f"{token}: {method} {path} answered {got}, expected {want}")
    print(f"{token or '(no token)':14}{cells}".rstrip())
print()
for line in wrong:
    print(line)
checks = len(EXPECTED) * len(ENDPOINTS)
print(f"{checks} checks, {len(wrong)} wrong")
sys.exit(1 if wrong else 0)
```

`EXPECTED` é a especificação, escrita por uma pessoa, uma linha por token. **É a parte a ler numa
revisão**: alguém que sabe o que a loja pretende pode conferir cada célula sem ler uma linha do
`orders.py`. Com o `orders.py` rodando no segundo terminal:

```
ana@api:~/shelf$ python3 matrix.py; echo "exit $?"
1  GET /orders
2  GET /orders/1
3  GET /orders/3
4  GET /orders/99
5  POST /orders
6  GET /admin/people

token              1     2     3     4     5     6
(no token)      401   401   401   401   401   401
demo-ana        200   200   404   404   201   403
demo-ana-app    200   200   404   404   403   403
demo-bruno      200   404   200   404   201   403
demo-carla      200   200   200   404   403   403
demo-dora       200   200   200   404   403   200
demo-eva        403   403   403   403   403   403

42 checks, 0 wrong
exit 0
```

Quarenta e duas checagens, nenhuma errada, e status de saída 0, então um script ou um job de CI pode
rodar o teste e parar numa falha. Cada execução faz mais dois pedidos, o da Ana e o do Bruno, o que
não muda nenhuma célula.

## Quebrando de propósito

Um teste que você só viu passar ainda não mostrou que consegue falhar. Faça uma cópia do `orders.py`
sem as duas linhas da checagem de dono, e veja o que saiu:

```
ana@api:~/shelf$ sed '/!= me and/,+1d' orders.py > broken.py
ana@api:~/shelf$ diff orders.py broken.py
80,81d79
<     if order["customer"] != me and "orders:read_all" not in perms:
<         return None
```

Pare o `orders.py` no segundo terminal e inicie a cópia ali com `python3 broken.py`. Depois rode a
matriz de novo:

```
ana@api:~/shelf$ python3 matrix.py; echo "exit $?"
1  GET /orders
2  GET /orders/1
3  GET /orders/3
4  GET /orders/99
5  POST /orders
6  GET /admin/people

token              1     2     3     4     5     6
(no token)      401   401   401   401   401   401
demo-ana        200   200   200!  404   201   403
demo-ana-app    200   200   200!  404   403   403
demo-bruno      200   200!  200   404   201   403
demo-carla      200   200   200   404   403   403
demo-dora       200   200   200   404   403   200
demo-eva        403   403   403   403   403   403

demo-ana: GET /orders/3 answered 200, expected 404
demo-ana-app: GET /orders/3 answered 200, expected 404
demo-bruno: GET /orders/1 answered 200, expected 404
42 checks, 3 wrong
exit 1
```

Três células mudaram, cada uma marcada com `!`, e as linhas embaixo da tabela dizem quem viu o que
não devia: a Ana e o aplicativo dela leram o pedido 3 do Bruno, e o Bruno leu o pedido 1 da Ana. O
status de saída é 1. **Cada uma dessas requisições respondeu 200 com um pedido bem formado**, e é por
isso que nenhum teste da funcionalidade teria notado.

Pare o `broken.py` e inicie o `orders.py` de novo antes de seguir; o `broken.py` pode ser apagado.
