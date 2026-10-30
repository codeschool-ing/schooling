---
title: A policy definition is a condition and an effect
version: 1
---

**Azure Policy is not about who may do something. It is about what may exist.** The wrong picture
merges it with permissions: if bia may create virtual machines, surely a policy is a finer
permission. It is not. Lesson 9's role-based access answers *may this identity make this request*,
and Azure Policy answers *may the resource this request describes exist here, in this shape*,
whoever asks. bia may be Owner of the whole subscription and still be refused a machine in Texas,
because the rule is about Texas and not about her.

A policy comes in two pieces:

- **a definition**: a condition on a resource's properties and an **effect**, what happens when the
  condition is true. "If the location is not one of these, deny";
- **an assignment**: that definition applied at a scope, one of lesson 2's boxes, with values for its
  parameters. "Deny anything outside Brazil, under `mg-shop`".

The definition says what the rule is; the assignment says where it holds. One definition can be
assigned many times, at different scopes, with different values.

## Reading a built-in definition

Microsoft ships a large catalogue of definitions ready to assign, the **built-in** ones, and publishes
them in a public GitHub repository, `Azure/azure-policy`. The one that keeps resources
inside a list of regions is called *Allowed locations*. Make the lesson's directory and fetch it:

```sh
mkdir -p ~/azure/policy && cd ~/azure/policy
curl -sS -o allowed-locations.json https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/General/AllowedLocations_Deny.json
```

```
ana@laptop:~/azure/policy$ jq '{name, displayName: .properties.displayName, mode: .properties.mode, version: .properties.version, effects: .properties.parameters.effect.allowedValues}' allowed-locations.json
{
  "name": "e56962a6-4747-49cd-b67b-bf8b01975c4c",
  "displayName": "Allowed locations",
  "mode": "Indexed",
  "version": "1.1.0",
  "effects": [
    "Audit",
    "Deny",
    "Disabled"
  ]
}
```

**`name` is a GUID, and it is the same in every tenant on Azure**: a built-in definition's id is
`/providers/Microsoft.Authorization/policyDefinitions/` followed by that GUID, with no subscription in
it, the same shape lesson 2 found for a management group. `version` is the definition's own, since
Microsoft revises built-ins. The `effect` is a **parameter**, chosen at assignment, from three values,
so the same rule can refuse or merely report. Now the rule itself:

```
ana@laptop:~/azure/policy$ jq '.properties.policyRule' allowed-locations.json
{
  "if": {
    "allOf": [
      {
        "field": "location",
        "notIn": "[parameters('listOfAllowedLocations')]"
      },
      {
        "field": "location",
        "notEquals": "global"
      },
      {
        "field": "type",
        "notEquals": "Microsoft.AzureActiveDirectory/b2cDirectories"
      }
    ]
  },
  "then": {
    "effect": "[parameters('effect')]"
  }
}
```

The `if` is a condition on **fields** of the resource being created or changed. `allOf` means every
item must hold: the location is not in the list, the location is not `global`, and the resource is
not an Entra B2C directory. `[parameters('listOfAllowedLocations')]` is an expression, filled in from
the assignment. The `then` names the effect. That is the whole grammar, give or take operators:
`field`, a comparison (`equals`, `notIn`, `like`, `exists`, `contains`...), and `allOf`, `anyOf` and
`not` to combine them.

## What the mode leaves out

**`"mode": "Indexed"` means the definition looks only at resource types that carry tags and a
location**, and a resource group is not one of them. That is why the description of *Allowed
locations* says it excludes resource groups, and why Microsoft ships a second definition for those:

```
ana@laptop:~/azure/policy$ curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/General/ResourceGroupAllowedLocations_Deny.json | jq -c '[.name, .properties.displayName, .properties.mode]'
["e765b5de-1225-4ba3-bd56-1ac6695af988","Allowed locations for resource groups","All"]
```

Mode `All` evaluates everything, resource groups and subscriptions included. A definition about
resources' regions wants `Indexed`, so that types with no location do not trip it; a definition
about resource groups has to be `All`, or it never sees them. Getting the mode wrong produces a
policy that is assigned, reports, and quietly governs nothing.

## The same definition, asked of Azure

Resource Manager holds the same built-ins, and the CLI can show one:

```
ana@laptop:~/azure/policy$ az policy definition show --name e56962a6-4747-49cd-b67b-bf8b01975c4c
ERROR: Please run 'az login' to setup account.
```

That one needs a sign-in, like every question to Resource Manager in this lab. The GitHub copy is
the one you can read here, and **it is the copy Microsoft maintains in the open**, so a definition's
history, every change to its rule, is in the repository's log.
