---
title: O Redis e o payments
version: 1
---

O Redis parado, e uma venda:

```
ana@lab:~/tickets$ docker compose stop redis
 Container tickets-redis-1 Stopping 
 Container tickets-redis-1 Stopped 
ana@lab:~/tickets$ curl -s -X POST -H 'X-Buyer: fan-1' localhost:8080/events/1/tickets; echo
{"event": 1, "seat": 1, "code": "cb5ad8d5b5fd9bea"}
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep 'rate limit unavailable' | tail -1
{"time": "2026-10-10T19:40:01.465+00:00", "level": "warning", "message": "rate limit unavailable", "host": "615b3114daa0", "error": "Error -2 connecting to redis:6379. Name or service not known.", "trace_id": "d98603fe45bb6c8e1e5c740c50987fcf"}
ana@lab:~/tickets$ docker compose start redis
 Container tickets-redis-1 Starting 
 Container tickets-redis-1 Started 
```

**A venda passou**, e o log registrou que o limite de taxa não pôde ser verificado. Enquanto o Redis
estiver fora, um robô consegue comprar mais rápido que duas por segundo, e a decisão tomada na aula 9
é que isso é melhor do que ninguém comprar.

Depois o payments parado, seis vendas, e uma leitura:

```
ana@lab:~/tickets$ docker compose stop payments
 Container tickets-payments-1 Stopping 
 Container tickets-payments-1 Stopped 
ana@lab:~/tickets$ for i in $(seq 6); do curl -s -w ' %{http_code}\n' -X POST -H "X-Buyer: fan-$i" localhost:8080/events/1/tickets; done
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payment failed"} 502
{"error": "payments unavailable"} 503
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' localhost:8080/events/1
{"name": "Show 1", "left": 999999, "host": "615b3114daa0", "source": "replica"} 200 in 0.002483 s
ana@lab:~/tickets$ docker compose start payments
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
```

Cinco vendas falharam com `502` depois das suas três tentativas cada, então **o disjuntor abriu** e a
sexta foi recusada na hora. **A leitura levou 2,5 ms**, como se nada tivesse acontecido, porque nada
de que ela precisa tinha acontecido. Uma bilheteria sem payments é uma bilheteria que ainda mostra
todo show e toda contagem de lugares, que é a maior parte do que os visitantes estão fazendo a cada
momento.

O que o comprador deve ver na venda é uma decisão de produto, mais que técnica. *Os pagamentos não
estão funcionando agora, tente de novo em alguns minutos* é honesto. Segurar o lugar por dez minutos
e cobrar quando o payments voltar é mais gentil, e é outro sistema: uma reserva com prazo, uma fila de
cobranças, e um jeito de avisar o comprador depois se deu certo.
