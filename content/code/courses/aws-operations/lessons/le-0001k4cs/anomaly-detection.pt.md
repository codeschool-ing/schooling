---
title: Cost Anomaly Detection, e por que chamar alguém
version: 1
---

A AWS roda a mesma ideia do `spike.py` como serviço: o **Cost Anomaly Detection**, parte do Billing and
Cost Management, grátis. Um **monitor** diz o que vigiar: cada serviço da AWS separado, a escolha mais
comum; ou uma conta, uma cost category da lição 24, ou uma tag de alocação de custo. Uma **assinatura** diz
quem fica sabendo, por e-mail ou SNS, na hora, por dia ou por semana, e acima de que **impacto**, em dólares
ou como porcentagem do gasto esperado. Em vez de uma mediana, ele aprende o padrão de cada monitor, dias
úteis e fins de semana inclusive, e informa a causa raiz que consegue ver: o serviço, a conta, a região e
o tipo de uso que se mexeram.

```
ana@laptop:~/aws/bill$ aws ce create-anomaly-monitor --anomaly-monitor '{"MonitorName":"services","MonitorType":"DIMENSIONAL","MonitorDimension":"SERVICE"}' 2>&1 | grep -m1 ERROR
aws: [ERROR]: An error occurred (500) when calling the CreateAnomalyMonitor operation (reached max retries: 2): <!doctype html>
```

O moto não tem detecção de anomalias, então isto é o comportamento documentado da AWS, não executado aqui.
Criado na conta da loja, um monitor por serviço com uma assinatura imediata acima de 20 USD de impacto
teria informado o CloudWatch em 9 de outubro, com `SAE1-DataProcessing-Bytes` como o tipo de uso que se
mexeu, a linha que a lição 9 calculou.

## Por que chamar alguém

Custo é lento comparado com erros, e chamar alguém a cada movimento é a fadiga da lição 14 de novo. Um
conjunto que funciona para uma equipe do tamanho da da loja:

| sinal | limite | rota |
|---|---|---|
| anomalia, um serviço | acima de 20 USD por dia de impacto | ticket, lido no mesmo dia |
| anomalia, qualquer | acima de 100 USD por dia, ou um serviço que ninguém usa | chamado |
| orçamento, previsão | acima de 100% do mês | ticket |
| orçamento, real | acima de 100% antes do dia 20 | chamado |
| taxa de `EstimatedCharges` | três vezes o ritmo usual | chamado |

Os dois chamados que mais importam são os que a tabela põe lá por um motivo: **um serviço que ninguém usa
aparecendo na conta** é a marca de uma credencial roubada, instâncias numa região que a equipe nunca usa,
e é o achado do GuardDuty da lição 19 visto pelo outro lado; e **uma conta crescendo três vezes mais rápido
que o usual** é um laço, um vazamento ou um ataque, seja de que lição for. Nos dois casos a conta percebeu
primeiro, e não deve ser a última a perceber.
