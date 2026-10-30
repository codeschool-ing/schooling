---
title: Availability zones, and the three ways a resource sits in a region
version: 1
---

An availability set spreads machines across racks in one place. **An availability zone puts them in
different places**: physically separate locations inside one region, each with its own power,
cooling and network, close enough for a fast connection and far enough apart that a local outage or
the weather is unlikely to reach two of them. Microsoft's documentation, read on 2026-10-30, says
a region that supports zones has at least three, that each is one or more datacentres, and that they
are joined by a network with a round trip under two milliseconds. `azure-foundations` lesson 1 says what a zone is for the whole platform; this
section is about what it means for a machine.

Brazil South has them. It is on Microsoft's list of regions that offer zone-redundant storage, a
kind of storage that only exists across zones, and lesson 4 spread the shop's scale set over its
zones `1`, `2` and `3`.

## Zonal, zone-redundant, and neither

The common picture is that a resource is either "in a zone" or "not". There are three cases, and
the third is the one that surprises people:

- A **zonal** resource is pinned to one zone and shares its fate. A virtual machine created with
  `zones: ['1']` is zonal, its managed disks are created in the same zone, and when that zone is
  dark the machine is down with it.
- A **zone-redundant** resource is spread across zones by Azure itself, and survives the loss of
  any one of them. You declare it once and do not choose where its copies live. A Standard public
  IP address can be zone-redundant.
- A **regional** resource, written with no zones at all, is placed by Azure somewhere in the
  region. **You are not told which zone it is in, and a failure in any one of the region's zones
  may take it down.** A virtual machine created without `zones` is regional, and it is not
  "in every zone": it is in one you cannot see.

So two zonal machines in two zones are redundant across zones, and two regional machines might be
in the same one. The shop's file below makes the first arrangement on purpose.

## Two machines in two zones, and one address for both

Save this as `shop-zones.bicep`. It declares the order API on two machines, one in zone `1` and one
in zone `2`, and the public address the load balancer of `azure-foundations` lesson 22 would answer
on, spread across all three:

```schooling-example
{"language": "bicep", "file": "shop-zones.bicep", "parts": [{"code": "// shop-zones.bicep\nparam location string = 'brazilsouth'\nparam adminUsername string = 'ana'\nparam sshPublicKey string\n\nvar zones = ['1', '2']\n\nresource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {\n  name: 'shop-vnet'\n}\n\nresource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {\n  parent: vnet\n  name: 'app'\n}\n\n", "note": "The same parameters and the same network as the set's file. `zones` is the list the loops below walk: one machine per item."}, {"code": "resource ip 'Microsoft.Network/publicIPAddresses@2024-05-01' = {\n  name: 'shop-lb-ip'\n  location: location\n  zones: ['1', '2', '3']\n  sku: {\n    name: 'Standard'\n    tier: 'Regional'\n  }\n  properties: {\n    publicIPAllocationMethod: 'Static'\n    publicIPAddressVersion: 'IPv4'\n  }\n}\n\n", "note": "**A zone-redundant address.** A Standard public IP given all three zones survives the loss of any one. It is static, so the address the shop's customers reach does not change."}, {"code": "resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = [for zone in zones: {\n  name: 'shop-web-z${zone}-nic'\n  location: location\n  properties: {\n    ipConfigurations: [\n      {\n        name: 'ipconfig'\n        properties: {\n          subnet: {\n            id: subnet.id\n          }\n        }\n      }\n    ]\n  }\n}]\n\n", "note": "One network interface per zone, named after it: `shop-web-z1-nic` and `shop-web-z2-nic`."}, {"code": "resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = [for (zone, i) in zones: {\n  name: 'shop-web-z${zone}'\n  location: location\n  zones: [zone]\n  properties: {\n    hardwareProfile: {\n      vmSize: 'Standard_D2s_v5'\n    }\n", "note": "**Each machine is zonal.** `zones` takes a list, and a machine accepts one item in it; `[zone]` is this copy's. `(zone, i)` gives the loop the item and its position, which picks the interface below."}, {"code": "    storageProfile: {\n      imageReference: {\n        publisher: 'Canonical'\n        offer: 'ubuntu-24_04-lts'\n        sku: 'server'\n        version: 'latest'\n      }\n      osDisk: {\n        createOption: 'FromImage'\n        managedDisk: {\n          storageAccountType: 'Premium_LRS'\n        }\n      }\n    }\n    osProfile: {\n      computerName: 'shop-web-z${zone}'\n      adminUsername: adminUsername\n      linuxConfiguration: {\n        disablePasswordAuthentication: true\n        ssh: {\n          publicKeys: [\n            {\n              path: '/home/${adminUsername}/.ssh/authorized_keys'\n              keyData: sshPublicKey\n            }\n          ]\n        }\n      }\n    }\n    networkProfile: {\n      networkInterfaces: [\n        {\n          id: nic[i].id\n        }\n      ]\n    }\n  }\n}]\n", "note": "As in the set's file, apart from the name. A zonal machine's disks are created in its zone, so `Premium_LRS` here means three copies inside zone 1 for the first machine and inside zone 2 for the second."}]}
```

