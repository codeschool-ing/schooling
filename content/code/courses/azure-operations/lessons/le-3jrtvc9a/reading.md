---
title: Reading a secret, with no code at all
version: 1
---

**The simplest way for an App Service app to use a secret is to never read it in code.** A **Key Vault
reference** is an app setting whose value names a secret; App Service resolves it with the app's managed
identity and hands the application an ordinary environment variable:

```bicep
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
```

```
ana@laptop:~/azure/vault$ bicep build app-settings.bicep; echo "exit status $?"
exit status 0
```

The application reads `DB_CONNECTION` from its environment as it always did, and has no idea a vault
exists. Leaving out a version in the reference means the **latest version** of the secret; App Service
fetches it again periodically, so a rotated secret reaches the app without a redeployment, after a delay
that Microsoft's documentation states. Container Apps and Functions have equivalent references.

When code does need to read a secret itself, for a value used rarely or chosen at run time, the SDK does it
with the same identity. This was **not run**: it needs a vault and an identity in Azure.

```python
# reading a secret from code, as the app's managed identity
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

client = SecretClient("https://kv-shop-prod.vault.azure.net", DefaultAzureCredential())
api_key = client.get_secret("payments-api-key").value
```

`DefaultAzureCredential` tries, in a fixed order, the ways an identity can be found: environment
variables, a managed identity, the Azure command line's sign-in on a developer's laptop. The same line
works in production and on a laptop, which is why the code names no credential.

Two habits complete it. **Read once and cache**, rather than per request: a vault has request limits per
vault, and an application that fetches a secret for every request meets them on its busiest day. And
**never log the value**: a debug line that prints a configuration dictionary prints the secret with it,
into the workspace of lesson 9, where anybody with read access will find it.
