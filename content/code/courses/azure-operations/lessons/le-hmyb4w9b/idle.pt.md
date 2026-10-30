---
title: Recursos ociosos, achados por uma consulta
version: 1
---

**Um recurso ocioso custa dinheiro e não serve a nada**, e os três mais comuns são sempre os mesmos: um disco gerenciado deixado para
trás quando a VM dele foi apagada, um endereço IP público associado a nada, e um plano do App Service sem nenhum app. Cada um é cobrado
por hora, e nenhum aparece no painel de ninguém.

O lugar para achá-los no Azure é o **Azure Resource Graph**, um serviço que responde consultas KQL sobre todo recurso das assinaturas
que você pode ler, numa tabela chamada `Resources`. São dados do plano de controle, então o laboratório não consegue consultá-lo; o que
o laboratório consegue é rodar a mesma KQL contra uma tabela do mesmo formato. Doze recursos da loja, escritos pelo curso, em
`inventory.kql`:

```kql
// inventory.kql: the subscription's resources, in the shape of Azure Resource Graph's Resources table
.set-or-replace Resources <|
datatable(name: string, type: string, resourceGroup: string, location: string, sku: string, tags: dynamic, properties: dynamic) [
    "app-shop-api", "microsoft.web/sites", "rg-shop", "brazilsouth", "", dynamic({"team": "shop", "env": "prod"}), dynamic({"serverFarm": "asp-shop-prod"}),
    "asp-shop-prod", "microsoft.web/serverfarms", "rg-shop", "brazilsouth", "P1v3", dynamic({"team": "shop", "env": "prod"}), dynamic({"numberOfSites": 1}),
    "asp-shop-old", "microsoft.web/serverfarms", "rg-shop", "brazilsouth", "P1v3", dynamic({"team": "shop"}), dynamic({"numberOfSites": 0}),
    "vm-shop-batch", "microsoft.compute/virtualmachines", "rg-shop-workers", "brazilsouth", "Standard_D8s_v5", dynamic({"team": "exports", "env": "prod"}), dynamic({"powerState": "running"}),
    "vm-reports", "microsoft.compute/virtualmachines", "rg-reports", "brazilsouth", "Standard_D4s_v5", dynamic({}), dynamic({"powerState": "running"}),
    "vm-reports-os", "microsoft.compute/disks", "rg-reports", "brazilsouth", "Premium_LRS", dynamic({}), dynamic({"diskState": "Attached", "diskSizeGB": 128}),
    "disk-old-1", "microsoft.compute/disks", "rg-test-ana", "brazilsouth", "Premium_LRS", dynamic({}), dynamic({"diskState": "Unattached", "diskSizeGB": 256}),
    "disk-old-2", "microsoft.compute/disks", "rg-test-ana", "brazilsouth", "Standard_LRS", dynamic({}), dynamic({"diskState": "Unattached", "diskSizeGB": 512}),
    "pip-test", "microsoft.network/publicipaddresses", "rg-test-ana", "brazilsouth", "Standard", dynamic({}), dynamic({"ipConfiguration": ""}),
    "pip-nat-shop", "microsoft.network/publicipaddresses", "rg-shop", "brazilsouth", "Standard", dynamic({"team": "shop"}), dynamic({"ipConfiguration": "nat-shop"}),
    "sql-shop", "microsoft.sql/servers", "rg-shop", "brazilsouth", "", dynamic({"team": "shop", "env": "prod"}), dynamic({}),
    "stshopexports", "microsoft.storage/storageaccounts", "rg-shop", "brazilsouth", "Standard_ZRS", dynamic({"team": "shop", "env": "prod"}), dynamic({})
]
```

A consulta, que rodaria sem mudança contra o Resource Graph:

```kql
// idle.kql: resources that cost money and serve nothing
Resources
| where (type == "microsoft.compute/disks" and properties.diskState == "Unattached")
     or (type == "microsoft.network/publicipaddresses" and isempty(tostring(properties.ipConfiguration)))
     or (type == "microsoft.web/serverfarms" and toint(properties.numberOfSites) == 0)
| project name, type, resourceGroup, sku, owner = tostring(tags.team)
```

```
ana@laptop:~/azure/kusto$ python3 kql.py < idle.kql
name          type                                 resourceGroup  sku           owner
asp-shop-old  microsoft.web/serverfarms            rg-shop        P1v3          shop
disk-old-1    microsoft.compute/disks              rg-test-ana    Premium_LRS
disk-old-2    microsoft.compute/disks              rg-test-ana    Standard_LRS
pip-test      microsoft.network/publicipaddresses  rg-test-ana    Standard
```

Quatro recursos ociosos: dois discos desanexados e um IP público sem uso, todos em `rg-test-ana`, e um plano do App Service sem sites,
`asp-shop-old`. A coluna `owner` é a tag `team`, e está vazia em três deles, que é o assunto da lição 24: um recurso ocioso sem dono é
um sobre o qual ninguém nunca vai ser perguntado.

Contra uma assinatura real, a mesma pergunta passa pela linha de comando, **não executada** aqui porque o Resource Graph precisa de uma
identidade logada:

```sh
az graph query -q "Resources | where type == 'microsoft.compute/disks' and properties.diskState == 'Unattached' | project name, resourceGroup, sku = sku.name"
```

O Resource Graph usa nomes de tipo em minúsculas e oferece o `type =~`, a comparação que ignora maiúsculas, para quando você não tem
certeza; a tabela gerada os guarda em minúsculas, como o Resource Graph.
