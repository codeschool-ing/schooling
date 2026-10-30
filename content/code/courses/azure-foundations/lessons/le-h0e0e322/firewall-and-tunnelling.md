---
title: Azure Firewall, and forcing the internet through the office
version: 1
---

**Azure Firewall is a firewall Microsoft runs for you, inside your network**: you give it a subnet
called `AzureFirewallSubnet`, at least a `/26`, and a public address, and it appears as a private
address that route tables can point at. It scales by adding instances of its own, which is why the
subnet is that size, and it is charged by the hour from the moment it exists plus by the gigabyte it
processes, whether or not anything is sent through it. **This course quotes no figure for it**: the
price list is the program of lesson 1, and the firewall is the most expensive thing in the shop's
network, so read the price before creating one.

It comes in three tiers, Basic, Standard and Premium, which differ in throughput and in what they
can inspect; Premium adds inspection of encrypted traffic and an intrusion detection system. The shop
uses Standard.

## A firewall denies until told otherwise

**An Azure Firewall with no rules lets nothing through.** That is the opposite of an NSG's defaults,
and it is the point: a packet the route table sent to the firewall is refused unless a rule allows
it. The rules live in a **firewall policy**, a resource of its own that one or many firewalls use, and
are arranged in three layers:

- a policy holds **rule collection groups**, each with a priority;
- a group holds **rule collections**, each with a priority and one action, allow or deny;
- a collection holds **rules** of one kind.

The kinds are three, and **they are processed in a fixed order whatever their priorities**: DNAT rules
first, which translate an address arriving from the internet to a private one; then network rules,
which match addresses, protocols and ports; then application rules, which match names, such as
`api.payments.example` over HTTPS. Inside each kind, groups and collections are read in priority
order, lowest number first, from 100 to 65,000, and the first match decides, as in an NSG.

Here is the shop's policy for production's outbound traffic. Save it as `~/azure/routes/fwpolicy.bicep`:

```bicep
param location string = 'brazilsouth'

resource policy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: 'afwp-shop'
  location: location
  properties: {
    sku: {
      tier: 'Standard'
    }
    threatIntelMode: 'Deny'
  }
}

resource rules 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2024-05-01' = {
  parent: policy
  name: 'shop-prod'
  properties: {
    priority: 200
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'prod-to-office'
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'NetworkRule'
            name: 'erp'
            ipProtocols: ['TCP']
            sourceAddresses: ['10.20.2.0/24']
            destinationAddresses: ['192.168.10.0/24']
            destinationPorts: ['1433']
          }
        ]
      }
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'prod-to-internet'
        priority: 200
        action: {
          type: 'Allow'
        }
        rules: [
          {
            ruleType: 'ApplicationRule'
            name: 'payments'
            protocols: [
              {
                protocolType: 'Https'
                port: 443
              }
            ]
            sourceAddresses: ['10.20.2.0/24']
            targetFqdns: ['api.payments.example']
          }
        ]
      }
    ]
  }
}
```

The application tier may reach the office's ERP database on 1433, and the payment provider by name
on 443, and nothing else: staging, the rest of the office and the rest of the internet meet the
firewall's default. `threatIntelMode: 'Deny'` also refuses traffic to and from addresses Microsoft's
threat intelligence lists as malicious, before any rule is read. Compile it and read the
collections back:

```
ana@laptop:~/azure/routes$ az bicep build --file fwpolicy.bicep --stdout | jq -c '.resources[] | select(.type | endswith("ruleCollectionGroups")) | .properties.ruleCollections[] | {name, priority, action: .action.type, rules: [.rules[] | {ruleType, name}]}'
{"name":"prod-to-office","priority":100,"action":"Allow","rules":[{"ruleType":"NetworkRule","name":"erp"}]}
{"name":"prod-to-internet","priority":200,"action":"Allow","rules":[{"ruleType":"ApplicationRule","name":"payments"}]}
```

**An application rule matches a name, and only a firewall that sees the name can use it.** For HTTPS
the name travels in the opening of the encrypted conversation, which Standard reads without
decrypting anything. That is the reason the shop's outbound internet goes through a firewall rather
than an NSG: an NSG knows addresses, and a payment provider's addresses change without notice.

## Forced tunnelling: the internet by way of the office

Some companies require that **all traffic to the internet leave through their own office**, past
their own firewall, so that one place logs and filters it. In Azure that is **forced tunnelling**: the
route for `0.0.0.0/0` points not at the internet but at the office, through the VPN or ExpressRoute
gateway of lesson 23, either written as a route or announced by the office over BGP.

With Azure Firewall in the middle, the default route goes on the firewall's own subnet: production
sends everything to the firewall, and the firewall's subnet sends the internet-bound part on to the
gateway. Microsoft's documentation adds three conditions, and **none of them could be run here**:

- **the firewall needs its management traffic kept apart**, through a second subnet called
  `AzureFirewallManagementSubnet`, at least a `/26`, with a public address of its own that only
  Microsoft's management uses. In the shop's hub plan that subnet is `10.0.3.0/26`. On the Standard
  and Premium tiers it is switched on when the firewall is created, or later by stopping and
  starting the firewall; Basic always has it;
- **the firewall translates internet-bound traffic to one of its private addresses** before handing
  it on, so the office's firewall sees the Azure firewall as the sender, not the machine;
- **DNAT from the internet stops working** on a firewall whose internet traffic is forced away, since
  replies would leave by a different path from the one the request came in on.

**Forced tunnelling moves the internet further away**: every request to a payment provider crosses to
São Paulo's office and back. It is a decision about control that is paid in latency and in the
office's bandwidth, and the shop does not make it. Its firewall sends the internet straight out, and
logs it in Azure.
