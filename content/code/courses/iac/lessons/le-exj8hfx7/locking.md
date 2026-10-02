---
title: Locking, so one run writes at a time
version: 1
---

Two runs that read the same state and both write it back produce a classic lost update. Each read
serial 5, each made its own change in AWS, each writes serial 6, and whichever writes second erases
the other's record. The resources the first run created are then real, billed and unknown to the
state, which is the accident of the second network arriving by a quieter road. **A lock makes the second run
wait or fail before it reads anything.**

With `use_lockfile = true`, the S3 backend locks by creating a second object beside the state, the
state's key with `.tflock` on the end, and it creates it with a **conditional write**: S3 accepts
the object only if no object with that key exists yet. Two runs racing for the lock cannot both
win, because S3 itself decides which write came first. The run that holds the lock deletes the
object when it finishes.

Ana makes a change worth applying, an `Environment` tag on the VPC:

```
ana@laptop:~/shop$ sed -i 's/{ Name = "shop" }/{ Name = "shop", Environment = "dev" }/' main.tf
```

In one terminal she starts `terraform apply`, reads the plan, and leaves the question *Do you want
to perform these actions?* on the screen while she checks something. **The apply holds the lock
from the moment it starts until it exits**, question included. In a second terminal, the bucket:

```
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 00:51:41       5835 shop/terraform.tfstate
2026-10-02 00:52:18        223 shop/terraform.tfstate.tflock
```

And a plan from that second terminal, which is what a colleague or a CI job would have done:

```
ana@laptop:~/shop$ terraform plan
╷
│ Error: Error acquiring the state lock
│ 
│ Error message: operation error S3: PutObject, https response error
│ StatusCode: 412, RequestID:
│ JXOdvefHqyTq5sSvp19pAUr8bWkyHAaboBlPa0I2mNWZyZeHWx4K, HostID:
│ 9Gjjt1m+cjU4OPvX9O9/8RuvnG41MRb/18Oux2o5H5MY7ISNTlXN+Dz9IG62/ILVxhAGI0qyPfg=,
│ api error PreconditionFailed: At least one of the pre-conditions you
│ specified did not hold
│ Lock Info:
│   ID:        5e1a4241-7664-589b-97c1-6af57ee23698
│   Path:      shop-tfstate-123456789012/shop/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       ana@vm
│   Version:   1.16.4
│   Created:   2026-10-02 03:52:18.315841962 +0000 UTC
│   Info:      
│ 
│ 
│ Terraform acquires a state lock to protect the state from being written
│ by multiple users at the same time. Please resolve the issue above and try
│ again. For most commands, you can disable locking with the "-lock=false"
│ flag, but this is not recommended.
╵
```

The `412` and `PreconditionFailed` are S3 refusing the conditional write: the lock object exists.
Below them is the lock's own content, and it answers the questions you have at that moment. `Who`
is the user and machine holding it (the lab's machine calls itself `vm`), `Operation` says it is an
apply, `Created` says since when, and `ID` is what you need if the holder never comes back. **Plans
lock too**, though they write nothing to AWS: a plan reads the state, and reading half of a state
that is being written gives a plan of a world that never existed.

Failing is not the only option. `-lock-timeout` makes a run retry for as long as you allow:

```
ana@laptop:~/shop$ terraform plan -lock-timeout=60s
Acquiring state lock. This may take a few moments...
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 00:52:26       5907 shop/terraform.tfstate
```

`Acquiring state lock` is the plan waiting while, in the first terminal, Ana answered `yes` and
the apply finished. Then the plan took the lock and planned against the state the apply had just written: the tag is already there,
so there is nothing to do, and the lock object is gone from the listing. In a pipeline, a lock
timeout of a few minutes turns two jobs that collided into two jobs that ran in turn.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A timeline with two runs and the bucket between them. Run one, an apply, writes the lock object and waits at its question. Run two, a plan, tries to write the same lock object and S3 refuses with 412. Run two retries under -lock-timeout. Run one is answered, writes the new state and deletes the lock. Run two then takes the lock and plans against the new state.\"><defs><marker id=\"lk-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"lk-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"80.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">terminal 1</text><text x=\"80.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bucket</text><text x=\"80.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">terminal 2</text><path d=\"M150 40 L700 40\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M150 220 L700 220\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"200\" y=\"112\" width=\"440\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">terraform.tfstate.tflock</text><path d=\"M220 44 L220 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-phosphor)\"></path><text x=\"225.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">apply: lock</text><path d=\"M300 216 L300 150\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#lk-ah-amber)\"></path><text x=\"305.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">plan: 412</text><text x=\"410.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">-lock-timeout: retry</text><path d=\"M520 44 L520 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-phosphor)\"></path><text x=\"525.0\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">yes: state, unlock</text><path d=\"M600 216 L600 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lk-ah-phosphor)\"></path><text x=\"605.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">plan: lock</text></svg>", "caption": "One lock object, created only if it does not exist: the second run fails or waits, and never writes alongside the first."}
```

**Before S3 could do this by itself**, the S3 backend kept its locks in a DynamoDB table, named with
`dynamodb_table`. You will meet that in most configurations written before it changed. The table is
one more thing to create and pay for, and current Terraform marks the argument deprecated in favour
of `use_lockfile`.

## When the lock outlives its run

A run that ends normally removes its lock, and so does one stopped with Ctrl-C. A run that is
*killed*, by a laptop losing power, a CI runner being reclaimed or `kill -9`, removes nothing. Ana
makes a second change, starts the apply in the first terminal, and the process dies at the question:

```
ana@laptop:~/shop$ sed -i 's/{ Name = "shop-a" }/{ Name = "shop-a", Environment = "dev" }/' main.tf
```

```
ana@laptop:~/shop$ terraform plan 2>&1 | grep -A 7 "Lock Info"
│ Lock Info:
│   ID:        59944514-fb19-86ba-d242-b8c55f2168ca
│   Path:      shop-tfstate-123456789012/shop/terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       ana@vm
│   Version:   1.16.4
│   Created:   2026-10-02 03:52:35.945232236 +0000 UTC
│   Info:      
```

```
ana@laptop:~/shop$ aws s3 cp s3://shop-tfstate-123456789012/shop/terraform.tfstate.tflock - | jq .
{
  "ID": "59944514-fb19-86ba-d242-b8c55f2168ca",
  "Operation": "OperationTypeApply",
  "Info": "",
  "Who": "ana@vm",
  "Version": "1.16.4",
  "Created": "2026-10-02T03:52:35.945232236Z",
  "Path": "shop-tfstate-123456789012/shop/terraform.tfstate"
}
```

Nobody holds that lock any more, and every run will fail on it until it is removed:

```
ana@laptop:~/shop$ terraform force-unlock -force 59944514-fb19-86ba-d242-b8c55f2168ca
Terraform state has been successfully unlocked!

The state has been unlocked, and Terraform commands should now be able to
obtain a new lock on the remote state.
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

**`force-unlock` is safe only when you know the holder is dead.** Here the process was gone and
`Who` named Ana's own machine, so she could be sure. Used on a run that is merely slow, it lets a
second writer in alongside the first, which is exactly the lost update the lock existed to stop.
The `-force` flag skips the confirmation question; without it, Terraform asks first. The same goes
for `-lock=false`, which the error message itself calls not recommended.
