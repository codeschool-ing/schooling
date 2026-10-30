---
title: A mesma rede, por três portas
version: 1
---

**Há três jeitos de fazer alguma coisa no Azure: clicar no portal, digitar numa linha de comando, ou
descrever num arquivo que uma ferramenta aplica. Parecem três produtos diferentes. São três clientes da
única API que a lição 25 abriu, e o que chega ao Resource Manager de cada um é o mesmo `PUT`.** O que
muda é tudo em volta desse pedido: se alguém consegue repeti-lo, revisá-lo, ou descobrir depois por que
a rede está do jeito que está.

Esta lição constrói uma coisa de três jeitos: a rede de produção da loja, `vnet-shop-prod`, com o
intervalo `10.20.0.0/16` e uma sub-rede, `snet-app`, no grupo `rg-shop-prod`. Crie o diretório dela:

```sh
mkdir -p ~/azure/doors && cd ~/azure/doors
```

## O portal

O portal é uma aplicação web que chama o Resource Manager com o seu token, um formulário de cada vez:
*Create a resource*, *Virtual network*, uma aba para o básico, uma aba para o espaço de endereços,
*Review + create*. **Nada dele foi executado para este curso**, que não tem conta e não desenha imitação
nenhuma das telas da Microsoft. Duas características dele importam aqui. Todo formulário de criação
termina com um link para **baixar um template para automação**, o JSON ARM do que você acabou de
preencher, que é a ponte da primeira porta para a terceira. E toda mudança feita ali vale na hora, sem
nada escrito em lugar nenhum além do Activity Log.

## A linha de comando

A CLI do Azure faz o mesmo em dois comandos, cada um um pedido:

```
ana@laptop:~/azure/doors$ az network vnet create --resource-group rg-shop-prod --name vnet-shop-prod --address-prefixes 10.20.0.0/16 --subnet-name snet-app --subnet-prefixes 10.20.2.0/24
ERROR: Please run 'az login' to setup account.
```

Essa é a linha que uma pessoa digita uma vez. Num script ela é **imperativa**: uma lista de passos,
rodados em ordem, cada um dizendo *faça isto agora*. Rode o script duas vezes e o segundo `create`
encontra uma rede que já existe. O que acontece então depende de como aquele comando foi escrito: alguns
mandam o mesmo `PUT` e sobrescrevem o que está lá, outros conferem antes e param. De um jeito ou de
outro, o script só está certo quando o mundo está no estado que ele supunha quando foi escrito. Um script
descreve um caminho, não um lugar.

## Um arquivo que descreve o resultado

O Bicep e o Terraform são **declarativos**: o arquivo diz o que deve existir quando eles terminarem, e a
ferramenta calcula os pedidos. Salve isto como `main.bicep`:

```bicep
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-shop-prod'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.20.2.0/24'
        }
      }
    ]
  }
}

output vnetId string = vnet.id
```

E a mesma rede para o Terraform, num diretório próprio, como `main.tf`:

```sh
mkdir -p ~/azure/doors/tf && cd ~/azure/doors/tf
```

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "prod" {
  name     = "rg-shop-prod"
  location = "brazilsouth"
}

resource "azurerm_virtual_network" "prod" {
  name                = "vnet-shop-prod"
  location            = azurerm_resource_group.prod.location
  resource_group_name = azurerm_resource_group.prod.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.prod.name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = ["10.20.2.0/24"]
}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l26-doors\" aria-label=\"Três portas para o Azure, da esquerda para a direita. O portal: você preenche formulários, e nada fica escrito. A linha de comando: você escreve os passos. Um arquivo declarativo, Bicep ou Terraform: você escreve o resultado, e a ferramenta calcula os passos. As três terminam no mesmo pedido PUT ao Resource Manager em management.azure.com, que cria vnet-shop-prod.\"><defs><marker id=\"l26-doors-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-doors-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"24.0\" width=\"200.0\" height=\"96.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">portal</text><text x=\"130.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você preenche formulários</text><text x=\"130.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nada fica escrito</text><path d=\"M130.0 121.0 L130.0 150.0 L302.5 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"24.0\" width=\"200.0\" height=\"96.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">linha de comando</text><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você escreve os passos</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">az network vnet create</text><path d=\"M360.0 121.0 L360.0 150.0 L360.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"24.0\" width=\"200.0\" height=\"96.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">um arquivo declarativo</text><text x=\"590.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">você escreve o resultado</text><text x=\"590.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main.bicep  main.tf</text><path d=\"M590.0 121.0 L590.0 150.0 L417.5 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"220.0\" y=\"180.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PUT .../virtualNetworks/vnet-shop-prod</text><path d=\"M360.0 225.0 L360.0 243.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-amber)\"></path><rect x=\"240.0\" y=\"244.0\" width=\"240.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Resource Manager</text></svg>", "caption": "Três jeitos de pedir, um pedido, uma API respondendo.", "same": ["Resource Manager", "portal"]}
```

**Os dois arquivos guardam os mesmos fatos, arrumados por dois fornecedores.** O arquivo Bicep mira num
grupo de recursos que precisa já existir, tira dele a localização, e escreve a sub-rede dentro da rede,
como a API da rede faz. O arquivo Terraform cria também o grupo, e faz da sub-rede um recurso à parte,
que o provider transforma num pedido separado. Nenhum dos dois diz *crie*: cada um diz *isto deve
existir*. Aplicados duas vezes, a segunda não acha nada para fazer.

| | portal | linha de comando | Bicep | Terraform |
|---|---|---|---|---|
| você escreve | nada | os passos | o resultado | o resultado |
| repetível | não | se o script for | sim | sim |
| revisado antes de rodar | não | como código, se estiver num repositório | como código | como código |
| sabe o que criou | não | não | o histórico de implantações do Resource Manager | o próprio arquivo de estado |
| chega a | Resource Manager | Resource Manager | Resource Manager | Resource Manager |
