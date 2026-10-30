---
title: Hub and spoke, written on both sides
version: 1
---

**A hub-and-spoke network puts what every network shares in one network, the hub, and peers each
workload's network, a spoke, to it and to nothing else.** The shop's hub is `vnet-shop-hub`,
`10.0.0.0/16`, in the subscription `shop-shared`, and it holds the things there should be one of:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l20-hub\" aria-label=\"The shop's hub and spokes. The hub vnet-shop-hub, 10.0.0.0/16 in shop-shared, holds three subnets: AzureFirewallSubnet with the firewall, GatewaySubnet with the gateway to the office, and a subnet for DNS. The office, 192.168.0.0/16, connects to the gateway. Two spokes, vnet-shop-prod and vnet-shop-staging, are peered to the hub; traffic from one spoke to the other goes up to the firewall and down again.\"><defs><marker id=\"l20-hub-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-hub-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M190 20 H530 V170 H190 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"206.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-hub</text><text x=\"514.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.0.0.0/16</text><rect x=\"206.0\" y=\"60.0\" width=\"98.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">AzureFirewallSubnet</text><text x=\"255.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">firewall</text><rect x=\"316.0\" y=\"60.0\" width=\"98.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">snet-dns</text><text x=\"365.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">DNS resolver</text><rect x=\"426.0\" y=\"60.0\" width=\"98.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"475.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">GatewaySubnet</text><text x=\"475.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">gateway</text><rect x=\"560.0\" y=\"60.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"630.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the office</text><text x=\"630.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">192.168.0.0/16</text><path d=\"M559.0 92.0 L531.0 105.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-paper-dim)\" marker-start=\"url(#l20-hub-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"230.0\" width=\"200.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"140.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.0.0/16</text><text x=\"140.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-prod</text><rect x=\"480.0\" y=\"230.0\" width=\"200.0\" height=\"72.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">vnet-shop-staging</text><text x=\"580.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.30.0.0/16</text><text x=\"580.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-staging</text><path d=\"M140.0 229.0 L140.0 200.0 L250.0 200.0 L250.0 171.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-amber)\"></path><path d=\"M270.0 171.0 L270.0 196.0 L590.0 196.0 L590.0 229.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l20-hub-af-ah-amber)\"></path><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">spoke to spoke: up to the firewall, and down again</text></svg>", "caption": "A spoke owns its workload and borrows everything else from the hub."}
```

- **the firewall**, in a subnet that must be called `AzureFirewallSubnet`, through which traffic
  between spokes and out to the internet passes (lesson 18);
- **the gateway** to the office, in a subnet that must be called `GatewaySubnet`, lent to every
  spoke by gateway transit (lesson 23);
- **the DNS**: the private zones of lessons 19 and 21, linked to the hub, and a resolver the office
  can forward to;
- in some designs, **Azure Bastion**, which gives administrators a shell on machines in the spokes
  without a public address on any of them.

Each spoke is one environment in one subscription: `vnet-shop-prod` in `shop-prod`,
`vnet-shop-staging` in `shop-staging`. **A spoke owns its workload and borrows everything else.**
Adding a spoke means one peering pair and one route table, and a spoke's team can deploy all day
without touching anything another spoke depends on.

## Both sides, from one file

The peering between production and the hub crosses two subscriptions, and its two halves live in
each. A Bicep file deploys to one scope, but a **module** can be aimed at another, as lesson 2's
`targetScope` foreshadowed. Save the hub's half as `hub-side.bicep` in `~/azure/peering`:

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

and the spoke's half, which calls it, as `peering.bicep`:

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

Two resources came out. The first is the spoke's half of the peering, in the group the deployment
is aimed at, with `useRemoteGateways`. **The second is not a peering at all: it is a deployment**,
`Microsoft.Resources/deployments`, with a subscription and a group of its own. That is what a module
aimed elsewhere compiles to: a template inside the template, which Resource Manager runs in
`shop-shared`'s `rg-shop-hub` as a second deployment. One file, two subscriptions, and the person
running it needs permission in both, which is the agreement of the first section written as a
permission.

The hub's half carries `allowGatewayTransit` and the spoke's `useRemoteGateways`: the lend and the
borrow. **Setting both on the same side is a mistake the compiler does not catch**, because each is
a valid boolean on its own; Azure refuses it when it arrives. The same is true of a hub with no
gateway yet: a spoke that asks to use the remote gateway is refused until there is one.

## The same pair, in Terraform

Terraform reaches two subscriptions with two copies of the provider, one of them given an **alias**.
Make a directory for it and save this as `main.tf`:

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

`init` printed what it printed in lesson 2, and `validate` passed. Each
peering names the provider that reaches its subscription: the spoke's uses the default, the hub's
says `provider = azurerm.shared`. Terraform's two copies of the provider are also two sign-ins, or
one identity with roles in both subscriptions, which is lesson 9's subject. `validate` checked the
shape; whether the two networks exist, whether their ranges overlap, and whether the hub has a
gateway to lend are all for Azure, and **none of the peerings was created**.
