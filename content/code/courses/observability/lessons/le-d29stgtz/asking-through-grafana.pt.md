---
title: Perguntando pelo Grafana
version: 1
---

A consulta de um painel é uma requisição HTTP como qualquer outra, e pode ser enviada à mão. O
`query.json` pede a taxa total de requisições da vitrine, em PromQL, endereçada à fonte de dados pelo
seu `uid`:

```
ana@obs:~/shop$ cat query.json
{
  "from": "now-5m",
  "to": "now",
  "queries": [
    {
      "refId": "A",
      "datasource": {"uid": "prometheus"},
      "expr": "sum(rate(http_server_requests_total{job=\"storefront\"}[1m]))",
      "instant": true
    }
  ]
}
```

Enviada à API de consulta do Grafana, e depois a mesma expressão enviada direto ao Prometheus, uma
fração de segundo mais tarde:

```
ana@obs:~/shop$ curl -s -u admin:$(cat .grafana-password) -H 'Content-Type: application/json' -d @query.json localhost:3000/api/ds/query | jq -c '.results.A.frames[0].data.values'
[[1790936947924],[5.084097777777777]]
ana@obs:~/shop$ curl -sG localhost:9090/api/v1/query --data-urlencode 'query=sum(rate(http_server_requests_total{job="storefront"}[1m]))' | jq -c '.data.result[0].value'
[1790936948.040,"5.0846133333333325"]
```

**O mesmo número, 5,08 requisições por segundo**, com o timestamp em milissegundos vindo do Grafana e
em segundos vindo do Prometheus. O Grafana traduziu a requisição, repassou-a, e remodelou a resposta
no seu próprio formato de *frames*, colunas de valores que todo tipo de painel sabe desenhar. Nada foi
calculado no Grafana.

Isso tem duas consequências que vale saber antes de construir qualquer coisa em cima. Um painel lento
é quase sempre **uma consulta lenta na fonte de dados**, e o conserto está no PromQL ou no LogQL, numa
regra de gravação ou num intervalo de tempo mais estreito, não no Grafana. E um painel aberto por
cinquenta pessoas ao mesmo tempo, atualizando a cada trinta segundos, são cinquenta vezes a consulta
de cada painel contra o Prometheus, que é o motivo mais barato que existe para dar a um painel pesado
uma regra de gravação.
