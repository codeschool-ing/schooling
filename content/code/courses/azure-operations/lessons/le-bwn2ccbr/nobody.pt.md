---
title: O recurso que não tem dono
version: 1
---

**Gasto sem tag é onde o desperdício se esconde, porque ninguém é perguntado sobre ele.** Os trinta dias da loja, por recurso:

```kql
// nobody.kql: thirty days of spend with no team tag, by resource
CostDaily
| where Date >= datetime(2026-09-19)
| where isempty(tostring(Tags.team))
| summarize cost = round(sum(Cost), 2) by ResourceGroup, ResourceName, MeterCategory
| order by cost desc
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < nobody.kql
ResourceGroup  ResourceName  MeterCategory     cost
rg-reports     vm-reports    Virtual Machines  144.27
rg-test-ana    disk-old-1    Storage           39.09
rg-test-ana    disk-old-2    Storage           20.96
rg-test-ana    pip-test      Virtual Network   3.6
```

Quatro recursos e dois grupos. A `vm-reports` é a VM de fim de mês da lição 23, real e necessária, e simplesmente nunca recebeu tag; a
correção é uma tag, `team: finance`, depois que a dona disse de quem era. Todo o resto é `rg-test-ana`, o grupo de teste que a lição 23
achou ocioso: dois discos e um IP público, ainda cobrados todo dia um mês depois de alguém usá-los. A fração como um número só:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'CostDaily | where Date >= datetime(2026-09-19) | summarize total = sum(Cost), untagged = sumif(Cost, isempty(tostring(Tags.team))) | extend untagged_pct = round(100.0 * untagged / total, 1), total = round(total, 2), untagged = round(untagged, 2)'
total   untagged  untagged_pct
2556.9  207.92    8.1
```

Oito por cento do mês não pertence a ninguém. Esse número é o que a loja acompanha, todo mês, e a meta dele não é zero, que
nenhuma organização alcança, mas **para baixo**: todo mês a fração sem tag deveria ser menor, e todo recurso nela deveria ter sido
perguntado.

As políticas de tag da primeira seção impedem novos grupos sem tag, que é a origem do problema. O `rg-test-ana` é anterior a elas, e por
isso está aqui: uma política muda o futuro, e uma consulta como esta é como o passado é achado.
