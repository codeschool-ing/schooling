---
title: Restoring the state from its own history
version: 1
---

**The fastest recovery is a copy of the state from before the accident.** The snapshot is one. Download
it, look at it before trusting it, and put it back:

```
ana@laptop:~/azure/tf/release$ az storage blob download --container-name tfstate --name shop.tfstate --snapshot 2026-10-30T18:22:54.9190000Z --file restored.tfstate --no-progress -o none
ana@laptop:~/azure/tf/release$ jq '{serial, lineage, resources: [.resources[].type]}' restored.tfstate
{
  "serial": 1,
  "lineage": "e8adb596-3007-ccb8-2df0-fd09af178519",
  "resources": [
    "terraform_data"
  ]
}
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file restored.tfstate --overwrite --no-progress -o none
ana@laptop:~/azure/tf/release$ cp restored.tfstate terraform.tfstate && terraform plan -no-color | grep -m1 "No changes"
No changes. Your infrastructure matches the configuration.
```

The `lineage` is the field to check: Terraform gives every state an identifier when it is first created
and refuses to replace a state with one of a different lineage, so a matching lineage says this really
is the same configuration's history. The `serial` counts writes; restoring an older serial is what
recovery means, and anything applied after that serial has to be brought back by the next `plan`.
After the upload, `plan` agrees with the world again.

## When the snapshots went with it

A blob deleted with its snapshots leaves nothing in the container:

```
ana@laptop:~/azure/tf/release$ az storage blob delete --container-name tfstate --name shop.tfstate --delete-snapshots include
ana@laptop:~/azure/tf/release$ az storage blob list --container-name tfstate --include s -o tsv | wc -l
0
```

In Azure, this is where **soft delete** earns its place. With it on, the account keeps a deleted blob,
snapshots and all, for the days you set, thirty in lesson 5's module, and `az storage blob undelete`
brings it back. Azurite does not implement soft delete, and says so:

```
ana@laptop:~/azure/tf/release$ az storage blob undelete --container-name tfstate --name shop.tfstate 2>&1 | grep -E "ErrorCode"
ErrorCode:APINotImplemented
```

So the rest of this paragraph is from Microsoft's documentation and was not run. **Blob versioning** is
the stronger of the two protections: with it on, every overwrite keeps the previous content as a
**version**, automatically, with no snapshot to remember. Recovering from this lesson's first accident
is then `az storage blob list --include v` to find the version from before the overwrite, and a copy of
that version over the current blob. Versioning answers the overwrite, soft delete answers the deletion,
and the state account in lesson 5 has both.
