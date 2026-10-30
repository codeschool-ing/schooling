#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# Bicep only, compiled. No Front Door, Application Gateway or WAF exists, no
# request is inspected, and nothing is blocked.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/waf" && mkdir -p "$HOME/azure/waf" && cd "$HOME/azure/waf" || exit 1

put frontdoor-waf.bicep <<'BICEP'
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
BICEP

block fd
run 'bicep build frontdoor-waf.bicep; echo "exit status $?"'
run "jq -r '.resources[0].properties.customRules.rules[] | [.priority, .name, .ruleType, .action] | @tsv' frontdoor-waf.json"

put appgw-waf.bicep <<'BICEP'
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
BICEP

block agw
run 'bicep build appgw-waf.bicep; echo "exit status $?"'
