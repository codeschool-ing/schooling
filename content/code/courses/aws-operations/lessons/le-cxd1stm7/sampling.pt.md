---
title: Amostragem, e quantos traces vale a pena guardar
version: 1
---

Registrar cada requisição de um serviço movimentado custa dinheiro, rede e um pouco de latência, e a
maioria desses traces mostraria a mesma coisa. **O X-Ray amostra**: registra um número fixo de
requisições por segundo, o reservatório, e uma porcentagem do resto, a taxa. A regra padrão,
como a AWS documenta, tem reservatório de uma requisição por segundo e taxa de 5%.

A 200 requisições por segundo, o padrão registra 1 + 5% das outras 199, uns 10,95 traces por segundo:
cerca de 946.000 por dia, 28,4 milhões num mês de 30 dias. **O reservatório garante que os serviços
calmos sejam registrados de algum modo**; a taxa mantém o volume de um serviço movimentado em
proporção.

```
ana@laptop:~/aws/traces$ python3 price.py AWSXRay TracesStored
AWSXRay, sa-east-1, published 2026-09-11
  Global-XRay-TracesStored                 0.000000 USD per Traces     AWS X-Ray - Traces Stored Free Tier - 100,000 traces
  SAE1-XRay-InsightsTracesStored           0.000001 USD per Traces     AWS X-Ray - Total Insights Traces Processed - South America (Sao Paulo)
  SAE1-XRay-TracesStored                   0.000005 USD per traces     AWS X-Ray - Total Traces Stored - South America (Sao Paulo)
```

Cinco dólares por milhão de traces guardados, depois de 100.000 gratuitos por mês (a linha `Global`).
Com 28,4 milhões por mês a loja paga uns 141 USD por um serviço movimentado, na taxa padrão. Uma regra
para o health check em 0% e uma para o checkout em 10% gasta o orçamento onde as perguntas são feitas.

## Regras, e onde elas moram

As regras de amostragem ficam no X-Ray, não em cada serviço: os SDKs e coletores as buscam, então uma
regra mudada no X-Ray muda o que cada serviço registra em um minuto, sem deploy. Uma regra casa com
requisições por nome de serviço, método HTTP, caminho da URL e host, e tem prioridade, reservatório e
taxa. A loja deixaria o health check de fora e registraria mais do caminho caro:

| prioridade | casa com | reservatório | taxa |
|---|---|---|---|
| 10 | `GET /health` | 0 | 0% |
| 20 | `POST /checkout` | 2 | 10% |
| 10000 | todo o resto (o padrão) | 1 | 5% |

```
ana@laptop:~/aws/traces$ aws xray get-sampling-rules 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (404) when calling the GetSamplingRules operation: <!doctype html>
```

O moto não implementa regras de amostragem: a chamada não é encontrada. A tabela é o modelo documentado
do X-Ray, e nada nela foi executado.

## A decisão também viaja

Uma requisição é amostrada ou não **uma vez, no primeiro serviço**, e a decisão vai no campo `Sampled=`
do cabeçalho para cada serviço seguinte. Se cada serviço decidisse sozinho, um trace voltaria com
buracos: a API registrada, o serviço de pagamentos não. Manter a primeira decisão é o que deixa
completo um trace registrado. A consequência para erros raros: **a 5%, dezenove de vinte checkouts que
falharam não deixam trace**, então erros são achados primeiro por métricas e logs, e o trace está lá
para os que foram amostrados.
