---
title: Closing the public path, and keeping it closed
version: 1
---

**A private endpoint adds a private path; it does not remove the public one.** That takes one more
property on the service, `publicNetworkAccess: 'Disabled'`, which the vault in lesson 17 already set. Until
it is set, the database is reachable both ways, and the private endpoint protects nothing that the public
firewall did not.

Setting it once is easy. Keeping it set is the problem, because the next person to need access from their
laptop will turn it back on, meaning to turn it off again later. **Azure Policy makes the decision stick**:
a policy with the `deny` effect refuses, at Resource Manager, any request that would create or change a SQL
server so that public access is anything but disabled:

```bicep
// no-public.bicep
targetScope = 'subscription'

resource denyPublicSql 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'deny-public-sql'
  properties: {
    displayName: 'SQL servers must not allow public network access'
    policyType: 'Custom'
    mode: 'Indexed'
    policyRule: {
      if: {
        allOf: [
          { field: 'type', equals: 'Microsoft.Sql/servers' }
          { field: 'Microsoft.Sql/servers/publicNetworkAccess', notEquals: 'Disabled' }
        ]
      }
      then: { effect: 'deny' }
    }
  }
}

resource assign 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'deny-public-sql'
  properties: {
    policyDefinitionId: denyPublicSql.id
    displayName: 'SQL servers must not allow public network access'
  }
}
```

```
ana@laptop:~/azure/private$ bicep build no-public.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/private$ jq -r '.resources[0].properties.policyRule.then.effect' no-public.json
deny
```

The policy is defined and assigned at the subscription, so it covers every resource group, including ones
created next year. It refuses the portal, the command line, Bicep and Terraform alike, because they all go
through Resource Manager, which is the point lesson 4 made about what Bicep compiles to. Azure also ships
built-in policies for the same rule on many services; a custom one is written here because it shows the
shape, and lesson 24 writes another.

A `deny` policy assigned to a subscription with existing violations does not change them: it stops new
ones. Existing resources show as **non-compliant**, which is lesson 16's posture view. The order the shop
follows is the safe one: fix the existing servers first, then assign the policy, then nobody can undo it
without changing the policy, which is a reviewed change to a file.
