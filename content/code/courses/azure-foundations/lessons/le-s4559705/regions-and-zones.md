---
title: Regions, availability zones and the clouds they belong to
version: 1
---

**A region is a place on the map where Microsoft runs a set of datacentres close enough to each
other to act as one.** Every resource you create in Azure is created in one of them, and the name
you give it is the region's programmatic name: `brazilsouth`, in the state of São Paulo, is the one
this course works in. Its neighbour `brazilsoutheast` is in Rio de Janeiro. Each region has a
display name as well, *Brazil South*, which is what the portal shows and what no command accepts.

## Which Azure

Before regions there is a question people skip, because the answer is almost always the same: **which
Azure?** Microsoft runs more than one copy of it, each with its own regions, its own directory of
identities and its own addresses, and an account in one does not exist in the others. The CLI knows
them all, and answers this without signing in, from its own installation:

```
ana@laptop:~/azure$ az cloud list --output table
IsActive    Name               Profile
----------  -----------------  ---------
True        AzureCloud         latest
False       AzureChinaCloud    latest
False       AzureUSGovernment  latest
False       AzureBleuCloud     latest
ana@laptop:~/azure$ az cloud show --name AzureCloud --query "{resourceManager: endpoints.resourceManager, signIn: endpoints.activeDirectory, storage: suffixes.storageEndpoint}"
{
  "resourceManager": "https://management.azure.com/",
  "signIn": "https://login.microsoftonline.com",
  "storage": "core.windows.net"
}
```

`AzureCloud` is the global Azure, the one this course and nearly every company use. **The other
three are sovereign clouds**: `AzureChinaCloud` is operated in China by a local company, as Chinese
law requires; `AzureUSGovernment` is reserved for American public bodies and their suppliers;
`AzureBleuCloud` is the French one, run by a company Orange and Capgemini set up for that purpose.
Each has its own sign-in address and its own Resource Manager, and the endpoints are the CLI's way
of telling them apart. The three addresses this course will meet again belong to the global one:

| address | what answers there | lesson |
|---|---|---|
| `https://management.azure.com/` | **Resource Manager**: every request to create, read, change or delete a resource | 25 |
| `https://login.microsoftonline.com` | **Microsoft Entra ID**: where an identity proves who it is and gets a token | 6 |
| `core.windows.net` | the end of every storage account's address, as in `shop.blob.core.windows.net` | 19 |

## Asking which regions there are

The list of regions a subscription can use is a question for Resource Manager, so in this lab it
gets the same answer as every other question for Resource Manager:

```
ana@laptop:~/azure$ az account list-locations --output table
ERROR: Please run 'az login' to setup account.
rc=0
```

**This command was not answered here**, and with an account it returns one entry per region. What
each entry carries is documented, and four of its fields matter in this lesson: `name`, the
programmatic name; `regionType`, which is `Physical` for a region you can deploy into and `Logical`
for a grouping such as `brazil` or `southamerica`; `metadata.pairedRegion`, the next section's
subject; and **`availabilityZoneMappings`**, which says where this subscription's zones really are.

## Availability zones

**An availability zone is one or more datacentres inside a region, with its own power, its own
cooling and its own network.** The zones are close enough to each other for a round trip of a couple
of milliseconds, and far enough apart that a fire, a flood or a failed substation takes out one zone
and not two. `brazilsouth` has three. `brazilsoutheast` has none, and is a region Microsoft opens only to
customers who need a second region inside Brazil, for recovery or for law.

A resource meets zones in one of three ways, and every resource's documentation says which:

- **zonal**: it lives in one zone you choose, such as a virtual machine in zone 2. Losing zone 2
  loses it, so a system that must survive needs one in each zone;
- **zone-redundant**: Azure spreads it across the zones itself, such as a storage account whose
  replication is set to ZRS or a load balancer with a zone-redundant front end. Losing a zone costs
  capacity, not the resource;
- **regional**, or non-zonal: it lives somewhere in the region and Azure decides where. It says
  nothing about zones, so it promises nothing about one going down.

## Zone 1 is not the same place for everybody

**The number of a zone is a label your subscription sees, not a building.** Azure maps the logical
zones 1, 2 and 3 of each subscription to the physical zones of the region independently, so that
everybody who writes `zones: ['1']` does not end up in the same datacentre:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-zone-mapping\" aria-label=\"An example of how two subscriptions see the zones of brazilsouth. The region holds three physical zones, brazilsouth-az1, az2 and az3. The subscription shop-prod maps its logical zone 1 to az2, zone 2 to az3 and zone 3 to az1; the subscription shop-staging maps its zone 1 to az1, zone 2 to az2 and zone 3 to az3. So zone 1 in one and zone 1 in the other are different buildings. The mapping drawn is invented; a real one is read from availabilityZoneMappings.\"><defs><marker id=\"l01-zone-mapping-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l01-zone-mapping-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40.0\" y=\"20.0\" width=\"290.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"54.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subscription</text><text x=\"316.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><rect x=\"58.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"92.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"92.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M92.0 114.0 L92.0 140.0 L344.0 190.0 L344.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-phosphor)\"></path><rect x=\"151.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"185.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M185.0 114.0 L185.0 140.0 L534.0 190.0 L534.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-phosphor)\"></path><rect x=\"244.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"278.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"278.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M278.0 114.0 L278.0 140.0 L154.0 190.0 L154.0 213.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-phosphor)\"></path><rect x=\"390.0\" y=\"20.0\" width=\"290.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"404.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subscription</text><text x=\"666.0\" y=\"38.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><rect x=\"408.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"442.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"442.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><path d=\"M442.0 114.0 L442.0 140.0 L186.0 190.0 L186.0 213.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-amber)\"></path><rect x=\"501.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"535.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><path d=\"M535.0 114.0 L535.0 140.0 L376.0 190.0 L376.0 213.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-amber)\"></path><rect x=\"594.0\" y=\"56.0\" width=\"68.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"628.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">zone</text><text x=\"628.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><path d=\"M628.0 114.0 L628.0 140.0 L566.0 190.0 L566.0 213.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l01-zone-mapping-af-ah-amber)\"></path><rect x=\"40.0\" y=\"214.0\" width=\"640.0\" height=\"96.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"56.0\" y=\"232.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">region</text><text x=\"664.0\" y=\"232.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">brazilsouth</text><rect x=\"98.0\" y=\"246.0\" width=\"144.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">physical zone</text><text x=\"170.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">brazilsouth-az1</text><rect x=\"288.0\" y=\"246.0\" width=\"144.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">physical zone</text><text x=\"360.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">brazilsouth-az2</text><rect x=\"478.0\" y=\"246.0\" width=\"144.0\" height=\"48.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">physical zone</text><text x=\"550.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">brazilsouth-az3</text></svg>", "caption": "An invented mapping, for the shape of it: zone 1 is a label each subscription maps on its own."}
```

So two subscriptions that each put a virtual machine in "zone 1" may have put them in different
buildings, or in the same one. **Inside one subscription the numbering is stable**, and a design that
spreads its machines over 1, 2 and 3 really is spread. Across subscriptions it means nothing until
you look, and `availabilityZoneMappings` is where you look: it pairs each logical zone with a physical
one named like `brazilsouth-az1`. The production subscription and the testing one of lesson 2 are
exactly the case where it matters, the day somebody wants a test machine in the same zone as a
production one.
