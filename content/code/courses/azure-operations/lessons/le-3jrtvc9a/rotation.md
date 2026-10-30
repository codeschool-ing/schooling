---
title: Rotation: keys rotate themselves, secrets need help
version: 1
---

**Rotation replaces a key or secret with a new version, on a schedule, so that a leaked one stops working
by itself.** Every object in a vault is versioned: rotating adds a version and leaves the old ones
readable until they expire or are disabled, which is what lets consumers move over without a gap.

**Keys can rotate themselves.** A key's **rotation policy** says when, and the vault does the rest. The
shop signs order receipts with an elliptic-curve key that rotates every year:

```bicep
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
```

```
ana@laptop:~/azure/vault$ bicep build signing-key.bicep; echo "exit status $?"
exit status 0
ana@laptop:~/azure/vault$ jq '.resources[0].properties.rotationPolicy.lifetimeActions' signing-key.json
[
  {
    "trigger": {
      "timeBeforeExpiry": "P30D"
    },
    "action": {
      "type": "rotate"
    }
  },
  {
    "trigger": {
      "timeBeforeExpiry": "P45D"
    },
    "action": {
      "type": "notify"
    }
  }
]
```

The key expires a year after each version is created; thirty days before that, the vault creates a new
version, and fifteen days earlier still, a *notify* action raises an event, so whoever verifies receipts
can fetch the new public key. Nothing the shop runs takes part.

**Secrets cannot rotate themselves**, because the vault cannot change the database's password: only the
database can. So secret rotation is a small piece of automation the shop writes. The vault publishes a
**near-expiry event** to Event Grid a set time before a secret's expiry date; a function receives it,
generates a new password, sets it **on the database first**, then writes it to the vault as a new version.
The order matters: written to the vault first, the new password would be fetched by the app before the
database accepted it. Many services offer a better path: **a managed identity for the database too**,
with Entra authentication, which removes the password altogether, and with it the rotation. Where that is
possible, it is the answer the shop prefers.

None of this rotation was run here; the Bicep was compiled.
