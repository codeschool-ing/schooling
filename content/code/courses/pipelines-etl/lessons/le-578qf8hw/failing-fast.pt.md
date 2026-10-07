---
title: Falhar rápido
version: 1
---

O `airflow tasks test` roda uma tarefa uma vez, fora do agendador, que é o jeito mais rápido de ver
em que uma falha se transforma. A Ana roda o `fetch` duas vezes: uma com a chave errada, e outra com
a chave certa e a API fora do ar.

```
ana@vm:~/etl$ PRICES_API_KEY=wrong airflow tasks test prices_daily fetch 2026-03-09 2>&1 | grep -oE "new_state=[a-z_]+|[A-Za-z.]*(Exception|Error): .*" | uniq
airflow.sdk.exceptions.AirflowFailException: the API refused the request: 401 {"error": "missing or wrong X-Api-Key"}
new_state=failed
ana@vm:~/etl$ airflow tasks test prices_daily fetch 2026-03-09 2>&1 | grep -oE "new_state=[a-z_]+|[A-Za-z.]*(Exception|Error): .*" | uniq
requests.exceptions.HTTPError: 503 Server Error: Service Unavailable for url: http://127.0.0.1:8081/v1/prices?page_size=200
new_state=up_for_retry
```

**A mesma tarefa, duas falhas, dois estados diferentes.** O `503` deixou a tarefa em `up_for_retry`:
uma exceção comum, então o Airflow vai tentar de novo depois do intervalo de retry, tantas vezes
quantas o `retries` deixar. O `401` a deixou em `failed`, com quatro retries ainda sem uso, porque o
código levantou `AirflowFailException`, que é a palavra do Airflow para *nem adianta tentar de novo*.

Aquele único `if` decide como vai ser a noite. Sem ele, uma chave errada custa cinco tentativas e as
esperas entre elas: quinze segundos, depois trinta, sessenta e cento e vinte, quase quatro minutos
aqui e horas com um intervalo de retry de produção. **E depois** vem o alerta, dizendo a mesma coisa
que poderia ter dito no começo. Com ele, o alerta é escrito na primeira tentativa.

A lista no `if` é o julgamento, e ele tem de ser feito fonte por fonte. `400`, `401` e `403` são a
API recusando o pedido do jeito que foi escrito. `404` pode ser qualquer um dos dois: uma página que
foi removida, ou uma que ainda não foi publicada. `429` nem é falha aqui, porque o laço espera o que
a API pede e tenta a mesma página de novo sem sair da tarefa. E tudo aquilo em que o código não
pensou cai no `raise_for_status()` e é tentado de novo, que é o padrão seguro: um retry por engano
custa minutos, e uma recusa por engano custa os dados da noite.
