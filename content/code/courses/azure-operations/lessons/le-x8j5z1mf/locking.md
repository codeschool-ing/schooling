---
title: The lock is a lease on the blob
version: 1
---

**Two `apply` runs writing one state at once is how a state file ends up describing neither of them.**
Terraform prevents it with a lock, and the `azurerm` backend's lock is a feature of Blob Storage itself:
a **lease**. A lease is an exclusive claim on a blob. While one is held, nobody without its id can take
another, overwrite the blob or delete it. There is no separate lock table to create, as the S3 backend
once needed.

Azurite implements leases, so the lock can be taken by hand, with the same storage operations the backend
issues:

```
ana@laptop:~/azure/tf/release$ az storage blob lease acquire --container-name tfstate --blob-name shop.tfstate --lease-duration -1 -o tsv
4fe580f7-40a3-4ef3-9a24-9acf8ef57588
ana@laptop:~/azure/tf/release$ az storage blob show --container-name tfstate --name shop.tfstate --query properties.lease -o json
{
  "duration": "infinite",
  "state": "leased",
  "status": "locked"
}
ana@laptop:~/azure/tf/release$ az storage blob lease acquire --container-name tfstate --blob-name shop.tfstate --lease-duration -1 -o tsv 2>&1 | grep -E "ErrorCode|already"
ERROR: There is already a lease present.
ErrorCode:LeaseAlreadyPresent
ana@laptop:~/azure/tf/release$ az storage blob upload --container-name tfstate --name shop.tfstate --file terraform.tfstate --overwrite --no-progress -o none 2>&1 | grep -E "ErrorCode|lease"
ERROR: There is currently a lease on the blob and no lease ID was specified in the request.
ErrorCode:LeaseIdMissing
```

The first `acquire` returned the lease's id, and the blob now shows `leased` and `locked`, with no time
limit. The second `acquire` was refused with `LeaseAlreadyPresent`: that is what a colleague's `terraform
plan` meets while your `apply` is running, and Terraform turns it into its message about the state being
locked, with who holds it. The upload without the lease id was refused too, which is the protection that
actually matters: **the blob cannot be overwritten by anyone not holding the lease**.

## When the holder died

A pipeline cancelled halfway through `apply` can leave the lease behind. Terraform's answer is
`terraform force-unlock` with the lock's id, and on this backend that **breaks the lease**:

```
ana@laptop:~/azure/tf/release$ az storage blob lease break --container-name tfstate --blob-name shop.tfstate --lease-break-period 0 -o tsv
0
ana@laptop:~/azure/tf/release$ az storage blob show --container-name tfstate --name shop.tfstate --query properties.lease.state -o tsv
broken
```

Breaking is the right tool and the dangerous one. It frees the blob whether or not somebody is still
writing it. So the shop's rule is the one `iac` gave for every backend: find out whether the holder is
really gone (the pipeline's run, the colleague's terminal) before breaking anything, and never script
`force-unlock` into a pipeline's retry.
