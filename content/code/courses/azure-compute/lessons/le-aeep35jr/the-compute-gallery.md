---
title: The Compute Gallery, from definition to version
version: 1
---

A gallery sounds like a folder that images are dropped into. **An Azure Compute Gallery is three
kinds of resource, nested**: the gallery, which is a container you control access to; inside it an
*image definition*, which says what kind of image something is; and inside each definition the
*image versions*, which are the images. A machine is never created from a definition. It is
created from a version, either one you name or the one the definition currently calls `latest`.

```schooling-figure
{"svg": "<svg id=\"fig-gallery-nesting\" viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Nesting: the gallery shopgallery in brazilsouth holds the image definition shop-web, which carries publisher shop, offer shop-web, sku ubuntu-24_04, osState Generalized and hyperVGeneration V2. The definition holds three image versions. 1.0.0 is replicated to brazilsouth three times and southcentralus once. 1.1.0 is replicated to brazilsouth three times and is what latest resolves to. 1.2.0 is marked excludeFromLatest, so a VM that names only the definition gets 1.1.0.\"><defs><marker id=\"gallery-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"688\" height=\"312\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">gallery: shopgallery, brazilsouth</text><rect x=\"34\" y=\"48\" width=\"652\" height=\"196\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">image definition: shop-web</text><rect x=\"48\" y=\"82\" width=\"196\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">publisher: shop</text><text x=\"60\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">offer: shop-web</text><text x=\"60\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sku: ubuntu-24_04</text><text x=\"60\" y=\"179\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">osState: Generalized</text><text x=\"60\" y=\"204\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">hyperVGeneration: V2</text><text x=\"270\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">image versions</text><rect x=\"270\" y=\"82\" width=\"126\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"333\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">1.0.0</text><text x=\"333\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">brazilsouth ×3,</text><text x=\"333\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">southcentralus ×1</text><rect x=\"410\" y=\"82\" width=\"126\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"473\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">1.1.0</text><text x=\"473\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">brazilsouth ×3</text><text x=\"473\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">what latest resolves to</text><rect x=\"550\" y=\"82\" width=\"126\" height=\"146\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"613\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">1.2.0</text><text x=\"613\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">brazilsouth ×1,</text><text x=\"613\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">for testing</text><text x=\"613\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">excluded from latest</text><rect x=\"200\" y=\"268\" width=\"320\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"360\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a VM naming only the definition</text><text x=\"360\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">is created from 1.1.0</text><line x1=\"473\" y1=\"228\" x2=\"420\" y2=\"266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#gallery-ah)\"></line></svg>", "caption": "The definition says what kind of image it is and never changes; the versions are the images. latest is the highest version number that is not excluded."}
```

## The definition: what kind of image this is

A definition carries its own three names, a publisher, an offer and a SKU, chosen by you and
shaped like a Marketplace image's. Two definitions may share one or two of them but never all
three, and Microsoft's documentation suggests copying the Marketplace image's own names when your
image is a customised one of theirs, so the operating system is readable at a glance. Beside the
names, the definition states what every version inside it must be:

- `osType`, `Linux` or `Windows`;
- `osState`, `Generalized` or `Specialized`, which is the previous section's choice: a version
  captured from a deprovisioned machine goes into a generalised definition;
- `hyperVGeneration`, `V1` or `V2`, the generation from the first section of this lesson;
- `architecture`, `x64` or `Arm64`;
- `features`, among them the security types a version supports, such as `TrustedLaunchSupported`:
  a generation 2 image that machines may be created from with or without Trusted Launch.

**These are fixed when the definition is created.** The documentation lists what can be changed
afterwards, and for a definition it is the description, the recommended processor and memory
counts, the release notes and an end-of-life date. A definition declared with the wrong generation
is replaced, not edited.

## The version: the image itself

A version's name is its number, `MAJOR.MINOR.PATCH`, three whole numbers and nothing else:
`1.0.0`, `1.1.0`, `1.10.2`. Its source is a captured machine, a disk, a snapshot, a managed image
or another version. And its *publishing profile* says where its copies live:

- **target regions**, each with a number of *replicas*. A replica is a copy, and a region's machine
  creations are spread across its replicas. Each region also gets a storage type, locally redundant
  (`Standard_LRS`) or zone-redundant (`Standard_ZRS`) in a region with availability zones;
- **`excludeFromLatest`**, which keeps the version out of `latest` while leaving it usable by
  number;
- **`endOfLifeDate`**, a date after which the version should not be used.

**`latest` is the highest version number that is not excluded**, compared as numbers, major first,
then minor, then patch. So `1.10.0` is later than `1.9.4`, as it would not be in an alphabetical
sort, and in the figure `1.2.0` exists and is still not `latest`, because it was published
excluded while it is being tried. A machine declaration that names the definition's id gets
`latest` at creation; one that names a version's id, ending in `/versions/1.1.0`, gets exactly that
version. Microsoft recommends the definition's id unless a specific version is needed, because a
named version that was deleted or never replicated to a region makes the deployment fail. That is
the Marketplace's `latest` again, with one difference: **here you decide what `latest` means**, by
publishing, excluding and numbering.

An end-of-life date is a statement and nothing more. In the documentation's words it is
informational, and machines can still be created from a version past it. Whatever tells people to
move off an old version has to be something you build.

The documentation's sizing rule for replicas is one replica for every twenty machines created at the
same moment from the version, and one per scale set created at the same time, and at least three for
production images. A region that will create sixty machines at once wants three replicas.

