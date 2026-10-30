---
title: Assignments, and how a rule runs down the tree
version: 1
---

**An assignment holds at its scope and at every scope below it.** Assigned to `mg-shop`, *Allowed
locations* governs every subscription under `mg-shop`, every resource group in those subscriptions
and every resource in those groups, including the ones created next year in a subscription nobody
has thought of yet. That is the reason lesson 2's management groups exist.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l04-inheritance\" aria-label=\"An assignment of Allowed locations on mg-shop reaches everything below it: the management groups mg-shop-prod and mg-shop-nonprod, the subscriptions shop-prod and shop-staging, and their resource groups. A second assignment on shop-staging adds a rule of its own, and both apply there. An exemption excuses one resource group, rg-shop-lab, from the first assignment only, until a date.\"><rect x=\"270.0\" y=\"20.0\" width=\"180.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">mg-shop</text><rect x=\"470.0\" y=\"18.0\" width=\"230.0\" height=\"38.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"585.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assignment: Allowed locations</text><path d=\"M452.0 37.0 L468.0 37.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 54.0 L360.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 72.0 L520.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M200.0 72.0 L200.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"120.0\" y=\"86.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mg-shop-prod</text><path d=\"M200.0 116.0 L200.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"110.0\" y=\"134.0\" width=\"180.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"200.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-prod</text><path d=\"M520.0 72.0 L520.0 86.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"440.0\" y=\"86.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"101.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">mg-shop-nonprod</text><path d=\"M520.0 116.0 L520.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"430.0\" y=\"134.0\" width=\"180.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"520.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-staging</text><text x=\"140.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one rule applies</text><path d=\"M200.0 166.0 L200.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"120.0\" y=\"222.0\" width=\"160.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"200.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-prod-app</text><rect x=\"620.0\" y=\"136.0\" width=\"92.0\" height=\"28.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"666.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2nd rule</text><path d=\"M611.0 150.0 L619.0 150.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 166.0 L470.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M570.0 166.0 L570.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"395.0\" y=\"222.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"470.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-staging</text><rect x=\"555.0\" y=\"222.0\" width=\"140.0\" height=\"30.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"625.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">rg-shop-lab</text><text x=\"470.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">both rules apply</text><text x=\"625.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">exempt from the first,</text><text x=\"625.0\" y=\"290.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">until a date</text></svg>", "caption": "An assignment holds at its scope and everywhere below it; only an exemption, written down, excuses."}
```

Three rules decide what a resource is subject to, and none of them is "the nearest assignment wins":

- **every assignment above a resource applies to it, independently.** Nothing below can switch off a
  rule assigned above. A subscription owner who disagrees with `mg-shop`'s policy can see it and
  cannot remove it, which is the point;
- **the result is the most restrictive, cumulatively.** Microsoft's documentation works through it:
  a subscription that denies everything outside `westus` and a group inside it that denies
  everything outside `eastus` together deny everything, in that group;
- **the way out is written into the assignment**, not done below it. An assignment can list
  **`notScopes`**, scopes it skips; and a separate **exemption** can excuse one resource or scope
  from one assignment, with a category, *waiver* or *mitigated*, and a date it expires.

## The shop's two rules, in Bicep

The shop wants two things under `mg-shop`: its resources in Brazil, and every resource group tagged
with the environment it belongs to. The first is the built-in definition from the previous section;
the second has no built-in that says exactly that, so the shop writes its own, a **custom**
definition. Save this as `policy.bicep` in `~/azure/policy`:

```bicep
targetScope = 'managementGroup'

@description('The regions the shop may put resources in.')
param allowedLocations array = [
  'brazilsouth'
  'brazilsoutheast'
]

var allowedLocationsDefinition = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

resource environmentTag 'Microsoft.Authorization/policyDefinitions@2025-03-01' = {
  name: 'shop-environment-tag'
  properties: {
    displayName: 'Resource groups must say their environment'
    policyType: 'Custom'
    mode: 'All'
    parameters: {
      effect: {
        type: 'String'
        defaultValue: 'Deny'
        allowedValues: [
          'Audit'
          'Deny'
          'Disabled'
        ]
      }
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            field: 'tags[environment]'
            notIn: [
              'prod'
              'staging'
              'shared'
            ]
          }
        ]
      }
      then: {
        effect: '[parameters(\'effect\')]'
      }
    }
  }
}

resource locations 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: 'shop-locations'
  properties: {
    displayName: 'Shop resources stay in Brazil'
    policyDefinitionId: allowedLocationsDefinition
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

resource environment 'Microsoft.Authorization/policyAssignments@2025-03-01' = {
  name: 'shop-environment-tag'
  properties: {
    displayName: 'Resource groups must say their environment'
    policyDefinitionId: environmentTag.id
    enforcementMode: 'DoNotEnforce'
  }
}
```

Three resources: the custom definition, stored at the management group so that everything below
can use it, and two assignments. The first assigns the built-in by its fixed id, with the two
Brazilian regions as its parameter. The second assigns the custom definition with
**`enforcementMode: 'DoNotEnforce'`**: the policy is evaluated and resources are reported compliant
or not, but nothing is refused. It is how a new rule should start, so that the report shows what it
would break before it breaks anything.

```
ana@laptop:~/azure/policy$ az bicep build --file policy.bicep --stdout | jq -c '."$schema", [.resources[] | [.type, .name]]'
"https://schema.management.azure.com/schemas/2019-08-01/managementGroupDeploymentTemplate.json#"
[["Microsoft.Authorization/policyDefinitions","shop-environment-tag"],["Microsoft.Authorization/policyAssignments","shop-locations"],["Microsoft.Authorization/policyAssignments","shop-environment-tag"]]
```

A `managementGroupDeploymentTemplate`, aimed where `targetScope` said. Two details in the compiled
template show the line between what Bicep resolves and what it leaves for Azure:

```
ana@laptop:~/azure/policy$ az bicep build --file policy.bicep --stdout | jq -c '.resources[0].properties.policyRule.then, .resources[2].properties.policyDefinitionId'
{"effect":"[[parameters('effect')]"}
"[extensionResourceId(managementGroup().id, 'Microsoft.Authorization/policyDefinitions', 'shop-environment-tag')]"
```

**The effect came out as `[[parameters('effect')]`, with two brackets.** A string starting with `[`
is an expression to Resource Manager, which would try to evaluate `parameters('effect')` while
deploying the template and fail, since the template has no such parameter. The doubled bracket tells
Resource Manager to store the text as it is, one bracket shorter, and **Azure Policy evaluates it
later, every time the rule runs**. Two evaluators read that string, at two different moments, and
Bicep escaped it for the first so that the second gets it. And the assignment points at its
definition with `extensionResourceId(managementGroup().id, ...)`: the definition's id depends on
which management group the template is deployed to, which only Resource Manager knows.

Deploying it would be `az deployment mg create --management-group-id mg-shop --location brazilsouth
--template-file policy.bicep`. **It was not run.** Bicep checked the shape; it did not check what
only Azure checks, such as that **a policy assignment at a management group may have a name of at
most 24 characters**, a limit `shop-environment-tag` meets with four to spare.