Compile it:

```
ana@laptop:~/azure$ bicep build shop-zones.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, zones, sku}" shop-zones.json
{"type":"Microsoft.Network/publicIPAddresses","name":"shop-lb-ip","zones":["1","2","3"],"sku":{"name":"Standard","tier":"Regional"}}
{"type":"Microsoft.Network/networkInterfaces","name":"[format('shop-web-z{0}-nic', variables('zones')[copyIndex()])]","zones":null,"sku":null}
{"type":"Microsoft.Compute/virtualMachines","name":"[format('shop-web-z{0}', variables('zones')[copyIndex()])]","zones":["[variables('zones')[copyIndex()]]"],"sku":null}
```

The address keeps its three zones as written. The machine's zone became an expression, because it
comes from the loop: `variables('zones')[copyIndex()]` is "the zone of this copy", `1` for the
first machine and `2` for the second. The command line asks for the same two things:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-zone -z : [^.]*\."
--zone -z : Availability zone into which to provision the resource.
ana@laptop:~/azure$ az network public-ip create --help | tr -s "[:space:]" " " | grep -o "\-\-zone -z : [^.]*\.\|\-\-sku : [^.]*\.[^.]*\."
--sku : Name of a public IP address SKU. Allowed values: Basic, Standard, StandardV2.
--zone -z : Space-separated list of availability zones into which to provision the resource.
```

**A machine takes one zone and an address takes a list**: one for a zonal address, all of the
region's for a zone-redundant one. Microsoft's page on public IP addresses adds what the help does
not say about the three SKUs it lists. `Basic` was retired on 30 September 2025 and never had zones,
and `StandardV2` is always zone-redundant where the region has zones. A Standard address
created with no zones in a region that has them is zone-redundant, so `zones: ['1', '2', '3']` and
no zones at all now mean the same thing there; the file writes the three so that the reader does
not need to know that. And an address cannot change its zone after it is created.

## Zone 1 is a label, not a building

A zone's number is **logical**. Resource Manager maps each subscription's zone numbers to physical
zones, and the SDK's description of the location list says so in two fields:

```
ana@laptop:~/azure$ grep -h -A3 ':ivar logical_zone:' venv/lib/python3.12/site-packages/azure/mgmt/resource/subscriptions/v2022_12_01/models/_models_py3.py
    :ivar logical_zone: The logical zone id for the availability zone.
    :vartype logical_zone: str
    :ivar physical_zone: The fully qualified physical zone id of availability zone to which logical
     zone id is mapped to.
