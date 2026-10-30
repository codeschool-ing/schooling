#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# Bicep only, compiled. No network, endpoint, DNS zone or policy exists, and no
# name was resolved: the DNS chain in the lesson is from the documentation, with
# an address the lesson calls illustrative.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/private" && mkdir -p "$HOME/azure/private" && cd "$HOME/azure/private" || exit 1

put sql-private.bicep <<'BICEP'
// sql-private.bicep
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: 'vnet-shop'
}

resource endpoints 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: 'snet-private-endpoints'
}

resource sql 'Microsoft.Sql/servers@2023-08-01' existing = {
  name: 'sql-shop'
}

resource pe 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: 'pe-sql-shop'
  location: 'brazilsouth'
  properties: {
    subnet: { id: endpoints.id }
    privateLinkServiceConnections: [
      {
        name: 'sql'
        properties: {
          privateLinkServiceId: sql.id
          groupIds: [ 'sqlServer' ]
        }
      }
    ]
  }
}

resource zone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
}

resource link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: zone
  name: 'vnet-shop'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnet.id }
    registrationEnabled: false
  }
}

resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: pe
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      { name: 'sql', properties: { privateDnsZoneId: zone.id } }
    ]
  }
}
BICEP

block pe
run 'bicep build sql-private.bicep; echo "exit status $?"'
run "jq -r '.resources[] | .type' sql-private.json"
run "jq -r '.resources[] | select(.type == \"Microsoft.Network/privateDnsZones\") | .name' sql-private.json"

put no-public.bicep <<'BICEP'
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
BICEP

block policy
run 'bicep build no-public.bicep; echo "exit status $?"'
run "jq -r '.resources[0].properties.policyRule.then.effect' no-public.json"
