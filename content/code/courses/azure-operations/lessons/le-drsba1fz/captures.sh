#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# Files are written with `put` and quoted from the run. Nothing is deployed:
# what-if and deployment stacks need Resource Manager and are taught from the
# documentation, with no transcript.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/infra" && mkdir -p "$HOME/azure/infra/modules" && cd "$HOME/azure/infra" || exit 1

put modules/state.bicep <<'BICEP'
// modules/state.bicep
@minLength(3)
@maxLength(24)
param accountName string
param location string

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: { name: 'Standard_ZRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
  properties: {
    isVersioningEnabled: true
    deleteRetentionPolicy: { enabled: true, days: 30 }
  }
}

resource state 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobs
  name: 'tfstate'
}

output accountId string = account.id
BICEP

put main.bicep <<'BICEP'
// main.bicep
@allowed([ 'dev', 'prod' ])
param environment string
param location string = 'brazilsouth'

var suffix = uniqueString(resourceGroup().id)

module state 'modules/state.bicep' = {
  name: 'state-${environment}'
  params: {
    accountName: 'stshop${environment}${take(suffix, 6)}'
    location: location
  }
}

output stateAccountId string = state.outputs.accountId
BICEP

block build
run 'bicep build main.bicep'
run "jq '.resources | map({type, name})' main.json"
run "jq '.resources[0].properties.template.resources | length' main.json"

put main.prod.bicepparam <<'BICEP'
// main.prod.bicepparam
using 'main.bicep'

param environment = 'prod'
BICEP

block params
run 'bicep build-params main.prod.bicepparam --outfile main.prod.parameters.json'
run 'jq . main.prod.parameters.json'

put main.wrong.bicepparam <<'BICEP'
// main.wrong.bicepparam
using 'main.bicep'

param environment = 'production'
param region = 'brazilsouth'
BICEP

block params-wrong
run 'bicep build-params main.wrong.bicepparam --outfile wrong.json; echo "exit status $?"'
run 'ls'

put modules/db.bicep <<'BICEP'
// modules/db.bicep
@secure()
param adminPassword string
param location string = 'brazilsouth'

resource sql 'Microsoft.Sql/servers@2023-08-01' = {
  name: 'sql-shop-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    administratorLogin: 'shopadmin'
    administratorLoginPassword: adminPassword
  }
}
BICEP
put db.bicepparam <<'BICEP'
// db.bicepparam
using 'modules/db.bicep'

param adminPassword = readEnvironmentVariable('SHOP_DB_PASSWORD')
BICEP

block secure
run 'bicep build-params db.bicepparam --outfile db.parameters.json; echo "exit status $?"'
run "SHOP_DB_PASSWORD='not-a-real-one' bicep build-params db.bicepparam --outfile db.parameters.json"
run "jq .parameters db.parameters.json"
