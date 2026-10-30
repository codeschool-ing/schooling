---
title: System-assigned and user-assigned
version: 1
---

**A managed identity is a service principal that Azure creates for a resource, holds the credential
of, and rotates by itself.** Lesson 7 climbed a ladder from a secret to a federated credential, and a
managed identity is the same top rung with the other side filled in by Azure: the program running on
an Azure resource asks for a token, and nobody, the program included, ever sees a credential. **There
is nothing to store, nothing to renew and nothing to leak.**

It only works for code running **on Azure**, in a resource that supports it: a virtual machine, an App
Service web app, a function, a container app, an AKS pod through workload identity. For anything
outside Azure, the shop's GitHub pipeline among them, lesson 7's federation is the answer.

There are two kinds, and the difference is **whose lifetime the identity follows**:

| | system-assigned | user-assigned |
|---|---|---|
| created | with the resource, by switching it on | on its own, as a resource of type `userAssignedIdentities` |
| belongs to | exactly one resource | nobody: it is attached to as many resources as you like |
| deleted | when the resource is deleted | when you delete it |
| roles | given after the resource exists | can be given before any resource uses it |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l08-two-kinds\" aria-label=\"Two kinds of managed identity compared by lifetime. On the left, the web app app-shop-prod contains its system-assigned identity inside its own box: deleting the app deletes the identity and its roles. On the right, the user-assigned identity id-shop-app is a box of its own, attached to two web apps by lines; deleting either app leaves the identity and its roles in place.\"><text x=\"175.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">system-assigned</text><rect x=\"40.0\" y=\"50.0\" width=\"270.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-shop-prod</text><rect x=\"75.0\" y=\"96.0\" width=\"200.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">its identity</text><text x=\"175.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and its roles</text><text x=\"175.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">delete the app: both go</text><text x=\"530.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">user-assigned</text><rect x=\"430.0\" y=\"50.0\" width=\"200.0\" height=\"60.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"530.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">id-shop-app</text><text x=\"530.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">and its roles</text><rect x=\"365.0\" y=\"150.0\" width=\"150.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"440.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app-shop-prod</text><rect x=\"565.0\" y=\"150.0\" width=\"125.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"627.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app-shop-prod-2</text><path d=\"M470.0 111.0 L445.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M590.0 111.0 L615.0 149.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"530.0\" y=\"236.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">delete an app: the identity stays</text></svg>", "caption": "The question is whose lifetime the identity follows: one resource's, or its own."}
```

**A system-assigned identity dies with its resource, and so do its role assignments.** Rebuild the
web app and the new one has a new identity with no roles, and the deployment that recreated it must
give them again. That is right for one resource with permissions of its own. A **user-assigned**
identity outlives the resources that use it: the shop gives `id-shop-app` its roles once, and every
new copy of the application, in every zone and every release, starts with them. It is also the only
way for several resources to be one principal, which keeps a role list short.

## The shop's web app, with both

Make the lesson's directory:

```sh
mkdir -p ~/azure/identity && cd ~/azure/identity
```

and save this as `app.bicep`:

```bicep
param location string = resourceGroup().location

resource appId 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-shop-app'
  location: location
}

resource plan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'asp-shop-prod'
  location: location
  sku: {
    name: 'B1'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource web 'Microsoft.Web/sites@2024-04-01' = {
  name: 'app-shop-prod'
  location: location
  identity: {
    type: 'SystemAssigned, UserAssigned'
    userAssignedIdentities: {
      '${appId.id}': {}
    }
  }
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'PYTHON|3.12'
      appSettings: [
        {
          name: 'AZURE_CLIENT_ID'
          value: appId.properties.clientId
        }
      ]
    }
  }
}

resource assets 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'stshopassetsprod'
  location: location
  sku: {
    name: 'Standard_ZRS'
  }
  kind: 'StorageV2'
}

resource canRead 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(assets.id, appId.id, 'blob-reader')
  scope: assets
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1')
    principalId: appId.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

output systemPrincipalId string = web.identity.principalId
output userClientId string = appId.properties.clientId
```

Five resources: the user-assigned identity, a plan for the web app to run on, the web app with
**both** identities switched on, a storage account for the shop's images, and a **role assignment**
that lets `id-shop-app` read blobs in that account. The GUID in it is the built-in role *Storage Blob
Data Reader*, from Microsoft's list of built-in roles, and lesson 9 explains where such ids come from.
Compile it and look at the two identities and the outputs:

```
ana@laptop:~/azure/identity$ az bicep build --file app.bicep --stdout | jq '{identity: .resources[] | select(.type == "Microsoft.Web/sites") | .identity, outputs}'
{
  "identity": {
    "type": "SystemAssigned, UserAssigned",
    "userAssignedIdentities": {
      "[format('{0}', resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'id-shop-app'))]": {}
    }
  },
  "outputs": {
    "systemPrincipalId": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Web/sites', 'app-shop-prod'), '2024-04-01', 'full').identity.principalId]"
    },
    "userClientId": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', 'id-shop-app'), '2023-01-31').clientId]"
    }
  }
}
```

The user-assigned identity is attached **by its resource id**, as a key whose value is empty. The two
outputs are `reference(...)` expressions: a principal id is a GUID Entra ID makes when the identity is
created, so the template can only say where to read it afterwards. **An identity with no role reaches
nothing.** Switching one on gives the resource a name in the directory and no permission at all; the
role assignment is what lets it read the images, and the next section is how the code asks for the
token.
