---
title: The same network, through three doors
version: 1
---

**There are three ways to make something in Azure: click it in the portal, type it on a command line,
or describe it in a file that a tool applies. They feel like three different products. They are three
clients of the one API lesson 25 opened, and what reaches Resource Manager from each is the same
`PUT`.** What differs is everything around that request: whether anybody can repeat it, review it, or
find out later why the network looks the way it does.

This lesson builds one thing three ways: the shop's production network, `vnet-shop-prod`, with the
range `10.20.0.0/16` and one subnet, `snet-app`, in the group `rg-shop-prod`. Make its directory:

```sh
mkdir -p ~/azure/doors && cd ~/azure/doors
```

## The portal

The portal is a web application that calls Resource Manager with your token, one form at a time: *Create
a resource*, *Virtual network*, a tab for the basics, a tab for the address space, *Review + create*.
**Nothing about it was run for this course**, which has no account and draws no imitation of Microsoft's
screens. Two of its features matter here. Every creation form ends with a link to **download a template
for automation**, the ARM JSON of what you just filled in, which is the bridge from the first door to
the third. And every change made there is real at once, with nothing written down anywhere except the
Activity Log.

## The command line

The Azure CLI does the same in two commands, each a request:

```
ana@laptop:~/azure/doors$ az network vnet create --resource-group rg-shop-prod --name vnet-shop-prod --address-prefixes 10.20.0.0/16 --subnet-name snet-app --subnet-prefixes 10.20.2.0/24
ERROR: Please run 'az login' to setup account.
```

That is the line a person types once. In a script it is **imperative**: a list of steps, run in order,
each saying *do this now*. Run the script twice and the second `create` meets a network that already
exists. What happens then is up to how that command was written: some send the same `PUT` and overwrite
what is there, some check first and stop. Either way, the script is only right when the world is in the
state it assumed when it was written. A script describes a path, not a place.

## A file that describes the result

Bicep and Terraform are **declarative**: the file says what should exist when they are done, and the
tool works out the requests. Save this as `main.bicep`:

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

And the same network for Terraform, in a directory of its own, as `main.tf`:

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
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l26-doors\" aria-label=\"Three doors into Azure, left to right. The portal: you fill in forms, and nothing is written down. The command line: you write the steps. A declarative file, Bicep or Terraform: you write the result, and the tool works out the steps. All three end in the same PUT request to Resource Manager at management.azure.com, which creates vnet-shop-prod.\"><defs><marker id=\"l26-doors-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l26-doors-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"24.0\" width=\"200.0\" height=\"96.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">portal</text><text x=\"130.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you fill in forms</text><text x=\"130.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing written down</text><path d=\"M130.0 121.0 L130.0 150.0 L302.5 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"24.0\" width=\"200.0\" height=\"96.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">command line</text><text x=\"360.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you write the steps</text><text x=\"360.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">az network vnet create</text><path d=\"M360.0 121.0 L360.0 150.0 L360.0 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"24.0\" width=\"200.0\" height=\"96.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a declarative file</text><text x=\"590.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you write the result</text><text x=\"590.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">main.bicep  main.tf</text><path d=\"M590.0 121.0 L590.0 150.0 L417.5 178.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-paper-dim)\"></path><rect x=\"220.0\" y=\"180.0\" width=\"280.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">PUT .../virtualNetworks/vnet-shop-prod</text><path d=\"M360.0 225.0 L360.0 243.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l26-doors-af-ah-amber)\"></path><rect x=\"240.0\" y=\"244.0\" width=\"240.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Resource Manager</text></svg>", "caption": "Three ways to ask, one request, one API answering it."}
```

**The two files hold the same facts, arranged by two vendors.** The Bicep file is aimed at a resource
group that must already exist, takes its location from it, and writes the subnet inside the network, as
the network's API does. The Terraform file creates the group too, and makes the subnet a resource of its
own, which the provider turns into a separate request. Neither says *create*: each says *this should
exist*. Applied twice, the second time finds nothing to do.

| | portal | command line | Bicep | Terraform |
|---|---|---|---|---|
| you write | nothing | the steps | the result | the result |
| repeatable | no | if the script is | yes | yes |
| reviewed before it runs | no | as code, if it is in a repository | as code | as code |
| knows what it created | no | no | Resource Manager's deployment history | its own state file |
| reaches | Resource Manager | Resource Manager | Resource Manager | Resource Manager |
