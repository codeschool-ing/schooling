---
title: The export, and where it lands
version: 1
---

**The console's cost table answers the questions somebody thought to put in it. The billing export answers
the rest**: Cloud Billing writes every line of the bill, as rows, into a BigQuery dataset the customer owns,
and from then on any question about cost is a query. It is the tool lesson 13 ended on, and the one every
company past a few projects ends up using.

There are three exports, each a table of its own in the same dataset:

| export | what each row is | table |
|---|---|---|
| **standard usage cost** | one SKU's usage and cost in one project over a stretch of time, usually an hour | `gcp_billing_export_v1_<account>` |
| **detailed usage cost** | the same, broken down further, to the individual resource where the service reports one | `gcp_billing_export_resource_v1_<account>` |
| **pricing** | one SKU's list price and the price this account pays | `cloud_pricing_export` |

`<account>` is the billing account's id with underscores for hyphens. The planner switches on the first two
and reads the standard one in this lesson: it is smaller, and every question below can be answered from it.

**The documentation for the export was not reachable when this lesson was written**, so the table above, and
the columns in the next section, are from the published schema as it stood before, not read on the day.
Check a column's name against the current page before relying on it in a report somebody signs.

## What is created, and by whom

Two things, by two people:

1. **A BigQuery dataset**, in a project. It is an ordinary resource, created like any other, and the planner
   keeps it in `planner-logs`, the project lesson 2 put in the `shared` folder.
2. **The export itself**, switched on in the console's *Billing export* page by somebody holding
   `roles/billing.costsManager` or `roles/billing.admin` on the billing account, lesson 11. There is no
   gcloud command and no Terraform resource for it: of everything in this course, it is the one step done
   only by a person in the console.

Make a directory with the provider file of lesson 2:

```sh
mkdir -p ~/gcp/export-dataset && cd ~/gcp/export-dataset
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `dataset.tf`, with a hyphen in the name, which is what most people type first:

```hcl
resource "google_bigquery_dataset" "billing" {
  project    = "planner-logs"
  dataset_id = "billing-export"
  location   = "southamerica-east1"
}
```

```
ana@laptop:~/gcp/export-dataset$ terraform plan -input=false -no-color 2>&1 | tail -6
Error: "dataset_id" must contain only letters (a-z, A-Z), numbers (0-9), or underscores (_)

  with google_bigquery_dataset.billing,
  on dataset.tf line 3, in resource "google_bigquery_dataset" "billing":
   3:   dataset_id = "billing-export"
```

**The provider refuses before asking anyone**: a dataset id takes letters, numbers and underscores, and
nothing else. Change the hyphen to an underscore, and give the finance people read access to the dataset and
to nothing around it. Replace `dataset.tf` with this:

```hcl
resource "google_bigquery_dataset" "billing" {
  project    = "planner-logs"
  dataset_id = "billing_export"
  location   = "southamerica-east1"
}

resource "google_bigquery_dataset_iam_member" "finance" {
  project    = "planner-logs"
  dataset_id = google_bigquery_dataset.billing.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:finance@example.com"
}
```

```
ana@laptop:~/gcp/export-dataset$ terraform plan -input=false -no-color | grep -E "^Plan:|# google|location|dataset_id|role"
  # google_bigquery_dataset.billing will be created
      + dataset_id                 = "billing_export"
      + location                   = "southamerica-east1"
  # google_bigquery_dataset_iam_member.finance will be created
      + dataset_id = "billing_export"
      + role       = "roles/bigquery.dataViewer"
Plan: 2 to add, 0 to change, 0 to destroy.
```

Planned, not created: BigQuery has no emulator in this lab. Three choices in that file matter more
than they look:

- **The location is set once.** A dataset cannot be moved to another region afterwards, and the export writes
  where the dataset is. The planner keeps its bill in São Paulo with everything else.
- **The read access is on the dataset**, not on the project. `roles/bigquery.dataViewer` on `planner-logs`
  would also open whatever else is kept there: a grant goes on the smallest thing that does the job.
- **The export starts on the day it is switched on.** Do not count on a history from before it: the cheapest
  moment to switch it on is the day the billing account is opened, and every month before that is a month the
  queries in this lesson cannot answer.
