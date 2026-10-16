---
title: Nenhum banco
version: 1
---

Agora o primário também. Uma leitura do show 1, que esta cópia já leu; uma leitura do show 2, que
ela não leu; e uma venda:

```
ana@lab:~/tickets$ docker compose stop db
 Container tickets-db-1 Stopping 
 Container tickets-db-1 Stopped 
ana@lab:~/tickets$ sleep 5
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "memory", "seconds_old": 6}
ana@lab:~/tickets$ curl -s localhost:8080/events/2; echo
{"error": "event unavailable"}
ana@lab:~/tickets$ curl -s -X POST localhost:8080/events/1/tickets; echo
{"error": "sales paused"}
```

- **O show 1 foi respondido da memória**, com seis segundos, e a resposta diz isso. Para uma página
  que mostra quantos lugares sobram, um número de seis segundos atrás é muito melhor que um erro, e a
  página pode dizer *cerca de 1.000.000 sobrando*.
- **O show 2 nunca tinha sido lido**, então não havia com o que responder: `503`, volte em cinco
  segundos. Um cache só devolve o que já viu.
- **A venda foi pausada** antes de qualquer cobrança. Vender precisa do primário; nada mais sabe quais
  lugares estão livres.

Depois os dois bancos de volta:

```
ana@lab:~/tickets$ docker compose start db replica
 Container tickets-db-1 Starting 
 Container tickets-db-1 Started 
 Container tickets-db-1 Waiting 
 Container tickets-db-1 Healthy 
 Container tickets-replica-1 Starting 
 Container tickets-replica-1 Started 
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "replica"}
ana@lab:~/tickets$ curl -s localhost:8080/events/1; echo
{"name": "Show 1", "left": 1000000, "host": "615b3114daa0", "source": "replica"}
```

As leituras voltaram a vir da réplica na hora, sem ninguém ter que trocar nada de volta: todo pedido
tenta a réplica primeiro, então a bilheteria volta ao normal assim que a réplica volta. Essa é a
segunda metade de um recuo, e a metade mais esquecida: **voltar é automático, ou não acontece às três
da manhã**.

## O que a memória não faz

A última resposta vista é guardada por cada cópia para si, para sempre, e só para shows que aquela
cópia leu. Um sistema real usa para isso um cache compartilhado com expiração, Redis ou uma CDN, e
define a expiração pelo quanto de atraso aguenta. A ideia é a mesma: decidir de antemão quão velha uma
resposta pode ser e ainda valer a pena dar.
