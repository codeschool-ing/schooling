---
title: Chaves de idempotência
version: 1
---

**Um cliente cujo POST ficou sem resposta não sabe se deu certo.** A requisição pode ter se perdido
na ida, ou o livro pode ter sido criado e a resposta se perdido na volta; do lado do cliente as duas
coisas parecem iguais, um tempo esgotado. Tentar de novo arrisca criar o livro duas vezes, e não
tentar arrisca nunca criá-lo. Um cabeçalho `Idempotency-Key` desfaz o dilema: o cliente dá nome à
operação, e o servidor reconhece uma nova tentativa dela e responde com o que respondeu da primeira
vez.

A aula 1 mostrou por que o POST é o método com esse problema: PUT e DELETE dizem qual é o estado
final, então enviá-los duas vezes não muda nada, enquanto o POST diz "crie mais um". A resposta comum
é contar com algo único nos dados. Para livros isso funciona pela metade, porque o ISBN é único. Um
cliente que repete a criação do livro 8, mais abaixo, sem chave, recebe:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
{"type": "https://shelf.example/problems/duplicate-isbn", "title": "ISBN already in the catalogue", "status": 409, "detail": "another book has ISBN 9786500000085", "instance": "/v1/books"}
409
```

Isso impede a duplicata e deixa o cliente com a pergunta errada respondida. Um 409 diz que existe um
livro com esse ISBN; não diz se foi a primeira tentativa deste cliente que o criou ou outra pessoa, e
um pedido, um pagamento ou uma mensagem em geral não têm campo único nenhum em que se apoiar.

## A chave

O cliente inventa uma chave, única para esta operação: um UUID aleatório é a escolha comum, e o Linux
entrega um novo a cada leitura de um arquivo em `/proc`:

```
ana@api:~/shelf$ cat /proc/sys/kernel/random/uuid
b1a0b623-b2c3-4be8-a499-0dfce682ffe7
```

Ele envia a chave na primeira tentativa e **a mesma chave em toda nova tentativa dessa operação**, e
uma chave nova para a operação seguinte. Esta aula digita uma chave fixa, `3f1c9a2e-alienista`, para
que as três requisições que a usam possam ser repetidas exatamente. A primeira cria o livro:

```
ana@api:~/shelf$ curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:43 GMT
Content-Type: application/json
Content-Length: 172
Location: /v1/books/8

{"id": 8, "isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}, "stock": 0, "in_stock": false}
```

A segunda é a nova tentativa, idêntica. Nada novo é criado, e a resposta é a guardada, com o mesmo
`Location`, mais um cabeçalho dizendo que é uma repetição:

```
ana@api:~/shelf$ curl -si -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}}'
HTTP/1.1 201 Created
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:29:43 GMT
Content-Type: application/json
Content-Length: 172
Location: /v1/books/8
Idempotent-Replayed: true

