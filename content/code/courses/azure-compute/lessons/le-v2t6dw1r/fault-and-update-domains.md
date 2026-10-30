---
title: Fault domains, update domains and the availability set
version: 1
---

Two virtual machines running the same program look like redundancy, and on a diagram they are.
**Whether they are redundant depends on what they share.** Two machines on one physical host stop
together when that host fails. Two on different hosts in the same rack stop together when the
rack loses its power or its network switch. So redundancy is always redundancy against something,
and the question to ask of any design is how big the thing is that fails:

| what fails | what it takes with it | what keeps a copy outside it |
|---|---|---|
| one host | every machine running on that server | a second machine on another host |
| a rack's power or network switch | every host in the rack | a different fault domain |
| a planned reboot for maintenance | one group of hosts at a time | a different update domain |
| a datacentre's power, cooling or network | every rack in the building | a different availability zone |
| a region | every zone in it | a second region |

This section is about the second and third rows, which an availability set answers. The next
section is the fourth. The fifth is where `azure-foundations` lesson 1 left off, with each region's
pair, and section 05 of this lesson says what that leaves for you to do.

## Two numbers for every machine

When a virtual machine is created in an availability set, Azure gives it two numbers, and neither
is yours to choose.

A **fault domain** is a group of machines that share a power source and a network switch. A
failure there is unplanned: a power supply dies, a switch stops forwarding, and everything behind
it goes at once. Microsoft's overview of availability sets, read on 2026-10-30, says a set has up
to 3 fault domains and that its machines are separated across them.

An **update domain** is a group of machines, and the hardware under them, that may be restarted
at the same time. A set has up to 20. When planned maintenance needs a reboot, **only one update
domain is restarted at a time**, and a restarted one has 30 minutes to recover before maintenance
starts on the next. The documentation does not promise the order, only the one-at-a-time.

