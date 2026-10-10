---
title: De quem é o objeto?
version: 1
---

**A falha de autorização mais comum em APIs é um objeto entregue a alguém a quem ele não pertence.**
A OWASP, o projeto aberto que publica listas das falhas de segurança web mais frequentes, põe essa
em primeiro lugar no seu API Security Top 10 de 2023, como **API1:2023 Broken Object Level
Authorization**, ou BOLA. A aula 13 volta à lista; esta é a primeira entrada dela.

O formato é sempre o mesmo. O endereço leva um id, `/orders/3`, e o handler lê a linha 3 porque o
endereço pediu. Quem chamou tem um token válido, tem `orders:read`, e a rota deixa entrar. Todas as
checagens do dispatcher passaram, e nenhuma perguntou de quem é o pedido 3.

No `orders.py` essa pergunta é o `find`. O Bruno fez o pedido 3, então ele lê. A Ana pede o mesmo
endereço e ouve que esse pedido não existe:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3
{"id": 3, "customer": "bruno", "book_id": 6, "quantity": 1, "total_cents": 6490, "status": "placed", "placed_on": "2026-10-09"}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3
{"error": "no order 3"}
404
```

Escrever passa pela mesma função, porque `cancel_order` busca o pedido antes de mexer nele. O Bruno
não consegue cancelar o pedido 1 da Ana, e a Ana consegue, uma vez:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/1/cancel
{"error": "no order 1"}
404
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' localhost:8000/orders/1/cancel
{"id": 1, "customer": "ana", "book_id": 1, "quantity": 1, "total_cents": 3990, "status": "cancelled", "placed_on": "2026-10-08"}
200
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' localhost:8000/orders/1/cancel
{"error": "order 1 is cancelled; only a placed order can be cancelled"}
409
```

O segundo cancelamento é um 409, porque um pedido cancelado não pode ser cancelado de novo. Essa é
uma regra sobre o estado do pedido, não sobre quem pode pedir, e 409 é o código que a aula 1 deu a
uma requisição que entra em conflito com o que já existe.

## Como é uma checagem que falta

A falha tem a cara deste handler, que está certo em tudo menos numa coisa:

```python
def get_order(self, me, perms, ident):
    with db.connect() as conn:
        order = conn.execute("SELECT * FROM orders WHERE id = ?", (ident,)).fetchone()
    if order is None:
        return self.error(404, f"no order {ident}")
    self.reply(200, show(order, perms))
```

O `me` chega como argumento e nunca é usado. Nada falha, todo teste escrito por alguém pensando nos
próprios pedidos passa, e como os ids são consecutivos, os pedidos de todos os outros clientes estão
a um número de distância. **Um handler que lê por id e nunca usa quem chamou é o que procurar numa
revisão.**

Três hábitos tornam essa falha difícil de escrever:

- buscar objetos por uma função que recebe quem chamou, como o `find`, para que um handler não
  consiga pegar um pedido sem dizer quem quer;
- filtrar na consulta ao listar: o `list_orders` põe `WHERE customer = ?` no SQL, então as linhas de
  outra pessoa nunca são lidas, em vez de lidas e depois descartadas;
- testar com pelo menos duas pessoas, porque um teste que só entra como uma não enxerga isso.
  "Testando a matriz" constrói esse teste.

Ids aleatórios, um UUID no lugar de 3, deixam os vizinhos mais difíceis de adivinhar, e vale a pena
ter. Eles não são a checagem. Um id vai parar em logs, links e capturas de tela, e quando alguém o
tem, a checagem de dono é a única coisa entre essa pessoa e o pedido.
