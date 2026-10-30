---
title: Hub e spoke, escrito dos dois lados
version: 1
---

**Uma rede hub-and-spoke põe o que toda rede divide numa rede só, o hub, e faz peering da rede de cada
carga de trabalho, uma spoke, com ele e com mais nada.** O hub da loja é a `vnet-shop-hub`,
`10.0.0.0/16`, na assinatura `shop-shared`, e guarda as coisas de que deve haver uma só:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l20-hub\" aria-label=\"O hub e as spokes da loja. O hub vnet-shop-hub, 10.0.0.0/16 em shop-shared, guarda três sub-redes: AzureFirewallSubnet com o firewall, GatewaySubnet com o gateway para o escritório, e uma sub-rede para o DNS. O escritório, 192.168.0.0/16, se liga ao gateway. Duas spokes, vnet-shop-prod e vnet-shop-staging, têm peering com o hub; o tráfego de uma spoke para a outra sobe até o firewall e desce de novo.\"><defs><marker id=\"l20-hub-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-hub-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M190 20 H530 V170 H190 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"206.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-hub</text><text x=\"514.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.0.0/16</text><rect x=\"206.0\" y=\"60.0\" width=\"98.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">AzureFirewallSubnet</text><text x=\"255.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">firewall</text><rect x=\"316.0\" y=\"60.0\" width=\"98.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">snet-dns</text><text x=\"365.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resolvedor DNS</text><rect x=\"426.0\" y=\"60.0\" width=\"98.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">GatewaySubnet</text><text x=\"475.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">gateway</text><rect x=\"560.0\" y=\"60.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"630.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o escritório</text><text x=\"630.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><path d=\"M559.0 92.0 L531.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-paper-dim)\" marker-start=\"url(#l20-hub-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"230.0\" width=\"200.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"140.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><text x=\"140.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-prod</text><rect x=\"480.0\" y=\"230.0\" width=\"200.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-staging</text><text x=\"580.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.0.0/16</text><text x=\"580.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-staging</text><path d=\"M140.0 229.0 L140.0 200.0 L250.0 200.0 L250.0 171.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-amber)\"></path><path d=\"M270.0 171.0 L270.0 196.0 L590.0 196.0 L590.0 229.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-amber)\"></path><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">de spoke para spoke: sobe até o firewall, e desce de novo</text></svg>", "caption": "Uma spoke é dona da sua carga e pega emprestado todo o resto do hub.", "same": ["firewall", "gateway", "shop-prod", "shop-staging"]}
```

- **o firewall**, numa sub-rede que precisa se chamar `AzureFirewallSubnet`, pelo qual passa o tráfego
  entre spokes e para a internet (lição 18);
- **o gateway** para o escritório, numa sub-rede que precisa se chamar `GatewaySubnet`, emprestado a
  toda spoke pelo gateway transit (lição 23);
- **o DNS**: as zonas privadas das lições 19 e 21, ligadas ao hub, e um resolvedor para o qual o
  escritório pode encaminhar;
- em alguns desenhos, o **Azure Bastion**, que dá aos administradores um shell nas máquinas das spokes
  sem endereço público em nenhuma delas.

Cada spoke é um ambiente numa assinatura: `vnet-shop-prod` em `shop-prod`, `vnet-shop-staging` em
`shop-staging`. **Uma spoke é dona da sua carga e pega emprestado todo o resto.** Acrescentar uma spoke
é um par de peerings e uma tabela de rotas, e a equipe de uma spoke pode implantar o dia todo sem tocar
em nada de que outra spoke dependa.

## Os dois lados, a partir de um arquivo

O peering entre a produção e o hub atravessa duas assinaturas, e as duas metades moram em cada uma
delas. Um arquivo Bicep implanta num escopo, mas um **módulo** pode mirar em outro, como o
`targetScope` da lição 2 antecipou. Salve a metade do hub como `hub-side.bicep` em `~/azure/peering`:

```bicep
param spokeId string

resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-hub'
}

resource toSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: hub
  name: 'peer-hub-to-prod'
  properties: {
    remoteVirtualNetwork: {
      id: spokeId
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
  }
}
```

e a metade da spoke, que a chama, como `peering.bicep`:

```bicep
@description('The subscription and group that hold the hub, in shop-shared.')
param hubSubscriptionId string = 'ddddeeee-3333-ffff-4444-aaaa5555bbbb'
param hubResourceGroup string = 'rg-shop-hub'

