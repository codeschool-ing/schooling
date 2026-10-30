---
title: Three guardrails for planner, written and planned
version: 1
---

The planner team wants three rules: resources only in South America and the United States, production
only in São Paulo, and no service account keys anywhere. The third is the one most likely to break
something that already works, so it goes in as a dry run first. Make a directory with lesson 2's
provider file:

```sh
mkdir -p ~/gcp/guardrails && cd ~/gcp/guardrails
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `policies.tf`:

```hcl
locals {
  org        = "organizations/123456789012" # example.com, made up for this course
  production = "folders/345678901234"       # lesson 2's production folder, by a made-up number
}

# Everything the company runs: South America and the United States.
resource "google_org_policy_policy" "locations" {
  name   = "${local.org}/policies/gcp.resourceLocations"
  parent = local.org
  spec {
    rules {
      values {
        allowed_values = ["in:southamerica-locations", "in:us-locations"]
      }
    }
  }
}

# Production replaces the organisation's list rather than merging with it.
resource "google_org_policy_policy" "production_locations" {
  name   = "${local.production}/policies/gcp.resourceLocations"
  parent = local.production
  spec {
    inherit_from_parent = false
    rules {
      values {
        allowed_values = ["in:southamerica-east1-locations"]
      }
    }
  }
}

# No keys, tried as a dry run before it is enforced.
resource "google_org_policy_policy" "no_keys" {
  name   = "${local.org}/policies/iam.managed.disableServiceAccountKeyCreation"
  parent = local.org
  dry_run_spec {
    rules {
      enforce = "TRUE"
    }
  }
}
```

The policy's `name` repeats its parent and the constraint, `organizations/123456789012/policies/...`,
because that is the policy's own address in the API: one policy per constraint per node. Writing it
out by hand is what the provider asks for, and what makes the file say exactly where each rule lives.

The full plan prints every field of every policy, most of them `(known after apply)`. Two commands make
it say only what matters here: `-out` saves the plan to a file, and `terraform show -json` prints that
file as JSON, which `jq` cuts down to the three fields that decide each policy's behaviour:

```
ana@laptop:~/gcp/guardrails$ terraform plan -input=false -out=plan.bin | tail -1
    terraform apply "plan.bin"
ana@laptop:~/gcp/guardrails$ terraform show -json plan.bin | jq -r '.resource_changes[].change.after | "\(.name)\n  inherit_from_parent: \(.spec[0].inherit_from_parent)\n  allowed_values: \(.spec[0].rules[0].values[0].allowed_values)\n  dry run enforce: \(.dry_run_spec[0].rules[0].enforce)"'
organizations/123456789012/policies/gcp.resourceLocations
  inherit_from_parent: null
  allowed_values: ["in:southamerica-locations","in:us-locations"]
  dry run enforce: null
organizations/123456789012/policies/iam.managed.disableServiceAccountKeyCreation
  inherit_from_parent: null
  allowed_values: null
  dry run enforce: TRUE
folders/345678901234/policies/gcp.resourceLocations
  inherit_from_parent: false
  allowed_values: ["in:southamerica-east1-locations"]
  dry run enforce: null
```

**Three policies, and the plan shows the one difference that decides the estate's behaviour**:
`inherit_from_parent: false` on production. False is the default, so the line changes nothing as
written; it is there so that the decision is on the page, where somebody who later sets it to `true`
in the belief that inheriting is safer has to delete it first. Set to `true`, the folder's list would
merge with the organisation's and allow the United States. Reading a plan for that one line is worth
more than reading the rest of it.

## What happens next, outside the lab

Applied against a real organisation, by somebody holding `roles/orgpolicy.policyAdmin`, the three
policies would take effect within minutes, and only for what is created or changed after that. **The
dry run is the part that keeps working**: every key creation it would have refused appears in the audit
logs, attributed to whoever tried. After a week with no violation that matters, the team adds a `spec`
block beside `dry_run_spec`, with the same rule, and plans again; the diff is four lines, and it is
the moment the guardrail becomes a wall.

That last step is the one the lab cannot show, and neither can the violations: both need Google. The
plan is as far as a laptop can see, and it is far enough to catch the mistake that matters most here,
an allow list that merges when it was meant to replace.
