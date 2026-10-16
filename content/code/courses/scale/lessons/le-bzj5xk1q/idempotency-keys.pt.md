---
title: Chaves de idempotência
version: 1
---

A correção é dar um nome a cada operação. A bilheteria cria uma **chave de idempotência** aleatória
para cada venda, uma vez, antes da primeira tentativa, e a manda com toda tentativa num cabeçalho
`Idempotency-Key`. O payments lembra as chaves que viu e a resposta que cada uma teve. Um pedido com
uma chave nova é cobrado; um pedido com uma chave conhecida recebe a resposta guardada, e nada é
cobrado de novo. As APIs públicas dos provedores de pagamento, a da Stripe entre elas, funcionam
exatamente assim.

A mesma execução, com as chaves ligadas, depois de reiniciar o payments para esvaziar a memória e a
contagem dele:

```
ana@lab:~/tickets$ docker compose restart payments
 Container tickets-payments-1 Restarting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-db-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 10
requests  45 in 10.8 s = 4.2 per second
latency   p50 894.0 ms  p95 1211.5 ms  p99 1218.5 ms  max 1218.5 ms
status    201: 45
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 45}
```

**45 ingressos vendidos, 45 cobranças.** Os timeouts e as novas tentativas aconteceram como antes; o
que mudou é que cada nova tentativa foi respondida com o resultado da primeira.

## Os detalhes que a fazem funcionar

- **A chave pertence à operação, não ao pedido.** Criada uma vez por venda, antes do laço. Uma chave
  criada por tentativa seria um nome diferente a cada nova tentativa, e as duplicatas voltariam.
- **Uma chave ainda em andamento é esperada.** Uma nova tentativa muitas vezes chega enquanto a
  primeira ainda está sendo cobrada, que é exatamente o caso do timeout. O payments faz a nova
  tentativa esperar a primeira e responde com o resultado dela. Alguns serviços respondem
  `409 Conflict` em vez disso e deixam quem chama tentar mais tarde; o que eles não podem é começar
  uma segunda cobrança.
- **Lembrada por tempo suficiente, num lugar durável.** Este payments guarda as chaves na memória, e
  é por isso que um reinício o esvazia. Um de verdade as guarda no banco, muitas vezes por 24 horas,
  escritas na mesma transação que a cobrança, para que uma queda entre cobrar e lembrar não possa
  acontecer.
- **A mesma chave com um pedido diferente é um erro.** Se uma chave chega com outro valor, um serviço
  cuidadoso a recusa em vez de responder com a cobrança de outra coisa.

Algumas operações não precisam de chave porque são idempotentes por natureza: marcar o estado de um
assento como *reservado*, apagar uma reserva, `PUT` e `DELETE` como o HTTP os define. Desenhar uma
operação desse jeito, *definir* em vez de *somar*, muitas vezes é mais simples que lembrar chaves, e
vale perguntar isso primeiro.
