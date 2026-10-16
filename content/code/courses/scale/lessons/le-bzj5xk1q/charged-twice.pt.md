---
title: Cobrado duas vezes
version: 1
---

Uma nova tentativa depois de um timeout manda o mesmo pedido de novo, e o timeout não disse nada
sobre se o primeiro fez o seu trabalho. A aula 9 mediu isso: a bilheteria desistiu em um segundo e o
payments terminou a cobrança em 5,6. Uma cobrança não é **idempotente**: fazê-la duas vezes não é o
mesmo que fazê-la uma.

Deixe o payments lento, de 600 a 1200 ms por cobrança, para que cerca de um terço das cobranças
passe do timeout de um segundo da bilheteria. Depois desligue as chaves de idempotência, venda por
dez segundos, e pergunte ao payments quantas cobranças ele fez:

```
ana@lab:~/tickets$ PAYMENTS_DELAY_MS=600 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ IDEMPOTENCY_KEYS=off docker compose up -d app
 Container tickets-replica-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-1 Recreate 
 Container tickets-app-1 Recreated 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
 Container tickets-app-1 Starting 
 Container tickets-app-1 Started 
ana@lab:~/tickets$ python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 10
requests  35 in 11.6 s = 3.0 per second
latency   p50 885.4 ms  p95 2871.1 ms  p99 3545.2 ms  max 3545.2 ms
status    201: 34  502: 1
ana@lab:~/tickets$ curl -s localhost:8001/charges; echo
{"charged": 48}
```

**34 ingressos vendidos, 48 cobranças.** Catorze cobranças foram de vendas que já tinham sido
cobradas: a bilheteria estourou o timeout, tentou de novo, e o payments, sem como saber que o segundo
pedido era o primeiro de novo, cobrou o cartão de novo. Uma venda falhou depois de três timeouts, e
muito provavelmente foi cobrada assim mesmo. Cada um desses compradores veria duas ou três cobranças
na fatura por um ingresso, e nada nos registros da própria bilheteria diria isso: ela registrou
algumas novas tentativas, e vendeu 34 ingressos.

As novas tentativas não eram o defeito. Sem elas esta execução teria falhado um terço das vendas; com
elas vendeu quase todas. **O defeito é tentar de novo uma operação que não é segura de repetir**, e a
correção é torná-la segura.
