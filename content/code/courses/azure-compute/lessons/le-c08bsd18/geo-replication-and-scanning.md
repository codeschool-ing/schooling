---
title: Geo-replication, the declaration, and scanning
version: 1
---

A replica sounds like a second registry, a backup with its own name that somebody copies images
into. **Geo-replication keeps one registry with one login server and stores its contents in several
regions.** You push once, to `shopregistry.azurecr.io`; the registry copies the push to every
replica; and each pull is served by the replica Azure judges closest to whoever asks. Credentials,
roles and network rules are the registry's, so they are the same everywhere. It needs Premium, and
nothing about it can run on a laptop, so this section is read, apart from a declaration that the
Bicep compiler checks.

## One name, several regions

The shop runs in São Paulo. Lesson 6 said that surviving the loss of a region takes a copy in a
second one, and lesson 2 kept a replica of the shop's machine image in `southcentralus` for that
day. The container image needs the same. Without replication, machines in `southcentralus` pull
from `brazilsouth`, across a continent, and cannot pull at all while the home region is down. With
a replica, they pull in their own region under the same name. The command, not run:

```sh
az acr replication create --registry shopregistry --location southcentralus
```

The option that decides whether that replica is used at all is in the help:

```
ana@laptop:~/azure$ az acr replication create --help | awk '/^    --/{p=0} /^    --(location|global-endpoint-routing) /{p=1} p'
    --global-endpoint-routing   : Allow routing to this replication via the registry global
                                  endpoint. If disabled, requests to the global endpoint will not be
                                  routed to the replica. Data syncing to the replica will continue
                                  regardless of the global endpoint routing status. Default: true.
                                  Allowed values: false, true.
    --location -l               : Location. Values from: `az account list-locations`. You can
                                  configure the default location using `az configure --defaults
                                  location=<location>`.  Config: brazilsouth.
```

Microsoft's documentation, read on 30 October 2026, describes the arrangement in some detail, and
four of its points change how you plan:

- **Every replica takes writes.** The model is active-active: a push, a pull or a delete may land
  in any region, not only at home.
- **The home region keeps the control plane.** If `brazilsouth` goes down, pushes and pulls carry on
  through the replicas, but the registry's settings cannot be changed until it returns, and **ACR
  Tasks do not run**, because tasks belong to the home region.
- **Storage is billed per replica.** One gigabyte in two regions is billed as two, although the
  tier's storage limit counts it once, and copying a push to a replica is charged as data
  transferred between regions.
- **Replicas are zone-redundant** in regions that have zones, like the registry itself.

## Consistent eventually

**A push reaches the other replicas later, not at once.** How much later depends on the size of the
image, and the documentation lists what that delay breaks:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two regions of one geo-replicated registry, on a time line. A pipeline pushes shop:1.2 and it lands in brazilsouth. It is copied to the replica in southcentralus in the background. A pod in southcentralus that pulls 1.2 before the copy arrives is answered manifest unknown; a pull after the copy arrives succeeds. Both pulls used the same login server.\"><defs><marker id=\"acr-geo-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"acr-geo-ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">shopregistry.azurecr.io</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one login server; each request goes to the replica Azure picks for the client</text><path d=\"M150 100 L170 100\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M320 100 L700 100\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">brazilsouth</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">home region</text><path d=\"M150 200 L340 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M490 200 L550 200\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">southcentralus</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">replica</text><rect x=\"170\" y=\"78\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"245\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a pipeline pushes 1.2</text><text x=\"245\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">it lands here first</text><path d=\"M320 112 L548 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 4\" marker-end=\"url(#acr-geo-ah)\"></path><text x=\"470\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copied in the background</text><rect x=\"340\" y=\"178\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"415\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a pod here pulls 1.2</text><text x=\"415\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">manifest unknown</text><rect x=\"550\" y=\"178\" width=\"150\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"625\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">the same pull, later</text><text x=\"625\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the copy has arrived</text><path d=\"M150 262 L700 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#acr-geo-ah)\"></path><text x=\"700\" y=\"280\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "A geo-replicated registry is consistent eventually, not at once. Between the push and the copy, the same name answers differently in the two regions."}
```

The figure is the case pipelines hit: an image is pushed, and pods in another region pull it
straight away and are told `manifest unknown`. The second case is section 03 again, worse. Push
`shop:1.2`, then push a different build under the same tag a minute later, and for a while the two
regions can resolve `1.2` to two different digests. A deployment that names the digest cannot be
caught by that, because a replica either has those exact bytes or answers that it does not. The
documentation's remedies are a retry with back-off after a cross-region push, and the registry's
webhooks, which send an event as each replica finishes copying an image.

A **regional endpoint**, in preview, names one replica directly,
`shopregistry.southcentralus.geo.azurecr.io`, for a pipeline that wants to push and pull in the same
place. It gives up the automatic failover the global name has, so the client then chooses another
region itself.

One feature that every tier has belongs beside replication, because it also keeps the shop pulling
when somebody else's service is having a bad day. An **artifact cache** rule tells the registry to
fetch an image from an upstream registry, such as Docker Hub, the first time it is asked for, and
keep it. `FROM shopregistry.azurecr.io/python:3.12-slim` then pulls from your own registry. A rule
caches only what has been pulled through it once, it does not fetch new tags by itself, and Docker
Hub is supported only with credentials of your own, which the rule reads from Key Vault.

## The registry, declared

Here is the whole registry as Bicep: Premium, the admin user off, untagged manifests kept seven
days, and a replica in `southcentralus`. Save it as `~/azure/acr.bicep`:

```bicep
// acr.bicep
param location string = 'brazilsouth'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'shopregistry'
  location: location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: false
    policies: {
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
    }
  }
}

