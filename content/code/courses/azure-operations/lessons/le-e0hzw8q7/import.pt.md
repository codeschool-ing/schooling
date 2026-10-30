---
title: Quando não sobra cópia, importe o que existe
version: 1
---

**Sem cópia do estado em lugar nenhum, o estado é reconstruído a partir do Azure, um recurso por vez.** Nada se perdeu
no Azure, então todo recurso pode ser achado de novo, pelo id, e preso ao seu endereço na configuração. O Terraform faz
isso com **blocos `import`**, que dizem: o recurso neste endereço é o que tem este id.

```hcl
# imports.tf
import {
  to = azurerm_resource_group.shop
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shop"
}

import {
  to = azurerm_storage_account.shop
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-shop/providers/Microsoft.Storage/storageAccounts/stshopprod7x2k9q"
}
```

Os ids são ids do Resource Manager, o caminho longo que todo recurso do Azure tem, e achá-los é um
`az resource list -g rg-shop --query "[].id"` contra a assinatura real. Com os blocos no lugar, o `plan` mostra cada
recurso como **a importar**, e também toda propriedade em que a configuração e o recurso discordam. O primeiro plano
depois de uma perda é longo por isso, e cada discordância é uma decisão: mudar a configuração para bater com o que
existe, ou deixar o próximo `apply` mudar o recurso. Para um recurso sem configuração escrita nenhuma, o Terraform
consegue rascunhá-la:

```sh
terraform plan -generate-config-out=generated.tf
```

O arquivo gerado é um rascunho no mesmo sentido do Bicep descompilado da lição 4: ele descreve toda propriedade que o
recurso tem, os padrões incluídos, e precisa ser lido antes de ficar. Nada disto foi executado aqui, porque cada passo
precisa da assinatura real. Os arquivos em si são configuração comum: o id de assinatura neles é o marcador que a
própria documentação do Azure usa.

Dois avisos de quem já passou por isso. **Importe em lotes pequenos**, um grupo de recursos por vez, aplicando entre
um e outro, para um erro aparecer entre cinco recursos e não entre oitenta. E **cuidado com nomes gerados**: um recurso
cujo nome veio de `random_string` ou de `uniqueString` é o que você mais provavelmente duplicou antes de perceber que o
estado sumiu, e a duplicata tem de ser achada e apagada à mão.