Neither count can be changed once the set exists. With five update domains, the sixth machine goes
into the same update domain as the first, the seventh with the second, and so on. Here are six
machines of the shop's order API in a set of two fault domains and five update domains, and the two
different things that can happen to them:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"Two grids of the same availability set, two fault domains as rows and five update domains as columns, holding six machines: web-1, web-3 and web-5 in fault domain 0 under update domains 0, 2 and 4; web-2, web-4 and web-6 in fault domain 1 under update domains 1, 3 and 0. Left: fault domain 1 loses power and its three machines are down. Right: maintenance reboots update domain 2 and only web-3 is down.\"><text x=\"182\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">a rack loses power</text><text x=\"225.0\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">update domain</text><text x=\"129.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"177.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"225.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"273.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"321.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"14\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fault domain 0</text><rect x=\"108\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"129.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-1</text><rect x=\"156\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"204\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"225.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-3</text><rect x=\"252\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"300\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"321.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-5</text><text x=\"14\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fault domain 1</text><rect x=\"108\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"129.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-6</text><rect x=\"156\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"177.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-2</text><rect x=\"204\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"252\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"273.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-4</text><rect x=\"300\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"104\" y=\"116\" width=\"242\" height=\"44\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"182\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the row goes: web-2, web-4 and web-6, three of six</text><text x=\"538\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">maintenance reboots one update domain</text><text x=\"581.0\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">update domain</text><text x=\"485.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"533.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"581.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"629.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><text x=\"677.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"370\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fault domain 0</text><rect x=\"464\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-1</text><rect x=\"512\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"560\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"581.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">web-3</text><rect x=\"608\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"656\" y=\"74\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"677.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-5</text><text x=\"370\" y=\"138.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fault domain 1</text><rect x=\"464\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-6</text><rect x=\"512\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"533.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-2</text><rect x=\"560\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"608\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"629.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">web-4</text><rect x=\"656\" y=\"120\" width=\"42\" height=\"36\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><rect x=\"556\" y=\"70\" width=\"50\" height=\"90\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"538\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one column at a time: web-3 only, five of six answer</text><path d=\"M360 36 L360 196\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path></svg>", "caption": "Six machines of the shop in one availability set with two fault domains and five update domains. An unplanned failure takes a row and a planned reboot takes a column. The sixth machine shares update domain 0 with the first, as the documentation says it will; which fault domain each lands in is Azure's choice, and this is one placement it might make."}
```

The figure is why both numbers exist. **A rack failure takes a row, and a maintenance reboot takes
a column**: half the shop goes in the first case and five of six machines keep answering in the
second. Which machine lands in which fault domain is Azure's decision, so the figure is one
placement it might make; the wrapping of update domains is the documented part.

The reboot is rarer than the figure makes it look. Microsoft's page on maintenance says most
platform updates do not touch the machines at all. When one has to, it is almost always a pause of
under ten seconds, or a live migration of the running machine to a host already updated, and that
kind is applied one fault domain at a time. A maintenance that needs a reboot is announced first,
with a self-service phase that typically lasts four weeks in which you may start it yourself at a
time that suits you. Lesson 5's Scheduled Events are how a machine hears about either kind before
it happens.

## Disks are spread as well

A machine's managed disks are aligned with its fault domain, so a machine and its disks fail
together or not at all. A set whose `sku` is `Aligned` is a managed set, and only machines with
managed disks can be created in one. **The number of disk fault domains differs by region: each has
two or three.** Microsoft documents a command that lists, region by region, the largest fault domain
count an aligned set may have. It needs a subscription and was not run in this course:

```sh
az vm list-skus --resource-type availabilitySets --query '[?name==`Aligned`].{Location:locationInfo[0].location, MaximumFaultDomainCount:capabilities[0].value}' -o Table
```

One sequence puts two machines in the same fault domain anyway: create the first machine, stop and
deallocate it, then create the second. The second machine's disk may then land in the fault domain
the first was in. The documented advice is to leave the first one running until the second exists.

## The set, in Bicep

Two machines of the shop's order API, `shop-web-1` and `shop-web-2`, in one set. The load balancer
of `azure-foundations` lesson 22 would sit in front of them, and the file leaves it out to stay with
what this lesson is about. Save it as `shop-avset.bicep`:

```schooling-example
{"language": "bicep", "file": "shop-avset.bicep", "parts": [{"code": "// shop-avset.bicep\nparam location string = 'brazilsouth'\nparam adminUsername string = 'ana'\nparam sshPublicKey string\n\nresource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {\n  name: 'shop-vnet'\n}\n\nresource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {\n  parent: vnet\n  name: 'app'\n}\n\n", "note": "What the machines stand on, named and not created: the network of `azure-foundations` lesson 16 and its `app` subnet. `sshPublicKey` has no default, so whoever deploys the file supplies a key."}, {"code": "resource avset 'Microsoft.Compute/availabilitySets@2024-07-01' = {\n  name: 'shop-avset'\n  location: location\n  sku: {\n    name: 'Aligned'\n  }\n  properties: {\n    platformFaultDomainCount: 2\n    platformUpdateDomainCount: 5\n  }\n}\n\n", "note": "**The set itself.** `Aligned` makes it a managed set, the kind machines with managed disks go in. The two counts are fixed for the life of the set: two fault domains, which every region's disks can match, and five update domains."}, {"code": "resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(1, 2): {\n  name: 'shop-web-${i}-nic'\n  location: location\n  properties: {\n    ipConfigurations: [\n      {\n        name: 'ipconfig'\n        properties: {\n          subnet: {\n            id: subnet.id\n          }\n        }\n      }\n    ]\n  }\n}]\n\n", "note": "One network interface per machine. `range(1, 2)` is two numbers starting at 1, so the loop makes `shop-web-1-nic` and `shop-web-2-nic`."}, {"code": "resource vm 'Microsoft.Compute/virtualMachines@2024-07-01' = [for i in range(1, 2): {\n  name: 'shop-web-${i}'\n  location: location\n  properties: {\n    availabilitySet: {\n      id: avset.id\n    }\n    hardwareProfile: {\n      vmSize: 'Standard_D2s_v5'\n    }\n", "note": "**The line that puts each machine in the set.** It is written in the machine, and only at creation. The size is lesson 1's default, `Standard_D2s_v5`."}, {"code": "    storageProfile: {\n      imageReference: {\n        publisher: 'Canonical'\n        offer: 'ubuntu-24_04-lts'\n        sku: 'server'\n        version: 'latest'\n      }\n      osDisk: {\n        createOption: 'FromImage'\n        managedDisk: {\n          storageAccountType: 'Premium_LRS'\n        }\n      }\n    }\n    osProfile: {\n      computerName: 'shop-web-${i}'\n      adminUsername: adminUsername\n      linuxConfiguration: {\n        disablePasswordAuthentication: true\n        ssh: {\n          publicKeys: [\n            {\n              path: '/home/${adminUsername}/.ssh/authorized_keys'\n              keyData: sshPublicKey\n            }\n          ]\n        }\n      }\n    }\n    networkProfile: {\n      networkInterfaces: [\n        {\n          id: nic[i - 1].id\n        }\n      ]\n    }\n  }\n}]\n", "note": "The rest is any Linux machine, as lesson 2 wrote it. `Premium_LRS` is the disk type the next section's single-machine figure depends on; in a set, the set's figure applies instead. `nic[i - 1]` is this machine's interface, since the loop counts from 1 and the list from 0."}]}
```

Compile it, and look at what the template holds:

```
ana@laptop:~/azure$ bicep build shop-avset.bicep
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, copy: .copy.count}" shop-avset.json
{"type":"Microsoft.Compute/availabilitySets","name":"shop-avset","copy":null}
{"type":"Microsoft.Network/networkInterfaces","name":"[format('shop-web-{0}-nic', range(1, 2)[copyIndex()])]","copy":"[length(range(1, 2))]"}
{"type":"Microsoft.Compute/virtualMachines","name":"[format('shop-web-{0}', range(1, 2)[copyIndex()])]","copy":"[length(range(1, 2))]"}
ana@laptop:~/azure$ jq ".resources[0].properties" shop-avset.json
{
  "platformFaultDomainCount": 2,
  "platformUpdateDomainCount": 5
}
```

Three resources, two of them written once and created twice: `copy` is how the template says "this
many", and the loop became one. The two counts went into the template as the numbers written. Here
is what the command line does when nobody writes them:

```
ana@laptop:~/azure$ az vm availability-set create --help | tr -s "[:space:]" " " | grep -o "\-\-platform-[a-z-]*-count : [^.]*\.[^.]*\."
--platform-fault-domain-count : Fault Domain count. Default: 2.
--platform-update-domain-count : Update Domain count. If unspecified, the server will pick the most optimal number like 5.
```

So a set created from the CLI with no counts gets two fault domains, and the server picks the
update domains. The shop's file writes both. **Two is a fault domain count every region's disks can
meet.** With two fault domains and five update domains, the two machines take different update
domains, because the wrapping only starts at the sixth, and the set separates them across its fault
domains. A rack failure takes at most one of them, and so does a maintenance reboot.

## A machine joins a set when it is created, or never

The set is named inside the machine, in `properties.availabilitySet`, and not the other way round.
That direction has a consequence that the SDK installed with the CLI writes in its own description
of the property:

```
ana@laptop:~/azure$ grep -m1 -A10 ':ivar availability_set:' venv/lib/python3.12/site-packages/azure/mgmt/compute/v2024_11_01/models/_models_py3.py
    :ivar availability_set: Specifies information about the availability set that the virtual
     machine should be assigned to. Virtual machines specified in the same availability set are
     allocated to different nodes to maximize availability. For more information about availability
     sets, see `Availability sets overview
     <https://docs.microsoft.com/azure/virtual-machines/availability-set-overview>`_. For more
     information on Azure planned maintenance, see `Maintenance and updates for Virtual Machines in
     Azure <https://docs.microsoft.com/azure/virtual-machines/maintenance-and-updates>`_. Currently,
     a VM can only be added to availability set at creation time. The availability set to which the
     VM is being added should be under the same resource group as the availability set resource. An
     existing VM cannot be added to an availability set. This property cannot exist along with a
     non-null properties.virtualMachineScaleSet reference.
