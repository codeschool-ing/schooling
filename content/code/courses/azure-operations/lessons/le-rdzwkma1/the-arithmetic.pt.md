---
title: A conta, em quatro tamanhos
version: 1
---

**O compromisso mais barato se acha pondo preço em alguns tamanhos contra as horas reais, e não por regra de bolso.** Com uma taxa
**ilustrativa** de pagamento conforme o uso de 0,25 USD por instância-hora e uma taxa de reserva de 1 ano de 0,16, um desconto de
36%, o mês custa:

```kql
// commit.kql: a month of the workers at three commitment sizes, with illustrative rates
let payg = 0.25;          // USD per instance-hour, pay as you go (illustrative)
let reserved = 0.16;      // USD per instance-hour under a 1-year reservation (illustrative)
WorkerHours
| extend k = 1
| join kind=inner (datatable(committed: int) [0, 2, 3, 4] | extend k = 1) on k
| extend covered = min_of(Instances, committed), uncovered = max_of(Instances - committed, 0)
| summarize used_reserved_hours = sum(covered), payg_hours = sum(uncovered), hours = count() by committed
| extend cost = round(committed * hours * reserved + payg_hours * payg, 2),
         unused_pct = round(100.0 * (committed * hours - used_reserved_hours) / max_of(committed * hours, 1), 1)
| project committed, cost, unused_pct
| order by committed asc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < commit.kql
committed  cost   unused_pct
0          517.0  0.0
2          387.4  0.0
3          442.6  22.2
4          497.8  33.3
```

A consulta junta cada hora a quatro tamanhos candidatos, usando o join com chave constante da lição 14. Para cada tamanho, as
instâncias comprometidas são pagas toda hora, rodem ou não, e o que passar delas é pago à taxa de uso. `unused_pct` é a fração das
horas comprometidas que não tinham nada a cobrir.

**Comprometer-se com o piso, 2, é o mês mais barato: 387,40 USD contra 517,00, um quarto a menos**, e nada da reserva é
desperdiçado. Comprometer-se com 3 custa mais que com 2, mesmo com mais do uso do mês com desconto, porque a terceira instância
reservada fica ociosa em 480 horas. Em 4 a conta quase volta ao pagamento conforme o uso, com um terço da reserva sem uso.

A forma geral vale sejam quais forem os preços reais: **a economia cresce conforme o compromisso sobe até o piso, e cai depois
dele**, mais rápido quanto maior o desconto. Um savings plan muda a conta só porque o compromisso dele é em dólares por hora e não
em instâncias, e por isso ele serve a uma mistura de serviços que se move entre eles. A ordem da loja é: reservar o piso das VMs
estáveis, cobrir o resto do gasto estável de computação com um savings plan, e deixar os picos no pagamento conforme o uso, que é
para isso que ele existe.
