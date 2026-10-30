---
title: Uma regra que dá para ler: hoje contra o usual
version: 1
---

**A verificação diária da loja compara cada dia com a mediana dos catorze dias anteriores**, e marca um dia mais de 5% acima. A mediana, e
não a média, para um dia estranho não mexer na linha de base. Catorze dias, para um padrão semanal caber na janela. E 5%, porque o ruído
diário da loja é uma fração disso, como mostram os oito primeiros dias de outubro.

```kql
// usual.kql: each day against the median of the fourteen days before it
let daily = CostDaily | summarize cost = sum(Cost) by Date;
daily
| extend k = 1
| join kind=inner (daily | project before = Date, earlier = cost | extend k = 1) on k
| where before between ((Date - 14d) .. (Date - 1d))
| summarize cost = take_any(cost), usual = percentile(earlier, 50) by Date
| extend ratio = round(cost / usual, 3)
| where Date >= datetime(2026-10-05)
| project Date, cost = round(cost, 2), usual = round(usual, 2), ratio, flag = ratio > 1.05
| order by Date asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < usual.kql
Date                  cost   usual  ratio  flag
2026-10-05T00:00:00Z  82.41  82.04  1.005  False
2026-10-06T00:00:00Z  82.47  82.07  1.005  False
2026-10-07T00:00:00Z  82.12  82.38  0.997  False
2026-10-08T00:00:00Z  82.96  82.38  1.007  False
2026-10-09T00:00:00Z  91.73  82.38  1.113  True
2026-10-10T00:00:00Z  91.25  82.41  1.107  True
2026-10-11T00:00:00Z  91.16  82.47  1.105  True
2026-10-12T00:00:00Z  90.57  82.47  1.098  True
2026-10-13T00:00:00Z  91.1   82.82  1.1    True
2026-10-14T00:00:00Z  91.51  82.89  1.104  True
2026-10-15T00:00:00Z  90.34  82.96  1.089  True
2026-10-16T00:00:00Z  91.33  83.47  1.094  True
2026-10-17T00:00:00Z  91.09  90.34  1.008  False
2026-10-18T00:00:00Z  91.21  90.57  1.007  False
```

O join junta cada dia a todos os outros, e o `where` fica com os catorze anteriores, o padrão de chave constante das lições 14 e 22. **A
regra marca o dia 9, o primeiro dia do degrau**, e todo dia depois dele por uma semana, cerca de 10% acima do usual.

E então, no dia 17, ela para. Não porque algo foi consertado: porque a essa altura a mediana de catorze dias tem oito dos dias caros dentro
dela, e **o nível novo virou o usual.** Essa é a linha mais importante da saída desta lição. Um alerta sobre mudança de custo tem uma
janela em que significa algo, e a janela é mais ou menos do tamanho da sua linha de base. Uma equipe que deixa a marca parada uma semana
aceitou o custo novo sem decidir isso.

Então a verificação da loja roda toda manhã, como um alerta de pesquisa de log do tipo da lição 12 sobre a exportação de custos no
workspace, e a notificação vai para a equipe dona do medidor que se mexeu, que é a pergunta da última seção.
