---
title: Propriedades que quem chama pode ler e escrever
version: 1
---

**Entre "pode ver este pedido" e "pode ver tudo deste pedido" existe uma terceira pergunta: quais
campos.** O **API3:2023 Broken Object Property Level Authorization** da OWASP junta duas entradas
mais antigas que são o mesmo erro em direções opostas. Enviar uma propriedade que quem chama não
deveria ler se chamava *excessive data exposure*, exposição excessiva de dados, e aceitar uma
propriedade que quem chama não deveria escrever se chamava *mass assignment*, atribuição em massa.

## Escrita: atribuição em massa

O handler tentador pega o corpo JSON e grava o que quer que ele nomeie. É curto e genérico, e deixa
um cliente mandar isto:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST -H 'Authorization: Bearer demo-ana' -H 'Content-Type: application/json' -d '{"book_id": 1, "quantity": 2, "status": "shipped", "total_cents": 1}' localhost:8000/orders
{"error": "fields you may not set: status, total_cents"}
422
```

O `orders.py` recusa, porque `create_order` aceita `book_id` e `quantity` e nada mais. Um cliente
escolhe um livro e quantos exemplares. O preço, o status, o cliente e a data são fatos que o servidor
conhece melhor, e ele mesmo os define:

```
ana@api:~/shelf$ curl -si -X POST -H 'Authorization: Bearer demo-ana' -H 'Content-Type: application/json' -d '{"book_id": 1, "quantity": 2}' localhost:8000/orders
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:27:57 GMT
Content-Type: application/json
Content-Length: 126
Location: /orders/5

{"id": 5, "customer": "ana", "book_id": 1, "quantity": 2, "total_cents": 7980, "status": "placed", "placed_on": "2026-10-10"}
```

O total é 7980, dois exemplares a 3990, calculado da tabela `books` em vez de acreditado no corpo.
**Os campos que quem chama pode escrever são uma lista de permitidos no handler, e um campo fora dela
é recusado, não descartado em silêncio.** Descartar também manteria o status seguro, e deixaria o
cliente acreditando que definiu algo que não definiu. O 422 é o código da lição 1 para conteúdo que
quebra uma regra, e a mensagem nomeia os campos, então o erro pode ser achado e corrigido. O
`rest.py` já fazia o mesmo com livros: a tabela `FIELDS` dele é o motivo de o PATCH com `colour` da
lição 1 ter sido um 422.

## Leitura: o que a representação deixa de fora

Todo pedido tem uma `note` só para os olhos da loja, e a do pedido 3 diz que o Bruno ligou com um
endereço novo. A Ana não vê o pedido, o Bruno vê sem a nota, e a Carla vê com a nota:

```
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-ana' localhost:8000/orders/3
{"error": "no order 3"}
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-bruno' localhost:8000/orders/3
{"id": 3, "customer": "bruno", "book_id": 6, "quantity": 1, "total_cents": 6490, "status": "placed", "placed_on": "2026-10-09"}
ana@api:~/shelf$ curl -s -H 'Authorization: Bearer demo-carla' localhost:8000/orders/3
{"id": 3, "customer": "bruno", "book_id": 6, "quantity": 1, "total_cents": 6490, "status": "placed", "placed_on": "2026-10-09", "note": "phoned: new address"}
```

O `show` monta a resposta a partir de uma lista de campos e só acrescenta `note` para quem tem
`orders:read_all`. **A representação também é uma lista de permitidos, e nunca a linha.** Uma API
que manda `SELECT *` como JSON e confia que o cliente não vai mostrar uma parte já mandou a nota
para o navegador do cliente, onde as ferramentas de desenvolvedor mostram a nota a quem abrir. Uma
coluna acrescentada à tabela no ano que vem sai do mesmo jeito, sem ninguém ter decidido que ela
devia sair.
