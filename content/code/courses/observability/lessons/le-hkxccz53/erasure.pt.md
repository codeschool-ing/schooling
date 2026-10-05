---
title: Recuperando o que foi escrito
version: 1
---

O vazamento foi achado. Agora as linhas que já chegaram aos armazenamentos têm de sair, e **é aqui
que os logs estão no seu pior**. Eles são feitos para receber acréscimos, não edições. Um
armazenamento pensado para milhões de escritas por minuto não foi pensado para apagar uma.

O Loki aceita um **pedido de exclusão**: um seletor e um filtro LogQL, e um intervalo de tempo. Ele não
apaga na hora. O pedido entra numa fila, e o compactor reescreve os chunks afetados na sua próxima
passada, depois de um período de carência:

```
ana@obs:~/shop$ curl -s -o /dev/null -w '%{http_code}\n' -X POST -G localhost:3100/loki/api/v1/delete --data-urlencode 'query={service_name="storefront"} |= "sk_live_9f8e7d6c5b4a"' --data-urlencode start=$(date -d '-1 hour' +%s)
204
ana@obs:~/shop$ curl -s localhost:3100/loki/api/v1/delete | jq -c '.[] | {query, status}'
{"query":"{service_name=\"storefront\"} |= \"sk_live_9f8e7d6c5b4a\"","status":"received"}
```

`204`, aceito, e o pedido fica como `received` até o compactor chegar nele. O Elasticsearch apaga por
consulta, na hora, todo documento que casa:

```
ana@obs:~/shop$ curl -s -X POST localhost:9200/logs-generic.otel-default/_delete_by_query -H 'Content-Type: application/json' -d '{"query": {"match_phrase": {"body.text": "sk_live_9f8e7d6c5b4a"}}}' | jq -c '{deleted, failures}'
{"deleted":1,"failures":[]}
```

**Um documento apagado**: a linha do primeiro checkout. O segundo vazamento nunca chegou ao
Elasticsearch, porque o filtro no código o tinha mascarado, e o terceiro chegou lá já mascarado pelo
Collector. Cada defesa aparece na contagem.

E as cópias sobre as quais ninguém perguntou continuam lá: o log do próprio contêiner na máquina,
qualquer backup feito de um dos armazenamentos, qualquer fornecedor para quem os logs foram
exportados, e qualquer pessoa que copiou uma linha para um chamado. **Apagar uma linha de log nunca
termina.** Isso transforma o direito de exclusão da LGPD num argumento de desenho e não de
ferramenta: a linha que nunca guardou o dado de uma pessoa não precisa ser apagada. Essa é a regra
com que esta aula termina. Registre identificadores que não significam nada fora do sistema, guarde
linhas só enquanto forem úteis, e trate um armazenamento cheio de dados pessoais como o incidente
que ele é.