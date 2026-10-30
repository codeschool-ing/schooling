---
title: A exportação de custos, como tabela
version: 1
---

**O Cost Management consegue exportar a conta, todo dia, como arquivos numa conta de armazenamento**, uma linha por recurso por medidor
por dia, com as tags do recurso numa coluna. Essa exportação é o que transforma a conta em dados: uma equipe pode carregá-la num
workspace ou num data warehouse e consultá-la como qualquer outra tabela. Criar a exportação exige um escopo de cobrança e uma conta de
armazenamento, então **isso não foi feito aqui**; o que o curso faz no lugar é gerar sessenta dias num formato simplificado dela, com
custos diários redondos e ilustrativos, em `cost.kql`:

```kql
// cost.kql: sixty days of the subscription's daily cost per resource, in the shape of a cost export
.set-or-replace CostDaily <|
let resources = datatable(ResourceName: string, ResourceGroup: string, MeterCategory: string, Daily: real, Tags: dynamic) [
    "asp-shop-prod", "rg-shop", "Azure App Service", 12.0, dynamic({"team": "shop", "env": "prod"}),
    "sql-shop", "rg-shop", "SQL Database", 15.0, dynamic({"team": "shop", "env": "prod"}),
    "log-shop", "rg-shop", "Log Analytics", 4.0, dynamic({"team": "shop", "env": "prod"}),
    "fd-shop", "rg-shop", "Azure Front Door", 11.0, dynamic({"team": "shop", "env": "prod"}),
    "kv-shop-prod", "rg-shop", "Key Vault", 0.3, dynamic({"team": "shop", "env": "prod"}),
    "stshopexports", "rg-shop", "Storage", 1.1, dynamic({"team": "shop", "env": "prod"}),
    "asp-shop-old", "rg-shop", "Azure App Service", 6.0, dynamic({"team": "shop"}),
    "vm-shop-batch", "rg-shop-workers", "Virtual Machines", 9.6, dynamic({"team": "exports", "env": "prod"}),
    "vmss-shop-workers", "rg-shop-workers", "Virtual Machines", 16.5, dynamic({"team": "exports", "env": "prod"}),
    "vm-reports", "rg-reports", "Virtual Machines", 4.8, dynamic({}),
    "disk-old-1", "rg-test-ana", "Storage", 1.3, dynamic({}),
    "disk-old-2", "rg-test-ana", "Storage", 0.7, dynamic({}),
    "pip-test", "rg-test-ana", "Virtual Network", 0.12, dynamic({}),
    "sttfstate", "rg-tfstate", "Storage", 0.05, dynamic({"team": "platform"})
];
range Date from datetime(2026-08-20) to datetime(2026-10-18) step 1d
| extend k = 1
| join kind=inner (resources | extend k = 1) on k
| extend spike = iff(ResourceName == "log-shop" and Date >= datetime(2026-10-09), 3.2, 1.0)
| extend Cost = round(Daily * spike * (0.97 + abs(hash(strcat(ResourceName, Date), 7)) / 100.0), 2)
| project Date, ResourceName, ResourceGroup, MeterCategory, Cost, Tags
```

Catorze recursos: os da loja, os dos workers de exportação, a VM de relatórios e as sobras de `rg-test-ana` que a lição 23 achou. A
partir de 9 de outubro o workspace do Log Analytics custa um pouco mais que o triplo, por um motivo que a lição 25 investiga. Uma
exportação real tem muito mais colunas, entre elas o medidor, o preço unitário, a quantidade e a moeda de cobrança; o curso fica com as
que usa.

Carregue, e agrupe os últimos trinta dias pela tag `team`:

```
ana@laptop:~/azure/kusto$ python3 kql.py 'CostDaily | where Date >= datetime(2026-09-19) | summarize cost = round(sum(Cost), 2) by team = tostring(Tags.team) | order by cost desc'
team      cost
shop      1565.4
exports   782.08
          207.92
platform  1.5
```

`tostring(Tags.team)` lê a tag da coluna dinâmica; um recurso sem tag `team` dá uma string vazia, que é a linha sem nome. **Essa linha é
cerca de oito por cento do mês**, 208 USD, muito mais que a da equipe de plataforma e cerca de um quarto do que a equipe de
exportação gasta. A
próxima seção pergunta o que tem dentro dela.
