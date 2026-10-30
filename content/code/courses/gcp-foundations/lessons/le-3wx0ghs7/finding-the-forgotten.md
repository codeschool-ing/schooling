---
title: Finding what nobody declared
version: 1
---

**Everything the planner runs is meant to be in Terraform, and the inventory is how it finds what is not.**
Terraform knows exactly what it made: its state lists every resource it manages, and nothing else. The
inventory knows what exists. A resource in the second list and not in the first is one somebody made by hand,
in the console or with gcloud, and it is the resource most likely to be forgotten, mislabelled or wrong.

The lab can do the comparison for real, at the scale of one project, because Terraform can apply to the
emulator: the provider takes an address for Pub/Sub the way gcloud does.

## Two topics from Terraform, one by hand

Make a directory with lesson 2's provider file, and tell the provider where Pub/Sub is. The line goes inside
the `provider "google"` block:

```sh
mkdir -p ~/gcp/inventory && cd ~/gcp/inventory
cp ~/gcp/hierarchy/provider.tf .
sed -i 's|  access_token = "placeholder"|  access_token = "placeholder"\n\n  pubsub_custom_endpoint = "http://localhost:8085/v1/"|' provider.tf
terraform init -input=false
```

Save this as `topics.tf`:

```hcl
resource "google_pubsub_topic" "orders" {
  name   = "orders"
  labels = { team = "planner" }
}

resource "google_pubsub_topic" "invoices" {
  name   = "invoices"
  labels = { team = "planner" }
}
```

**This is the course's first apply**, and it is real: against the emulator, which creates the topics, and
nothing else.

```
ana@laptop:~/gcp/inventory$ terraform apply -input=false -no-color -auto-approve | grep -E "^(Apply|Error)"
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Now somebody makes a topic by hand, the way a quick test always starts:

```
ana@laptop:~/gcp/inventory$ gcloud pubsub topics create scratch-2025
Created topic [projects/planner-dev/topics/scratch-2025].
```

## The comparison

What Terraform manages, and what exists:

```
ana@laptop:~/gcp/inventory$ terraform state list
google_pubsub_topic.invoices
google_pubsub_topic.orders
ana@laptop:~/gcp/inventory$ gcloud pubsub topics list --format="value(name.basename())"
invoices
orders
scratch-2025
```

Two lists, and the difference between them is the answer. `comm -13` prints the lines only in the second of two
sorted lists:

```
ana@laptop:~/gcp/inventory$ comm -13 <(terraform show -json | jq -r '.values.root_module.resources[].values.name' | sort) <(gcloud pubsub topics list --format="value(name.basename())" | sort)
scratch-2025
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l25-difference\" aria-label=\"Two lists side by side. On the left, what Terraform declares, read from its state: orders and invoices. On the right, what exists, read from the inventory or, in the lab, from gcloud: orders, invoices and scratch-2025. An arrow from the two lists to a third box gives the difference, what exists and nobody declared: scratch-2025. Its two possible endings are written under it: imported into Terraform, or deleted. A note says that a declared resource changed by hand appears in both lists, and is the next lesson's drift.\"><defs><marker id=\"l25-difference-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">declared</text><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform state</text><text x=\"120.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"120.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoices</text><rect x=\"260.0\" y=\"20.0\" width=\"200.0\" height=\"130.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">existing</text><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the inventory, or gcloud</text><text x=\"360.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><text x=\"360.0\" y=\"106.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoices</text><text x=\"360.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">scratch-2025</text><path d=\"M462.0 85.0 L506.0 85.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" marker-end=\"url(#l25-difference-af-ah-amber)\"></path><rect x=\"510.0\" y=\"20.0\" width=\"190.0\" height=\"130.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"605.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">exists, undeclared</text><text x=\"605.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">scratch-2025</text><text x=\"605.0\" y=\"116.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">import it, or delete it</text><text x=\"360.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">what exists, minus what is declared, is what somebody forgot</text><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a declared resource changed by hand is in both lists: that is drift, lesson 26</text></svg>", "caption": "The difference between the two lists is the work."}
```

**`scratch-2025` exists and nobody declared it.** At the planner's scale the second list comes from the
inventory rather than from gcloud, one search across every project instead of one list per project, and the
first comes from the state of every Terraform workspace. The nightly job that compares them opens a ticket for
each name in the difference, and the ticket has two possible endings: the resource is written into Terraform,
with `terraform import`, or it is deleted.

**What this does not find** is a resource Terraform manages that someone changed by hand. Its name is in both
lists. That is drift, and the next lesson is about it.
