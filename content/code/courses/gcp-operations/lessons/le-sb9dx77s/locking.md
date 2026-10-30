---
title: The lock, and the precondition behind it
version: 1
---

**Two applies against one state at the same time would each write their own version of it, and the
second would erase the first.** The `gcs` backend prevents that with a lock: before an operation that
may write the state, Terraform creates an object `default.tflock` beside it, and it creates it with a
**precondition** that the object must not exist yet. Cloud Storage refuses the write if it does. One
apply gets the lock; the other is told it is taken.

To see it, the shop needs an apply that takes a while. This resource does nothing except wait fifteen
seconds while it is created:

```hcl
# tf/shop/slow.tf
resource "terraform_data" "slow" {
  provisioner "local-exec" {
    command = "sleep 15"
  }
}
```

Put it in `~/gcp/tf/shop/slow.tf` and start `terraform apply -auto-approve` in a **second terminal**,
with the same variables. While it waits, ask for a plan in the first, with `-lock-timeout=0s` so that it
does not wait for the lock either:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -lock-timeout=0s -input=false -no-color 2>&1 | head -12

Error: Error acquiring the state lock

Error message: writing "gs://planner-dev-tfstate/shop/default.tflock" failed:
googleapi: Error 412: Precondition failed, Precondition Failed
Lock Info:
  ID:        1793386576193180
  Path:      gs://planner-dev-tfstate/shop/default.tflock
  Operation: OperationTypeApply
  Who:       root@vm
  Version:   1.16.4
  Created:   2026-10-30 18:56:16.188547796 +0000 UTC
```

**Error 412, Precondition Failed** is Cloud Storage refusing to create an object that already exists,
and it is the whole mechanism. Terraform then reads the lock and reports who holds it. `Who` is the user
and machine that took the lock, here the computer the course was recorded on. The lock is an ordinary
object, and can be read like one:

```
ana@laptop:~/gcp/tf/shop$ gcloud storage cat gs://planner-dev-tfstate/shop/default.tflock; echo
{"ID":"f8bd2b2d-a594-2165-a8b5-caa6c6aac82e","Operation":"OperationTypeApply","Info":"","Who":"root@vm","Version":"1.16.4","Created":"2026-10-30T18:56:16.188547796Z","Path":"gs://planner-dev-tfstate/shop/default.tflock"}
```

When the apply in the other terminal finishes, it deletes the lock:

```
ana@laptop:~/gcp/tf/shop$ gcloud storage ls gs://planner-dev-tfstate/shop/
gs://planner-dev-tfstate/shop/default.tfstate
```

Delete `slow.tf` and apply again, so that the state goes back to the two real resources.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Two terminals and one lock object in the state bucket. Terminal one creates default.tflock with the precondition that it does not exist, and Cloud Storage answers 200. Terminal two makes the same request a moment later and gets 412 Precondition Failed, so its apply stops before it reads or writes the state.\"><defs><marker id=\"ah2\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">terminal 1</text><rect x=\"20\" y=\"120\" width=\"180\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"110\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">terminal 2</text><rect x=\"470\" y=\"70\" width=\"230\" height=\"60\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"585\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">default.tflock</text><text x=\"585\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the state bucket</text><line x1=\"202\" y1=\"55\" x2=\"468\" y2=\"88\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#ah2)\"></line><text x=\"330\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">create if absent → 200</text><line x1=\"202\" y1=\"145\" x2=\"468\" y2=\"114\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#ah2)\"></line><text x=\"330\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">create if absent → 412</text></svg>", "caption": "Only one create can succeed, so only one apply runs. The bucket enforces it, not Terraform."}
```

## A lock left behind

An apply killed halfway (a closed laptop, a cancelled pipeline job) leaves its lock in place, and every
operation after it is refused with the message above. `terraform force-unlock` with the lock's `ID`
removes it:

```sh
terraform force-unlock 1793386576193180
```

It was not run here, and **it is the command to type slowest of all in this lesson**. Before it, find
out whether the operation in `Who` and `Created` is really dead: a pipeline job still running, or a
colleague's apply in progress, is exactly what the lock is protecting, and removing it lets two writers
in at once. The `ID` in Terraform's message is the one `force-unlock` takes; it is the object's
generation, which is why it differs from the `ID` inside the file.

## Without the backend, without the lock

`-lock=false` turns locking off for one command, and appears in tutorials as the fix for "Error
acquiring the state lock". It is not a fix. A pipeline that runs Terraform with it is a pipeline in which
two merges in the same minute can each write a state, and the second one wins.
