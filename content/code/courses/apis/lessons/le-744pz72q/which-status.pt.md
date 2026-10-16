---
title: 401, 403 ou 404
version: 1
---

**401 quer dizer "não sei quem você é", 403 quer dizer "sei, e não", e 404 quer dizer "não há nada
aqui para você".** Os dois primeiros saem das duas perguntas da primeira seção. A escolha que pede
reflexão é entre 403 e 404.

| status | a pergunta que falhou | no `orders.py` |
|---|---|---|
| 401 Unauthorized | quem está pedindo? | sem token, ou com um nunca emitido; sempre com `WWW-Authenticate` |
| 403 Forbidden | quem chamou pode usar esta função, aqui e agora? | uma permissão que falta no papel ou no token, ou uma política |
| 404 Not Found | existe essa coisa, para quem chamou? | endereço que não existe, pedido que não existe, ou pedido de outra pessoa |

O nome *Unauthorized* é um acidente histórico, e o 401 é sobre autenticação. Um cliente que recebe
um 401 deve conseguir um token, ou um novo. Um cliente que recebe um 403 não deve se dar ao
trabalho, porque um token novo para a mesma pessoa é recusado do mesmo jeito.

## Por que o pedido de outra pessoa é um 404

A Ana pede o pedido 3, que é do Bruno, e o pedido 99, que não existe:

```
ana@api:~/shelf$ curl -si -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 24

{"error": "no order 3"}
ana@api:~/shelf$ curl -si -H 'Authorization: Bearer demo-ana' localhost:8000/orders/99
HTTP/1.1 404 Not Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 25

{"error": "no order 99"}
```

As duas respostas têm o mesmo status e o mesmo corpo, tirando o número, que é também o motivo de o
`Content-Length` diferir em um. **Um
403 para o pedido 3 diria à Ana que o pedido 3 existe.** Com ids consecutivos, um estranho que
recebesse 403 para todo número até 1240 e 404 depois disso saberia quantos pedidos a loja já
recebeu. Conferir de novo toda semana diria a ele as vendas dela. Um 404 não diz nada que
ele já não tenha mandado.

Então a regra prática é:

- um objeto que quem chamou não pode ver responde 404, exatamente como um objeto que não existe;
- uma função que quem chamou não pode usar responde 403, porque a função já está na documentação, e
  a recusa é algo sobre o qual quem chamou pode agir.

A API do GitHub funciona assim, e diz isso na documentação: um repositório privado responde 404, e
não 403, a quem não pode vê-lo. O preço é pago no suporte. Um cliente logado na conta errada ouve que
o pedido não existe, e alguém tem que explicar. Para objetos, vale pagar.
