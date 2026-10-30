---
title: The network in a file, and a subnet handed to a service
version: 1
---

**Some Azure services do not take an address in your subnet; they take the whole subnet.** A
PostgreSQL flexible server joined to a network, an App Service app that reaches into one, a
container group: each runs machines Microsoft manages, and needs to place and replace them inside
your network without asking you each time. **Delegating** a subnet is how you allow it: the subnet
is marked as belonging to one service, that service may then create what it needs there, and it
may set network rules of its own on the subnet that you cannot remove while it is there.

Three consequences follow from that, and Microsoft's documentation lists them:

- **a delegated subnet is the service's**, and most services want it to themselves: no virtual
  machines beside the database, and no private endpoints, which lesson 19 places elsewhere;
- **the service may dictate a minimum size**, and the delegation has to be removed before the
  subnet, or the network, can be deleted;
- **delegating is the network owner's decision**, made on the subnet, before the service arrives.

The shop delegates `snet-data` to PostgreSQL, so that its database lives at an address of
production's network and nowhere on the internet.

## Writing the network down

Here is the whole of `vnet-shop-prod` in Bicep: the range, the four subnets, and the delegation.
Save it as `~/azure/vnet/vnet.bicep`:

```bicep
param location string = 'brazilsouth'

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
        name: 'snet-web'
        properties: {
          addressPrefix: '10.20.1.0/24'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.20.2.0/24'
          defaultOutboundAccess: false
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: '10.20.3.0/24'
          defaultOutboundAccess: false
          delegations: [
            {
              name: 'postgres'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: '10.20.4.0/24'
          defaultOutboundAccess: false
        }
      }
    ]
  }
}

output appSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, 'snet-app')
```

**Subnets are written inside the network**, not as resources of their own beside it. Bicep allows
both, and the inside form is the safe one: a network deployed again from a file that lists its
subnets keeps them, while a network file that leaves them to separate resources can, deployed
alone, describe a network with no subnets and remove them.

`defaultOutboundAccess: false` makes each subnet **private**: a machine in it reaches the internet
only through a route somebody built on purpose, such as the firewall of lesson 18. Microsoft made
that the default for new networks created with versions of the API released after March 2026, and
older versions kept the old default, under which every machine had a way out nobody had chosen.
Writing the value down means the file means the same thing whichever version it names.

Compile it and read the subnets back:

```
ana@laptop:~/azure/vnet$ az bicep build --file vnet.bicep --stdout | jq -c '.resources[0].properties.subnets[] | {name, prefix: .properties.addressPrefix, delegatedTo: .properties.delegations[0].properties.serviceName}'
{"name":"snet-web","prefix":"10.20.1.0/24","delegatedTo":null}
{"name":"snet-app","prefix":"10.20.2.0/24","delegatedTo":null}
{"name":"snet-data","prefix":"10.20.3.0/24","delegatedTo":"Microsoft.DBforPostgreSQL/flexibleServers"}
{"name":"snet-pe","prefix":"10.20.4.0/24","delegatedTo":null}
```

## What the compiler does not see

The compiler checks names and types, and nothing about addresses. Two experiments make the edge
visible. First, `snet-pe` moved to a range outside the network; then a property misspelt:

```
ana@laptop:~/azure/vnet$ sed 's#10.20.4.0/24#10.99.4.0/24#' vnet.bicep > outside.bicep && az bicep build --file outside.bicep --stdout | jq -r '.resources[0].properties.subnets[3].properties.addressPrefix'
10.99.4.0/24
```

```
ana@laptop:~/azure/vnet$ sed '0,/defaultOutboundAccess/s//defaultOutbondAccess/' vnet.bicep > typo.bicep && az bicep build --file typo.bicep --stdout | jq -c '.resources[0].properties.subnets[0].properties'
WARNING: /home/ana/azure/vnet/typo.bicep(17,11) : Warning BCP089: The property "defaultOutbondAccess" is not allowed on objects of type "SubnetPropertiesFormat". Did you mean "defaultOutboundAccess"? [https://aka.ms/bicep/core-diagnostics#BCP089]

{"addressPrefix":"10.20.1.0/24","defaultOutbondAccess":false}
```

**A subnet outside its network compiled without a word.** `10.99.4.0/24` is a perfectly good string,
and only Azure, comparing it with the range, would refuse the deployment. That is what `plan.py` is
for: the arithmetic the compiler does not do.

**The misspelling was a warning, and the build still succeeded.** `BCP089` named the property, and
even guessed the right one, but the template was written, with the misspelt name in it. Deployed, the subnet would have kept its
API version's default, and the file would have said something different from what it did. **Read
the warnings**, or ask Bicep to treat them as errors in a `bicepconfig.json`, which is how teams that
deploy from a pipeline usually run it.

## The same cut, in Terraform's arithmetic

Terraform plans subnets with a function rather than by hand. `cidrsubnet(range, bits, number)` adds
`bits` to the prefix and returns the `number`-th slice, and `cidrhost` the address at a position
inside one. `terraform console` evaluates an expression without a configuration:

```
ana@laptop:~/azure/vnet$ echo '[for i in range(1, 5) : cidrsubnet("10.20.0.0/16", 8, i)]' | terraform console
[
  "10.20.1.0/24",
  "10.20.2.0/24",
  "10.20.3.0/24",
  "10.20.4.0/24",
]
ana@laptop:~/azure/vnet$ echo 'cidrhost("10.20.2.0/24", 4)' | terraform console
"10.20.2.4"
```

Eight more bits on a `/16` make `/24`s, and slices 1 to 4 are exactly the four subnets of the plan.
`cidrhost` at position 4 is the first address a machine in `snet-app` can get, the fifth of the
range, because the first four are Azure's.
