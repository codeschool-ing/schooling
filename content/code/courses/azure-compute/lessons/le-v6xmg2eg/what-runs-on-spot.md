---
title: A floor of regular machines, and what belongs on Spot
version: 1
---

The question to ask of a workload is not how important it is. A production service can run largely
on Spot, and a test database must not. **The question is what one eviction costs**: if any one
machine can go with thirty seconds' notice and the work carries on elsewhere, Spot is a discount;
if one machine going loses something or stops everything, it is a gamble that loses eventually. A
scale set makes the first case easy to build, because it can hold a floor of regular machines that
no eviction touches and fill the rest with Spot.

## A scale set with a floor

Lesson 4's scale sets are all one priority. **Spot Priority Mix** lets one Flexible scale set hold
both, from two numbers:

- `baseRegularPriorityCount`, the regular machines the set always keeps first;
- `regularPriorityPercentageAboveBase`, the share of regular machines in everything above that
  base, from 0 to 100. The rest of what is above the base is Spot.

The shop's workers are the case. They take jobs from a queue, the report's pieces and the finance
export, and lesson 20 builds that queue; for now what matters is that a job a worker does not
complete goes back on the queue for another worker. Here is the set, ten workers with a floor of
two. Copy it with the button and save it as `workers-vmss.bicep`:

```schooling-example
{"language": "bicep", "file": "workers-vmss.bicep", "parts": [{"code": "// workers-vmss.bicep\nparam location string = 'brazilsouth'\nparam adminUser string = 'ana'\nparam adminKey string\nparam subnetId string\n\n", "note": "What the workers need from outside: a public key to sign in with and the subnet their network interfaces go in, both given by whoever deploys the file. Unlike lesson 4's set there is no load balancer: nothing sends requests to a worker, because workers go and fetch their jobs."}, {"code": "resource workers 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' = {\n  name: 'shop-workers'\n  location: location\n  zones: ['1', '2', '3']\n  sku: {\n    name: 'Standard_D2s_v5'\n    tier: 'Standard'\n    capacity: 10\n  }\n  properties: {\n", "note": "Ten instances of the size lesson 1 read letter by letter, spread over the three zones of `brazilsouth`."}, {"code": "    orchestrationMode: 'Flexible'\n    platformFaultDomainCount: 1\n    singlePlacementGroup: false\n", "note": "Flexible, as in lesson 4, and here it is required: Spot Priority Mix works only in Flexible mode, and not with a single placement group."}, {"code": "    priorityMixPolicy: {\n      baseRegularPriorityCount: 2\n      regularPriorityPercentageAboveBase: 25\n    }\n", "note": "The mix. The first two instances are regular; above them, a quarter are regular and three quarters are Spot."}, {"code": "    spotRestorePolicy: {\n      enabled: true\n      restoreTimeout: 'PT1H'\n    }\n", "note": "Try and restore, with an hour to try in. A part of this section below says what it does and when it is switched off."}, {"code": "    virtualMachineProfile: {\n      priority: 'Spot'\n      evictionPolicy: 'Delete'\n      billingProfile: {\n        maxPrice: -1\n      }\n", "note": "The same three properties as the report machine, inside the profile every instance is made from. The priority says Spot, and the mix decides which instances are made regular anyway. An evicted worker is deleted with its disk."}, {"code": "      storageProfile: {\n        imageReference: {\n          publisher: 'Canonical'\n          offer: 'ubuntu-24_04-lts'\n          sku: 'server'\n          version: 'latest'\n        }\n        osDisk: {\n          createOption: 'FromImage'\n          managedDisk: {\n            storageAccountType: 'Premium_LRS'\n          }\n        }\n      }\n      osProfile: {\n        computerNamePrefix: 'worker'\n        adminUsername: adminUser\n        linuxConfiguration: {\n          disablePasswordAuthentication: true\n          ssh: {\n            publicKeys: [\n              {\n                path: '/home/${adminUser}/.ssh/authorized_keys'\n                keyData: adminKey\n              }\n            ]\n          }\n        }\n      }\n      networkProfile: {\n        networkApiVersion: '2020-11-01'\n        networkInterfaceConfigurations: [\n          {\n            name: 'worker-nic'\n            properties: {\n              primary: true\n              ipConfigurations: [\n                {\n                  name: 'ipconfig'\n                  properties: {\n                    subnet: {\n                      id: subnetId\n                    }\n                  }\n                }\n              ]\n            }\n          }\n        ]\n      }\n    }\n  }\n}\n", "note": "The rest is lesson 4's profile without the load balancer and the health extension: an Ubuntu image, a disk, a name prefix, a key, and a network interface in the subnet."}]}
```

