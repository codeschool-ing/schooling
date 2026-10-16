---
title: Quatro mudanças, ou nenhuma
version: 1
---

Fazer um pedido muda três tabelas: grava o pedido, tira as unidades do estoque e registra o
pagamento. Se o pagamento for recusado depois de o estoque ter sido baixado, a loja tem um
problema: unidades que ninguém comprou sumiram da prateleira. **Num monólito com um banco, a
resposta é uma transação, e custa uma linha.**

`orders_place` roda tudo dentro de `with con:`. O SQLite abre uma transação na primeira escrita e,
quando o bloco termina, ou confirma tudo, ou, se qualquer coisa levantou uma exceção, desfaz tudo.
Então um cartão recusado não deixa rastro. Tente um terminado em `0002`, que a operadora de mentira
recusa:

```
ana@vm:~/lab/monolith$ curl -s -i -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 1, "card": "4000000000000002"}'
HTTP/1.0 402 Payment Required
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:10:24 GMT
Content-Type: application/json
Content-Length: 27

{"error": "card declined"}
ana@vm:~/lab/monolith$ curl -s localhost:8000/products | grep coffee
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 10},
ana@vm:~/lab/monolith$ curl -s localhost:8000/orders
[
{"id": 1, "sku": "coffee", "qty": 2, "total_cents": 6580}
]
```

A resposta é `402 Payment Required`. O pedido foi inserido e o café foi baixado antes de a cobrança
falhar, e nada disso aconteceu para quem olha: o café continua com as `10` unidades que o primeiro
pedido deixou, e a lista de pedidos continua só com o pedido 1.

O mesmo mecanismo cobre a outra falha. Pedir mais café do que existe faz o `CHECK (units >= 0)` da
tabela de estoque recusar a atualização, a exceção desfaz a linha do pedido gravada um instante
antes, e a loja responde `409 Conflict`:

```
ana@vm:~/lab/monolith$ curl -s -i -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 50, "card": "4111111111111111"}'
HTTP/1.0 409 Conflict
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:10:24 GMT
Content-Type: application/json
Content-Length: 30

{"error": "not enough stock"}
ana@vm:~/lab/monolith$ curl -s localhost:8000/orders
[
{"id": 1, "sku": "coffee", "qty": 2, "total_cents": 6580}
]
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um contêiner com um processo. Dentro dele, quatro módulos: catálogo, estoque, pagamentos e pedidos. Pedidos chama os outros três como chamadas de função comuns. Abaixo, um banco SQLite com quatro tabelas. Uma fronteira tracejada marca a transação única que envolve fazer um pedido.\"><defs><marker id=\"l1-process-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"280\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">contêiner: shop</text><rect x=\"30\" y=\"44\" width=\"660\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"46\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">um processo Python</text><rect x=\"60\" y=\"92\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">catálogo</text><rect x=\"210\" y=\"92\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">estoque</text><rect x=\"360\" y=\"92\" width=\"120\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pagamentos</text><rect x=\"530\" y=\"92\" width=\"140\" height=\"48\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">pedidos</text><path d=\"M528 108 L482 108\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l1-process-ah-amber)\"></path><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chama os outros três</text><rect x=\"30\" y=\"186\" width=\"660\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"46\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma transação: BEGIN … COMMIT, ou ROLLBACK de tudo</text><rect x=\"60\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">products</text><rect x=\"215\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stock</text><rect x=\"370\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"435\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><rect x=\"525\" y=\"222\" width=\"130\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">payments</text></svg>", "caption": "Um processo, um banco, e uma transação que alcança todas as tabelas. Essa última propriedade é a que uma divisão tira."}
```

**Essa é a propriedade que uma divisão tira.** No dia em que estoque e pagamentos morarem em dois
serviços com dois bancos, não existe `with con:` que alcance os dois. O pedido, o estoque e o
pagamento viram três mudanças em três lugares, cada uma podendo dar certo enquanto outra falha, e a
loja precisa de outro mecanismo para acertar as coisas depois. A aula 14 é esse mecanismo, a saga, e
ele é bem mais longo do que uma linha.

A lição para guardar agora é mais estreita. **Atomicidade sobre todos os dados é algo que um monólito
ganha de graça**, e vale pôr na lista de motivos para mantê-lo, porque é a primeira coisa de que as
pessoas sentem falta depois de dividir.
