---
title: Tags, and the policy that puts them there
version: 1
---

**A tag is a name and a value on a resource, and it is the only thing in Azure that says whose a resource
is.** The resource group says where it lives, the subscription says who pays for the subscription, and
neither says which team decided it should exist. The shop uses two tags on everything: `team`, which
team answers for it, and `env`, `prod` or `dev`.

Tags work only when nobody has to remember them. **Two policies make them automatic**:

```bicep
// tag-policies.bicep
targetScope = 'subscription'

resource requireTeam 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'require-team-tag-on-groups'
  properties: {
    displayName: 'Resource groups must carry a team tag'
    policyType: 'Custom'
    mode: 'All'
    policyRule: {
      if: {
        allOf: [
          { field: 'type', equals: 'Microsoft.Resources/subscriptions/resourceGroups' }
          { field: 'tags[\'team\']', exists: 'false' }
        ]
      }
      then: { effect: 'deny' }
    }
  }
}

resource inheritTeam 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'inherit-team-tag'
  properties: {
    displayName: 'Resources inherit the team tag from their resource group'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          { field: 'tags[\'team\']', exists: 'false' }
          { value: '[resourceGroup().tags[\'team\']]', notEquals: '' }
        ]
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [ '/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' ]
          operations: [
            { operation: 'add', field: 'tags[\'team\']', value: '[resourceGroup().tags[\'team\']]' }
          ]
        }
      }
    }
  }
}
```

```
ana@laptop:~/azure/tags$ bicep build tag-policies.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/tags$ jq -r '.resources[] | [.name, .properties.policyRule.then.effect] | @tsv' tag-policies.json
require-team-tag-on-groups	deny
inherit-team-tag	modify
```

The first **denies** creating a resource group without a `team` tag, so every group starts owned. The
second **modifies**: a resource created without a `team` tag gets its group's, added by Azure Policy at
creation. A `modify` policy changes the request, so it needs an identity with a role that may write tags;
the GUID in `roleDefinitionIds` is the built-in *Contributor* role, which the assignment's managed
identity is given. Both compiled; neither was assigned, because there is no subscription.

Together they make the common case free: a team creates `rg-search` with `team: search`, and everything
inside it is tagged without anybody thinking about it. Resources that existed before the policies are not
changed by `modify` until a **remediation task** runs over them, which is a one-off job after the
assignment.

Three rules keep tags useful. **Few of them**: two tags everybody sets beat twelve nobody trusts. **Fixed
values**: `shop`, not `Shop`, `shop-team` or `the shop`, which a policy with `allowedValues` can enforce.
And **not secrets**: tags are readable by anyone with read access to the resource, and they appear in the
cost export.
