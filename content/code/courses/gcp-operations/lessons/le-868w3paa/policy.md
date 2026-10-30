---
title: A security policy is an ordered list of rules
version: 1
---

**Cloud Armor is a policy attached to a load balancer's backend service, and every request passes through it
before it reaches the shop.** A policy is a list of rules, each with a priority, a match and an action; Cloud
Armor evaluates them from the lowest priority number up and applies the first that matches, and the last rule,
at the highest number possible, is the default. It works only behind Google's external Application Load
Balancer (and a few other load balancers), so a Cloud Run service reached directly at its own `run.app`
address bypasses it entirely. **Nothing in this lesson ran against Cloud Armor**, which has no emulator: what
runs is Terraform's plan of the policy, and the plan shows where that stops being proof.

The shop's policy, in `~/gcp/tf/armor/main.tf`:

```hcl
# tf/armor/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_compute_security_policy" "shop" {
  name        = "shop-edge"
  description = "In front of the shop's load balancer"

  rule {
    priority    = 1000
    action      = "deny(403)"
    preview     = true
    description = "SQL injection, OWASP CRS, sensitivity 1"
    match {
      expr {
        expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': 1})"
      }
    }
  }

  rule {
    priority    = 2000
    action      = "rate_based_ban"
    description = "More than 60 checkouts a minute from one address"
    match {
      expr {
        expression = "request.path.startsWith('/checkout')"
      }
    }
    rate_limit_options {
      conform_action   = "allow"
      exceed_action    = "deny(429)"
      enforce_on_key   = "IP"
      ban_duration_sec = 600
      rate_limit_threshold {
        count        = 60
        interval_sec = 60
      }
    }
  }

  rule {
    priority    = 2147483647
    action      = "allow"
    description = "Everything else"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}
```

```
ana@laptop:~/gcp/tf/armor$ terraform plan -input=false -no-color | grep -E "^  # |priority |action |preview |Plan:"
  # google_compute_security_policy.shop will be created
          + action      = "allow"
          + preview     = (known after apply)
          + priority    = 2147483647
          + action      = "deny(403)"
          + preview     = true
          + priority    = 1000
          + action      = "rate_based_ban"
          + preview     = (known after apply)
          + priority    = 2000
              + conform_action      = "allow"
              + exceed_action       = "deny(429)"
Plan: 1 to add, 0 to change, 0 to destroy.
```

The plan lists the rules in its own order; Cloud Armor will evaluate them by priority: 1000, then 2000, then the
default at 2147483647.

## Rule 1000: a WAF rule, in preview

`evaluatePreconfiguredWaf('sqli-v33-stable', …)` is one of Google's preconfigured rule sets, built from the
OWASP Core Rule Set, matching the shapes of SQL injection attempts in a request. The **sensitivity** chooses how
many of its signatures apply: 1 is the fewest and the least likely to match a legitimate request, 4 the most.

**`preview = true` is the way every WAF rule starts.** In preview, the rule is evaluated and its verdict written
to the load balancer's request log, `jsonPayload.previewSecurityPolicy`, and the request is let through. A week
of preview shows which legitimate requests the rule would have blocked, a search box with a quote in it, a
product named *O'Reilly*, before any customer is refused. Turning a WAF rule on without preview is how a shop
blocks its own checkout on a Friday.

## What the plan did not catch

Change the rule's action from `deny(403)` to `deny(418)` and ask again:

```
ana@laptop:~/gcp/tf/armor$ terraform validate -no-color 2>&1 | head -6
Success! The configuration is valid.
ana@laptop:~/gcp/tf/armor$ terraform plan -input=false -no-color 2>&1 | grep -E "Error|418|Plan:" | head -4
          + action      = "deny(418)"
Plan: 1 to add, 0 to change, 0 to destroy.
```

Both accept it. Cloud Armor's deny action takes only **403, 404 and 502** (and 429 in a rate limit's `exceed_action`,
as rule 2000 uses), and Google refuses `deny(418)` when the policy is created. The provider's schema says `action` is a string, and any string passes; the rule about which
strings is Google's. This is lesson 1's warning in its sharpest form: a clean plan is not an accepted change, and
on a security policy the difference is found at apply, or by somebody reading the documentation.
