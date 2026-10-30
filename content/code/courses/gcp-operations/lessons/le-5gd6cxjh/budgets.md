---
title: A budget is an alert, not a cap
version: 1
---

**A Cloud Billing budget is an amount for a period and a set of rules for telling somebody when the spend
approaches it. It stops nothing.** It belongs to a billing account rather than a project, and its filter says what it
counts: some projects, the projects under a folder, some services, or the resources carrying one label. The amount is a
number you write or last period's actual spend, and the period is a calendar month, quarter or year, each starting at
midnight Pacific Time, UTC-8, whatever time zone the shop keeps. Creating a budget needs a billing account, so this
section plans one with Terraform and the fake token, as lesson 5 did, and creates nothing.

## Two kinds of threshold

A **threshold rule** is a share of the amount, written as a fraction (`0.8` is 80%), with a basis:

- **`CURRENT_SPEND`**, the default: the money already spent this period has passed the share.
- **`FORECASTED_SPEND`**: Google's forecast of the whole period has passed it. Only a calendar period can carry one,
  and it is the rule that warns on the 9th rather than on the 30th.

A threshold rule sends an e-mail to the billing account's administrators unless that is switched off. **The e-mail is
the part this lesson replaces.** It lands in the inbox of whoever administers billing, who is rarely the person who can
stop what is spending, and it arrives with nothing attached that a program can act on.

## A topic instead of an inbox

The **`all_updates_rule`** sends every update about the budget to a Pub/Sub topic, with `schema_version` `"1.0"`, the
only one accepted. The topic receives updates **at regular intervals, whatever the thresholds say**: it is a stream of
the budget's state, not a stream of alerts. The threshold rules still matter, because without one the messages carry
nothing about thresholds.

The shop's two budgets, in `~/gcp/tf/budget/main.tf`. The month was 623.07 USD in lesson 23, so the shop's budget is
700; the sandbox folder spent 32.94, so it gets 40:

```hcl
# tf/budget/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

variable "billing_account" {
  description = "The billing account id, XXXXXX-XXXXXX-XXXXXX"
  type        = string
}

variable "sandbox_folder" {
  description = "The sandbox folder, folders/NUMBER"
  type        = string
}

resource "google_pubsub_topic" "budget" {
  name = "budget-alerts"
}

resource "google_billing_budget" "shop" {
  billing_account = var.billing_account
  display_name    = "shop-monthly"

  budget_filter {
    projects        = ["projects/planner-prod", "projects/planner-dev"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "700"
    }
  }

  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    pubsub_topic   = google_pubsub_topic.budget.id
    schema_version = "1.0"
  }
}

resource "google_billing_budget" "sandbox" {
  billing_account = var.billing_account
  display_name    = "sandbox-monthly"

  budget_filter {
    resource_ancestors = [var.sandbox_folder]
    calendar_period    = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "40"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic   = google_pubsub_topic.budget.id
    schema_version = "1.0"
  }
}
```

The billing account and the folder are variables, because both are numbers Google assigns. The plan, with made-up
values in their shapes:

```
ana@laptop:~/gcp/tf/budget$ terraform plan -input=false -no-color -var billing_account=000000-000000-000000 -var sandbox_folder=folders/100000000001 | grep -E "^  # |display_name|units|threshold_percent|spend_basis|Plan:"
  # google_billing_budget.sandbox will be created
      + display_name    = "sandbox-monthly"
              + units         = "40"
          + spend_basis       = "CURRENT_SPEND"
          + threshold_percent = 1
  # google_billing_budget.shop will be created
      + display_name    = "shop-monthly"
              + units         = "700"
          + spend_basis       = "CURRENT_SPEND"
          + threshold_percent = 0.8
          + spend_basis       = "FORECASTED_SPEND"
          + threshold_percent = 1
  # google_pubsub_topic.budget will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

Three resources: the topic and two budgets. The budget on the sandbox folder is the one that makes a person's
experiment visible, the fourth line of lesson 23's remainder. On Google Cloud, applying this also needs permission to
set the topic's IAM policy, because Billing has to be allowed to publish to it.

**Spend reaches a budget hours after the usage that caused it**, so a budget is never a hard limit, even with an action
behind it: by the time the message says 100%, more has been spent. That is the reason for the forecast rule, and the
reason the next section's function acts on shares below 100% as well.
