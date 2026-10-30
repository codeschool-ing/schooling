---
title: What answers, and what does not
version: 1
---

Every lesson of this course is about something Azure runs, and almost none of it can be created on
a laptop. **So each section is one of two kinds, and it tells you which.** A *practised* section
has transcripts that were recorded in the lab of the previous section, command by command, with
the output pasted as the machine printed it. A *read* section is taught from Microsoft's
documentation: it shows the command you would type against a real subscription, says plainly that
it was not run, and shows no output, because any output shown would have been invented.

That second kind is not a lesser lesson. A scale set's upgrade policy, an AKS maintenance window or
an App Service slot swap is a decision written in a few lines and carried out by Microsoft's
machines; what you need to learn is what those lines say and what happens after them, and the
documentation is the authority on both. What a read section cannot give you is the feel of the
thing failing, and the lessons say where that matters.

## What runs on the laptop

| what | stands in for | from lesson |
| --- | --- | --- |
| the Azure CLI, without an account | its help, its offline lists, and the refusal you met in the last section | 1 |
| the Bicep compiler | the check Azure makes of a declaration's shape, before anything is created | 1 |
| Docker running the shop's image | the container that Container Instances, Container Apps, AKS and App Service would run | 7 |
| Dapr's sidecar in a container | Dapr as Container Apps hosts it | 9 |
| a local registry | the push, pull, tag and digest half of Container Registry | 10 |
| kind, Kubernetes in Docker containers | the Kubernetes that AKS manages, but not AKS itself | 11 |
| the Functions host, in Microsoft's image, with Azurite for storage | a function app's runtime, triggers and bindings | 15 |
| the Service Bus and Event Hubs emulators | the two services' data planes: sending, receiving, partitions | 20 |

**What none of them reproduces is the control plane**: the part of Azure that creates a resource,
places it in a datacentre, bills it and enforces your permissions on it. A virtual machine, a scale
set, a disk, an availability zone, a Spot eviction, an AKS upgrade, a Container Apps revision, an
App Service plan, a Logic App, an Event Grid topic: each of those is taught by reading, and each
time the section says so.

## The compiler as the closest thing to Azure

One tool earns a place in almost every lesson, and it is worth seeing what it does before the
first one leans on it. A Bicep file declares resources; `azure-operations` lessons 4 and 5 teach
the language properly, and this course uses only the plainest part of it. The compiler turns the
file into the JSON template that Resource Manager accepts. **On the way, it checks every property
against the resource types Microsoft publishes for each API version, without a subscription.**

Here is a data disk for the shop, declared with two mistakes in it. Save it as `check.bicep`:

```bicep
// check.bicep
param location string = 'brazilsouth'

resource disk 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-data'
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: '128'
    burstingEnabeld: true
  }
}
```

And compile it:

```
ana@laptop:~/azure$ bicep build check.bicep
/home/ana/azure/check.bicep(14,17) : Warning BCP036: The property "diskSizeGB" expected a value of type "int | null" but the provided value is of type "'128'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
/home/ana/azure/check.bicep(15,5) : Warning BCP089: The property "burstingEnabeld" is not allowed on objects of type "DiskProperties". Did you mean "burstingEnabled"? [https://aka.ms/bicep/core-diagnostics#BCP089]
ana@laptop:~/azure$ ls
check.bicep
check.json
venv
```

Both mistakes were found: a size written as text where the disk API takes a number, and a property
name with two letters swapped, with the right spelling suggested. **But they are warnings, and the
template was written anyway**, as `check.json`. The compiler knows the types, and it also knows
that Microsoft's published types are sometimes behind the service, which is what the sentence about
reporting an inaccuracy is for. So it tells you and carries on. What Azure would do with the file as
it stands is decided by the disk service, not by the compiler: it might refuse the text where a
number belongs, and it might drop the misspelt property without a word and create a disk without
the bursting you asked for. A laptop cannot find out which.

**Treat every warning as a refusal.** In this course a declaration is finished when it compiles
with no warnings at all, because that is the strongest check anybody can make of it without a
subscription. What the compiler cannot know is whether the request would succeed: whether the size
is offered in `brazilsouth`, whether your subscription has the quota, whether a name is taken.
Those are answered only by Azure, and the lessons say so where they matter.

The template itself is ordinary JSON, and `jq` can read it:

```
ana@laptop:~/azure$ jq ".resources[0] | {type, apiVersion, name}" check.json
{
  "type": "Microsoft.Compute/disks",
  "apiVersion": "2024-03-02",
  "name": "shop-data"
}
```

That type and API version pair, `Microsoft.Compute/disks@2024-03-02`, is how Resource Manager
names what a request is about. Every resource in this course has one, and `azure-foundations`
lesson 25 says how the API behind it works.

## The command line without an account

The CLI still teaches without a subscription. Its help text is generated from the same definitions
that build its requests, so it states what each parameter accepts and what is chosen when you say
nothing. Asked what size `az vm create` gives a machine when no size is named:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "Default: Standard_[A-Za-z0-9_]*"
Default: Standard_D2s_v5
```

That is a real default, chosen by Microsoft and written into this version of the CLI, and the next
section reads it letter by letter. Where a lesson writes an `az` command that needs a subscription,
it says so and shows no output.

## Prices

**This course quotes no price from Azure's price list.** The machine its transcripts were recorded
on could not reach Microsoft's pricing pages or the Retail Prices API, and a price copied from
memory would be the one kind of number a reader cannot check. Where a lesson needs arithmetic, it
uses round rates and says each time that they are illustrative, not Azure's: the reasoning is the
same at any price, and lesson 21 shows how to put real ones in.

You can read the real ones yourself. The Retail Prices API needs no account and no key, and
answers in JSON; this request asks for the hourly price of the size above in São Paulo. It was not
run in this course:

```sh
curl -s "https://prices.azure.com/api/retail/prices?\$filter=armRegionName%20eq%20'brazilsouth'%20and%20armSkuName%20eq%20'Standard_D2s_v5'" | jq '.Items[] | {productName, meterName, retailPrice, unitOfMeasure}'
```

It answers with one item per way of paying for that size: Linux and Windows, pay as you go, Spot
and the reservations. Lesson 5 is about why there are so many. A figure that IS in Microsoft's
documentation, such as a free monthly grant or a discount ceiling, is quoted with the date the
documentation was read, which for this course was 30 October 2026.
