---
title: The shop's policy, at the edge
version: 1
---

**The shop's Front Door policy has two managed rule sets and two rules of its own.**

```bicep
// frontdoor-waf.bicep
@allowed([ 'Detection', 'Prevention' ])
param mode string = 'Detection'

resource waf 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2024-02-01' = {
  name: 'wafshopprod'
  location: 'Global'
  sku: { name: 'Premium_AzureFrontDoor' }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: mode
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        { ruleSetType: 'Microsoft_DefaultRuleSet', ruleSetVersion: '2.1', ruleSetAction: 'Block' }
        { ruleSetType: 'Microsoft_BotManagerRuleSet', ruleSetVersion: '1.1' }
      ]
    }
    customRules: {
      rules: [
        {
          name: 'checkoutRateLimit'
          priority: 10
          ruleType: 'RateLimitRule'
          rateLimitDurationInMinutes: 1
          rateLimitThreshold: 30
          matchConditions: [
            { matchVariable: 'RequestUri', operator: 'Contains', matchValue: [ '/checkout' ] }
          ]
          action: 'Block'
        }
        {
          name: 'onlyBrazilForAdmin'
          priority: 20
          ruleType: 'MatchRule'
          matchConditions: [
            { matchVariable: 'RequestUri', operator: 'BeginsWith', matchValue: [ '/admin' ] }
            { matchVariable: 'RemoteAddr', operator: 'GeoMatch', negateCondition: true, matchValue: [ 'BR' ] }
          ]
          action: 'Block'
        }
      ]
    }
  }
}
```

```
ana@laptop:~/azure/waf$ bicep build frontdoor-waf.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/waf$ jq -r '.resources[0].properties.customRules.rules[] | [.priority, .name, .ruleType, .action] | @tsv' frontdoor-waf.json
10	checkoutRateLimit	RateLimitRule	Block
20	onlyBrazilForAdmin	MatchRule	Block
```

**`Microsoft_DefaultRuleSet` 2.1** is Microsoft's core set, covering the OWASP categories: injection,
cross-site scripting, protocol violations, local file inclusion. Its rules score a request, and a request
over the threshold gets the set's action, `Block` here. **`Microsoft_BotManagerRuleSet`** sorts traffic
into good bots, such as search engines, known bad bots and unknown ones, and acts on each class.

The custom rules are evaluated before the managed ones, in order of **priority**, lowest first:

- **`checkoutRateLimit`**: more than 30 requests to `/checkout` in a minute from one client address is not
  a customer; it is somebody testing stolen card numbers, and the rule blocks them for the rest of the
  minute. The threshold came from the shop's own data: lesson 10's week never shows one client near it;
- **`onlyBrazilForAdmin`**: the administration path, which only the shop's staff use, refuses requests
  from outside Brazil. Two conditions in one rule are combined with *and*, and `negateCondition` turns
  the country match into *not Brazil*.

Geography is a weak control, and the shop knows it: an address can be in any country its owner rents.
The rule is there to cut the noise of scanners from elsewhere, not to authenticate anybody; the
administration path still needs a sign-in with a second factor, which is what actually protects it.