Compile it, and read back the parts that are new:

```
ana@laptop:~/azure$ bicep build workers-vmss.bicep
ana@laptop:~/azure$ jq ".resources[0].properties | {priorityMixPolicy, spotRestorePolicy, priority: .virtualMachineProfile.priority, evictionPolicy: .virtualMachineProfile.evictionPolicy}" workers-vmss.json
{
  "priorityMixPolicy": {
    "baseRegularPriorityCount": 2,
    "regularPriorityPercentageAboveBase": 25
  },
  "spotRestorePolicy": {
    "enabled": true,
    "restoreTimeout": "PT1H"
  },
  "priority": "Spot",
  "evictionPolicy": "Delete"
}
```

**At ten instances, the base takes the first two as regular, and the percentage splits the other
eight**: 25% of eight is two more regular, and six are Spot. Four regular and six Spot, and the four
are what is left on the worst night, when every Spot instance is evicted at once. As the set grows
the base stays at two and the split applies above it: at thirty, two plus 25% of twenty-eight, so
nine regular and twenty-one Spot. When the share above the base does not come out whole, the
documentation's worked examples round the regular part down and give the odd instance to Spot. With
a base of ten and 25%, twenty instances are twelve regular and eight Spot, because 2.5 became 2. The
documentation also says three things the file cannot show. The mix needs Flexible orchestration; it
does not work with a single placement group; and changing the two numbers changes only what the set
does at its next scale operation, so the machines already running are not rebalanced.

