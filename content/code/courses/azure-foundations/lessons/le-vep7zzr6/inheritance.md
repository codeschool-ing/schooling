---
title: Copying a group's tags down to its resources
version: 1
---

**A resource group's tags stay on the group.** Tag `rg-shop-prod-app` with `cost-centre: cc-410`, and
every machine created inside it afterwards has no `cost-centre` at all unless the file that made it
said so. That is the gap every tagging scheme falls into: the group is tagged once, carefully, by the
person who designed the scheme, and its resources are created for years afterwards by people who
never read it. Azure offers two ways to close the gap, and they work at different layers.

## A policy that writes the tag

The first is Azure Policy, which lesson 4 introduced: a rule evaluated by Resource Manager when a
request to create or change a resource arrives. Microsoft publishes its built-in policy definitions,
and the copy on GitHub can be read with no account. Ask for the one that inherits a tag:

```
ana@laptop:~/azure/tags$ curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json | jq '{name, displayName: .properties.displayName, mode: .properties.mode, effect: .properties.policyRule.then.effect, operation: .properties.policyRule.then.details.operations[0].operation, role: .properties.policyRule.then.details.roleDefinitionIds[0]}'
{
  "name": "ea3f2387-9b95-492a-a190-fcdc54f7b070",
  "displayName": "Inherit a tag from the resource group if missing",
  "mode": "Indexed",
  "effect": "modify",
  "operation": "add",
  "role": "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
}
```

Field by field, what that answer says:

- **`name`** is the definition's id, a GUID that is the same in every tenant, because a built-in
  definition is Microsoft's and is shared by all of them. An assignment names it by that id.
- **`displayName`** says *if missing*, and that is the rule: the policy adds the group's value when
  the resource has no such tag, and **leaves a different value alone**. A sibling definition,
  *Inherit a tag from the resource group*, adds or replaces, overwriting whatever the resource said.
- **`mode: Indexed`** means the policy looks only at resources that support tags and a location, so
  resource groups themselves are not touched by it.
- **`effect: modify`** is the effect that changes the request on its way in: the resource is created
  with the tag added, as if the person had written it.
- **`role`** is the GUID of the built-in role **Contributor**. A policy that writes to resources needs
  an identity allowed to write, and this is the role that identity must hold. Lessons 8 and 9 explain
  managed identities and roles; here it is enough that the assignment brings an identity of its own.

The rule itself, in the same file, has two conditions: the resource lacks the tag, and the group's
value is not empty. A group that was never tagged adds nothing.

## Assigning it

An assignment applies a definition at a scope, with values for its parameters. The shop assigns this
one to the whole production subscription, for the tag `cost-centre`. Save this as `inherit.bicep`:

```bicep
targetScope = 'subscription'

resource inheritCostCentre 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'inherit-cost-centre'
  location: 'brazilsouth'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Inherit cost-centre from the resource group if missing'
    policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070'
    parameters: {
      tagName: {
        value: 'cost-centre'
      }
    }
  }
}

output principalId string = inheritCostCentre.identity.principalId
```

```
ana@laptop:~/azure/tags$ az bicep build --file inherit.bicep --stdout | jq -c '(.resources[0] | {type, identity, policy: .properties.policyDefinitionId}), .outputs'
{"type":"Microsoft.Authorization/policyAssignments","identity":{"type":"SystemAssigned"},"policy":"/providers/Microsoft.Authorization/policyDefinitions/ea3f2387-9b95-492a-a190-fcdc54f7b070"}
{"principalId":{"type":"string","value":"[reference(subscriptionResourceId('Microsoft.Authorization/policyAssignments', 'inherit-cost-centre'), '2024-04-01', 'full').identity.principalId]"}}
```

`identity: SystemAssigned` asks Azure to create that identity with the assignment, and `location` is
where it lives. The output is the identity's id, an expression only Resource Manager can fill in,
and somebody then has to give that identity the Contributor role on the subscription; until then the
policy can decide to add a tag and has no right to do it. **None of it was deployed.**

Two things the policy does not do. **It does not touch what already exists**: it acts on requests,
and a resource created last year receives no request. Existing resources are fixed by a
**remediation task**, which applies the modification to everything the policy finds out of line.
And **it changes the resource**, which is the point and also the cost: the tag is now on the
resource, where anybody can change it and every later deployment of that resource either repeats it
or fights it.

## Inheritance in the cost data only

The second way works on the bill instead of the resources. Cost Management has a **tag inheritance**
setting which, once switched on, applies a subscription's and a resource group's tags to the
**usage records** of the resources inside them. Microsoft's documentation is precise about the
difference: inherited tags are applied *to child resource usage records and not the resources
themselves*. Nothing in Azure changes; the export of this lesson's next section gains the tags.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-two-inheritances\" aria-label=\"The resource group rg-shop-prod-app carries the tag cost-centre cc-410, and the virtual machine vm-shop-web-2 inside it has no tags. Two ways bring the group's tag down. On the left, an Azure Policy assignment with the modify effect writes the tag onto the resource itself, when it is created or remediated. On the right, Cost Management's tag inheritance leaves the resource as it is and adds the tag only to its usage records in the cost data.\"><defs><marker id=\"l15-two-inheritances-af-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l15-two-inheritances-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"220.0\" y=\"16.0\" width=\"280.0\" height=\"92.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"232.0\" y=\"32.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resource group</text><text x=\"488.0\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">rg-shop-prod-app</text><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">cost-centre: cc-410</text><rect x=\"270.0\" y=\"64.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"81.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm-shop-web-2</text><path d=\"M300.0 110.0 L300.0 130.0 L170.0 130.0 L170.0 154.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-two-inheritances-af-ah-phosphor)\"></path><rect x=\"30.0\" y=\"156.0\" width=\"280.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Azure Policy, effect modify</text><rect x=\"70.0\" y=\"190.0\" width=\"200.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">vm-shop-web-2</text><text x=\"170.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">cost-centre: cc-410</text><text x=\"170.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the tag is written on the resource</text><path d=\"M420.0 110.0 L420.0 130.0 L550.0 130.0 L550.0 154.0\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15-two-inheritances-af-ah-paper)\"></path><rect x=\"410.0\" y=\"156.0\" width=\"280.0\" height=\"112.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Cost Management tag inheritance</text><rect x=\"430.0\" y=\"190.0\" width=\"240.0\" height=\"44.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">vm-shop-web-2  3.20  Tags:</text><text x=\"550.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">{&quot;cost-centre&quot;: &quot;cc-410&quot;}</text><text x=\"550.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only the usage records gain it</text></svg>", "caption": "One rule changes the resource; the other changes only what the bill says about it."}
```

It is available only for some kinds of billing account, the Enterprise Agreement, the Microsoft
Customer Agreement and the Microsoft Partner Agreement, and not for every subscription bought by
card. **Nothing here was switched on.** Where it is available, it is the gentler tool for the
question *who spent what*, and the policy is the tool for the question *whose is this resource*; a
shop that asks both uses both.
