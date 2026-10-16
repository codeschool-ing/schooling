---
title: Recuo exponencial
version: 1
---

Quanto a bilheteria deve esperar antes de tentar de novo? Não esperar nada é a pior resposta: um
serviço sobrecarregado recebe de novo todo pedido que falhou, na hora, em cima dos novos, e a
sobrecarga que causou a falha agora é maior. Uma espera fixa é melhor, e ainda errada quando o
problema dura mais que a espera.

O **recuo exponencial** (*exponential backoff*) dobra a espera depois de cada tentativa que falha. O
teto da bilheteria é 100 ms × 2ⁿ para a tentativa *n*: 200 ms depois da primeira falha, 400 ms depois
da segunda, e nunca mais de dois segundos. Um problema curto custa uma espera curta; um longo é
tentado cada vez menos, que é o que dá espaço ao outro lado para se recuperar.

Faça toda chamada ao payments falhar, e compre um ingresso:

```
ana@lab:~/tickets$ PAYMENTS_FAIL_PERCENT=100 docker compose up -d payments
 Container tickets-payments-1 Recreate 
 Container tickets-payments-1 Recreated 
 Container tickets-payments-1 Starting 
 Container tickets-payments-1 Started 
ana@lab:~/tickets$ curl -s -w ' %{http_code} in %{time_total} s\n' -X POST localhost:8080/events/1/tickets
{"error": "payment failed"} 502 in 0.341069 s
ana@lab:~/tickets$ docker compose logs app --no-log-prefix | grep 'charge retry' | tail -2
{"time": "2026-10-10T07:43:16.992+00:00", "level": "warning", "message": "charge retry", "host": "6bc51142e2fa", "attempt": 1, "wait_ms": 131, "error": "HTTPError: HTTP Error 503: Service Unavailable", "trace_id": "4c5b53d3f5228de06cd7d4d9da6f9e27"}
{"time": "2026-10-10T07:43:17.127+00:00", "level": "warning", "message": "charge retry", "host": "6bc51142e2fa", "attempt": 2, "wait_ms": 194, "error": "HTTPError: HTTP Error 503: Service Unavailable", "trace_id": "4c5b53d3f5228de06cd7d4d9da6f9e27"}
ana@lab:~/tickets$ sleep 7
ana@lab:~/tickets$ python3 trace.py
trace 4c5b53d3f5228de06cd7d4d9da6f9e27
POST /events/{id}/tickets      tickets   at   0.0 ms  took 339.4 ms
  charge                       tickets   at   0.8 ms  took   4.6 ms
    POST /charges              payments  at   3.0 ms  took   0.2 ms
  charge                       tickets   at 137.0 ms  took   3.4 ms
    POST /charges              payments  at 139.2 ms  took   0.2 ms
  charge                       tickets   at 335.4 ms  took   3.5 ms
    POST /charges              payments  at 337.7 ms  took   0.2 ms
```

A venda falhou depois de **0,34 s** com três tentativas, e o log e o rastro dizem como o tempo foi
gasto. Cada tentativa levou poucos milissegundos e o payments respondeu `503` em 0,2 ms. Entre elas a
bilheteria esperou **131 ms**, depois **194 ms**. Não são 200 e 400: cada espera é um número
aleatório entre zero e o teto, e a seção 06 explica por quê.

Mais duas regras moram no `backoff`. **Um `Retry-After` do payments ganha**: se quem é chamado diz
quando voltar, quem chama não tem informação melhor. E **o total é limitado**: três tentativas quer
dizer no máximo duas esperas, cada uma abaixo do seu teto a não ser que o payments peça mais, porque
o comprador está esperando atrás delas, e uma das 32 vagas da bilheteria também.
