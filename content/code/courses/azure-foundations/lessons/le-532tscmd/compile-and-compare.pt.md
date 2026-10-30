---
title: O que cada porta confere antes de bater
version: 1
---

**As duas ferramentas declarativas fazem a sua conferência no seu computador, e param na mesma linha: o
momento em que precisam saber o que existe no Azure.** Esta seção leva os dois arquivos da seção
anterior até onde o laboratório vai, e depois um passo além, para ver cada um parar.

## Bicep: compilar, e voltar

A partir de `~/azure/doors`:

```
ana@laptop:~/azure/doors$ az bicep build --file main.bicep && jq -c '.resources[] | {type, apiVersion, name}' main.json
{"type":"Microsoft.Network/virtualNetworks","apiVersion":"2024-05-01","name":"vnet-shop-prod"}
```

O template é o JSON ARM que o link *baixar um template* do portal produz, e é isso que faz as duas
portas se encontrarem: **um template pode ser descompilado de volta para Bicep**. Para ver o que
sobrevive à viagem, tire a parte do template que diz que o Bicep o fez, já que um template exportado do
portal não a teria, e descompile isso:

```
ana@laptop:~/azure/doors$ jq 'del(.metadata)' main.json > exported.json && az bicep decompile --file exported.json
WARNING: WARNING: Decompilation is a best-effort process, as there is no guaranteed mapping from ARM JSON to Bicep Template or Bicep Parameters.
You may need to fix warnings and errors in the generated bicep/bicepparam file(s), or decompilation may fail entirely if an accurate conversion is not possible.
If you would like to report any issues or inaccurate conversions, please see https://github.com/Azure/bicep/issues.

ana@laptop:~/azure/doors$ diff main.bicep exported.bicep
3c3
< resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
---
> resource vnet_shop_prod 'Microsoft.Network/virtualNetworks@2024-05-01' = {
23c23
< output vnetId string = vnet.id
---
> output vnetId string = vnet_shop_prod.id
```

O aviso é justo, e o `diff` diz o quanto: **tudo voltou, menos o nome simbólico**. `vnet`, o nome que o
arquivo usa para se referir ao recurso, não existe no JSON, então o descompilador inventou um a partir
do nome do próprio recurso. Num template de uma exportação real do portal o resultado precisa de mais
arrumação, com valores fixos onde deviam estar parâmetros e propriedades que o Azure preencheu e que
ninguém escolheu. É um ponto de partida, que é tudo o que a Microsoft promete.

O Bicep também conhece as propriedades de cada tipo. Dê ao espaço de endereços um texto onde a API quer
uma lista, salvo como `typo.bicep`:

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-shop-prod'
  location: 'brazilsouth'
  properties: {
    addressSpace: {
      addressPrefixes: '10.20.0.0/16'
    }
  }
}
```

```
ana@laptop:~/azure/doors$ az bicep build --file typo.bicep --stdout > /dev/null
WARNING: /home/ana/azure/doors/typo.bicep(6,24) : Warning BCP036: The property "addressPrefixes" expected a value of type "null | string[]" but the provided value is of type "'10.20.0.0/16'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

`BCP036`, com a linha e a coluna, o tipo que ele esperava e o que recebeu. **É um aviso, e o arquivo
compilou mesmo assim**, porque as definições de tipo do Bicep são geradas a partir das descrições de API
da Microsoft e às vezes estão erradas; a própria mensagem diz para relatar se for o caso. Trate como
erro mesmo assim: o pedido que ele produziria é um que o Resource Manager recusa.

## Terraform: validar, e o grafo

A partir de `~/azure/doors/tf`:

```
ana@laptop:~/azure/doors/tf$ terraform init -input=false
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/doors/tf$ terraform validate
Success! The configuration is valid.

ana@laptop:~/azure/doors/tf$ terraform fmt -check
ana@laptop:~/azure/doors/tf$ terraform graph
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "azurerm_resource_group.prod" [label="azurerm_resource_group.prod"];
  "azurerm_subnet.app" [label="azurerm_subnet.app"];
  "azurerm_virtual_network.prod" [label="azurerm_virtual_network.prod"];
  "azurerm_subnet.app" -> "azurerm_virtual_network.prod";
  "azurerm_virtual_network.prod" -> "azurerm_resource_group.prod";
}
```

O `init` baixou o provider de novo, embora a lição 2 tenha buscado a mesma versão: **um diretório sem
arquivo de trava não confia no cache**, e o Terraform só tira um provider de lá quando o
`.terraform.lock.hcl` já registra o checksum desse provider. Esse arquivo é o que o `init` acabou de
criar; guarde-o ao lado da configuração, e todo `init` seguinte pega a cópia do cache. O `validate`
conferiu cada bloco contra o esquema do provider, e o `terraform fmt -check` não imprimiu nada, que é o
jeito dele de dizer que o arquivo está arrumado como o Terraform arruma. **O grafo é o que o Terraform
vai fazer com os três recursos**: a sub-rede depende da rede e a rede do grupo, lido das referências
entre eles, exatamente como o Resource Manager ordenou a rede e a sub-rede da lição 25 pelo `dependsOn`.

## O passo que nenhum dos dois consegue dar aqui

As duas ferramentas têm um comando que compara o arquivo com o que existe e diz o que mudaria, e as duas
precisam do Resource Manager para isso:

```
ana@laptop:~/azure/doors/tf$ terraform plan -input=false

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: unable to build authorizer for Resource Manager API: could not configure AzureCli Authorizer: tenant ID was not specified and the default tenant ID could not be determined: obtaining tenant ID: obtaining account details: running Azure CLI: exit status 1: ERROR: Please run 'az login' to setup account.
│ 
│   with provider["registry.terraform.io/hashicorp/azurerm"],
│   on main.tf line 10, in provider "azurerm":
│   10: provider "azurerm" {
│ 
╵
ana@laptop:~/azure/doors/tf$ az deployment group what-if --resource-group rg-shop-prod --template-file ../main.bicep
ERROR: Please run 'az login' to setup account.
```

O `terraform plan` pediu uma identidade à CLI do Azure, como na lição 2, e parou. **O `what-if` é o
equivalente do Bicep**: o `az deployment group what-if` manda o template ao Resource Manager, que avalia
cada expressão contra a assinatura real e responde com cada recurso marcado para ser criado,
modificado, apagado ou deixado como está, propriedade por propriedade. Ele foi recusado no mesmo lugar.
**Numa assinatura de verdade, este é o comando mais importante das duas ferramentas**, porque é o último
momento em que um erro não custa nada. Leia a saída dele antes de toda implantação, do jeito que você lê
um `diff` antes de um commit.