```

**A running machine cannot be moved into a set.** If `shop-web-1` already runs on its own, the way
into a set is a new machine created there, so the set is decided before the first deployment.
Deploying the file would be the command below, not run in this course, because it needs a
subscription and two machines that are billed:

```sh
az deployment group create --resource-group shop --template-file shop-avset.bicep --parameters sshPublicKey="$(cat ~/.ssh/id_ed25519.pub)"
```

## What the compiler checks here

A copy of the file with two mistakes in it: four fault domains, where a set has at most three, and
the update domain count written as text:

```
ana@laptop:~/azure$ sed -e 's/platformFaultDomainCount: 2/platformFaultDomainCount: 4/' -e "s/platformUpdateDomainCount: 5/platformUpdateDomainCount: '5'/" shop-avset.bicep > avset-wrong.bicep
ana@laptop:~/azure$ diff shop-avset.bicep avset-wrong.bicep
22,23c22,23
<     platformFaultDomainCount: 2
<     platformUpdateDomainCount: 5
---
>     platformFaultDomainCount: 4
>     platformUpdateDomainCount: '5'
ana@laptop:~/azure$ bicep build avset-wrong.bicep
/home/ana/azure/avset-wrong.bicep(23,32) : Warning BCP036: The property "platformUpdateDomainCount" expected a value of type "int | null" but the provided value is of type "'5'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

**One warning, for two mistakes.** Text where a number belongs is a type error, and the compiler
knows the type. Four is a number. That a set stops at three fault domains, and at the two or three
its region's disks have, is written in Microsoft's documentation and not in the type, so only
Resource Manager would refuse it, at deployment. Lesson 1's rule again: no warning means the shape
is right, not the values.

## Close together on purpose

Spreading machines apart costs distance, and some workloads would rather pay the other way. A
**proximity placement group** is a resource that keeps the machines named in it physically close,
for the lowest network latency between them. It is a colocation constraint: the first resource
deployed into it pins it to one datacentre, and it is unpinned once all of them are deallocated or
deleted. An availability set or a scale set is placed in one as a whole, at the level of the set
rather than machine by machine. **It moves in the opposite direction from everything else in this
lesson**, trading the protection of distance for speed, and section 05 says when that trade is
worth making.
