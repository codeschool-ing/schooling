---
title: Montando no CloudWatch
version: 1
---

Tudo o que esta lição calculou em Python, o CloudWatch consegue calcular sozinho, com **matemática de
métricas**: consultas que leem métricas e expressões que as combinam, no `get-metric-data`, num painel e
num alarme. O SLI de disponibilidade, como matemática de métricas:

```json
[
  {"Id": "errors", "MetricStat": {"Metric": {"Namespace": "Shop", "MetricName": "Errors", "Dimensions": [{"Name": "Service", "Value": "ongoing"}]}, "Period": 300, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "requests", "MetricStat": {"Metric": {"Namespace": "Shop", "MetricName": "Requests", "Dimensions": [{"Name": "Service", "Value": "ongoing"}]}, "Period": 300, "Stat": "Sum"}, "ReturnData": false},
  {"Id": "sli", "Expression": "100 * (1 - errors / requests)", "Label": "availability, %"}
]
```

Duas consultas leem as somas e não as devolvem (`ReturnData: false`); a expressão as divide e devolve o
indicador como porcentagem.

```
ana@laptop:~/aws/slo$ aws cloudwatch get-metric-data --metric-data-queries file://math.json --start-time $(date -u -d '-30 min' +%FT%TZ) --end-time $(date -u +%FT%TZ) --query 'MetricDataResults[].[Id,Label,length(Values)]' --output text
sli	availability, %	0
```

**Zero valores**: o moto aceita a expressão e não calcula nada. Na AWS, essa consulta devolve um número
de disponibilidade a cada cinco minutos, e um alarme pode usar as mesmas três linhas: o alarme de taxa
de queima da seção anterior são dois desses alarmes, um por janela, cada um na expressão
`(errors / requests) / 0.001`, unidos por um alarme composto com `AND` (lição 10).

## Trinta dias de minutos não existem

Um objetivo de 30 dias precisa de 30 dias de contagens. A tabela de retenção da lição 8 diz que dados
de um minuto duram 15 dias e de cinco minutos, 63, então **um SLI móvel de 30 dias é calculado com somas
de cinco minutos**, ou com uma cópia das contagens guardada em outro lugar por mais tempo. Equipes que
relatam SLOs por um ano exportam os totais diários, alguns números por serviço por dia, para uma tabela
própria.

## Application Signals

O CloudWatch também oferece SLOs como recurso, no **Application Signals**: um objetivo definido sobre a
latência ou a disponibilidade de um serviço, com o orçamento e a taxa de queima calculados e desenhados
pela AWS, e alarmes sobre eles. Poupa montar a matemática à mão e é cobrado à parte; o moto não o
implementa, então não foi executado aqui. A aritmética por baixo é a desta lição, e é ela que torna os
números dele legíveis.

## O que mostrar, e para quem

| público | do que precisa |
|---|---|
| a equipe de plantão | alertas de taxa de queima em duas janelas, nada mais chama |
| o planejamento da equipe | o orçamento restante no mês, e o que o gastou |
| o negócio | o objetivo, cumprido ou não, mês a mês |

Um painel de SLO que mostra o orçamento restante como um número só, com os incidentes que o gastaram
listados ao lado, é o que muda decisões.
