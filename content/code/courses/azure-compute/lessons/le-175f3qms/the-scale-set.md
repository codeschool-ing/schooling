---
title: "The scale set: a model and a count"
version: 1
---

The first picture most people have of a scale set is a group of virtual machines created together,
which grows when traffic rises. Both halves are slightly off. **A scale set is a model and a
number**: a description of one instance, called the virtual machine profile, and how many instances
should exist. Azure creates instances from the profile until the count is met, and deletes them when
the count falls. The growing is not the scale set's at all. It belongs to a second resource, an
autoscale setting, which moves the number; section 04 of this lesson writes one.

## What the file declares

The shop's order API runs on three instances, one in each zone of São Paulo, behind the load
balancer that `azure-foundations` lesson 22 built. Here is the scale set that holds them, as a Bicep
file. Save it as `shop-vmss.bicep`; it is long, and each part says what it is for:

```schooling-example
{"language": "bicep", "file": "shop-vmss.bicep", "parts": [{"code": "// shop-vmss.bicep\nparam location string = 'brazilsouth'\nparam adminUser string = 'ana'\nparam adminKey string\n\nresource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {\n  name: 'shop-vnet'\n}\n\nresource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {\n  parent: vnet\n  name: 'app'\n}\n\nresource lb 'Microsoft.Network/loadBalancers@2024-05-01' existing = {\n  name: 'shop-lb'\n}\n\nresource pool 'Microsoft.Network/loadBalancers/backendAddressPools@2024-05-01' existing = {\n  parent: lb\n  name: 'shop-pool'\n}\n\nresource gallery 'Microsoft.Compute/galleries@2024-03-03' existing = {\n  name: 'shopgallery'\n}\n\nresource image 'Microsoft.Compute/galleries/images@2024-03-03' existing = {\n  parent: gallery\n  name: 'shop'\n}\n\n", "note": "What the scale set stands on, named and not created. `existing` points at the network of `azure-foundations` lesson 16, the load balancer and its backend pool from lesson 22, and a gallery image of the shop like the one lesson 2 publishes; the names here are this lesson's own. `adminKey` has no default, so whoever deploys the file supplies a public key."}, {"code": "resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' = {\n  name: 'shop-vmss'\n  location: location\n  zones: ['1', '2', '3']\n  sku: {\n    name: 'Standard_D2s_v5'\n    tier: 'Standard'\n    capacity: 3\n  }\n  properties: {\n", "note": "The size of every instance, and the count. `sku.name` is a size of the kind lesson 1 read letter by letter; `capacity` is how many instances the scale set should have now, and it is the number autoscale moves. `zones` lets the set use all three zones of `brazilsouth`."}, {"code": "    orchestrationMode: 'Flexible'\n    platformFaultDomainCount: 1\n    singlePlacementGroup: false\n", "note": "Three lines that make it a Flexible scale set, the subject of the next section. The mode is chosen once, when the set is created."}, {"code": "    scaleInPolicy: {\n      rules: ['Default']\n    }\n", "note": "Which instance goes when the count falls. `Default` is what Azure applies when nothing is written; it is spelt out so the choice can be read."}, {"code": "    upgradePolicy: {\n      mode: 'Rolling'\n      rollingUpgradePolicy: {\n        maxBatchInstancePercent: 20\n        maxUnhealthyInstancePercent: 20\n        maxUnhealthyUpgradedInstancePercent: 20\n        pauseTimeBetweenBatches: 'PT2M'\n      }\n    }\n    automaticRepairsPolicy: {\n      enabled: true\n      gracePeriod: 'PT30M'\n      repairAction: 'Replace'\n    }\n", "note": "What happens to running instances when the model changes, and to an instance that stops answering. Section 05 of this lesson reads both."}, {"code": "    virtualMachineProfile: {\n      storageProfile: {\n        imageReference: {\n          id: image.id\n        }\n        osDisk: {\n          createOption: 'FromImage'\n          managedDisk: {\n            storageAccountType: 'Premium_LRS'\n          }\n        }\n      }\n      osProfile: {\n        computerNamePrefix: 'shop'\n        adminUsername: adminUser\n        linuxConfiguration: {\n          disablePasswordAuthentication: true\n          ssh: {\n            publicKeys: [\n              {\n                path: '/home/${adminUser}/.ssh/authorized_keys'\n                keyData: adminKey\n              }\n            ]\n          }\n        }\n      }\n", "note": "The profile every new instance is made from: the image, the operating system disk, a name prefix and the key to sign in with. Azure appends a number to `shop` for each instance it creates."}, {"code": "      networkProfile: {\n        networkApiVersion: '2020-11-01'\n        networkInterfaceConfigurations: [\n          {\n            name: 'shop-nic'\n            properties: {\n              primary: true\n              ipConfigurations: [\n                {\n                  name: 'ipconfig'\n                  properties: {\n                    subnet: {\n                      id: subnet.id\n                    }\n                    loadBalancerBackendAddressPools: [\n                      {\n                        id: pool.id\n                      }\n                    ]\n                  }\n                }\n              ]\n            }\n          }\n        ]\n      }\n", "note": "Every instance gets a network interface in the subnet, and its address joins the load balancer's backend pool, so traffic reaches a new instance without anybody touching the balancer. `networkApiVersion` is the line Microsoft's own template for a Flexible scale set carries, with this value."}, {"code": "      extensionProfile: {\n        extensions: [\n          {\n            name: 'health'\n            properties: {\n              publisher: 'Microsoft.ManagedServices'\n              type: 'ApplicationHealthLinux'\n              typeHandlerVersion: '1.0'\n              autoUpgradeMinorVersion: true\n              settings: {\n                protocol: 'http'\n                port: 8080\n                requestPath: '/healthz'\n                intervalInSeconds: 5\n                numberOfProbes: 3\n              }\n            }\n          }\n        ]\n      }\n    }\n  }\n}\n", "note": "The Application Health extension, which runs inside each instance and asks the shop's `/healthz` every five seconds. Section 05 says why version `1.0` and not `2.0`."}]}
```

