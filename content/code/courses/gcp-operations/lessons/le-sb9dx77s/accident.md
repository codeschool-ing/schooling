---
title: The lost-state accident, and the version that saves it
version: 1
---

**The state disappears more often than people expect**: somebody tidies the bucket, a script deletes the
wrong prefix, a migration copies over the wrong file. The resources keep running; only Terraform's memory
of them is gone. Below the state object is deleted. Against Google the command would be `gcloud storage rm
gs://planner-dev-tfstate/shop/default.tfstate`; here it is the same request made directly to the Cloud
Storage JSON API with `curl`, because `fake-gcs-server` answers `gcloud`'s deletion with an error message
even when it has deleted the object, and that error is the imitation's, not Google's:

```
ana@laptop:~/gcp/tf/shop$ curl -s -X DELETE localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate
null
```

Then the plan:

```
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color 2>&1 | grep -E "^  # |Plan:|Error|already exists"
  # google_pubsub_topic.orders will be created
  # google_storage_bucket_object.prices will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

**Both resources exist, and Terraform proposes to create them.** Applied, the topic would fail with "already
exists" and the price list would be overwritten; on a larger configuration, some resources would be
duplicated under new names and others would fail halfway. The plan is the warning, and it says nothing
alarming: it reads exactly like a plan for a new project.

## The versions

The bucket was created with versioning, so every state Terraform ever wrote is still there as a
noncurrent version. `gcloud storage ls --all-versions` lists them against Google; the imitation answers
that command with the newest version only, so on your computer the same question goes to the JSON API:

```
ana@laptop:~/gcp/tf/shop$ curl -s 'localhost:4443/storage/v1/b/planner-dev-tfstate/o?prefix=shop/default.tfstate&versions=true' | jq -r '.items[] | [.generation, .updated] | @tsv' | sort
1793386572668836	2026-10-30T18:56:12.668831Z
1793386572687355	2026-10-30T18:56:12.6873Z
1793386592437916	2026-10-30T18:56:32.437887Z
1793386596547680	2026-10-30T18:56:36.547653Z
1793386597092596	2026-10-30T18:56:37.092587Z
```

Five versions, and **the newest one is not the one you want.** Look inside each: `serial` is the number
Terraform increments on every write, and the number of resources says what each version knows about:

```
ana@laptop:~/gcp/tf/shop$ for g in $(curl -s 'localhost:4443/storage/v1/b/planner-dev-tfstate/o?prefix=shop/default.tfstate&versions=true' | jq -r '.items[].generation' | sort); do printf '%s ' $g; curl -s "localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate?generation=$g&alt=media" | jq -c '[.serial, (.resources | length)]'; done
1793386572668836 [1,0]
1793386572687355 [4,2]
1793386592437916 [5,3]
1793386596547680 [6,2]
1793386597092596 [1,0]
```

Read it from the top. Serial 1 with nothing is the empty state the migration started from; 4 with two
resources is the state it copied in; 5 with three is the apply with `slow.tf`; 6 with two is the apply that
removed it again. **The last line, serial 1 and nothing, was written by the plan after the accident**:
finding no state, the backend created an empty one. Restoring "the latest version" would restore that, and
leave Terraform exactly as lost as before.

## Putting it back

The version with serial 6 is downloaded and pushed as the current state. `terraform state push` writes it
through the backend, taking the lock like any other write; `-force` is needed because the serial it
replaces, 1, belongs to a different lineage of state:

```
ana@laptop:~/gcp/tf/shop$ curl -s -o restored.tfstate 'localhost:4443/storage/v1/b/planner-dev-tfstate/o/shop%2Fdefault.tfstate?generation=1793386596547680&alt=media'
ana@laptop:~/gcp/tf/shop$ terraform state push -force restored.tfstate
ana@laptop:~/gcp/tf/shop$ terraform plan -input=false -no-color | grep -E "^  # |No changes|Plan:"
No changes. Your infrastructure matches the configuration.
ana@laptop:~/gcp/tf/shop$ rm restored.tfstate
```

**No changes** is the sentence that says the state and the world agree again. Against Google, `gcloud
storage cp 'gs://planner-dev-tfstate/shop/default.tfstate#GENERATION' restored.tfstate` downloads a
version in one step; the rest is the same.