resource spoke 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-prod'
}

resource hub 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop-hub'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroup)
}

resource toHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-05-01' = {
  parent: spoke
  name: 'peer-prod-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hub.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    useRemoteGateways: true
  }
}

module toSpoke 'hub-side.bicep' = {
  name: 'peer-hub-to-prod'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroup)
  params: {
    spokeId: spoke.id
  }
}
```

```
ana@laptop:~/azure/peering$ az bicep build --file peering.bicep --stdout | jq -c '.resources[] | {type, name, subscription: .subscriptionId, group: .resourceGroup}'
{"type":"Microsoft.Network/virtualNetworks/virtualNetworkPeerings","name":"[format('{0}/{1}', 'vnet-shop-prod', 'peer-prod-to-hub')]","subscription":null,"group":null}
{"type":"Microsoft.Resources/deployments","name":"peer-hub-to-prod","subscription":"[parameters('hubSubscriptionId')]","group":"[parameters('hubResourceGroup')]"}
```

Saíram dois recursos. O primeiro é a metade da spoke no peering, no grupo para onde a implantação
mira, com `useRemoteGateways`. **O segundo nem é um peering: é uma implantação**,
`Microsoft.Resources/deployments`, com assinatura e grupo próprios. É nisso que um módulo mirado em
outro lugar compila: um template dentro do template, que o Resource Manager roda no `rg-shop-hub` da
`shop-shared` como uma segunda implantação. Um arquivo, duas assinaturas, e quem o roda precisa de
permissão nas duas, que é o acordo da primeira seção escrito como permissão.

A metade do hub leva o `allowGatewayTransit` e a da spoke o `useRemoteGateways`: o empréstimo e o
pegar emprestado. **Ligar os dois no mesmo lado é um erro que o compilador não pega**, porque cada um é
um booleano válido sozinho; o Azure o recusa quando chega. O mesmo vale para um hub ainda sem gateway:
uma spoke que pede para usar o gateway remoto é recusada até haver um.

## O mesmo par, em Terraform

O Terraform alcança duas assinaturas com duas cópias do provider, uma delas com um **alias**. Crie um
diretório para ele e salve isto como `main.tf`:

```sh
mkdir -p ~/azure/peering/tf && cd ~/azure/peering/tf
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
  subscription_id = "bbbbcccc-1111-dddd-2222-eeee3333ffff"
}

provider "azurerm" {
  alias = "shared"
  features {}
  subscription_id = "ddddeeee-3333-ffff-4444-aaaa5555bbbb"
}

locals {
  hub_id   = "/subscriptions/ddddeeee-3333-ffff-4444-aaaa5555bbbb/resourceGroups/rg-shop-hub/providers/Microsoft.Network/virtualNetworks/vnet-shop-hub"
  spoke_id = "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod"
}

resource "azurerm_virtual_network_peering" "prod_to_hub" {
  name                      = "peer-prod-to-hub"
  resource_group_name       = "rg-shop-prod"
  virtual_network_name      = "vnet-shop-prod"
  remote_virtual_network_id = local.hub_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
}

resource "azurerm_virtual_network_peering" "hub_to_prod" {
  provider                  = azurerm.shared
  name                      = "peer-hub-to-prod"
  resource_group_name       = "rg-shop-hub"
  virtual_network_name      = "vnet-shop-hub"
  remote_virtual_network_id = local.spoke_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}
```

```
ana@laptop:~/azure/peering/tf$ terraform init -input=false
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
ana@laptop:~/azure/peering/tf$ terraform validate
Success! The configuration is valid.
```

O `init` imprimiu o que imprimiu na lição 2, e o `validate` passou. Cada peering cita o provider que
alcança a sua assinatura: o da spoke usa o padrão, o do hub diz `provider = azurerm.shared`. As duas
cópias do provider do Terraform são também dois logins, ou uma identidade com papéis nas duas
assinaturas, que é o assunto da lição 9. O `validate` conferiu o formato; se as duas redes existem, se
os intervalos se sobrepõem, e se o hub tem um gateway para emprestar são todas perguntas para o Azure,
e **nenhum dos peerings foi criado**.
