---
title: Detection first, then prevention
version: 1
---

**A new WAF policy starts in Detection mode, and stays there until its logs say it can block.** In
Detection, every rule is evaluated and every match is **logged**, and nothing is blocked. The reason is
false positives: a managed rule written to catch SQL injection also matches a customer searching for
`O'Brien's 1/2 price`, and in Prevention that customer gets a 403 and leaves.

So the shop's path to Prevention is a few weeks of reading what Detection would have blocked. The WAF's
logs reach the workspace through a diagnostic setting, lesson 8's mechanism, in a table per product, and
the question asked of them is: **which rule matched which legitimate requests?** Every match on a real
customer is a false positive to remove before switching. That reading was not done here, because a WAF
log needs a WAF.

The usual remedy is an **exclusion**: a part of the request a rule set ignores. The shop's search box
sends free text in an argument called `search`, which the default rule set kept matching, so the regional
policy excludes it:

```bicep
// appgw-waf.bicep
resource waf 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-05-01' = {
  name: 'waf-agw-shop'
  location: 'brazilsouth'
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: true
    }
    managedRules: {
      managedRuleSets: [
        { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1' }
      ]
      exclusions: [
        {
          matchVariable: 'RequestArgNames'
          selectorMatchOperator: 'Equals'
          selector: 'search'
          exclusionManagedRuleSets: [
            { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1' }
          ]
        }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/waf$ bicep build appgw-waf.bicep; echo "exit status $?"
exit status 0
```

An exclusion is a hole cut on purpose, and the narrower it is the better: one argument name, for one rule
set, rather than turning a rule off for the whole site. It should also be written down with its reason,
because the next person to read the policy will see a gap and wonder.

Once the false positives are excluded, the mode changes to Prevention, which in the shop's Front Door
policy is one parameter. The switch is a deployment like any other: through the pipeline, with lesson 3's
approval, and watched for a jump in 403s in the minutes after, which is the WAF's version of the canary.
