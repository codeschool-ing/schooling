---
title: The accident, step by step
version: 1
---

**The state file is Terraform's memory, and Azure knows nothing about it.** Every resource Terraform
manages is mapped, in that file, from an address in the configuration, `azurerm_resource_group.shop`,
to an id in Azure. Lose the file and the resources keep running; what is lost is the mapping.

The lab rebuilds lesson 6's situation: a real state, written by `terraform apply`, uploaded to the
`tfstate` container in Azurite. This configuration keeps a copy of its state locally as well, so its
`plan` shows what Terraform concludes from each version of the file. At the start, it agrees with the
world:

```
ana@laptop:~/azure/tf/release$ terraform plan -no-color | grep -m1 "No changes"
No changes. Your infrastructure matches the configuration.
```

Before anything goes wrong, a habit: **a snapshot**, a read-only copy of the blob at a point in time,
taken here by hand and in practice by the pipeline before every `apply`:

```
ana@laptop:~/azure/tf/release$ az storage blob snapshot --container-name tfstate --name shop.tfstate --query snapshot -o tsv
2026-10-30T18:22:54.9190000Z
```

Then the accident. The common real ones are a `terraform init -migrate-state` pointed at the wrong key,
a colleague's empty working directory pushing its state over yours, or a script that "cleans up" a
container. Here it is the second, done by hand: an empty state uploaded over the real one.

```
ana@laptop:~/azure/tf/release$ echo '{"version": 4, "serial": 1, "resources": []}' > empty.tfstate
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file empty.tfstate --overwrite --no-progress -o none
ana@laptop:~/azure/tf/release$ az storage blob list --container-name tfstate --include s --query "[].{snapshot:snapshot, size:properties.contentLength}" -o table
Size    Snapshot
------  ----------------------------
45
861     2026-10-30T18:22:54.9190000Z
```

The blob is now 45 bytes. The snapshot still holds the 861 bytes of the real state. And this is what
Terraform makes of the empty file:

```
ana@laptop:~/azure/tf/release$ cp terraform.tfstate saved.tfstate && cp empty.tfstate terraform.tfstate
ana@laptop:~/azure/tf/release$ terraform plan -no-color | grep -E "will be created|Plan:"
  # terraform_data.release will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

**Terraform proposes to create something that exists.** For `terraform_data` that is harmless; for the
shop it is not. Applied against Azure, a plan like this fails on the first resource whose name is
taken, `rg-shop already exists`, which is the lucky case. The unlucky case is a resource whose name is
generated, which Terraform creates a second time beside the first, and from then on both are billed and
only one is managed.
