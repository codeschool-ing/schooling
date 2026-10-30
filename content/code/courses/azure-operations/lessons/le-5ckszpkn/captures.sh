#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# The files the lesson shows are written here with `put` and quoted from the
# run, so the lesson's copy and the one the commands used are the same bytes.
# Nothing is deployed: there is no subscription. Bicep compiles, decompiles and
# lints on this machine and asks nobody.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
rm -rf "$HOME/azure/bicep" && mkdir -p "$HOME/azure/bicep" && cd "$HOME/azure/bicep" || exit 1

block version
run 'bicep --version'
run 'du -sh ~/.azure/bin/bicep'

put storage.json <<'JSON'
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "accountName": {
      "type": "string",
      "minLength": 3,
      "maxLength": 24
    }
  },
  "variables": {
    "location": "brazilsouth"
  },
  "resources": [
    {
      "type": "Microsoft.Storage/storageAccounts",
      "apiVersion": "2023-05-01",
      "name": "[parameters('accountName')]",
      "location": "[variables('location')]",
      "sku": { "name": "Standard_LRS" },
      "kind": "StorageV2",
      "properties": {
        "minimumTlsVersion": "TLS1_2",
        "allowBlobPublicAccess": false
      }
    },
    {
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers",
      "apiVersion": "2023-05-01",
      "name": "[format('{0}/default/tfstate', parameters('accountName'))]",
      "dependsOn": [
        "[resourceId('Microsoft.Storage/storageAccounts', parameters('accountName'))]"
      ]
    }
  ],
  "outputs": {
    "blobEndpoint": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Storage/storageAccounts', parameters('accountName'))).primaryEndpoints.blob]"
    }
  }
}
JSON

block decompile
run 'bicep decompile storage.json'
run 'cat storage.bicep'

put shop.bicep <<'BICEP'
// shop.bicep
param accountName string
param location string = resourceGroup().location

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
  }
}

resource blobs 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: account
  name: 'default'
}

resource state 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobs
  name: 'tfstate'
}

output blobEndpoint string = account.properties.primaryEndpoints.blob
BICEP

block build
run 'bicep build shop.bicep'
run 'ls'
run 'wc -l shop.bicep shop.json storage.json'
run "jq '.resources[] | {type, name, dependsOn}' shop.json"
run "jq -r '.outputs.blobEndpoint.value' shop.json"

block typo
sed 's/Standard_LRS/Standard_LRSS/; s/TLS1_2/TLS1_3/' shop.bicep > typo.bicep
run 'bicep build typo.bicep; echo "exit status $?"'
sed 's/account.properties.primaryEndpoints.blob/account.properties.primaryEndpoint.blob/' shop.bicep > typo2.bicep
run 'bicep build typo2.bicep; echo "exit status $?"'

put lint.bicep <<'BICEP'
// lint.bicep
param accountName string
param environment string

resource account 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: 'brazilsouth'
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
  }
}

output connection string = 'DefaultEndpointsProtocol=https;AccountName=${accountName};AccountKey=${account.listKeys().keys[0].value}'
BICEP

block lint
run 'bicep lint lint.bicep; echo "exit status $?"'
