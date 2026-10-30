---
title: A resource id, read from the left
version: 1
---

**Every resource in Azure has one full name, its resource id, and it is the name a role assignment,
a policy, a log line and an error message use.** It is a path, and reading it from the left walks
down the boxes of the previous section:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-resource-id\" aria-label=\"A subnet's resource id cut into its pieces, on two lines: the subscription id bbbbcccc-1111-dddd-2222-eeee3333ffff, the resource group rg-shop-prod, the provider namespace Microsoft.Network, the type virtualNetworks, the name vnet-shop-prod, and the child subnets/snet-app. The literal words subscriptions, resourceGroups and providers separate them.\"><text x=\"148.8\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/subscriptions/</text><rect x=\"196.3\" y=\"47.0\" width=\"241.6\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"317.1\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">subscription</text><text x=\"317.1\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">bbbbcccc-1111-dddd-2222-eeee3333ffff</text><text x=\"488.7\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/resourceGroups/</text><rect x=\"539.5\" y=\"47.0\" width=\"83.2\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"581.1\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource group</text><text x=\"581.1\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rg-shop-prod</text><text x=\"145.5\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/providers/</text><rect x=\"179.8\" y=\"157.0\" width=\"116.2\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"237.9\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">provider namespace</text><text x=\"237.9\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Microsoft.Network</text><text x=\"297.3\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/</text><rect x=\"298.6\" y=\"157.0\" width=\"103.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.1\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">type</text><text x=\"350.1\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">virtualNetworks</text><text x=\"402.9\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/</text><rect x=\"404.2\" y=\"157.0\" width=\"96.4\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"452.4\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">name</text><text x=\"452.4\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">vnet-shop-prod</text><text x=\"501.9\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/</text><rect x=\"503.2\" y=\"157.0\" width=\"109.6\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">child resource</text><text x=\"558.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">subnets/snet-app</text></svg>", "caption": "Read from the left, an id walks down the boxes: subscription, group, provider, type, name."}
```

A subscription is named by its GUID, never by its display name, and the rest is the resource group,
then `providers`, then the **resource provider namespace** that owns the type: `Microsoft.Network`
for networks, `Microsoft.Compute` for machines, `Microsoft.Storage` for storage accounts. Then the
type and the name, and for a child resource such as a subnet, its own type and name appended.

## Taking ids apart in the lab

The Azure CLI parses ids with a function from a library it brought into the virtual environment,
and a program of a few lines can use the same function. Make the lesson's directory, and save this
as `rid.py` in it:

```sh
mkdir -p ~/azure/hierarchy && cd ~/azure/hierarchy
```

```schooling-example
{"language": "python", "file": "rid.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"rid.py ID...: cut Azure resource ids into the scopes they sit in.\"\"\"\nimport sys\n\nfrom azure.mgmt.core.tools import parse_resource_id\n\n", "note": "`azure.mgmt.core` came into the virtual environment with the Azure CLI, which uses it for exactly this. Nothing here talks to Azure: an id is a string, and cutting it up needs no account."}, {"code": "for rid in sys.argv[1:]:\n    p = parse_resource_id(rid)\n    print(rid)\n", "note": "`parse_resource_id` returns a dictionary of the pieces it recognised, and leaves out the ones the id does not have."}, {"code": "    for key in ('subscription', 'resource_group', 'namespace', 'type', 'name'):\n        if key in p:\n            print(f'  {key:<16}{p[key]}')\n", "note": "The five pieces every resource has, from the outside in: the subscription, the group, the **provider namespace** that owns the type, the type and the name."}, {"code": "    for i in range(1, p.get('last_child_num', 0) + 1):\n        print(f\"  {'child ' + str(i):<16}{p['child_type_' + str(i)]}/{p['child_name_' + str(i)]}\")\n", "note": "A **child resource** lives inside another one, such as a subnet inside a network, and adds a type and a name to the end of its parent's id. `last_child_num` says how many levels there are."}]}
```

Give it four ids: a subnet, its resource group, a management group, and the network again written
the way a careless person types it:

```
ana@laptop:~/azure/hierarchy$ python3 rid.py /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod/subnets/snet-app /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod /providers/Microsoft.Management/managementGroups/mg-shop /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourcegroups/RG-SHOP-PROD/providers/microsoft.network/virtualnetworks/vnet-shop-prod
/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod/subnets/snet-app
  subscription    bbbbcccc-1111-dddd-2222-eeee3333ffff
  resource_group  rg-shop-prod
  namespace       Microsoft.Network
  type            virtualNetworks
  name            vnet-shop-prod
  child 1         subnets/snet-app
/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod
  subscription    bbbbcccc-1111-dddd-2222-eeee3333ffff
  resource_group  rg-shop-prod
/providers/Microsoft.Management/managementGroups/mg-shop
  name            /providers/Microsoft.Management/managementGroups/mg-shop
/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourcegroups/RG-SHOP-PROD/providers/microsoft.network/virtualnetworks/vnet-shop-prod
  subscription    bbbbcccc-1111-dddd-2222-eeee3333ffff
  resource_group  RG-SHOP-PROD
  namespace       microsoft.network
  type            virtualnetworks
  name            vnet-shop-prod
```

Three things in that answer are worth more than the program.

**The subscription id is in every id below it**, which is how you read whose a resource is, and
the first thing to check when a script reports something nobody recognises. The GUID here,
`bbbbcccc-1111-dddd-2222-eeee3333ffff`, is the kind of made-up value Microsoft's own documentation
uses, and stands for the shop's production subscription in every lesson of this course.

**A management group's id does not start with a subscription**, and the parser did not understand
it: it gave back the whole string as a name. A management group sits above every subscription, so
its id starts at `/providers/Microsoft.Management/managementGroups/`, with no subscription and no
resource group in it. The same is true of anything at the level of the tenant. A program that
assumes every id begins with `/subscriptions/` is right about resources and wrong about the tree.

**Case does not matter to Azure, and it does to everything else.** The last id was typed with
`resourcegroups`, `RG-SHOP-PROD` and `microsoft.network`, and Resource Manager treats it as the same
resource: ids are compared without regard to case. The parser returned the pieces exactly as typed,
though, and so does every tool that compares strings. Two scripts that store the same id in two
spellings and compare them with `==` disagree about whether a resource exists. **Lower-case an id
before comparing it**, or use a comparison that ignores case.

## Names, which are not ids

The id is built from names, and the names have rules that only Azure enforces:

- a name must be **unique among its siblings**: two resource groups called `rg-shop-prod` cannot
  exist in one subscription, and two networks of the same name cannot exist in one group;
- some names must be **unique across all of Azure**, because they become part of an address. A
  storage account called `shopassets` becomes `shopassets.blob.core.windows.net`, and nobody else
  on the planet can have it. Lesson 19 returns to those addresses;
- each type has its own **length and characters**: a resource group takes up to 90, a storage
  account 3 to 24 lower-case letters and digits and nothing else.

**A convention for names is the cheapest governance there is.** This course uses the one in
Microsoft's Cloud Adoption Framework, which lesson 5 introduces: a short prefix for the type, then
the workload, then the environment. `rg-shop-prod` is a resource group, `vnet-shop-prod` a virtual
network, `snet-app` a subnet. A name that says what a thing is gets read correctly by the person
who did not create it, which is everybody, eventually.