The command line's help puts limits on the same two numbers:

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o -- "--regular-priority-[a-z]* \[Preview\] : [^.]*\. Must be [^.]*\."
--regular-priority-count [Preview] : The base number of regular priority VMs that will be created in this scale set as it scales out. Must be greater than 0.
--regular-priority-percentage [Preview] : The percentage of VM instances, after the base regular priority count has been reached, that are expected to use regular priority. Must be between 0 and 100.
```

The percentage agrees with the compiler's type, 0 to 100. The count disagrees with the
documentation: the help says it must be greater than 0, and the Spot Priority Mix FAQ says a base of
0 is allowed, though production work should keep some. A laptop cannot settle which is right, and
this file uses 2.

Four mistakes, in a copy of the file:

```
ana@laptop:~/azure$ sed -e 's/AboveBase: 25/AboveBase: 150/' -e "s/restoreTimeout: 'PT1H'/restoreTimeout: 60/" -e "s/'Flexible'/'Uniform'/" -e "s/'Delete'/'delete'/" workers-vmss.bicep > workers-wrong.bicep
ana@laptop:~/azure$ diff workers-vmss.bicep workers-wrong.bicep
17c17
<     orchestrationMode: 'Flexible'
---
>     orchestrationMode: 'Uniform'
22c22
<       regularPriorityPercentageAboveBase: 25
---
>       regularPriorityPercentageAboveBase: 150
26c26
<       restoreTimeout: 'PT1H'
---
>       restoreTimeout: 60
30c30
<       evictionPolicy: 'Delete'
---
>       evictionPolicy: 'delete'
ana@laptop:~/azure$ bicep build workers-wrong.bicep
/home/ana/azure/workers-wrong.bicep(22,43) : Warning BCP327: The provided value (which will always be greater than or equal to 150) is too large to assign to a target for which the maximum allowable value is 100. [https://aka.ms/bicep/core-diagnostics#BCP327]
/home/ana/azure/workers-wrong.bicep(26,23) : Warning BCP036: The property "restoreTimeout" expected a value of type "null | string" but the provided value is of type "60". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**Two are refused and two compile in silence.** A percentage of 150 is caught, because the type
knows the range, and so is a timeout of `60`, because a timeout is a string in ISO 8601 such as
`PT1H`. The type does not check that the string is a duration, so `'one hour'` would pass as well.
`'Uniform'` compiles, though the documentation says plainly that Spot Priority Mix works only with
Flexible, and `'delete'` compiles for the same reason `'spot'` did in the first section: the
compiler has no list for it. **The compiler checks each property on its own, not the rules that tie
properties together**: those live in Microsoft's documentation and in Azure's answer to a
deployment, and neither can be asked from here.

## Try and restore

`spotRestorePolicy` is the other new block. With it on, the scale set itself tries to restore Spot
instances that were evicted for capacity, so that it keeps its target count, and gives up after the
`restoreTimeout`, an hour in this file. The documentation describes it as a platform feature that
uses AI to pick where to restore them, and expects restored instances to live longer. It has one
condition worth remembering: **try and restore is disabled on a scale set that has autoscale**,
because then the count belongs to the autoscale rules of lesson 4. The workers have no autoscale
setting, so it applies to them. For a Spot set that does have autoscale, the documentation advises
`Delete`, so that evicted instances do not hold disks and quota while autoscale replaces them.

## What fits, and what never does

What fits has one thing in common: losing any one machine loses no work that cannot be done again.

- **Batch jobs that checkpoint**, like the report: an eviction costs the minutes since the last
  checkpoint.
- **Workers behind a queue**, and the part of any stateless service above its minimum: a job that is
  not completed comes back, so an eviction costs one job done twice.
- **CI build agents and test environments**: an interrupted build runs again, and builds are made to
  be repeatable. Microsoft's own list of good fits names batch processing, dev and test, and build
  agents for non-production work.

And what never goes on Spot:

- **A single machine holding state**: the shop's only database server, or a machine whose disk is
  the only copy of anything.
- **The minimum a service needs to stay up.** If the order API needs three machines to answer at
  all, three regular machines are the base, and only what is above them is Spot.
- **Anything that needs capacity now.** The FAQ's answer to "what if I am evicted and still need the
  capacity" is to use standard machines.
- **Long jobs that cannot checkpoint**, because the longer the job, the more likely an eviction lands
  inside it, and each one starts it again.

## What an eviction costs, in numbers

The report makes the arithmetic concrete. Every number here is illustrative and none is Azure's.
The rates are the first section's, 0.10 USD an hour regular and 0.03 USD on Spot. **The eviction
rate is 10% an hour**, the kind of figure the portal shows. A restart takes ten minutes, supposing
capacity comes back, and the report is four hours of work, started at 01:00 and needed by 07:00. Four hours at 10% an hour carry about 0.4
evictions on average. A night passes with none 0.9 × 0.9 × 0.9 × 0.9 = 66% of the time, so one
night in three has at least one.

| | regular | Spot, no checkpoint | Spot, checkpoint every 30 min |
| --- | --- | --- | --- |
| evictions expected a night | 0 | 0.4 | 0.4 |
| work lost per eviction, on average | none | 2 h 10 min | 25 min |
| expected hours a night | 4.00 | 4.87 | 4.17 |
| expected cost a night | 0.40 USD | 0.15 USD | 0.13 USD |
| nights finishing after 07:00 | none | about one in six | almost none |

Without checkpoints an eviction lands halfway through on average and loses two hours plus the
restart: 4 + 0.4 × 2.17 = 4.87 hours. With a checkpoint every thirty minutes it loses fifteen
minutes plus the restart: 4 + 0.4 × 0.42 = 4.17 hours. The costs are those hours at 0.03, rounded
to the cent, and all of it is a first-order estimate that ignores evictions during the extra hours.
The last row is the one that decides: a report with no checkpoint that is evicted after about 02:50
cannot start again from nothing and finish by 07:00, and a first eviction lands in that stretch on
about 17% of nights.

**On money Spot wins both times; on the clock it loses one of them.** What an eviction costs is the
work it throws away and the deadline it moves, and a checkpoint is what makes the discount safe to
take.