resource replica 'Microsoft.ContainerRegistry/registries/replications@2025-11-01' = {
  parent: registry
  name: 'southcentralus'
  location: 'southcentralus'
}
```

A replication is a resource of its own under the registry, which is what `parent` says, and its
name is the region it is in, by convention. `zoneRedundancy` is left out on purpose, for the reason
section 02 gave. Compiled:

```
ana@laptop:~/azure$ bicep build acr.bicep
ana@laptop:~/azure$ ls acr.*
acr.bicep
acr.json
ana@laptop:~/azure$ jq -c ".resources[] | {type, name, location}" acr.json
{"type":"Microsoft.ContainerRegistry/registries","name":"shopregistry","location":"[parameters('location')]"}
{"type":"Microsoft.ContainerRegistry/registries/replications","name":"[format('{0}/{1}', 'shopregistry', 'southcentralus')]","location":"southcentralus"}
```

No warnings, so by lesson 1's rule it is finished. The second resource's name became
`shopregistry/southcentralus`, the full name of a child resource. Section 04 is why the retention
policy is a smaller safety net than it looks: the shop's OCI images are outside it.

Now the same registry with five mistakes in it, of the kind a hurried edit makes. Save it as
`~/azure/wrong.bicep`:

```bicep
// wrong.bicep
param location string = 'brazilsouth'

resource registry 'Microsoft.ContainerRegistry/registries@2025-11-01' = {
  name: 'shop-registry'
  location: location
  sku: {
    name: 'Premuim'
  }
  properties: {
    adminUserEnabled: 'false'
    policies: {
      retentionPolicy: {
        stauts: 'enabled'
        days: 400
      }
    }
  }
}
```

```
ana@laptop:~/azure$ bicep build wrong.bicep
/home/ana/azure/wrong.bicep(5,9) : Warning BCP416: The supplied string does not match the expected pattern of /$^[a-zA-Z0-9]*$/. [https://aka.ms/bicep/core-diagnostics#BCP416]
/home/ana/azure/wrong.bicep(11,23) : Warning BCP036: The property "adminUserEnabled" expected a value of type "bool | null" but the provided value is of type "'false'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
/home/ana/azure/wrong.bicep(14,9) : Warning BCP089: The property "stauts" is not allowed on objects of type "RetentionPolicy". Did you mean "status"? [https://aka.ms/bicep/core-diagnostics#BCP089]
ana@laptop:~/azure$ ls wrong.*
wrong.bicep
wrong.json
```

**Three were caught and two were not.** The hyphen in `shop-registry` broke the naming pattern; the
pattern in the message is printed oddly, and what it means is letters and digits only. The quoted
`'false'` is text where the API takes a boolean, and `stauts` is a misspelt property, with the right
spelling offered. But `'Premuim'` passed, because the compiler types a SKU's name as one of the
three tiers **or any string**, so a typo there compiles in silence and is left for Azure to refuse.
And `days: 400` passed, although the CLI's help in section 04 gave the range as 0 to 365: the type
says only that it is a number. Treat the warnings as refusals, and read the values the compiler
cannot judge yourself.

## Scanning, and what a clean result means

A vulnerability scan compares the packages it can identify in an image with the vulnerabilities that
have been published for them. **It finds known problems in known packages, and nothing else**: not a
bug in `app.py`, not a token somebody copied into a layer, and not a vulnerability published
tomorrow. A clean result describes those packages on that day.

Microsoft's own scanner for ACR is Defender for Cloud, through its plan for containers, and it is
switched on for the **subscription** in Defender for Cloud, not on the registry. Microsoft's container registry
documentation says what it then does. It scans the images that are pushed or imported, and the
images **pulled in the last 30 days**. Findings appear in **Defender for Cloud as recommendations**,
not in the registry, with the steps to fix each. A fixed image is pushed in place of the old one, and
Defender scans it again to confirm. The scanner signs in and pulls like any client, so its pulls show
in the registry's logs; behind a private endpoint, the registry must allow trusted Microsoft
services, which a new registry does.

The Defender pages that list exactly which operating systems and package managers it reads could not
be read for this course. Check them before relying on a scan to cover a particular base image or a
particular language's packages. The rest of the decision is the same as anywhere: a finding is a reason to rebuild on a
patched base, which is the base image trigger of section 04 doing what it is for.

## Cleaning up

The local registry and its volume are the only things this lesson left running:

```
ana@laptop:~/azure$ docker rm -f registry
registry
ana@laptop:~/azure$ docker volume rm shop-registry
shop-registry
```
