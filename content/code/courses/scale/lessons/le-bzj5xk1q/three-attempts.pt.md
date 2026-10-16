---
title: Três tentativas
version: 1
---

Faça o payments falhar uma chamada em dez, na hora e sem cobrar, como um serviço de pagamento faz
quando está descartando carga. Primeiro com uma única tentativa, depois com o padrão de três. O
`load.py` é um único comprador anônimo, então o limite por comprador da aula 9 fica levantado a aula
inteira:

```
ana@lab:~/tickets$ export BUYER_RATE=1000 BUYER_BURST=1000
ana@lab:~/tickets$ PAYMENTS_FAIL_PERCENT=10 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ CHARGE_ATTEMPTS=1 docker compose up -d app
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
requests  972 in 10.0 s = 96.8 per second
latency   p50 43.6 ms  p95 55.4 ms  p99 62.7 ms  max 102.5 ms
status    201: 886  502: 86
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Healthy 
 Container tickets-db-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 10
requests  719 in 10.2 s = 70.7 per second
latency   p50 45.9 ms  p95 147.4 ms  p99 243.5 ms  max 483.6 ms
status    201: 719
```

Com uma tentativa, **86 vendas de 972 falharam**, cerca de uma em dez, como pedido. Com três
tentativas, **nenhuma de 719 falhou**. Se cada tentativa falha de forma independente uma vez em dez,
uma venda só falha quando as três falham, e 0,1³ é uma em mil: cerca de uma venda esperada em 719, e
esta execução não teve nenhuma.

O preço está nos outros números da segunda execução. A venda mediana quase não mudou, mas o
percentil 95 foi de 55 para 147 ms e o 99 de 63 para 244 ms: as vendas que precisaram de uma segunda
ou terceira tentativa pagaram as esperas no meio. A taxa caiu também, de 97 para 71 vendas por
segundo, porque os quatro trabalhadores do `load.py` passaram parte do tempo esperando essas vendas.
**Novas tentativas trocam latência na cauda por sucessos**, e essa costuma ser a troca certa numa
compra, em que um comprador prefere um ingresso mais lento a um erro.

Note também o que não aconteceu: o disjuntor da aula 9 nunca abriu. Ele conta as falhas de uma venda
inteira, depois das novas tentativas, então um serviço de pagamento que falha uma chamada em dez
parece saudável para ele, e está.
