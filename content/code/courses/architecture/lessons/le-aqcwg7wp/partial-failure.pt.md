---
title: Quando metade do sistema está fora do ar
version: 1
---

Um monólito está de pé ou caído. Um sistema de serviços tem um terceiro estado, e ele é o normal em
escala: **alguns serviços de pé, alguns caídos, alguns lentos**. Lamport disse isso numa frase em
1987: um sistema distribuído é aquele em que a falha de um computador que você nem sabia que existia
pode deixar o seu próprio computador inutilizável.

Pare o serviço de estoque e peça o catálogo:

```
ana@vm:~/lab/split$ docker compose stop stock
 Container split-stock-1 Stopping 
 Container split-stock-1 Stopped 
ana@vm:~/lab/split$ curl -s -i -w "took %{time_total}s\n" localhost:8000/products
HTTP/1.0 503 Service Unavailable
Server: BaseHTTP/0.6 Python/3.12.15
Date: Sat, 10 Oct 2026 04:24:04 GMT
Content-Type: application/json
Content-Length: 31
X-Request-Id: 29547aa9

{"error": "stock unavailable"}
took 0.004912s
```

A loja está rodando e responde em poucos milissegundos, com `503 Service Unavailable` e um corpo que
diz por quê. É uma falha decente: rápida, explícita, e a loja em si continua de pé. Ela é decente
porque `stock_call` falhou rápido. Com o contêiner parado, o nome `stock` deixa de resolver, e o erro
é imediato. Um serviço de estoque rodando mas travado teria segurado cada requisição do catálogo pelos
dois segundos inteiros do timeout, e sem timeout, para sempre. A aula 11 trata desse caso, e a aula 12
de impedir que uma dependência lenta prenda tudo o que a chama.

Inicie de novo antes de continuar:

```
ana@vm:~/lab/split$ docker compose start stock
 Container split-stock-1 Starting 
 Container split-stock-1 Started 
```

## O pedido feito pela metade

A falha pior é a que devolve uma resposta. No monólito, um cartão recusado desfazia o pedido e o
estoque juntos, numa transação. Aqui o estoque foi baixado por outro programa e confirmado em outro
banco antes de o cartão ser tentado. Observe o café:

```
ana@vm:~/lab/split$ curl -s localhost:8000/products | grep coffee
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 12},
ana@vm:~/lab/split$ curl -s -X POST localhost:8000/orders -d '{"sku": "coffee", "qty": 1, "card": "4000000000000002"}'
{"error": "card declined"}
ana@vm:~/lab/split$ curl -s localhost:8000/products | grep coffee
{"sku": "coffee", "name": "Coffee beans, 500 g", "price_cents": 3290, "units": 11},
```

O cartão foi recusado e o cliente recebeu um `402`. Não existe pedido, não existe pagamento, e **um
pacote de café saiu do estoque mesmo assim**: a contagem foi de 12 para 11. Nada falhou de forma
barulhenta. Cada serviço fez exatamente o que mandaram, e juntos perderam uma unidade.

Isso não é um bug da divisão que uma linha mais cuidadosa resolveria. `with con:` só consegue desfazer
o banco ao qual pertence, e o estoque está em outro. Há três saídas, e o resto do curso trata de cada
uma:

| abordagem | onde está |
| --- | --- |
| desfazer a baixa com uma segunda chamada, uma **compensação**, quando o pagamento falha | aula 14, a saga |
| reservar as unidades primeiro e confirmá-las só depois do pagamento, para uma falha só liberar uma reserva | também na aula 14, como trava semântica |
| pôr estoque e pagamento de volta num serviço, porque precisam concordar no mesmo instante | a terceira pergunta da seção sobre fronteiras |

**A terceira é uma resposta legítima.** Se o negócio não tolera essa janela de jeito nenhum, a
fronteira está no lugar errado, e trazê-la de volta é mais barato do que construir o maquinário para
conviver com ela.