Four things are in it, and they are what every scale set holds:

- the profile, `virtualMachineProfile`: the image, the disk, the operating system settings, the
  network interface and the extensions, from which every instance is made;
- the size and the count, in `sku`: `Standard_D2s_v5` for every instance, and `capacity: 3`;
- the zones the instances may be placed in, which lesson 6 weighs against what they cost;
- the load balancer's backend pool, named inside the network interface.

The last one is easy to read past. An instance created at two in the morning joins the pool by being
created, which is why nobody has to edit the balancer when the count moves. Compile the file:

```
ana@laptop:~/azure$ bicep build shop-vmss.bicep
ana@laptop:~/azure$ ls
shop-vmss.bicep
shop-vmss.json
venv
ana@laptop:~/azure$ jq ".resources[] | {type, apiVersion, name, zones, sku}" shop-vmss.json
{
  "type": "Microsoft.Compute/virtualMachineScaleSets",
  "apiVersion": "2024-11-01",
  "name": "shop-vmss",
  "zones": [
    "1",
    "2",
    "3"
  ],
  "sku": {
    "name": "Standard_D2s_v5",
    "tier": "Standard",
    "capacity": 3
  }
}
```

No warnings, so every property name and type matches what Microsoft publishes for
`Microsoft.Compute/virtualMachineScaleSets` at API version `2024-11-01`. **The template holds one
resource, and the six `existing` declarations are not in it.** They were names, and the compiler
turned each one into an expression that Resource Manager works out when the template is deployed:

```
ana@laptop:~/azure$ jq ".resources[0].properties.virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].properties.ipConfigurations[0].properties" shop-vmss.json
{
  "subnet": {
    "id": "[resourceId('Microsoft.Network/virtualNetworks/subnets', 'shop-vnet', 'app')]"
  },
  "loadBalancerBackendAddressPools": [
    {
      "id": "[resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'shop-lb', 'shop-pool')]"
    }
  ]
}
```

So the compiler checked that the backend pool is named in the right shape. It cannot know whether a
load balancer called `shop-lb` exists in your subscription; that is answered at deployment, by a
refusal if it does not. Deploying the file would be this command, which was not run in this course
because it needs a subscription and the three machines it creates would be billed:

```sh
az deployment group create --resource-group shop --template-file shop-vmss.bicep --parameters adminKey="$(cat ~/.ssh/id_ed25519.pub)"
```

## The count, by hand

`capacity` is a number you can change without touching anything else. Microsoft documents
`az vmss scale --resource-group shop --name shop-vmss --new-capacity 5` for it, not run here: Azure
creates two instances from the profile, places them so the zones stay balanced, and they join the
backend pool. The same number is what autoscale changes, and the two do not share it politely. **A
count set by hand outside the autoscale setting's minimum and maximum is moved back inside on
autoscale's next run.** Microsoft's guidance gives the example of a range of 3 to 6: set eight by hand
and it is six again on the next run.

The scale set itself costs nothing. Microsoft's overview, read on 2026-10-30, says you pay for the
compute, network and storage the instances use, and that a Flexible scale set holds up to 1,000 of
them.

## A model, and instances that may differ from it

Because the profile is a model, a change to it is a change to the instances that have not been
created yet. Change the size in the file to `Standard_D4s_v5` and deploy it again, and the instances
already running are still `D2s_v5`; the next one created is a `D4s_v5`. **Whether the running ones
are brought into line, and when, and how many at a time, is the upgrade policy's decision**, and
section 05 of this lesson reads it. Until then a scale set whose model was edited holds instances of
two kinds, and that is a normal state for it to be in.

## Which instance goes when the count falls

When the count drops from five to four, Azure has to choose which instance to delete. The
**scale-in policy** in the model decides. It has three values:

- `Default` balances the set across zones first, then across fault domains as far as it can, and
  then deletes the instance with the highest instance id;
- `NewestVM` deletes the most recently created instance, after balancing across zones;
- `OldestVM` deletes the oldest, after balancing across zones.

Balancing comes first in all three, and it is done by deleting, never by moving an instance. With
three of five instances in zone 1 and one each in zones 2 and 3, the next scale-in takes an instance
from zone 1 whatever the policy says, and the policy only chooses which of those three. The shop's
file writes `Default` although Azure applies it when the property is absent, so that the choice is
in the file where somebody can read it.

`OldestVM` suits instances that age badly, by filling a disk with cache or logs. `NewestVM` suits a
set where the newest instance is the least proven, such as the first instances of a change you want
to be able to back out by scaling in.

## Keeping one instance out of the choice

Sometimes one instance is busy with something that must not be cut short, such as the nightly sales
report. **Instance protection** marks that one instance, not the model, and it comes in two
strengths. `protectFromScaleIn` keeps it out of autoscale's choice when the count falls.
`protectFromScaleSetActions` also keeps it out of operations started on the whole scale set, such as
an upgrade or a reimage. Neither stops a person: deleting the instance by hand still deletes it.

For a Flexible scale set, instance protection needs the Compute API version `2023-09-01` or later,
and the file's `2024-11-01` is. A protected instance is also left alone by automatic repairs, which
section 05 explains.
