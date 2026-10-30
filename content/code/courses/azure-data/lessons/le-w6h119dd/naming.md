---
title: Names that survive
version: 1
---

**Three things get names in Blob Storage, and none of them can be renamed**: the account, the
container and the blob. An account's name is fixed at creation. A container has no rename operation
at all. A blob can only be copied to a new name and the old one deleted, which for a million blobs is
two million operations and, on Azure, a bill. So a name is chosen once, and it has to still make sense
when the company has three more teams and five more years of data.

## The account: short, global and public

**A storage account name is between 3 and 24 characters, lowercase letters and digits only, and
unique across all of Azure**, because it becomes a host name under `core.windows.net` that anybody on
the internet can look up. The first two rules are the provider's to check, so Terraform refuses a
name before anything is sent:

```
ana@laptop:~/azure/tf/account$ sed -i 's/stquitandadataprd/st-quitanda-data-prd/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: invalid value for name (can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long)
ana@laptop:~/azure/tf/account$ sed -i 's/st-quitanda-data-prd/stquitandadataanalyticsprd/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: invalid value for name (can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long)
```

The hyphens are refused in the first, and the length in the second: `stquitandadataanalyticsprd` is 26
characters. **The third rule, uniqueness, nobody can check offline.** Only Azure knows which names are
taken, and a name that passes `validate` can still fail at creation because somebody somewhere
already has it. That is the reason names carry the company and not only the purpose: `stdata` was
taken years ago, `stquitandadataprd` most likely was not.

Twenty-four characters without separators is tight, so the convention Microsoft's Cloud Adoption
Framework suggests, and Quitanda follows, packs the parts in a fixed order:

| part | example | why |
|---|---|---|
| resource type | `st` | so a name in a log says what it is |
| organisation | `quitanda` | uniqueness, and whose bill it is |
| workload | `data`, `lake`, `logs` | what lives there |
| environment | `prd`, `dev` | so production is never touched by mistake |

**Leave the region out unless you will really have two.** A name that says `brs` for Brazil South
becomes a lie the day the data is replicated to a second region, and it cannot be changed.

## The container: a little more room

A container name is 3 to 63 characters: lowercase letters, digits and single hyphens, starting with a
letter or a digit. Azurite enforces the same rules Azure does, so this is a real refusal:

```
ana@laptop:~/azure$ az storage container create -n Orders 2>&1 | head -2
ERROR: The specified resource name contains invalid characters.
RequestId:ae4b4168-5b97-47c7-b5c2-f6db4a9cc820
ana@laptop:~/azure$ az storage container create -n or 2>&1 | head -2
ERROR: The specified resource name length is not within the permissible limits.
RequestId:61467083-44bb-4f56-9c04-f8146d89b4f6
ana@laptop:~/azure$ az storage container create -n orders-raw
{
  "created": true
}
```

Quitanda names containers by **what stage the data is in**, not by who wrote it: `orders-raw` for
the nightly exports as the shop produced them, and later `orders-curated` for the cleaned version the
analysts read. A container is also where access is most often granted, so a container that mixes two
audiences is a permission that cannot be given cleanly to either.

## The blob: the slash is only a character

A blob name can be up to 1,024 characters and can contain `/`, and that slash is where folders seem
to come from:

```
ana@laptop:~/azure$ echo x > x.csv && az storage blob upload -c orders-raw -n "exports/2026/10/29/orders.csv" -f x.csv -o none 2>/dev/null && az storage blob list -c orders-raw --query "[].name" -o tsv
exports/2026/10/29/orders.csv
```

**There is one blob here, and no folder called `exports`.** The name is the whole string, slashes
included, and the listing tools draw folders by cutting names at the slash. Lesson 2 shows the cutting
and lesson 3 shows the one kind of account where the folders are real. What matters for naming is the
order: **put the part you will filter by first, and dates as year, month and day, zero-padded.** A
list sorted by name is then sorted by date, and "everything from October" is one prefix,
`exports/2026/10/`, rather than a scan of every blob the container holds.
