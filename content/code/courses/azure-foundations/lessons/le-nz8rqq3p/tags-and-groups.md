---
title: Service tags and application security groups
version: 1
---

**A rule written with addresses describes the network as it was on the day it was written.** The web
tier has two machines today, `10.20.1.4` and `10.20.1.5`; next month it has five, and a rule listing
two addresses is wrong without anybody having touched it. Azure gives two ways to write a rule about
*what* something is rather than *where* it is, one for things Microsoft runs and one for things you
run.

## Service tags: Microsoft's address lists, by name

**A service tag is a name for a set of addresses that Microsoft maintains**, used in a rule where an
address would go. Four matter in this course:

| tag | what it stands for |
|---|---|
| `VirtualNetwork` | the network's own ranges, the networks peered with it, the ranges of an office joined to it, and the address `168.63.129.16` of Azure's host |
| `AzureLoadBalancer` | `168.63.129.16`, the address Azure's health probes come from, and only the probes |
| `Internet` | everything outside the network that is reachable on the public internet, Azure's own public addresses included |
| `Storage`, `Storage.BrazilSouth` | the public addresses of Azure Storage, everywhere or in one region |

The last row shows the form many tags take: a service, and optionally a region after a dot.
`Storage.BrazilSouth` lets the shop's machines reach storage in São Paulo and nowhere else. The tags
are updated by Microsoft as its addresses change, which is their whole point, and the lists behind
them are published as a JSON file and through an API, for firewalls outside Azure that need the same
addresses. **`VirtualNetwork` is wider than its name**: it grows every time a network is peered or an
office is joined, and the last section of this lesson meets the consequence of it containing
Azure's own host address.

## Application security groups: your machines, by role

**An application security group, an ASG, is a label you put on network interfaces**, and a rule can
name it as a source or a destination. `asg-shop-web` holds the web servers' interfaces and
`asg-shop-app` the application's; a rule saying *from `asg-shop-web` to `asg-shop-app` on 8080* stays
true however many machines join or leave either group, because the membership is set on the
interface when the machine is built.

Two constraints come with them, and both are about networks: every interface in one ASG must be in
the same virtual network, and a rule naming an ASG on each side needs both groups' interfaces in the
same network. An ASG is a role inside a network, not across networks.

## The application tier's NSG, in Bicep

Make the lesson's directory, and save this as `~/azure/nsg/nsg.bicep`:

```sh
mkdir -p ~/azure/nsg && cd ~/azure/nsg
```

```bicep
param location string = 'brazilsouth'

resource asgWeb 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'asg-shop-web'
  location: location
}

resource asgApp 'Microsoft.Network/applicationSecurityGroups@2024-05-01' = {
  name: 'asg-shop-app'
  location: location
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: 'nsg-shop-app'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowWebToApp'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceApplicationSecurityGroups: [{ id: asgWeb.id }]
          sourcePortRange: '*'
          destinationApplicationSecurityGroups: [{ id: asgApp.id }]
          destinationPortRange: '8080'
        }
      }
      {
        name: 'AllowLoadBalancerProbe'
        properties: {
          priority: 3900
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyVnetInBound'
        properties: {
          priority: 4000
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      {
        name: 'AllowStorageOut'
        properties: {
          priority: 100
          direction: 'Outbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage.BrazilSouth'
          destinationPortRange: '443'
        }
      }
      {
        name: 'DenyInternetOut'
        properties: {
          priority: 4000
          direction: 'Outbound'
          access: 'Deny'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}
```

Inbound, it lets the web tier in on 8080 and closes the network-wide door of `AllowVnetInBound` with a
deny at 4000; the rule at 3900 is explained by the last section. Outbound, it allows storage in São
Paulo on 443 and denies the rest of the internet, closing the other default. **The gaps between
priorities are on purpose**: a rule needed in an emergency can go at 150 or at 3950 without
renumbering anything. Compile it into a template the next section reads:

```
ana@laptop:~/azure/nsg$ az bicep build --file nsg.bicep --outfile nsg.json && jq -c '.resources[] | {type, name}' nsg.json
{"type":"Microsoft.Network/applicationSecurityGroups","name":"asg-shop-web"}
{"type":"Microsoft.Network/applicationSecurityGroups","name":"asg-shop-app"}
{"type":"Microsoft.Network/networkSecurityGroups","name":"nsg-shop-app"}
```

Three resources, and the ASGs came first: the rules refer to them by id, so Bicep made the NSG depend
on both and wrote them earlier. Attaching the NSG to `snet-app` is one more line, a
`networkSecurityGroup` property with its id on the subnet in lesson 16's `vnet.bicep`, and putting an
interface in an ASG is a property of the interface, set when a machine is built, which this course
does not do.
