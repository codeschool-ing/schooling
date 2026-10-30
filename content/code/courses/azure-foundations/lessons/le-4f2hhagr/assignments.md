---
title: Assignments, scope and inheritance
version: 1
---

**A role assignment joins three things: who, which role, and where.** The who is a security
principal: a user, a group, a service principal or a managed identity, all of them objects in the
tenant from lessons 6 to 8. The which is a role definition. The where is a scope, one of lesson 2's
boxes: a management group, a subscription, a resource group or a single resource.

**An assignment reaches down, never up.** Reader on `rg-shop-prod` lets a person see every resource
in that group and nothing outside it. Reader on the subscription lets them see every group in it.
Reader on `mg-shop` lets them see every subscription under the shop's branch of the tree. That is
why the tree was drawn around how things are governed: an assignment on a management group is
inherited by everything under it, today and on the day a new subscription is added.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l09-scope\" aria-label=\"Inheritance of a role assignment down lesson 2's boxes. Reader is assigned to a group at the subscription shop-prod. It reaches the resource groups rg-shop-prod-app and rg-shop-prod-data and every resource in them, but not the management group mg-shop-prod above the subscription, nor the subscription shop-staging beside it.\"><defs><marker id=\"l09-scope-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"220.0\" y=\"20.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop-prod</text><text x=\"440.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not reached</text><path d=\"M320.0 56.0 L320.0 84.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200.0\" y=\"84.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"320.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-prod</text><text x=\"320.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">Reader assigned here</text><rect x=\"500.0\" y=\"84.0\" width=\"190.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shop-staging</text><text x=\"595.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not reached</text><path d=\"M320.0 129.0 L320.0 150.0 L200.0 150.0 L200.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"110.0\" y=\"172.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"200.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rg-shop-prod-app</text><path d=\"M200.0 213.0 L200.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"120.0\" y=\"240.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vnet-shop-prod</text><path d=\"M320.0 129.0 L320.0 150.0 L440.0 150.0 L440.0 172.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"350.0\" y=\"172.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"440.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rg-shop-prod-data</text><path d=\"M440.0 213.0 L440.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l09-scope-af-ah-amber)\"></path><rect x=\"360.0\" y=\"240.0\" width=\"160.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">sql-shop-prod</text><text x=\"360.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">an assignment reaches down, never up and never sideways</text></svg>", "caption": "Reader on the subscription is Reader on everything inside it, and on nothing else."}
```

## Three habits that keep this manageable

**Assign to groups, not to people.** `bia` joins the team and is added to the group that holds
Reader on production; the day `bia` leaves, the group loses a member. The assignments do not change, and
the question "who can read production?" becomes "who is in that group?", which Entra ID answers.
There is also a hard reason: **a subscription holds at most 5,000 role assignments**, a limit
Microsoft says it will not raise, and a company that assigns roles person by person reaches it.

**Assign at the smallest scope that works.** Contributor on the subscription is the answer that
always works and the one that makes every mistake as large as possible. Contributor on one resource
group, or a specific role on one resource, is what least privilege means in practice.

**Prefer a specific role to a general one.** Network Contributor manages networks and nothing else;
Storage Blob Data Reader reads blobs and nothing else. When no built-in role is narrow enough, write
your own.

## A custom role, in Bicep

A custom role is a role definition you write, with the same fields as the built-in ones. The shop's
on-call developers need to restart the web app at three in the morning, and nothing else, so the
role allows reading the app, restarting it and reading its metrics. Save this as `role.bicep`:

```bicep
targetScope = 'subscription'

resource restarter 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'shop-app-restarter')
  properties: {
    roleName: 'Shop App Restarter'
    description: 'Reads the shop\'s web apps and restarts them; changes nothing else.'
    type: 'CustomRole'
    permissions: [
      {
        actions: [
          'Microsoft.Web/sites/read'
          'Microsoft.Web/sites/restart/action'
          'Microsoft.Insights/metrics/read'
        ]
        notActions: []
        dataActions: []
        notDataActions: []
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

output id string = restarter.id
```

A role definition's own name must be a GUID, and `guid(...)` makes one: it hashes its arguments into
a GUID, **the same one every time for the same arguments**. Deploy the file twice and the second
deployment updates the role instead of creating another. `assignableScopes` keeps the role to this
subscription; a tenant can hold 5,000 custom roles, and one assignable everywhere is one more thing
everybody can grant.

## An assignment, in Bicep

Then the assignment, aimed at a resource group, the default scope. Save this as `assign.bicep`:

```bicep
@description('The object id of the group whose members may read the resource group.')
param groupId string

var readerId = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'

resource readers 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, groupId, readerId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', readerId)
    principalId: groupId
    principalType: 'Group'
  }
}
```

Compile both and read the names:

```
ana@laptop:~/azure/rbac$ az bicep build --file role.bicep --stdout | jq '{schema: ."$schema", name: .resources[0].name, scopes: .resources[0].properties.assignableScopes}'
{
  "schema": "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#",
  "name": "[guid(subscription().id, 'shop-app-restarter')]",
  "scopes": [
    "[subscription().id]"
  ]
}
ana@laptop:~/azure/rbac$ az bicep build --file assign.bicep --stdout | jq '.resources[0] | {name, roleDefinitionId: .properties.roleDefinitionId}'
{
  "name": "[guid(resourceGroup().id, parameters('groupId'), variables('readerId'))]",
  "roleDefinitionId": "[subscriptionResourceId('Microsoft.Authorization/roleDefinitions', variables('readerId'))]"
}
```

**The assignment's name is built from the three things it joins**: the scope, the principal and the
role. That is the habit worth copying. A role assignment's name must also be a GUID, and Resource
Manager refuses a second assignment of the same role to the same principal at the same scope. A
name derived from those three makes a repeated deployment land on the existing assignment instead
of failing. A name such as `readers-of-rg-shop-prod` compiles without a complaint, because the
compiler does not know the rule, and **Resource Manager would refuse it** when the deployment
arrived. That refusal was not run here.

The reader role is named by its id, with `subscriptionResourceId`, and not by its display name.
Display names can change; the id is the same in every tenant, which the table in the first section
of this lesson relies on.

Deploying either file is `az deployment sub create` and `az deployment group create`, as lesson 2
listed, and **neither was run**. Creating a role assignment needs
`Microsoft.Authorization/roleAssignments/write` at the scope, which is to say Owner, User Access
Administrator or Role Based Access Control Administrator there: the same operation `can.py` refused
to Contributor.
