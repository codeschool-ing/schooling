---
title: Achando rastros no Jaeger
version: 1
---

Ler um rastro exige o id dele, e até aqui o id veio de uma linha de log. A outra porta de entrada é uma
**busca**: todo armazenamento de rastros indexa spans por serviço, operação, duração, tempo e
atributos, então dá para pedir os rastros que se parecem com o problema.

O formulário de busca do Jaeger em `localhost:16686` aceita esses campos, e a API HTTP documentada
dele, a versão 3, aceita os mesmos. Todo checkout dos últimos três minutos que levou pelo menos
400 ms:

```
ana@obs:~/shop$ curl -sG localhost:16686/api/v3/traces --data-urlencode query.service_name=storefront --data-urlencode 'query.operation_name=POST /checkout' --data-urlencode query.duration_min=400ms --data-urlencode query.start_time_min=2026-10-02T16:36:11Z --data-urlencode query.start_time_max=2026-10-02T16:39:11Z --data-urlencode query.search_depth=5 | jq -r '[.result.resourceSpans[].scopeSpans[].spans[] | select(.name == "POST /checkout")] | .[] | [.traceId, ((((.endTimeUnixNano | tonumber) - (.startTimeUnixNano | tonumber)) / 1e6) | floor)] | @tsv'
5c2c908e9788a59688745c45c443f1c1	431
c3490bff2db63cee980be1857e2a7435	428
524e5284c6ecc3306a24cf03feb82850	434
3aa2e4729024e38908cb92da13a2a0f6	432
ced73eb37b6c3b1ec4a1e9332fd9990d	422
```

Cinco rastros, o máximo que a requisição pediu, cada um com a duração do span raiz em milissegundos.
Na interface, a mesma busca os desenha como pontos num eixo de tempo, com a duração como altura. Os
pontos que vale abrir são os altos e os que ficam afastados da multidão.

Três coisas sobre buscar valem ser sabidas antes de um incidente, e não durante:

- **Uma busca só vê o que foi guardado.** A aula 12 amostra rastros, e uma busca sobre uma amostra
  acha as requisições lentas que por acaso foram amostradas. Se elas são representativas é o assunto
  daquela aula.
- **Os atributos que você pode buscar são os atributos que alguém escreveu.** Uma busca pelos checkouts
  de um produto só funciona porque a vitrine pôs `shop.sku` no span dela na aula 2. Se ninguém o
  definiu, nenhum formulário o acha.
- **O armazenamento decide quanto tempo ele dura.** O Jaeger do laboratório guarda rastros em memória e
  os esquece ao reiniciar. Em produção ele grava no Elasticsearch, no OpenSearch ou no Cassandra, com
  uma retenção escolhida exatamente como a aula 10 escolheu uma para os logs.

O laboratório lê um rastro com `/api/traces/<id>`, o endpoint que a própria interface usa. Ele está
estável há anos, mas o projeto documenta a versão 3 como a API sobre a qual construir, e um script que
precisa sobreviver a uma atualização deve usar essa.

O Jaeger nasceu na Uber em 2015 e hoje é um projeto da CNCF. A versão 2 é construída sobre o
OpenTelemetry Collector, e é por isso que o Collector do laboratório fala com ele em OTLP, o mesmo
protocolo que os serviços falam com o Collector.