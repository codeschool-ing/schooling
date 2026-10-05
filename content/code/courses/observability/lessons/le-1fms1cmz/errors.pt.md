---
title: Quando falha: status e exceções
version: 1
---

Um rastro se paga na requisição que falhou, então a loja é quebrada de propósito: o `orders` é
parado, e um checkout é enviado.

```
ana@obs:~/shop$ docker compose stop orders
 Container shop-orders-1 Stopping 
 Container shop-orders-1 Stopped 
ana@obs:~/shop$ curl -s -w ' %{http_code}\n' -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d @checkout.json
{"error":"try again later"}
 503
ana@obs:~/shop$ docker compose start orders
 Container shop-orders-1 Starting 
 Container shop-orders-1 Started 
```

O cliente recebeu um `503` e uma frase educada. A vitrine registrou um erro com o id do rastro da
requisição, e o rastro diz o que o log só resumiu:

```
ana@obs:~/shop$ docker compose logs --no-log-prefix storefront | grep unreachable | jq -c '{level, message, trace_id}'
{"level":"ERROR","message":"orders unreachable","trace_id":"76d585ac77c4564bdfae0e3aefa5e611"}
ana@obs:~/shop$ curl -s localhost:16686/api/traces/76d585ac77c4564bdfae0e3aefa5e611 | jq '.data[0].spans[0] | {tags: ([.tags[] | select(.key | test("^(otel.status|error)")) | {(.key): .value}] | add), events: [.logs[].fields | from_entries | {event, "exception.type"}]}'
{
  "tags": {
    "otel.status_code": "ERROR",
    "error": true,
    "otel.status_description": "orders unreachable"
  },
  "events": [
    {
      "event": "exception",
      "exception.type": "requests.exceptions.ConnectionError"
    }
  ]
}
```

**Duas coisas diferentes foram registradas, por duas chamadas no código da vitrine.** Quando o
`requests` levantou a exceção, o bloco `except` fez isto:

```python
            span.record_exception(e)
            span.set_status(Status(StatusCode.ERROR, "orders unreachable"))
```

O `set_status` marca o span como falho, e os backends transformam isso no `error: true` que o
Jaeger mostra, no vermelho de toda tela de rastro e no filtro *mostre os rastros que falharam*. O
`record_exception` acrescenta um **evento**: uma anotação com horário dentro do span, aqui levando o
tipo, a mensagem e a pilha da exceção. Um evento é como um span diz *isto aconteceu neste momento*
sem virar um span novo.

O status de um span tem três valores, e a regra para eles é mais estreita do que parece:

| status | quer dizer | quem define |
|---|---|---|
| `UNSET` | ninguém disse que falhou | o padrão |
| `ERROR` | esta operação falhou | a instrumentação, quando a operação falhou |
| `OK` | alguém insiste que deu certo | a aplicação, raramente, para anular um `ERROR` |

**Uma falha é do próprio span, não de quem o chamou.** A vitrine responder `404` para um produto
desconhecido é uma recusa correta, e o código deixa o status em paz. A mesma regra está escrita nas
convenções HTTP do OpenTelemetry: um `4xx` marca como falho o span do *cliente* e não o do
servidor, porque o servidor fez o seu trabalho. Um `5xx` marca os dois. Marque toda recusa como
erro e a taxa de erros deixa de querer dizer *algo está quebrado* e passa a querer dizer *alguém
digitou um endereço errado*.
