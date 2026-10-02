---
title: Um painel é um arquivo
version: 1
---

Painéis montados com cliques têm uma vida conhecida. Alguém faz um bom, e outra pessoa muda uma consulta
para investigar algo e esquece de desfazer. Um mês depois ninguém sabe qual versão estava certa nem
quem a quebrou. **Um painel guardado como arquivo no controle de versão tem histórico, revisão, e um
caminho de volta.** Os painéis do Grafana são JSON, e o provisionamento do laboratório lê todo arquivo
em `grafana/dashboards` na partida e de novo a cada poucos segundos. O da loja:

```schooling-example
{
  "language": "json",
  "file": "grafana/dashboards/shop.json",
  "parts": [
    {
      "code": "{\n  \"uid\": \"shop\",\n  \"title\": \"Shop: requests, errors, duration\",\n  \"tags\": [\"shop\"],\n  \"time\": {\"from\": \"now-30m\", \"to\": \"now\"},\n  \"refresh\": \"30s\",\n",
      "note": "**O `uid` do próprio painel, `shop`**, escolhido no arquivo como o das fontes de dados, para que links e anotações possam nomeá-lo em qualquer Grafana que carregue este arquivo."
    },
    {
      "code": "  \"templating\": {\n    \"list\": [\n      {\n        \"name\": \"job\",\n        \"type\": \"query\",\n        \"datasource\": {\"uid\": \"prometheus\"},\n        \"query\": \"label_values(http_server_requests_total, job)\",\n        \"current\": {\"text\": \"storefront\", \"value\": \"storefront\"}\n      }\n    ]\n  },\n",
      "note": "Uma **variável**, `job`, cujos valores vêm de uma função do PromQL. Toda consulta abaixo escreve `$job` onde iria o nome de um serviço."
    },
    {
      "code": "  \"annotations\": {\n    \"list\": [\n      {\"name\": \"Deploys\", \"datasource\": {\"uid\": \"-- Grafana --\"}, \"enable\": true, \"iconColor\": \"orange\",\n       \"target\": {\"type\": \"tags\", \"tags\": [\"deploy\"]}}\n    ]\n  },\n",
      "note": "Anotações com a tag `deploy` são desenhadas em todo painel como linhas verticais. A seção de anotações cria duas."
    },
    {
      "code": "  \"panels\": [\n    {\n      \"id\": 1, \"type\": \"timeseries\", \"title\": \"Requests per second, by status code\",\n      \"gridPos\": {\"x\": 0, \"y\": 0, \"w\": 12, \"h\": 8},\n      \"targets\": [{\"refId\": \"A\", \"datasource\": {\"uid\": \"prometheus\"},\n        \"expr\": \"sum by (code) (rate(http_server_requests_total{job=\\\"$job\\\"}[1m]))\", \"legendFormat\": \"{{code}}\"}]\n    },\n",
      "note": "Um painel é um título, uma posição numa grade de 24 colunas, e uma ou mais consultas endereçadas a uma fonte de dados pelo `uid`. Este é a taxa por código de status, a consulta da aula 5."
    },
    {
      "code": "    {\n      \"id\": 2, \"type\": \"timeseries\", \"title\": \"Share of requests failing (5xx)\",\n      \"gridPos\": {\"x\": 12, \"y\": 0, \"w\": 12, \"h\": 8},\n      \"fieldConfig\": {\"defaults\": {\"unit\": \"percentunit\", \"min\": 0}},\n      \"targets\": [{\"refId\": \"A\", \"datasource\": {\"uid\": \"prometheus\"},\n        \"expr\": \"sum(rate(http_server_requests_total{job=\\\"$job\\\", code=~\\\"5..\\\"}[1m])) / sum(rate(http_server_requests_total{job=\\\"$job\\\"}[1m]))\"}]\n    },\n    {\n      \"id\": 3, \"type\": \"timeseries\", \"title\": \"Duration, 50th and 99th percentile\",\n      \"gridPos\": {\"x\": 0, \"y\": 8, \"w\": 24, \"h\": 8},\n      \"fieldConfig\": {\"defaults\": {\"unit\": \"s\", \"min\": 0}},\n      \"targets\": [\n        {\"refId\": \"A\", \"datasource\": {\"uid\": \"prometheus\"}, \"legendFormat\": \"p50\",\n         \"expr\": \"histogram_quantile(0.5, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\\\"$job\\\"}[1m])))\"},\n        {\"refId\": \"B\", \"datasource\": {\"uid\": \"prometheus\"}, \"legendFormat\": \"p99\",\n         \"expr\": \"histogram_quantile(0.99, sum by (le) (rate(http_server_request_duration_seconds_bucket{job=\\\"$job\\\"}[1m])))\"}\n      ]\n    }\n  ]\n}\n",
      "note": "A fração de erros, com a unidade declarada para o eixo ler em porcentagem, e os dois percentis da aula 6, cada um uma consulta própria num painel só."
    }
  ]
}
```

O Grafana o achou e o arquivou na pasta que o arquivo de provisionamento nomeou:

```
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" 'localhost:3000/api/search?query=Shop' | jq -c '.[] | {uid, title, folderTitle, tags}'
{"uid":"bg007clzi8vlsc","title":"Shop","folderTitle":null,"tags":[]}
{"uid":"shop","title":"Shop: requests, errors, duration","folderTitle":"Shop","tags":["shop"]}
ana@obs:~/shop$ curl -s -H "Authorization: Bearer $(cat .grafana-token)" localhost:3000/api/dashboards/uid/shop | jq -r '.meta.provisioned, (.dashboard.panels[] | .title)'
true
Requests per second, by status code
Share of requests failing (5xx)
Duration, 50th and 99th percentile
```

Dois resultados para *Shop*: a pasta, que o Grafana criou para o provisionamento, e o painel, com seu
`uid`, título e tag. O painel diz que é **provisionado**, e o Grafana age de acordo. Uma tentativa de
salvar por cima dele pela API, a mesma requisição que o botão de salvar da interface manda:

```
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Bearer $(cat .grafana-token)" -H 'Content-Type: application/json' -d '{"dashboard": {"uid": "shop", "title": "edited by hand"}, "overwrite": true}' localhost:3000/api/dashboards/db
400
```

**Recusado.** O Grafana não deixa um painel provisionado ser sobrescrito no lugar, porque a próxima
leitura do arquivo desfaria a edição em silêncio. Quem quiser mudá-lo muda o arquivo, num pull
request, onde alguém pode ver a mudança da consulta antes de ela chegar à tela de todo mundo. Qualquer
um ainda pode salvar uma *cópia* para experimentar, que é o lugar certo para um experimento.
