---
title: A perimeter around the data
version: 1
---

**IAM decides who may call an API; VPC Service Controls decides from where, and to where the data may go.** The
failure it exists for is a valid credential in the wrong hands: a service account key copied out of a
laptop, a token stolen from a CI log. With that credential, IAM says yes, and the thief can copy the shop's order
exports to a bucket in their own project. A **service perimeter** draws a line around projects and the services
inside them: a request to a restricted service from outside the line is refused, and so is a request from inside
that tries to write to a project outside it, **whatever the caller's IAM permissions**. Nothing in this lesson ran:
VPC Service Controls needs an organisation, and has no emulator. What runs is a Terraform plan, with placeholder
numbers for the organisation and the projects.

The shop's perimeter, in `~/gcp/tf/vpcsc/main.tf`:

```hcl
# tf/vpcsc/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {}

resource "google_access_context_manager_access_policy" "org" {
  parent = "organizations/123456789012"
  title  = "planner organisation"
}

resource "google_access_context_manager_access_level" "office" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.org.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.org.name}/accessLevels/office"
  title  = "office"
  basic {
    conditions {
      ip_subnetworks = ["203.0.113.0/24"]
    }
  }
}

resource "google_access_context_manager_service_perimeter" "shop_data" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.org.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.org.name}/servicePerimeters/shop_data"
  title  = "shop data"

  use_explicit_dry_run_spec = true
  spec {
    resources           = ["projects/111111111111"]
    restricted_services = ["storage.googleapis.com", "bigquery.googleapis.com"]
    access_levels       = [google_access_context_manager_access_level.office.name]

    egress_policies {
      egress_from {
        identities = ["serviceAccount:shop-exports@planner-dev.iam.gserviceaccount.com"]
      }
      egress_to {
        resources = ["projects/222222222222"]
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "google.storage.objects.create"
          }
        }
      }
    }
  }
}
```

```
ana@laptop:~/gcp/tf/vpcsc$ terraform plan -input=false -no-color | grep -E "^  # |restricted_services|use_explicit_dry_run_spec|Plan:" 
  # google_access_context_manager_access_level.office will be created
  # google_access_context_manager_access_policy.org will be created
  # google_access_context_manager_service_perimeter.shop_data will be created
      + use_explicit_dry_run_spec = true
          + restricted_services = [
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three objects, all at the level of the organisation, not the project:

- **An access policy**, the organisation's container for perimeters and access levels. An organisation has one,
  and creating it needs an organisation-level role; a project owner cannot.
- **An access level**, `office`: requests coming from the office's address range, `203.0.113.0/24`. An access level
  is a condition on the request's origin (addresses, device state, identity), named so that perimeters can use it.
- **The perimeter**, `shop_data`: the project holding the order exports, with Cloud Storage and BigQuery restricted.
  Inside it, those two APIs answer only requests that originate inside the perimeter or satisfy the access level.

## What it stops, concretely

| the request | IAM | the perimeter |
|---|---|---|
| the API's service account, from Cloud Run inside the project, reads an export | allowed | allowed: it is inside |
| a person at the office, with the role, downloads an export | allowed | allowed: the access level |
| the same person's stolen token, used from another country | allowed | **refused**: outside, no access level |
| a script inside the project copies exports to a bucket in another project | allowed | **refused**: data leaving the perimeter |
| the export job writes to the partner's bucket in project 222222222222 | allowed | allowed: the egress rule |

The third and fourth rows are the reason for the perimeter. IAM cannot tell a person from their stolen token, and
cannot tell a legitimate copy from an exfiltration; the perimeter decides by where, which neither the thief nor the
script can change.

## The egress rule

The perimeter would also stop the export job's legitimate work, writing a daily file to a partner's bucket. The
egress policy allows exactly that: this one service account, to that one project, for `storage.objects.create`
and nothing else. Read it as a hole cut deliberately to the size of one job. **Each egress rule is a path out for
the data**, so each names an identity, a destination and an operation, never `*`.
