#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# Bicep only, compiled and linted. No vault exists: nothing here creates,
# reads or rotates a secret, and no secret value appears in any file.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/vault" && mkdir -p "$HOME/azure/vault" && cd "$HOME/azure/vault" || exit 1

put vault.bicep <<'BICEP'
// vault.bicep
param appPrincipalId string

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-shop-prod'
  location: 'brazilsouth'
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    publicNetworkAccess: 'Disabled'
  }
}

// Key Vault Secrets User: read secret values, nothing else
var secretsUser = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

resource appReads 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(vault.id, appPrincipalId, secretsUser)
  scope: vault
  properties: {
    roleDefinitionId: secretsUser
    principalId: appPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output vaultUri string = vault.properties.vaultUri
BICEP

block vault
run 'bicep build vault.bicep; echo "exit status $?"'
run "jq -r '.resources[] | .type' vault.json"

put leaky.bicep <<'BICEP'
// leaky.bicep
param dbPassword string

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-shop-prod'
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'db-password'
  properties: {
    value: dbPassword
  }
}
BICEP

block leaky
run 'bicep lint leaky.bicep; echo "exit status $?"'

put app-settings.bicep <<'BICEP'
// app-settings.bicep
resource app 'Microsoft.Web/sites@2024-04-01' existing = {
  name: 'app-shop-api'
}

resource settings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: app
  name: 'appsettings'
  properties: {
    DB_CONNECTION: '@Microsoft.KeyVault(VaultName=kv-shop-prod;SecretName=db-connection)'
    PAYMENTS_API_KEY: '@Microsoft.KeyVault(VaultName=kv-shop-prod;SecretName=payments-api-key)'
  }
}
BICEP

block settings
run 'bicep build app-settings.bicep; echo "exit status $?"'

put signing-key.bicep <<'BICEP'
// signing-key.bicep
resource vault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: 'kv-shop-prod'
}

resource receipts 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: vault
  name: 'receipt-signing'
  properties: {
    kty: 'EC'
    curveName: 'P-256'
    keyOps: [ 'sign', 'verify' ]
    rotationPolicy: {
      attributes: { expiryTime: 'P1Y' }
      lifetimeActions: [
        { trigger: { timeBeforeExpiry: 'P30D' }, action: { type: 'rotate' } }
        { trigger: { timeBeforeExpiry: 'P45D' }, action: { type: 'notify' } }
      ]
    }
  }
}
BICEP

block key
run 'bicep build signing-key.bicep; echo "exit status $?"'
run "jq '.resources[0].properties.rotationPolicy.lifetimeActions' signing-key.json"
