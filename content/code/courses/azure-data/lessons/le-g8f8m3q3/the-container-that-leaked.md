---
title: The container that leaked, and how not to have one
version: 1
---

**The storage exposures that reach the news are, as a rule, a setting somebody chose, not a
break-in.** Nobody guessed a password. A container was public, or a SAS lived for years, or an account
key sat in a file somebody published, and nothing anybody looked at said so. This section is the
defender's side: the three shapes, the settings that remove each one, and how to notice one that
happened anyway. The settings are checked with Terraform; Defender for Storage and the logs are
taught from Microsoft's documentation and were not run.

## Three ways a container leaks

| shape | how it happens | what stops it |
|---|---|---|
| a public container | a level set to `blob` or `container` for a test, or for one public file in a container of private ones | the account's anonymous access set to false |
| a SAS that lives too long | a URL with a year's expiry, pasted into a ticket, a chat or a repository | short expiries, stored access policies, user delegation SAS, an expiration policy on the account |
| an account key in the open | a connection string committed with code, or printed in a log | shared key access switched off, Microsoft Entra ID for every client |

**The third is the worst**, because this lesson's first section showed what a key can do, and because
the only remedy, rotation, breaks every honest client still using the old key.

## The account, hardened

Make a directory for the declaration:

```sh
mkdir -p ~/azure/tf/hardened && cd ~/azure/tf/hardened
```

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "data" {
  name                     = "stquitandadataprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"

  sas_policy {
    expiration_period = "00.01:00:00"
    expiration_action = "Block"
  }
}
```

@@CAP tf-hardened@@

Line by line, from the leak each one closes:

- **`allow_nested_items_to_be_public = false`** is the account's anonymous access switch of the
  previous section, under the provider's name for it. No container in the account can be public.
- **`shared_access_key_enabled = false`** refuses every request signed with an account key,
  including every SAS signed with one. Clients sign in with Microsoft Entra ID instead, and a
  user delegation SAS still works, because it is not signed with the account key.
  `default_to_oauth_authentication` makes the portal do the same.
- **`https_traffic_only_enabled` and `min_tls_version`** keep the data encrypted in transit. The
  provider in this course accepts only `TLS1_2`, as the refusal shows, so the older protocol versions
  cannot even be declared.
- **`sas_policy`** sets the longest validity a SAS should have, one hour here in the provider's
  `days.hours:minutes:seconds` form. By Microsoft's description, `Block` refuses a request whose SAS
  was signed for longer, and `Log`, the provider's other value, lets it through and records it.

Switching shared keys off is the strongest line and the one with a migration behind it: every program
in lessons 2 to 5 signs with the key, through the connection string. Those programs would sign in with
an Entra ID identity instead, which the libraries support, and none of that can be tried against
Azurite, which knows only its key.

## Noticing a leak

**Defender for Storage** watches requests to the account and raises alerts for patterns Microsoft
documents, such as access from an unusual place or an unusual amount of data read, and, in its newer
plan, scans uploaded blobs for malware. It is a paid plan per storage account and is switched on in
Microsoft Defender for Cloud.

**The logs say who read what, and how.** With a diagnostic setting sending the blob service's logs to
a Log Analytics workspace, each request is a row in the table `StorageBlobLogs`, and one of its columns,
`AuthenticationType`, says whether the request was signed with the key, with a SAS, with Entra ID, or
by nobody. A query of this shape, in Kusto, the workspace's query language, lists anonymous reads by
blob; it was not run in this course:

```
StorageBlobLogs
| where AuthenticationType == "Anonymous" and OperationName == "GetBlob"
| summarize reads = count() by Uri
| order by reads desc
```

**The response to a leak is in the order of the table above.** A public container is set back to
`off` and the account switch to false. A leaked service SAS is revoked by deleting its stored access
policy, or, without one, by rotating the key that signed it; a user delegation SAS by revoking the
delegation keys. A leaked account key is regenerated at once, which breaks every client using it, and
that breakage is the price of having used the key in the first place. Then the logs answer the
question an incident report has to: what was read, by whom, between which times.
