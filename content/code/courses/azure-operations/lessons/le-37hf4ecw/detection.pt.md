---
title: Detecção, e as três durações que descrevem um incidente
version: 1
---

**Um incidente é descrito por quando começou, quando alguém soube e quando parou de doer.** O começo está nos logs de
requisição; o saber está no canal do incidente, que as próximas seções carregam como tabela. As três durações entre esses
momentos são as que uma equipe acompanha ao longo do tempo:

```kql
// measures.kql: when it started, when somebody knew, when it stopped
let started = toscalar(AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize min(TimeGenerated));
let ended = toscalar(AppRequests | where Name == "POST /checkout" and not(Success) and DurationMs > 2000 | summarize max(TimeGenerated));
let paged = toscalar(IncidentLog | where Who == "pager" | summarize min(TimeGenerated));
let fixed = toscalar(IncidentLog | where What startswith "scaled" | summarize min(TimeGenerated));
print to_detect = paged - started, to_mitigate = fixed - started, customers_affected_for = ended - started
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < measures.kql
to_detect  to_mitigate  customers_affected_for
00:09:48   00:38:48     00:41:16
```

**Dez minutos para detectar, 39 para mitigar, 41 minutos de clientes afetados.** A primeira é o alerta das lições 12 e 14
fazendo o seu trabalho: a regra de taxa de queima chamou às 17:15 UTC. Dez minutos não é ruim, e também não é de graça:
uns 25 checkouts falharam antes de alguém saber. A segunda é a que esta lição consegue encurtar, porque a maior parte
daqueles 39 minutos foi gasta descobrindo o que tinha mudado.

A detecção deveria vir dos alertas, e um bom teste de um conjunto de alertas é perguntar, depois de todo incidente, **quem
percebeu primeiro**. Se a resposta for um cliente, um chamado no suporte ou um colega num chat, então falta um alerta, ou
existe um e ninguém confia nele. Na quinta o pager veio primeiro, que é a resposta que se quer.

`print` avalia expressões sem tabela nenhuma, e subtrair dois datetimes dá um **timespan**, impresso em horas, minutos e
segundos. O `toscalar()` é o da lição 11: um valor, saído de uma consulta, num nome.