```

The mapping is returned per subscription, which is the point of returning it: zone `1` in the
shop's subscription and zone `1` in the finance team's are not promised to be the same building. Two
subscriptions that each spread over zones `1` and `2` may still share a physical zone, and a design
that relies on two subscriptions being in different zones has to read both mappings. This reads
them for the subscription you are signed in to; it needs one, and was not run in this course:

```sh
az rest --method get --uri "https://management.azure.com/subscriptions/{subscriptionId}/locations?api-version=2022-12-01" --query "value[?name=='brazilsouth'].availabilityZoneMappings"
```

## What the compiler checks here

A copy of the file with two mistakes: the address's zones written as numbers, and the machines
placed in zones `1` and `4`:

```
ana@laptop:~/azure$ sed -e "s/zones: \['1', '2', '3'\]/zones: [1, 2, 3]/" -e "s/var zones = \['1', '2'\]/var zones = ['1', '4']/" shop-zones.bicep > zones-wrong.bicep
ana@laptop:~/azure$ diff shop-zones.bicep zones-wrong.bicep
6c6
< var zones = ['1', '2']
---
> var zones = ['1', '4']
20c20
<   zones: ['1', '2', '3']
---
>   zones: [1, 2, 3]
ana@laptop:~/azure$ bicep build zones-wrong.bicep
/home/ana/azure/zones-wrong.bicep(20,11) : Warning BCP034: The enclosing array expected an item of type "string", but the provided item was of type "1". [https://aka.ms/bicep/core-diagnostics#BCP034]
/home/ana/azure/zones-wrong.bicep(20,14) : Warning BCP034: The enclosing array expected an item of type "string", but the provided item was of type "2". [https://aka.ms/bicep/core-diagnostics#BCP034]
/home/ana/azure/zones-wrong.bicep(20,17) : Warning BCP034: The enclosing array expected an item of type "string", but the provided item was of type "3". [https://aka.ms/bicep/core-diagnostics#BCP034]
```

**Three warnings for one mistake, and none for the other.** A zone is a string, so `1` without
quotes is refused once per item. `'4'` is a string, and a region with three zones has no zone 4,
but the type does not know how many zones Brazil South has. Resource Manager would refuse the
request, and a laptop cannot see how.

The same blindness covers a combination. An availability set and a zone are two answers to the
same question, and **a machine takes one or the other**: Microsoft's page on disk availability says
availability sets cannot be used with availability zones. Here is the set's file from the last
section with a zone added to each machine:

```
ana@laptop:~/azure$ sed "/^resource vm/,/^  properties/s/^  location: location$/&\n  zones: ['1']/" shop-avset.bicep > both.bicep
ana@laptop:~/azure$ diff shop-avset.bicep both.bicep
46a47
>   zones: ['1']
ana@laptop:~/azure$ bicep build both.bicep
```

No warning. Each property is valid on its own, and the rule that forbids the pair is not in the
type.

## Zones in a scale set

Lesson 4's scale set took `zones: ['1', '2', '3']`, which makes it *zone-spanning*: each instance
is zonal, pinned to one zone with its disks, and the scale set chooses which. It aims to keep the
zones *balanced*, which Microsoft defines as each zone holding the same number of instances, plus
or minus one, so that five instances over three zones is two, two and one.

What happens when a zone fails depends on the balancing mode, chosen on the scale set:

- Best effort, the default: the set keeps scaling out into the zones still working and accepts
  the imbalance while one zone is down. With two or more zones down it stops scaling at all. Once
  the zone is back, later scale-outs add to it and scale-ins take from the full ones.
- Strict: a scaling operation that would leave the set unbalanced is blocked, even while a zone
  is down.

Best effort is the one that keeps capacity during an outage, which is when capacity is needed.
Two more things are worth knowing before they surprise you. **Adding a zone to an existing scale
set moves nothing**: the instances stay where they are, and only new ones go to the new zone. And a
set rebalanced by hand is rebalanced the way lesson 4 described scale-in, by adding instances and
then removing others, never by moving one.
