---
title: O custo diário, e o que o detector embutido achou dele
version: 1
---

**A conta é uma série temporal, um ponto por dia, e uma série temporal pode ser observada.** Carregue o `cost.kql` da lição 24 de novo se
o emulador reiniciou, e olhe outubro:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'CostDaily | where Date >= datetime(2026-10-01) | summarize cost = round(sum(Cost), 2) by Date | order by Date asc'
Date                  cost
2026-10-01T00:00:00Z  82.04
2026-10-02T00:00:00Z  82.89
2026-10-03T00:00:00Z  82.04
2026-10-04T00:00:00Z  83.47
2026-10-05T00:00:00Z  82.41
2026-10-06T00:00:00Z  82.47
2026-10-07T00:00:00Z  82.12
2026-10-08T00:00:00Z  82.96
2026-10-09T00:00:00Z  91.73
2026-10-10T00:00:00Z  91.25
2026-10-11T00:00:00Z  91.16
2026-10-12T00:00:00Z  90.57
2026-10-13T00:00:00Z  91.1
2026-10-14T00:00:00Z  91.51
2026-10-15T00:00:00Z  90.34
2026-10-16T00:00:00Z  91.33
2026-10-17T00:00:00Z  91.09
2026-10-18T00:00:00Z  91.21
```

Quem lê enxerga na hora: cerca de 82 USD por dia até o dia 8, e cerca de 91 a partir do dia 9, todo dia desde então. Um degrau, não um
pico: algo mudou no dia 9 e custa nove dólares a mais por dia desde então.

O KQL tem uma função feita para esse tipo de pergunta, `series_decompose_anomalies()`, que separa uma série numa linha de base, numa parte
sazonal e num resíduo, e marca os dias cujo resíduo é incomum. Rodada sobre os sessenta dias:

```kql
// anomalies.kql: the daily total as a series, and the days the engine calls anomalous
CostDaily
| make-series cost = sum(Cost) default = 0 on Date from datetime(2026-08-20) to datetime(2026-10-19) step 1d
| extend (flag, score, expected) = series_decompose_anomalies(cost, 2.5)
| mv-expand Date to typeof(datetime), cost to typeof(real), flag to typeof(int), score to typeof(real), expected to typeof(real)
| where flag != 0
| project Date, cost = round(cost, 2), expected = round(expected, 2), score = round(score, 1)
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < anomalies.kql
Date  cost  expected  score
```

**Ela não marcou nada.** É um resultado real, que vale mais do que um arrumado. O `make-series` montou a série diária, a função pontuou
todo dia, e nenhum passou do limite de 2,5; as pontuações do dia 9 em diante ficaram abaixo de 0,2 quando o curso as olhou. A função julga
cada dia contra a decomposição da própria série, e aqui o nível mais alto foi absorvido por ela em vez de destacado. Um detector é tão bom
quanto a forma de mudança que ele foi feito para ver, e a forma aqui é um degrau que se mantém.

O Cost Management oferece **alertas de anomalia** numa assinatura, que rodam o modelo da própria Microsoft sobre o custo diário e mandam
e-mail quando acham algo. Eles não foram executados aqui, e merecem o mesmo teste antes de você confiar neles: eles marcam a mudança que
importa para você, nos seus dados?
