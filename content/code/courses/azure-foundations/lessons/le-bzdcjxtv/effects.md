---
title: Effects, and when a rule actually runs
version: 1
---

**The effect decides what a true condition does, and the choice is between stopping a request,
changing it, and writing it down.** Microsoft's documentation lists eleven effects; the shop meets
seven of them, in three families:

| family | effect | what happens when the condition is true |
|---|---|---|
| refuse | `deny` | the request to create or change the resource is refused, with the policy's name in the error |
| refuse | `denyAction` | a named action, such as deleting, is refused on resources that match |
| change | `modify` | the request is altered before it is carried out: a tag added, replaced or removed |
| change | `deployIfNotExists` | after the resource is created, a related resource is deployed if it is missing |
| report | `audit` | the resource is created and marked non-compliant |
| report | `auditIfNotExists` | the resource is marked non-compliant if a related resource is missing |
| off | `disabled` | nothing; the assignment exists and is switched off |

## The order they run in

**When a request to create or update a resource arrives, Resource Manager collects every assignment
that applies to it and runs their effects in a fixed order**, which Microsoft documents:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-order\" aria-label=\"The order Azure Policy runs effects in when a request arrives: disabled first, then append and modify, which change the request, then deny, then audit, then auditIfNotExists, then denyAction last. After the resource provider reports success, auditIfNotExists and deployIfNotExists look at what exists beside the new resource.\"><defs><marker id=\"l04-order-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"23.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">disabled</text><text x=\"75.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">skip if off</text><path d=\"M128.0 75.0 L136.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"137.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"189.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">append, modify</text><text x=\"189.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">change the request</text><path d=\"M242.0 75.0 L250.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"251.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"303.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">deny</text><text x=\"303.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">refuse it</text><path d=\"M356.0 75.0 L364.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"365.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"417.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">audit</text><text x=\"417.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">report it</text><path d=\"M470.0 75.0 L478.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"479.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"531.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">auditIfNotExists</text><text x=\"531.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">missing neighbour</text><path d=\"M584.0 75.0 L592.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-order-af-ah-paper-dim)\"></path><rect x=\"593.0\" y=\"40.0\" width=\"104.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">denyAction</text><text x=\"645.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">refuse a delete</text><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">when the request arrives</text><path d=\"M23.0 140.0 L697.0 140.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"360.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">after the resource provider reports success</text><rect x=\"170.0\" y=\"180.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">auditIfNotExists</text><rect x=\"370.0\" y=\"180.0\" width=\"180.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">deployIfNotExists</text></svg>", "caption": "Change before deny, deny before audit, and the effects about neighbours after the resource exists."}
```

The order is not arbitrary. `disabled` is checked first so a switched-off rule costs nothing.
`modify` and `append` run before `deny` because they can change the request, and a request fixed by
`modify`, given the tag it was missing, should not then be denied for missing it. `deny` runs before
`audit` so that a refused request is not also logged as a non-compliant resource that never existed.
The two `IfNotExists` effects run only after the resource provider has said the creation succeeded,
because they are about what exists next to the new resource.

## Effects that act need an identity

`modify` and `deployIfNotExists` do something in your subscription, so somebody has to be allowed to
do it. That somebody is the **assignment's own managed identity**, an identity Azure creates for the
assignment, which lesson 8 explains, given the roles the definition asks for. The built-in that copies
a tag from the resource group to resources missing it shows the request in its rule:

```
ana@laptop:~/azure/policy$ curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json | jq '{displayName: .properties.displayName, effect: .properties.policyRule.then.effect, roles: .properties.policyRule.then.details.roleDefinitionIds}'
{
  "displayName": "Inherit a tag from the resource group if missing",
  "effect": "modify",
  "roles": [
    "/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
  ]
}
```

`b24988ac-6180-42a0-ab88-20f7382dd24c` is the id of the built-in role *Contributor*, the same GUID in
every tenant; roles are lesson 9's subject. Assigning this definition creates the identity and needs the role
given to it at the assignment's scope; without the role, the rule evaluates and its changes fail.
Lesson 15 is about why those tags matter to the bill.

## When a rule runs, and when it does not

A `deny` acts at the moment of a request, and only then. **Resources that existed before the
assignment are not touched by it**: they are evaluated and reported, and that is all. So an
assignment of *Allowed locations* on a subscription with a machine in Texas leaves the machine
running and marks it non-compliant. Fixing what already exists is a separate step, a **remediation
task**, available for `modify` and `deployIfNotExists`, and a manual decision for everything else.

The documentation gives the timings, none of which this lab can show:

- a new assignment takes **about five minutes** to apply to its scope, and then evaluation starts;
- every assignment is evaluated again **once every 24 hours**, the standard cycle, with no promise
  about when a large one finishes;
- a scan can be asked for, for a subscription or a resource group, with `az policy state
  trigger-scan`.

```
ana@laptop:~/azure/policy$ az policy state trigger-scan --resource-group rg-shop-prod
ERROR: Please run 'az login' to setup account.
```

## Several definitions as one

The shop's two rules will become ten. Assigning ten definitions one by one, at the same scope, with
overlapping parameters, is how a rule gets forgotten in one branch. An **initiative**, called a
*policy set definition* in the API, groups definitions so that they are assigned, reported and
exempted as one, with shared parameters. Microsoft's regulatory benchmarks, such as the one for ISO
27001, are built-in initiatives of many definitions each, and the compliance page then
answers by initiative: how far is this subscription from the benchmark.
