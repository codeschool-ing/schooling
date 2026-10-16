---
title: Métricas personalizadas, e a dimensão que multiplica a fatura
version: 1
---

A AWS publica as métricas dos próprios serviços, de graça: a contagem de requisições de um
balanceador, a profundidade de uma fila, os erros de uma função. **O que importa para o negócio não
está entre elas**: pedidos feitos, pagamentos recusados, a idade do pedido mais antigo não enviado.
Essas são **métricas personalizadas**, publicadas pela aplicação, e cobradas por métrica por mês:

```
ana@laptop:~/aws/metrics$ python3 price.py AmazonCloudWatch MetricMonitorUsage
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-CW:MetricMonitorUsage             0.000000 USD per Metrics    Global
  SAE1-CW:MetricMonitorUsage               0.020000 USD per Metrics    $0.02 per metric-month for over 1,000,000 metrics - South America (Sao Paulo)
  SAE1-CW:MetricMonitorUsage               0.050000 USD per Metrics    $0.05 per metric-month for the next 750,000 metrics - South America (Sao Paulo)
  SAE1-CW:MetricMonitorUsage               0.100000 USD per Metrics    $0.10 per metric-month for the next 240,000 metrics - South America (Sao Paulo)
  SAE1-CW:MetricMonitorUsage               0.300000 USD per Metrics    $0.30 per metric-month for the first 10,000 metrics - South America (Sao Paulo)
ana@laptop:~/aws/metrics$ python3 price.py AmazonCloudWatch CW:Requests
AmazonCloudWatch, sa-east-1, published 2026-10-07
  Global-CW:Requests                       0.000000 USD per Requests   Global
  SAE1-CW:Requests                         0.000014 USD per Requests   $0.014 per 1,000 requests
```

Trinta centavos por mês para cada uma das primeiras dez mil métricas, menos acima disso, e 1,4 centavo
por mil requisições de API por cima. Uma métrica existe para a fatura em qualquer mês em que um ponto
for publicado nela, e **uma métrica é um namespace, um nome e dimensões distintos**, que é onde o custo
se esconde.

## Cardinalidade

A loja quer latência por cliente, para responder reclamações. Uma dimensão `Customer` com o id do
cliente parece inofensiva e é a linha mais cara desta lição:

| dimensões | métricas |
|---|---|
| `Service` (3 serviços) | 3 |
| `Service`, `Stage` (2) | 6 |
| `Service`, `Stage`, `Endpoint` (40) | 240 |
| `Service`, `Stage`, `Endpoint`, `Customer` (20.000) | 4.800.000 |

Cada linha multiplica a de cima. A última, aos preços de lista acima, são 10.000 métricas a 0,30,
240.000 a 0,10, 750.000 a 0,05 e as 3.800.000 restantes a 0,02, **uns 140.500 USD por mês** para uma
métrica de latência. Perguntas por cliente pertencem aos logs, cobrados por gigabyte e consultados
quando alguém pergunta, que é a lição 9. **Os valores de uma dimensão precisam ser poucos e fixos**:
serviços, estágios, endpoints, zonas de disponibilidade. Nunca ids, nunca algo que um cliente consiga
criar mais.

## Publicando sem uma chamada por ponto

Chamar `PutMetricData` a cada requisição custa uma requisição cada e acrescenta latência. Dois jeitos
melhores:

- **agregar antes**: juntar um minuto de valores na aplicação e publicá-los numa chamada, com valores e
  contagens, como a seção anterior fez;
- **o Embedded Metric Format**: escrever uma linha de log estruturada, e o CloudWatch extrai a métrica
  dela quando a linha chega num grupo de logs, sem chamada de API nenhuma.

Uma linha EMF, como a API da loja a imprimiria na saída padrão:

```json
{"_aws": {"Timestamp": 1792166400000, "CloudWatchMetrics": [{"Namespace": "Shop", "Dimensions": [["Service"]], "Metrics": [{"Name": "Latency", "Unit": "Milliseconds"}]}]}, "Service": "api", "Latency": 42, "customer": "c-48213", "path": "/cart"}
```

O bloco `_aws` declara que `Latency` é uma métrica com a dimensão `Service`; todo o resto da linha,
inclusive o id do cliente, continua sendo um campo de log, pesquisável e não uma dimensão. **Uma linha
é a métrica e o detalhe por trás dela.** O moto guarda linhas de log e não extrai nada delas, então a
extração não foi executada aqui.
