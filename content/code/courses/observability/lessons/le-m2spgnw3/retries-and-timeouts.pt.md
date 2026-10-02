---
title: Novas tentativas e timeouts, e o que eles escondem
version: 1
---

O segundo listener do Envoy fica entre `orders` e payments, na porta 10001. Um override aponta `orders`
para ele:

```
ana@obs:~/shop$ cat compose.override.yaml
services:
  orders:
    environment:
      PAYMENTS_URL: http://envoy:10001
```

A rota tem um timeout de dois segundos e uma política de nova tentativa: um 5xx de payments é tentado de
novo, até duas vezes.

```
ana@obs:~/shop$ sed -n '/cluster: payments$/,/num_retries/p' envoy/envoy.yaml
                            cluster: payments
                            timeout: 2s
                            retry_policy:
                              retry_on: 5xx
                              num_retries: 2
```

Então payments recebe a ordem de falhar uma cobrança em cada dez, a falha que paginou alguém na aula 16.
Noventa segundos depois, as taxas por serviço e status:

```
ana@obs:~/shop$ ./promq 'sum by (job, code) (rate(http_server_requests_total{job=~"storefront|payments",route=~"/checkout|/charge"}[1m]))'
code=200 job=payments  9.02222222222222
code=201 job=storefront  8.510543741528343
code=402 job=storefront  0.488856298468991
code=503 job=storefront  0
code=503 job=payments  0.9999999999999999
```

Payments responde umas nove cobranças por segundo com 200 e uma com 503, então a falha está funcionando. A storefront responde 201, e 402 para os cartões recusados dos clientes simulados; a série de 503 dela está em zero. **Nenhum cliente viu a falha.**

```
ana@obs:~/shop$ curl -s localhost:9901/stats | grep -E '^cluster\.payments\.upstream_rq_(total|retry|retry_success|5xx|503):'
cluster.payments.upstream_rq_retry: 90
cluster.payments.upstream_rq_retry_success: 90
cluster.payments.upstream_rq_total: 905
```

O Envoy tentou de novo 90 das 905 requisições que mandou a payments, e as 90 deram certo: payments falha a cada décima cobrança, e a nova tentativa chega como a seguinte. Uma cobrança tentada de novo, no log de acesso:

```
ana@obs:~/shop$ docker logs shop-envoy-1 2>&1 | grep '"listener":"payments"' | grep -m1 '"attempts":2' | jq -c .
{"attempts":2,"code":200,"flags":"-","listener":"payments","method":"POST","ms":16,"path":"/charge"}
```

**O mesh deixou uma falha invisível para os clientes, e isso é ao mesmo tempo o uso e o perigo dele.**
Três consequências:

- **Os dois lados agora discordam.** As métricas de payments dizem que uma cobrança em dez falha; as da
  storefront dizem que nenhuma falha. Os dois estão certos, e um alerta sobre a taxa de erro de payments
  paginaria alguém por um problema que nenhum cliente tem. A regra da aula 16 é a resposta de novo:
  paginar pelo sintoma na borda, deixar as causas como tickets.
- **Novas tentativas custam capacidade.** Cada cobrança que falhou virou duas requisições para payments.
  Um serviço que falha por estar sobrecarregado recebe mais carga de cada chamador que tenta de novo, e
  é assim que um problema pequeno vira uma queda. O Envoy tem orçamentos de nova tentativa e circuit
  breakers por esse motivo.
- **Uma nova tentativa só é segura se a requisição for.** Cobrar um cartão duas vezes é o caso clássico.
  Payments aqui falha antes de cobrar qualquer coisa, então tentar de novo não faz mal; uma API de
  pagamento de verdade precisa de uma chave de idempotência para que uma requisição repetida seja
  reconhecida como a mesma.

Depois, o timeout. Payments recebe a ordem de levar 2,5 segundos por cobrança, mais do que a rota permite:

```
ana@obs:~/shop$ docker logs shop-envoy-1 2>&1 | grep '"listener":"payments"' | tail -1 | jq -c .
{"attempts":1,"code":504,"flags":"UT","listener":"payments","method":"POST","ms":2000,"path":"/charge"}
```

O Envoy desistiu aos 2000 milissegundos e respondeu 504 ele mesmo; a flag `UT` quer dizer timeout da requisição ao upstream. Não tentou de novo, porque o timeout da rota vale para todas as tentativas juntas e já tinha se esgotado.

```
ana@obs:~/shop$ curl -s -X POST localhost:8080/checkout -H 'Content-Type: application/json' -d '{"sku": "kettle", "qty": 1, "card": "4111 1111 1111 1111"}' -w ' %{http_code}\n'
{"error":"try again later"}
 502
```

O cliente vê o mesmo `try again later` da aula 14. O proxy transformou uma dependência lenta numa falha
rápida, o que costuma ser a troca certa: uma resposta em dois segundos é melhor que uma em dez, e uma
requisição esperando segura uma thread de que o próximo cliente precisa.
