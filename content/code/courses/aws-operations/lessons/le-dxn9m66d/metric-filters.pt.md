---
title: Filtros de métrica, e transformar linhas num número
version: 1
---

Uma consulta responde a uma pergunta quando alguém a faz. Um alarme precisa de um número a cada minuto
sem ninguém perguntar. Um **filtro de métrica** liga os dois: ele vigia cada linha que chega a um
grupo de logs, e para cada linha que casa com o padrão soma um valor a uma métrica. Os erros da loja,
contados a partir dos logs:

```
ana@laptop:~/aws/logs$ aws logs put-metric-filter --log-group-name /shop/api --filter-name errors-5xx --filter-pattern '{ $.status >= 500 }' --metric-transformations metricName=Errors5xx,metricNamespace=Shop,metricValue=1,defaultValue=0
ana@laptop:~/aws/logs$ aws logs describe-metric-filters --log-group-name /shop/api --query 'metricFilters[0].[filterName,filterPattern,metricTransformations[0].metricName]' --output text
errors-5xx	{ $.status >= 500 }	Errors5xx
ana@laptop:~/aws/logs$ jq -n --arg t "$(date +%s000)" '[{timestamp: ($t | tonumber), message: ({status: 503, path: "/checkout"} | tojson)}]' > one.json
ana@laptop:~/aws/logs$ aws logs put-log-events --log-group-name /shop/api --log-stream-name api-1 --log-events file://one.json --query rejectedLogEventsInfo
null
ana@laptop:~/aws/logs$ aws cloudwatch list-metrics --namespace Shop --query 'Metrics'
[]
```

O filtro foi guardado, com o padrão e a métrica que alimenta, `Shop/Errors5xx`. Depois chegou uma
linha com status 503, e **nenhuma métrica apareceu**: o moto guarda filtros de métrica e nunca os roda.
Na AWS, essa linha teria somado 1 a `Errors5xx` dentro do minuto, e `defaultValue=0` faz o filtro
publicar um zero nos minutos sem linha correspondente, para um alarme ver um minuto quieto como zero e
não como dado ausente, o que a lição 10 explica.

## Logs, métricas e a ordem deles

Filtros de métrica invertem a ordem da lição 8. Lá, a aplicação publicava métricas e guardava logs
para o detalhe; aqui, a aplicação só escreve logs e as métricas derivam deles. Os dois funcionam, e
falham de jeitos diferentes:

| | métrica publicada | métrica de um filtro |
|---|---|---|
| custo | uma métrica personalizada e as requisições dela | a ingestão de logs, já paga |
| quando o padrão muda | uma mudança de código | uma mudança de filtro, sem deploy |
| quando se loga menos | não é afetada | a métrica cai, em silêncio |

A última linha é a que se deve lembrar. **Uma métrica derivada de logs depende de uma linha que alguém
pode apagar** ao limpar o log para economizar, e nada avisa essa pessoa de que o alarme lá na frente
acabou de ficar cego. Mantenha as linhas que um filtro lê na mesma revisão que o filtro, ou publique a
métrica diretamente.

## Mandando linhas para outro lugar

Um **filtro de assinatura** é o outro jeito de um grupo de logs empurrar linhas para fora: cada linha
que casa é enviada, quando chega, para um stream do Kinesis, um delivery stream do Firehose ou uma
função Lambda, para um serviço de busca ou um arquivo no S3. É assim que logs saem do CloudWatch para
uma ferramenta que os guarda por mais tempo ou mais barato, e é cobrado como a entrega que o destino
recebe.