{"id": 8, "isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 2990, "currency": "BRL"}, "stock": 0, "in_stock": false}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Uma sequência entre o cliente, o catalogue.py e o banco de dados. O cliente envia POST com Idempotency-Key 3f1c9a2e-alienista. Numa transação, o servidor insere o livro 8 e guarda a chave com a resposta, e o 201 se perde na volta. O cliente estoura o tempo e envia a mesma requisição com a mesma chave. O servidor encontra a chave com a mesma impressão digital, não insere nada, e repete o 201 com Location /v1/books/8 e Idempotent-Replayed true. Uma terceira requisição com a mesma chave e outro preço é recusada com 422.\"><defs><marker id=\"l02-ik-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"10\" width=\"120\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cliente</text><line x1=\"90\" y1=\"40\" x2=\"90\" y2=\"350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"320\" y=\"10\" width=\"120\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">catalogue.py</text><line x1=\"380\" y1=\"40\" x2=\"380\" y2=\"350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><rect x=\"570\" y=\"10\" width=\"120\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shelf.db</text><line x1=\"630\" y1=\"40\" x2=\"630\" y2=\"350\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line><line x1=\"90\" y1=\"70\" x2=\"376\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"233.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">POST  Idempotency-Key: 3f1c9a2e-alienista</text><line x1=\"380\" y1=\"98\" x2=\"626\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"503.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">uma transação: livro 8 + chave + resposta</text><line x1=\"380\" y1=\"130\" x2=\"240\" y2=\"130\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"310.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">201  Location: /v1/books/8</text><line x1=\"214\" y1=\"124\" x2=\"226\" y2=\"136\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><line x1=\"214\" y1=\"136\" x2=\"226\" y2=\"124\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"96\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">sem resposta: tempo esgotado</text><line x1=\"90\" y1=\"194\" x2=\"376\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"233.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">o mesmo POST, a mesma chave</text><line x1=\"380\" y1=\"222\" x2=\"626\" y2=\"222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"503.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">chave conhecida, mesma impressão</text><text x=\"636\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada inserido</text><line x1=\"380\" y1=\"254\" x2=\"94\" y2=\"254\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"237.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">201  Location: /v1/books/8</text><text x=\"235.0\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Idempotent-Replayed: true</text><line x1=\"90\" y1=\"306\" x2=\"376\" y2=\"306\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"233.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">a mesma chave, outro preço</text><line x1=\"380\" y1=\"334\" x2=\"94\" y2=\"334\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l02-ik-ah)\"></line><text x=\"237.0\" y=\"326.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">422  chave reutilizada</text></svg>", "caption": "A chave transforma uma nova tentativa numa pergunta que o servidor sabe responder: esta operação já aconteceu? Se já, o cliente recebe a resposta que perdeu."}
```

O servidor guarda cada chave com uma impressão digital do corpo que veio com ela. A mesma chave com
outro corpo é um bug do cliente, a chave reaproveitada para outra coisa, e é recusada em vez de
adivinhada:

```
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -X POST localhost:8000/v1/books -H 'Content-Type: application/json' -H 'Idempotency-Key: 3f1c9a2e-alienista' -d '{"isbn": "9786500000085", "title": "O Alienista", "author_id": 1, "year": 1882, "price": {"amount_cents": 3290, "currency": "BRL"}}'
{"type": "https://shelf.example/problems/key-reused", "title": "Idempotency-Key reused", "status": 422, "detail": "this key came with a different book; use a new key", "instance": "/v1/books"}
422
```

## As regras, por escrito

O cabeçalho está sendo padronizado pelo IETF, num rascunho chamado *The Idempotency-Key HTTP Header
Field*, que dá um código de status a cada caso. O `catalogue.py` o segue:

| a requisição | a resposta |
|---|---|
| uma chave nova | tratada normalmente; se der certo, a chave, a impressão digital e a resposta são guardadas |
| uma chave conhecida, o mesmo corpo | a resposta guardada, de novo: 201 e o mesmo `Location`, com `Idempotent-Replayed: true` |
| uma chave conhecida, outro corpo | **422**, e nada é feito |
| uma chave conhecida cuja primeira requisição ainda está rodando | **409**; tente de novo daqui a pouco |
| sem chave | um POST comum, sem proteção contra nova tentativa |

O `catalogue.py` nunca envia esse 409, porque trata uma chave dentro de uma única transação do banco.
**A conferência da chave, o livro novo e a resposta guardada são gravados juntos ou não são
gravados.** A transação pega o lock de escrita do SQLite antes de ler a chave, então uma segunda
requisição com a mesma chave espera a primeira terminar e então a encontra. Um servidor que
guardasse a chave num lugar e o livro em outro precisaria do 409, e precisaria limpar a bagunça
depois de uma queda entre os dois.

O que fica guardado está à vista, e leva um timestamp em RFC 3339 com deslocamento, como a seção
sobre nomes pede:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT key, location, created_at FROM idempotency_keys'
3f1c9a2e-alienista|/v1/books/8|2026-10-10T04:29:43+00:00
```

Duas coisas que uma API de produção acrescenta. **Chaves expiram**: a API do Stripe, que popularizou
este cabeçalho, só remove uma chave depois que ela tem pelo menos 24 horas, tempo suficiente para
qualquer nova tentativa razoável; o `catalogue.py` as guarda para sempre. E **uma chave pertence a
um cliente**: dois clientes podem muito bem escolher a mesma string, então a chave é guardada junto
com quem a enviou, e para isso é preciso saber quem está pedindo, o assunto da aula 7.
