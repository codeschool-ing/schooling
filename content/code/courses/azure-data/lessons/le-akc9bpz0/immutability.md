---
title: Immutability, the write that nobody can undo
version: 1
---

**Soft delete and versioning keep a copy after a mistake; an immutability policy refuses the mistake.**
While a blob is under one, it cannot be overwritten or deleted, by anybody, whatever role or key they
hold. Storage people call that WORM, write once, read many. It exists for records that a law or an
auditor requires to stay exactly as written: Brazil's tax rules oblige Quitanda to keep its invoices
and the records behind them for years, and "nobody changed them" is easier to show when nobody could.

This section is taught from Microsoft's documentation on immutable storage and checked with
Terraform. Azurite refuses both data-plane operations for it, as the next section shows.

## Two kinds of policy

| policy | what it does | how it ends |
|---|---|---|
| time-based retention | no overwrite and no delete until the blob is older than a number of days | the days pass |
| legal hold | no overwrite and no delete while the hold is set | somebody clears it |

**A legal hold has no date.** It is for the lawsuit or the investigation that will last as long as
it lasts. At container level it is set and cleared by named tags, so that several holds can sit on the
same data for several reasons.

**A time-based policy is unlocked or locked, and the difference is the whole point.** Unlocked, it can
be shortened or deleted, which is how a design is tested. Locked, Microsoft documents that it can be
extended and never shortened or removed, and that a container or an account holding blobs still under
a locked policy cannot be deleted. That is what an auditor asks for, and it is also a commitment: a
locked seven-year policy on the wrong container is seven years of storage nobody can delete.

A policy can sit on a whole container, the older arrangement, or, with version-level immutability, on
individual blob versions. Container level is enough for a container that holds only records, which is
the design below.

## Quitanda's audit container

Save this beside the other two files:

`audit.tf`:

```hcl
resource "azurerm_storage_container" "audit" {
  name               = "audit"
  storage_account_id = azurerm_storage_account.data.id
}

resource "azurerm_storage_container_immutability_policy" "audit" {
  storage_container_resource_manager_id = azurerm_storage_container.audit.id
  immutability_period_in_days           = 2557
  locked                                = false
}
```

```
ana@laptop:~/azure/tf/protect$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/protect$ sed -i 's/= 2557/= 0/' audit.tf && terraform validate -no-color

Error: expected immutability_period_in_days to be in the range (1 - 146000), got 0

  with azurerm_storage_container_immutability_policy.audit,
  on audit.tf line 8, in resource "azurerm_storage_container_immutability_policy" "audit":
   8:   immutability_period_in_days           = 0
```

**2,557 days is seven years**, with the two leap days of the next seven counted. `locked = false` is
deliberate for the first version of this file: the policy goes on unlocked, the export job is tested
against it, and somebody changes the word to `true` in a reviewed change when everyone agrees, because
after that apply nothing can be taken back. The refusal is the provider's range, 1 to 146,000 days;
zero is not a policy.

**What immutability does not do** is keep the data safe from loss of the account's region, or from a
bill. A blob under a policy is still stored, still billed, and still lives where the account's
replication puts it. Locking audit records also locks their cost in, which is one more reason the
audit container holds the records and nothing else.
