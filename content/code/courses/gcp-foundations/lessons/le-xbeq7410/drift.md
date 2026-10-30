---
title: Drift
version: 1
---

**Drift is the difference between what Terraform's files declare and what exists**, made by somebody using
another door. It is not an error anywhere: the API accepted every change, Terraform's state recorded what it last
knew, and the two now disagree in silence until somebody asks. Terraform asks every time it plans, because a plan
**refreshes** first: it reads every resource it manages, the `GET`s of the previous section, and compares.

## Somebody deletes a resource

In `~/gcp/doors`, where Terraform made `shipments`, somebody tidies up with gcloud:

```
ana@laptop:~/gcp/doors$ gcloud pubsub topics delete shipments
Deleted topic [projects/planner-dev/topics/shipments].
```

Ask Terraform what it sees, without proposing anything. `-refresh-only` reports the differences between its
state and the world, and changes no resource:

```
ana@laptop:~/gcp/doors$ terraform plan -input=false -no-color -refresh-only 2>&1 | grep -E "has been deleted|^Plan|No changes"
  # google_pubsub_topic.shipments has been deleted
```

**Terraform noticed**, and says so in the past tense: the resource *has been deleted*, by somebody else. Now the
ordinary plan, which compares the files with that refreshed world:

```
ana@laptop:~/gcp/doors$ terraform plan -input=false -no-color | grep -E "^Plan|will be created"
  # google_pubsub_topic.shipments will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

**The files still declare `shipments`, so the plan puts it back.** That is drift being corrected, and it is the
right outcome only if the files are right. If the deletion was deliberate, the fix is to delete the resource from
the files, and the plan then proposes nothing. Either way **the files decide**, and the person who used another
door has to change them too or see the change undone at the next apply.

## Somebody changes the file

The other direction is the ordinary one. Put `shipments` back first, so that the files and the world agree
again:

```sh
terraform apply -input=false -auto-approve
```

Then change the label in `topics.tf` from `planner` to `platform`, and plan:

```
ana@laptop:~/gcp/doors$ sed -i 's/team = "planner"/team = "platform"/' topics.tf
ana@laptop:~/gcp/doors$ terraform plan -input=false -no-color | grep -E "^Plan|update in-place|\"team\""
  ~ update in-place
          ~ "team"                       = "planner" -> "platform"
          ~ "team" = "planner" -> "platform"
          ~ "team"                       = "planner" -> "platform"
Plan: 0 to add, 1 to change, 0 to destroy.
```

`~ update in-place`, with the label going from one value to the other. It shows three times because the
provider keeps three views of a resource's labels: `labels`, as the file writes them; `terraform_labels`, those
plus any the provider adds by default; and `effective_labels`, every label on the resource, including any set
through another door.
It is only planned here: lesson 3 showed that the emulator refuses to update a topic's labels, which is a gap in
the emulator, not in Pub/Sub.

## The planner's rules about drift

- **Every Terraform workspace is planned every night**, by a pipeline that changes nothing and alerts on any plan
  that is not empty. A non-empty plan the morning after an incident is the list of what was changed by hand during
  it, which is the list somebody has to write back into the files.
- **A change in production through another door is allowed in an emergency** and is followed, the same day, by
  the change in the files. The break-glass accounts of lesson 10 exist for exactly that, and their use is audited.
- **`-refresh-only` is read before an apply that was not expected to do anything**: it says what changed
  underneath, rather than what the apply would do about it.
