---
title: The reference tree, and why it is not lesson 2's
version: 1
---

**CAF publishes a management group tree, and it is not split by environment.** Lesson 2 drew the
shop's tree the way most teams draw it first: production in one branch, non-production in another.
CAF says, in as many words, not to create management groups for production, testing and
development. The reason is the point of a test environment: **staging should be governed exactly like
production**, so that what passes in staging passes in production. Two branches with two sets of
policies make the test measure something else. Environments are separated by **subscription**,
`shop-prod` beside `shop-staging`, inside the same management group.

What CAF splits by instead is **what a workload needs from the platform**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l05-alz-tree\" aria-label=\"The Cloud Adoption Framework's management group tree, with the shop's names. Under the tenant root group sits the intermediate root, shop. Under it: shop-platform, with shop-security, shop-management, shop-connectivity and shop-identity; shop-landingzones, with shop-corp and shop-online; shop-sandbox; and shop-decommissioned. The subscription shop-shared sits under shop-connectivity; shop-prod and shop-staging sit side by side under shop-online.\"><rect x=\"280.0\" y=\"14.0\" width=\"160.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tenant root group</text><path d=\"M360.0 42.0 L360.0 54.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"310.0\" y=\"54.0\" width=\"100.0\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop</text><path d=\"M360.0 82.0 L360.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 96.0 L640.0 96.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 96.0 L110.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"62.9\" y=\"108.0\" width=\"94.1\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-platform</text><path d=\"M330.0 96.0 L330.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"271.6\" y=\"108.0\" width=\"116.9\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-landingzones</text><path d=\"M510.0 96.0 L510.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"465.8\" y=\"108.0\" width=\"88.4\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"510.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-sandbox</text><path d=\"M640.0 96.0 L640.0 108.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"575.9\" y=\"108.0\" width=\"128.3\" height=\"28.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-decommissioned</text><path d=\"M40.0 150.0 L40.0 278.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 136.0 L110.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 150.0 L110.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M40.0 164.0 L56.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"151.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"164.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-security</text><path d=\"M40.0 202.0 L56.0 202.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"189.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-management</text><path d=\"M40.0 240.0 L56.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"227.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-connectivity</text><path d=\"M40.0 278.0 L56.0 278.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"56.0\" y=\"265.0\" width=\"130.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"121.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-identity</text><rect x=\"196.0\" y=\"227.0\" width=\"100.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"246.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-shared</text><path d=\"M187.0 240.0 L195.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M330.0 136.0 L330.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 150.0 L390.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 150.0 L290.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"245.0\" y=\"164.0\" width=\"90.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-corp</text><path d=\"M330.0 136.0 L330.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 150.0 L390.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390.0 150.0 L390.0 164.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"345.0\" y=\"164.0\" width=\"90.0\" height=\"26.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-online</text><path d=\"M390.0 190.0 L390.0 216.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"320.0\" y=\"216.0\" width=\"140.0\" height=\"64.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"330.0\" y=\"224.0\" width=\"120.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-prod</text><rect x=\"330.0\" y=\"250.0\" width=\"120.0\" height=\"22.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"390.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">shop-staging</text><text x=\"590.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">production and staging:</text><text x=\"590.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one group, the same rules</text></svg>", "caption": "Split by what a workload needs from the platform, never by environment."}
```

| management group | holds |
|---|---|
| the **intermediate root**, `shop` | everything of the organisation's, so that nothing has to be assigned at the tenant root itself |
| **platform**, and under it **security**, **management**, **connectivity** and **identity** | the subscriptions of the platform team: security tooling, logs and monitoring, the hub network and DNS, directory servers |
| **landing zones**, and under it **corp** and **online** | the workloads. *Corp* for those that reach the office's network through the hub; *online* for those that face the internet directly |
| **sandbox** | experiments, with lighter policies, isolated from both kinds of landing zone |
| **decommissioned** | subscriptions being shut down, until they are deleted |

The shop's three subscriptions fall into it without strain: `shop-shared` under connectivity,
`shop-prod` and `shop-staging` together under online, since the shop serves the internet. The policy
that keeps staging honest is assigned once, on online, and both get it.

CAF adds two pieces of advice about depth: keep the tree **three to four levels deep**, well inside
lesson 2's limit of six, and **do not assign workload teams roles at management group scope**, only
at their subscriptions and groups. A permission on a management group reaches every subscription
under it, including the next team's.

## The tree, in Bicep

Make the lesson's directory and save this as `alz.bicep`:

```sh
mkdir -p ~/azure/alz && cd ~/azure/alz
```

```bicep
targetScope = 'tenant'

@description('The intermediate root: every management group of the shop hangs under it.')
param prefix string = 'shop'

var children = [
  { name: '${prefix}-platform', parent: prefix }
  { name: '${prefix}-security', parent: '${prefix}-platform' }
  { name: '${prefix}-management', parent: '${prefix}-platform' }
  { name: '${prefix}-connectivity', parent: '${prefix}-platform' }
  { name: '${prefix}-identity', parent: '${prefix}-platform' }
  { name: '${prefix}-landingzones', parent: prefix }
  { name: '${prefix}-corp', parent: '${prefix}-landingzones' }
  { name: '${prefix}-online', parent: '${prefix}-landingzones' }
  { name: '${prefix}-sandbox', parent: prefix }
  { name: '${prefix}-decommissioned', parent: prefix }
]

resource root 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: prefix
  properties: {
    displayName: prefix
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', tenant().tenantId)
      }
    }
  }
}

@batchSize(1)
resource groups 'Microsoft.Management/managementGroups@2023-04-01' = [
  for g in children: {
    name: g.name
    properties: {
      displayName: g.name
      details: {
        parent: {
          id: tenantResourceId('Microsoft.Management/managementGroups', g.parent)
        }
      }
    }
    dependsOn: [
      root
    ]
  }
]
```

The intermediate root is one resource and the ten groups under it are one **loop**: `for g in
children` creates a management group for each entry of the list. Each child names its parent by
name, and `tenantResourceId` turns the name into the parent's id. Compile it and look at how the loop
arrives in the template:

```
ana@laptop:~/azure/alz$ az bicep build --file alz.bicep --stdout | jq -c '."$schema", (.resources | map({type, name, copy}))'
"https://schema.management.azure.com/schemas/2019-08-01/tenantDeploymentTemplate.json#"
[{"type":"Microsoft.Management/managementGroups","name":"[parameters('prefix')]","copy":null},{"type":"Microsoft.Management/managementGroups","name":"[variables('children')[copyIndex()].name]","copy":{"name":"groups","count":"[length(variables('children'))]","mode":"serial","batchSize":1}}]
```

The loop became a **`copy`** element: Resource Manager's own loop, which it will expand when the
template arrives, `length(variables('children'))` times. The `mode` is `serial` and the `batchSize`
1 because of **`@batchSize(1)`**, the line above the loop, and that line is not decoration. A copy
loop runs its iterations **in parallel** unless told otherwise, and `shop-management` cannot be
created before `shop-platform`, its parent, exists. Serial, one at a time, in the order of the list,
puts every parent before its children, because the list was written that way.

That is a dependency the compiler cannot see: inside one loop, Bicep does not know that one item's
`parent` is another item's `name`. **It compiled clean with or without the line**, and without it a
deployment would fail, sometimes, depending on which request Resource Manager happened to run first.
Deploying it is `az deployment tenant create`, which needs rights at the root of a tenant and was not
run.
