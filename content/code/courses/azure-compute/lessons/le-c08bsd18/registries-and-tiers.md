---
title: A registry of your own, and the three tiers
version: 1
---

Lessons 7, 8 and 9 wrote `shopregistry.azurecr.io/shop:1.0` into every file and called the
registry a placeholder. The name invites a picture of a shared hub with Azure's logo on it, where
the shop's image sits beside everybody else's. **An Azure container registry is a resource you
create in your own subscription, and its name belongs to nobody else.** `shopregistry` is unique
across all of Azure, so `shopregistry.azurecr.io`, the registry's *login server*, reaches one
registry. Inside it, a repository holds the versions of one image and a tag names a version. Nobody
outside can read any of it until somebody is given a role on it.

## The address

| piece | in this lesson | what it says |
| --- | --- | --- |
| `shopregistry` | the registry | 5 to 50 lowercase letters and digits, unique within Azure |
| `azurecr.io` | the domain | Azure's, the same for every registry in the public cloud |
| `shop` | the repository | lowercase letters, digits, periods, dashes, underscores and slashes |
| `1.0` | the tag | one version, named by whoever pushed it |

The region is not in the address. A registry is created in a **home region**, `brazilsouth` here,
which Microsoft's documentation says is fixed at creation; moving it means creating a new registry.
For this shop the home region has one more consequence. In most regions Azure may also keep a
registry's data in the paired region of the same geography, but **in Brazil South a registry's data
never leaves the region**, a rule Microsoft keeps for data residency there and in Southeast Asia.
Section 05 shows the one way to put a copy somewhere else on purpose.

## Three tiers, and one API

A registry is created in one of three tiers, which the CLI calls SKUs. The CLI's help says which,
and what the two settings around them default to:

```
ana@laptop:~/azure$ az acr create --help | awk '/^    --/{p=0} /^    --(sku|admin-enabled|zone-redundancy) /{p=1} p'
    --sku                  [Required] : The SKU of the container registry.  Allowed values: Basic,
                                        Premium, Standard.
    --admin-enabled                   : Indicates whether the admin user is enabled.  Allowed
                                        values: false, true.
    --zone-redundancy       [Preview] : Indicates whether or not zone redundancy should be enabled
                                        for this registry or replication. For more information, such
                                        as supported locations, please visit https://aka.ms/acr/az.
                                        Zone-redundancy cannot be updated. Defaults to 'Disabled'.
                                        Allowed values: Disabled, Enabled.
        WARNING: Argument '--zone-redundancy' is in preview and under development. Reference and
        support levels: https://aka.ms/CLI_refstatus

Customer managed key Arguments
```

**Basic, Standard and Premium speak the same API**, the one section 03 uses: the same push, the same
pull, the same manifests. Microsoft's documentation says so in as many words, and it is why a
pipeline written against a Basic registry works unchanged against a Premium one. What the tier
changes is how much traffic the registry takes and which features it has. The limits are published
per minute, and two lines of that table, read on 30 October 2026, show the shape:

| requests per minute, per registry | Basic and Standard | Premium |
| --- | --- | --- |
| reads: pulls of manifests and layers | 10,000 | 20,000 |
| writes: pushes of manifests and layers | 2,000 | 4,000 |

A registry over a limit answers `429 Too Many Requests` with a `Retry-After` header, and the
documentation says the numbers are approximate and carry no SLA. Fifty nodes of a cluster pulling an
image of ten layers at the same moment make well over five hundred requests, so the ceiling is
nearer than it sounds, and every tier has the same answer to it: pull less often, and retry.

The features are the bigger difference. These are the ones the documentation ties to a tier:

| feature | tiers | in this lesson |
| --- | --- | --- |
| geo-replication, one registry in several regions | Premium | section 05 |
| private endpoints, up to 200 per registry | Premium | |
| encryption with a key of your own in Key Vault | Premium | |
| a retention policy for untagged manifests (preview) | Premium | section 04 |
| dedicated agent pools for tasks (preview) | Premium | section 04 |
| a connected registry, synchronised to a site of your own | Premium | |
| anonymous pull, for a registry anyone may read | Standard and Premium | |
| artifact cache, a local copy of an image from Docker Hub or another registry | all three | section 05 |
| zone redundancy across the region's availability zones | all three, on by default | section 05 |

Docker Content Trust, the older way of signing images, used to be on that list as a Premium
feature. **Since 31 May 2026 it cannot be turned on for a registry that did not already use it**,
and Microsoft will remove it on 31 March 2028 in favour of the Notary Project's signatures. Moving
between tiers is one command, `az acr update --name shopregistry --sku Premium`, with no downtime;
going down from Premium needs the Premium-only resources, such as replications, deleted first.

**Read the zone redundancy line of the help against the last row of that table.** The CLI says the
setting defaults to `Disabled` and cannot be changed afterwards. The documentation, in a page dated
March 2026, says zone redundancy is now on for every registry in a region with availability zones,
in every tier, whatever the property says, and that the portal, the CLI and the API may go on
displaying `Disabled` for a registry that is in fact zone-redundant. The help text is generated from
the same definitions as the requests, so it describes the API faithfully, and the API's property is
the part that went out of date. Lesson 6 explained what zones buy; here they come free.

How much storage each tier includes, and what each extra gigabyte costs, is on Azure's pricing page,
which this course does not quote. Lesson 1 shows how to read it.

## Who may push and pull

**A person signs in to a registry with their own Microsoft Entra identity**, through the CLI. These
two commands were not run in this course: the first needs an account, and without one the second
goes on to call the login server it names, which is somebody else's.

```sh
az login
az acr login --name shopregistry
```

`az acr login` exchanges the token `az login` obtained for a registry token, and hands it to Docker,
so `docker push` and `docker pull` work afterwards with no password typed. **The registry token
lasts three hours**, which is why a pipeline signs in again on every run instead of keeping a
secret. Where no Docker daemon runs, `--expose-token` prints the token instead, and `docker login`
takes it as the password with the user name `00000000-0000-0000-0000-000000000000`.

Every registry also has an **admin user**: one account with two passwords, push and pull on
everything, and no way to tell who used it. It is disabled when a registry is created and the
documentation's advice is to leave it so. The Bicep of section 05 says `adminUserEnabled: false`
anyway, so the decision is written down.

The services of this course pull with a **managed identity**, the identity an Azure resource carries
from `azure-foundations` lesson 8, holding the **AcrPull** role on the registry, from lesson 9 of the
same course. For AKS, the subject of lesson 11, one flag on the cluster gives its nodes that role.
For Container Apps, the subject of lesson 8, the app is told to use its own system-assigned identity
on this server. Neither was run here:

```sh
az aks update --resource-group shop --name shop-aks --attach-acr shopregistry
az containerapp registry set --resource-group shop --name shop --server shopregistry.azurecr.io --identity system
```

The first assigns AcrPull to the identity the cluster's nodes use, and it does so with the
permissions of whoever runs it, so that person needs the right to assign roles. The second turns the
app's identity on and points it at the registry, and the CLI assigns the role. **No password exists
anywhere in either arrangement**, which is the whole reason for them.

One newer arrangement changes the role's name. A registry can be switched to a mode Microsoft calls
*RBAC Registry + ABAC Repository Permissions*, where a role assignment may be limited to particular
repositories. In that mode the pull role is **Container Registry Repository Reader** rather than
AcrPull, and `--attach-acr` is not supported, so the assignment is made by hand. A registry created
the ordinary way keeps AcrPull.
