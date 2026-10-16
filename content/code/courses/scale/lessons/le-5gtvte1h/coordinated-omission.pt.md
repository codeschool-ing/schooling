---
title: Omissão coordenada
version: 1
---

A diferença entre os dois modelos fica mais nítida quando o sistema para. O `docker compose pause`
congela um contêiner onde ele está: todo processo dentro para, as conexões ficam abertas, nada é
respondido. Pause a bilheteria por dois segundos no meio de uma execução, primeiro com o `load.py` e
quatro trabalhadores, depois com o k6 a cinquenta por segundo. A pausa começa em segundo plano, cinco
segundos depois:

```
ana@lab:~/tickets$ export BUYER_RATE=100000 BUYER_BURST=100000
ana@lab:~/tickets$ docker compose up -d app
 Container tickets-db-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-replica-1 Running 
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
ana@lab:~/tickets$ (sleep 5; docker compose pause app; sleep 2; docker compose unpause app) >/dev/null 2>&1 & python3 load.py -m POST 'http://localhost:8080/events/{event}/tickets' --events 50 -c 4 -d 15; wait
requests  1342 in 15.0 s = 89.3 per second
latency   p50 38.2 ms  p95 48.0 ms  p99 59.4 ms  max 2148.4 ms
status    201: 1342
ana@lab:~/tickets$ (sleep 5; docker compose pause app; sleep 2; docker compose unpause app) >/dev/null 2>&1 & docker run --rm -i --network host grafana/k6:2.3.0 run -q --log-output=none -e DURATION=15s - < sale.js; wait
asked     50 a second for 15s
answered  745 = 49.6 a second
latency   p50 41.5 ms  p95 1871.5 ms  p99 2146.7 ms  max 2196.9 ms
sold 745  refused 0  failed 0  never sent 5
```

O mesmo congelamento de dois segundos, medido duas vezes:

| | load.py, fechado | k6, aberto |
|---|---|---|
| percentil 95 | 48 ms | 1872 ms |
| percentil 99 | 59 ms | 2147 ms |
| máximo | 2148 ms | 2197 ms |

**O `load.py` diz que o congelamento quase não aconteceu.** Cada um dos seus quatro trabalhadores
tinha um pedido em andamento quando a bilheteria congelou; esses quatro levaram dois segundos, e
depois os trabalhadores seguiram. Quatro respostas lentas em 1342 não chegam ao percentil 99. **O k6
diz que mais de uma venda em vinte levou quase dois segundos**, porque durante o congelamento chegaram
cem compradores, a cinquenta por segundo, e todos eles esperaram.

A segunda resposta é a verdadeira. Um comprador que chegou durante aqueles dois segundos esperou, e o
teste fechado nem mandou esse comprador: os trabalhadores dele também estavam presos esperando, então
os pedidos que seriam lentos nunca foram feitos, nem medidos. Isso se chama **omissão coordenada**
(*coordinated omission*), um nome de Gil Tene: o gerador de carga se coordena com o sistema que está
medindo e omite exatamente as amostras que importam. Toda ferramenta de ciclo fechado tem isso, e
também os números de latência de um cliente que tenta de novo ou enfileira do próprio lado.

Há duas saídas. Usar um modelo aberto, como o k6 faz aqui. Ou, numa ferramenta fechada, medir cada
pedido a partir do momento em que ele **deveria** ter sido mandado, numa agenda fixa, e não a partir
do momento em que foi. De um jeito ou de outro, a pergunta a fazer a qualquer número de latência é:
*os pedidos foram mandados quando os usuários os teriam mandado?*
