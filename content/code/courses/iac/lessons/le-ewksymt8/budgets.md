---
title: A budget, written as code
version: 1
---

Everything so far happens before the money is spent: a price in the review, a tag that cannot be left
out, a search for what nobody claimed. **A budget is the check that runs afterwards**, against what
the account actually spent, and lesson 10 of the cloud course built one with the AWS CLI. The same
budget is a resource, and written beside what it watches it gets what everything else in this
configuration gets: a review, a history, and a `destroy` that takes it away with the project.

```hcl
resource "aws_budgets_budget" "shop" {
  name         = "shop-monthly"
  budget_type  = "COST"
  limit_amount = "300"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # only what carries the tag Project = shop
  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Project$shop"]
  }

  notification {
    notification_type          = "ACTUAL"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["ana@example.com"]
  }

  notification {
    notification_type          = "FORECASTED"
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = ["ana@example.com"]
  }
}
```

Three choices in it are worth reading slowly.

**The filter is a tag.** `user:Project$shop` means the user-defined tag `Project` with the value
`shop`, so the budget counts only what the default tags from earlier in this lesson marked. It is
also why those tags had to be impossible to forget: a resource without `Project` is spending this
budget never sees. And, as the cloud course warned, the tag only counts once it has been activated
for cost allocation.

**The limit comes from the estimate.** The priced plan said 175.73 USD a month for what runs by the
hour, and that number is a floor, because traffic and requests come on top. 300 leaves room for the
usage no plan can see, without leaving so much that the alert never fires.

**Two alerts, neither at 100% of actual spending.** One fires when actual spending passes 80% of the
limit; the other when AWS's forecast for the month passes the limit. Billing data arrives hours after
the usage it describes, so an alert at 100% of actual reports money already gone; the forecast is the
earliest warning there is.

## Planned, not applied

**In this lab the budget is planned and never applied.** Moto stores the budget and then answers the
provider's read of the alert's subscribers with an internal error, which the provider retries, so the
apply does not finish. Against a real account it would. The plan is the part this lab can show
truthfully:

```
ana@laptop:~/shop$ terraform plan -no-color | sed -n '/Terraform will perform/,$p'
Terraform will perform the following actions:

  # aws_budgets_budget.shop will be created
  + resource "aws_budgets_budget" "shop" {
      + account_id        = (known after apply)
      + arn               = (known after apply)
      + budget_type       = "COST"
      + id                = (known after apply)
      + limit_amount      = "300"
      + limit_unit        = "USD"
      + name              = "shop-monthly"
      + name_prefix       = (known after apply)
      + tags_all          = {
          + "CostCenter"  = "cc-4410"
          + "Environment" = "prod"
          + "Owner"       = "ana"
          + "Project"     = "shop"
        }
      + time_period_end   = "2087-06-15_00:00"
      + time_period_start = (known after apply)
      + time_unit         = "MONTHLY"

      + cost_filter {
          + name   = "TagKeyValue"
          + values = [
              + "user:Project$shop",
            ]
        }

      + cost_types (known after apply)

      + notification {
          + comparison_operator        = "GREATER_THAN"
          + notification_type          = "ACTUAL"
          + subscriber_email_addresses = [
              + "ana@example.com",
            ]
          + subscriber_sns_topic_arns  = []
          + threshold                  = 80
          + threshold_type             = "PERCENTAGE"
        }
      + notification {
          + comparison_operator        = "GREATER_THAN"
          + notification_type          = "FORECASTED"
          + subscriber_email_addresses = [
              + "ana@example.com",
            ]
          + subscriber_sns_topic_arns  = []
          + threshold                  = 100
          + threshold_type             = "PERCENTAGE"
        }
    }

Plan: 1 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

The default tags reached the budget too, in `tags_all`. `time_period_end` is the provider's default,
a date far enough away to mean "no end", and `time_period_start` is left for AWS to fill in. The rest
is the file, read back as the change it would make.

## What a budget is not

A budget warns; it does not stop anything. When the 80% message arrives the NAT gateway is still
running and the preview environments are still up, and somebody has to read the message and act,
which is the routine the cloud course wrote down. AWS also offers Cost Anomaly Detection, which
learns a normal pattern and flags a sudden change instead of a fixed line, and it too is a resource
in the provider, `aws_ce_anomaly_monitor`. It is named here and not used.

**The order of this lesson is the order of cost.** A price in review stops the expensive change before
it happens, tags make the spending attributable, the orphan search and the expiry date catch what fell
outside every configuration, and the budget is the net under all of it, after the money moved.
