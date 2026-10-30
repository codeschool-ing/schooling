---
title: What Spot sells, and what it does not promise
version: 1
---

Spot is easy to picture as a cheaper grade of machine: smaller, slower, or on old hardware. It is
none of those. **A Spot virtual machine is an ordinary virtual machine running on capacity Azure is
not using at the moment, sold at a discount, on one condition: Azure takes the capacity back
whenever it needs it.** Microsoft's guide to building on Spot says it in so many words: the same
images, the same hardware, the same disks and so the same performance as a regular machine. What
differs is priority. A regular machine gets capacity when it asks for it; a Spot machine gets what
is left over, and keeps it only until a regular machine needs the hardware.

## What is promised, and what is not

Microsoft's documentation, read on 2026-10-30, puts the discount at **up to 90%**. The Spot Priority
Mix page says "save up to 90%" on compute, and the guide says Spot machines "can be up to 90%
cheaper" than pay-as-you-go ones. That is a ceiling, not a quote. The price moves with the region,
the size, the operating system and demand, so a size everybody wants in a busy region is discounted
far less than an older one nobody asks for.

The other half of the bargain is written down just as plainly: **there is no SLA for a Spot
machine**, and no high-availability guarantee of any kind. The documentation's own FAQ asks whether
a Spot machine, once created, is the same as a standard one, and answers that it is, except that it
has no SLA and can be evicted at any time. Lesson 6 is about what an SLA promises a regular machine;
for Spot, the promise is nothing.

Four restrictions settle early whether Spot is possible at all:

- **No B-series**, and no promo sizes. Lesson 1's burstable family cannot run as Spot.
- **Not in an availability set.** The documentation's list of errors has a code for exactly that,
  `AzureSpotVMNotSupportedInAvailabilitySet`; lesson 6 explains what an availability set is.
- **Spot is decided at creation.** An existing machine cannot be turned into a Spot one, and a Spot
  machine cannot be turned into a standard one. Changing your mind means a new machine.
- **A quota of its own.** Spot cores come out of a separate quota pool, shared between single
  machines and scale set instances, and raised through the ordinary quota request.

## The price, which this lesson does not have

This course quotes no price from Azure's price list, for the reason lesson 1 gives, and a Spot price
is the least quotable price of all because it changes while you read it. The real one is on the
pricing pages, and behind the link *View pricing history and compare prices in nearby regions* that
the portal shows while you create a Spot machine. It is also in the Retail Prices API, where a Spot
meter carries `Spot` in its `meterName` and its `skuName`. This request asks for the São Paulo
meters of a `D2s_v5` and keeps the Spot ones. It was not run in this course:

```sh
curl -s "https://prices.azure.com/api/retail/prices?\$filter=armRegionName%20eq%20'brazilsouth'%20and%20armSkuName%20eq%20'Standard_D2s_v5'" | jq '.Items[] | select(.meterName | contains("Spot")) | {productName, meterName, retailPrice}'
```

## Asking for one

To the command line, Spot is one value of one option:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o -- "--priority : [^:]*Allowed values: [A-Za-z, ]*\."
--priority : Priority. Use 'Spot' or 'SpotPlus' to run short-lived workloads in a cost-effective way. 'Low' enum will be deprecated in the future. Please use 'Spot' or 'SpotPlus' to deploy Azure spot VM and/or VMSS. Default to Regular. Allowed values: Low, Regular, Spot, SpotPlus.
```

`Spot` is the value this lesson uses. The help says itself that `Low` will be deprecated, and
`SpotPlus` is a value this version of the CLI lists and the Spot documentation read for this lesson
does not describe, so the lesson leaves it alone. `Regular`, the default, is what every machine in
lessons 1 to 4 was.

The shop has an obvious first candidate. Its nightly sales report runs for about four hours on a
machine of its own, `shop-report-1`, and nobody is waiting for it until the morning. Here it is as
a Spot machine. It is lesson 2's `vm.bicep` with a new name, without the security profile to keep
it short, and with three new properties at the top of `properties`. Save it as `report-vm.bicep`:

```bicep
// report-vm.bicep
param location string = 'brazilsouth'
param adminUsername string = 'ana'
param sshPublicKey string
param nicId string

resource report 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'shop-report-1'
  location: location
  properties: {
    priority: 'Spot'
    evictionPolicy: 'Deallocate'
    billingProfile: {
      maxPrice: -1
    }
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'server'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'shop-report-1'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicId
        }
      ]
    }
  }
}
```

`priority: 'Spot'` is the whole of the choice. `evictionPolicy` and `billingProfile.maxPrice` say
what happens when Azure wants the capacity back and whether price is one of the reasons it may;
both are the next section's subject. Everything else is the machine you have declared before.
Compile it:

```
ana@laptop:~/azure$ bicep build report-vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties | {priority, evictionPolicy, billingProfile}" report-vm.json
{
  "priority": "Spot",
  "evictionPolicy": "Deallocate",
  "billingProfile": {
    "maxPrice": -1
  }
}
```

No warnings, and the three properties are in the template as written. Now the mistake somebody
copying from memory makes, a lower-case `spot`:

```
ana@laptop:~/azure$ sed "s/'Spot'/'spot'/" report-vm.bicep > lower.bicep
ana@laptop:~/azure$ bicep build lower.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.priority" lower.json
"spot"
ana@laptop:~/azure$ sed "s/'Spot'/1/" report-vm.bicep > number.bicep
ana@laptop:~/azure$ bicep build number.bicep
/home/ana/azure/number.bicep(11,15) : Warning BCP036: The property "priority" expected a value of type "null | string" but the provided value is of type "1". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

The lower-case value compiled with no warning and went into the template as `"spot"`. Putting a
number in the same place shows why: **the compiler's type for `priority` in this API version is
`null | string`, any text at all**, with no list of allowed values. In lesson 2 the compiler refused
the British spelling `Generalised` because `osState` is one of exactly two words to it; here it
has no words to compare against. Whether Resource Manager would accept `"spot"` is the compute
service's decision, and a laptop cannot ask it. The spelling to copy is the one in the CLI's list
above, with the capital letter.

## What the discount is worth

With no real price to hand, take lesson 1's illustrative rate for a `D2s_v5`, 0.10 USD an hour,
and **suppose, for the arithmetic only, a Spot discount of 70%**, which puts the machine at 0.03 USD
an hour. Neither number is Azure's. The report runs four hours a night, 120 hours in a month of
thirty nights: 12.00 USD on a regular machine and 3.60 USD on Spot, a saving of 8.40 USD.

That is the shape to keep. **The saving is the discount times the hours that run on Spot**, and the
hours that can run on Spot are limited by what one eviction costs. A report that is evicted at
three in the morning and starts again from the beginning has not saved anything if it is still
running when the shop opens. The rest of this lesson is about that cost: when an eviction comes,
what it leaves behind, what notice it gives, and which work can afford it.