What a version costs is its copies. Each replica is stored and billed as a snapshot of the image's
**occupied** size, not its disk size: the documentation's example is a 127 GB OS disk holding
10 GB, replicated to three regions with two replicas in each, which is six snapshots of 10 GB.
Copying the first replica to each other region is billed as outbound data; the extra replicas
inside a region are not.

## Declaring one

Here are the shop's gallery, a definition for its web machines, and a first version captured from
a generalised machine whose id is a parameter. Save it as `gallery.bicep`:

```bicep
// gallery.bicep
param location string = 'brazilsouth'
@description('The generalised VM the version is captured from')
param sourceVmId string

resource gallery 'Microsoft.Compute/galleries@2024-03-03' = {
  name: 'shopgallery'
  location: location
  properties: {
    description: 'Images for the shop'
  }
}

resource web 'Microsoft.Compute/galleries/images@2024-03-03' = {
  parent: gallery
  name: 'shop-web'
  location: location
  properties: {
    osType: 'Linux'
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    architecture: 'x64'
    identifier: {
      publisher: 'shop'
      offer: 'shop-web'
      sku: 'ubuntu-24_04'
    }
    features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunchSupported'
      }
    ]
  }
}

resource v100 'Microsoft.Compute/galleries/images/versions@2024-03-03' = {
  parent: web
  name: '1.0.0'
  location: location
  properties: {
    storageProfile: {
      source: {
        virtualMachineId: sourceVmId
      }
    }
    publishingProfile: {
      replicaCount: 1
      excludeFromLatest: false
      endOfLifeDate: '2027-10-30T00:00:00Z'
      targetRegions: [
        {
          name: 'brazilsouth'
          regionalReplicaCount: 3
          storageAccountType: 'Standard_ZRS'
        }
        {
          name: 'southcentralus'
          regionalReplicaCount: 1
          storageAccountType: 'Standard_LRS'
        }
      ]
    }
  }
}
```

The version keeps three replicas in São Paulo on zone-redundant storage and one in South Central
US, the region the shop would recreate its machines in if São Paulo were unavailable. Lesson 6 is
about what that does and does not protect against. The default `replicaCount` of 1 applies only to
a target region that does not give its own. And every property whose default has moved between API
versions is written down: the documentation says a definition created through API version
`2025-03-03` or later defaults to `V2` and `TrustedLaunchSupported`, while this file uses
`2024-03-03`, whose definition with no generation is `V1`. Compile it:

```
ana@laptop:~/azure$ bicep build gallery.bicep
ana@laptop:~/azure$ jq -r ".resources[] | [.type, .name] | @tsv" gallery.json
Microsoft.Compute/galleries	shopgallery
Microsoft.Compute/galleries/images	[format('{0}/{1}', 'shopgallery', 'shop-web')]
Microsoft.Compute/galleries/images/versions	[format('{0}/{1}/{2}', 'shopgallery', 'shop-web', '1.0.0')]
```

The nesting is in the names: `shop-web` is inside `shopgallery`, and `1.0.0` inside both. Now two
mistakes a person with British spelling and a lowercase habit could make:

```
ana@laptop:~/azure$ sed -i "s/Generalized/Generalised/; s/V2/v2/" gallery.bicep
ana@laptop:~/azure$ bicep build gallery.bicep
/home/ana/azure/gallery.bicep(20,14) : Warning BCP088: The property "osState" expected a value of type "'Generalized' | 'Specialized'" but the provided value is of type "'Generalised'". Did you mean "'Generalized'"? [https://aka.ms/bicep/core-diagnostics#BCP088]
ana@laptop:~/azure$ sed -i "s/Generalised/Generalized/; s/v2/V2/" gallery.bicep
```

`osState` is one of exactly two values to the compiler, so the British `Generalised` is refused,
with the right spelling offered. `v2` for `V2` went through without a word: `hyperVGeneration`,
like the security type in the previous section, is a string the compiler cannot check. **What a
warning catches is what Microsoft's types happen to make strict, and nothing more.** The last
command put both back.

## Who may use it

A gallery is private to your subscription until it is shared, and there are three ways to share it,
each wider than the last:

| shared with | how | what the other side sees |
|---|---|---|
| people, groups, service principals | Azure RBAC, a role on the gallery | nothing until you send them the image's id; they cannot list it |
| every user in chosen subscriptions or tenants | a direct shared gallery, in preview | a read-only gallery; up to 30 subscriptions and 5 tenants |
| every Azure customer | a community gallery | public images under a name made from your prefix |

RBAC is `azure-foundations` lesson 9's role assignments, given at the gallery so that a new
definition is covered on the day it is created; the documentation recommends sharing the whole
gallery rather than single versions. A direct shared gallery cannot hold encrypted versions. A
community gallery publishes the definition's names along with the images, cannot be made from an
existing private gallery, and carries no support from Microsoft for what is in it. **A secret
baked into an image goes wherever the image is shared**, which is the strongest reason the
previous section configured the settings at boot.

Two rules from Microsoft's own list of good practice finish the picture. The gallery is a
resource in one region, so a second gallery in another region is what keeps new versions possible
if the first region is down. And production and test images live in separate galleries, so that a
role given to the testers never reaches what the shop's machines are made from.

That is the third reason the gallery is where your images belong, after Trusted Launch and a
`latest` you decide: it is the one kind of image of your own that can leave its region and its
subscription.
