---
title: Descarte de carga, todo mundo junto
version: 1
---

Um limite de taxa por comprador não faz nada contra dez mil compradores que ficam, cada um, dentro
do próprio limite. O que protege a bilheteria de todos eles juntos é um teto para **quanto trabalho
ela aceita ao mesmo tempo**, e uma recusa para o que passar dele. Isso é **descarte de carga**
(*load shedding*): quando a bilheteria está cheia, o próximo pedido é mandado embora na porta, barato,
em vez de entrar para deixar todo pedido mais lento e, como a seção 02 mostrou, quebrar o banco.

O `guards.Shed` guarda 32 vagas. Um pedido pega uma vaga livre ou é respondido com `503 Service
Unavailable` na hora, e cada vaga guarda as próprias conexões com o banco, então **as vagas limitam
as conexões também**. Os mesmos 128 trabalhadores da seção 02, com o limite por comprador aumentado
para esta execução, porque o `load.py` é um único comprador anônimo e só uma guarda está sendo medida
aqui:

```
ana@lab:~/tickets$ docker compose up -d --scale app=1
 Container tickets-collector-1 Running 
 Container tickets-app-1 Running 
 Container tickets-prometheus-1 Running 
 Container tickets-payments-1 Running 
 Container tickets-redis-1 Running 
 Container tickets-replica-1 Running 
 Container tickets-lb-1 Running 
 Container tickets-jaeger-1 Running 
 Container tickets-db-1 Running 
 Container tickets-app-2 Stopping 
 Container tickets-app-3 Stopping 
 Container tickets-app-2 Stopped 
 Container tickets-app-2 Removing 
 Container tickets-app-3 Stopped 
 Container tickets-app-3 Removing 
 Container tickets-app-2 Removed 
 Container tickets-app-3 Removed 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-db-1 Waiting 
 Container tickets-replica-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Healthy 
ana@lab:~/tickets$ docker compose restart lb
 Container tickets-lb-1 Restarting 
 Container tickets-lb-1 Started 
ana@lab:~/tickets$ BUYER_RATE=1000 BUYER_BURST=1000 docker compose up -d app
 Container tickets-redis-1 Running 
 Container tickets-db-1 Running 
 Container tickets-replica-1 Running 
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
ana@lab:~/tickets$ python3 load.py -m POST -d 10 'http://localhost:8080/events/{event}/tickets' --events 50 -c 128
requests  1123 in 11.3 s = 99.3 per second
latency   p50 918.1 ms  p95 2501.5 ms  p99 3607.2 ms  max 4164.0 ms
status    201: 1017  503: 106
ana@lab:~/tickets$ docker compose exec db psql -U tickets -tAc "SELECT count(*) FROM pg_stat_activity WHERE backend_type = 'client backend'"
33
```

Compare com a última execução da seção 02:

| | sem guarda | 32 vagas |
|---|---|---|
| vendidos | 1003 | 1017 |
| recusados | 146 × `500`, o banco sem conexões | 106 × `503`, na porta |
| conexões com o banco depois da execução | 52 | 33 |

**As falhas mudaram de tipo.** Em vez de uma venda que chegou até o banco e quebrou lá, um pedido que
nem começou, respondido com um status que quer dizer *ocupado, volte depois* e um `Retry-After`
dizendo quando. **O banco ficou dentro do limite**: 33 conexões, que são as 32 vagas e a do próprio
`psql`. E alguns ingressos a mais foram vendidos, porque nenhuma venda se perdeu numa conexão que
falhou.

**O que não mudou foi a espera**: o pedido mediano ainda levou cerca de um segundo. O descarte protege
o que está atrás da porta; ele não deixa a CPU na frente dela mais rápida. Aqui a espera é antes da
porta, em threads que ainda não ganharam a CPU para chegar até ela, e os trabalhadores do `load.py`
garantem que ela continue cheia: um trabalhador recusado pede de novo na hora. Uma recusa só diminui
a carga se quem chamou fizer algo com ela, que é a seção 06.

## Escolhendo o número

Vagas de menos e a bilheteria recusa trabalho que conseguiria fazer; vagas demais e o limite não
segura nada que importe. O ponto de partida útil é o recurso protegido: aqui o banco, cujo limite é
de 100 conexões, divididas entre todas as cópias. Três cópias com 32 vagas cada cabem nele, com uma
folga pequena. Além de um número fixo, existem **limites adaptativos** que medem a latência e movem o
teto do jeito que o TCP move a sua janela de congestionamento, subindo enquanto as respostas continuam
rápidas e cortando quando elas ficam lentas.
