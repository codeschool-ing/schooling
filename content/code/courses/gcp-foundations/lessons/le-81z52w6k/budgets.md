---
title: A budget, and what its thresholds mean
version: 1
---

**A budget is an amount and a list of thresholds, attached to a billing account, that sends a message when
spending crosses one.** That is all it does, and the sentence people most need to hear about Google Cloud
budgets is the one they least expect: **a budget does not stop spending.** Crossing 100% sends an e-mail
and, if asked, a Pub/Sub message. The machines keep running. Lesson 1's account section put the budget
first for that reason: it is a warning, and a warning is worth most while the amount is small.

## What a budget is made of

| part | what it says | the planner's choice |
|---|---|---|
| **scope** | which costs count: the whole billing account, some projects, some services, some labels | the three planner projects |
| **amount** | a fixed sum, or **last month's spend**, which follows the bill as it grows | 300 USD a month |
| **thresholds** | percentages of the amount, each on **actual** or **forecasted** spend | 50%, 90% and 100% actual; 100% forecasted |
| **who hears** | the billing account's administrators by e-mail, chosen monitoring channels, and a Pub/Sub topic | e-mail, and the topic of the next section |

**Actual and forecasted are the two words to keep apart.** An actual threshold fires when the money has
been spent. A forecasted threshold fires when Google's projection says the month **will** end above it,
which can be on the fifth day of the month, while there is still time to act. The two together tell a team
both "you are on track to overspend" and "you have overspent".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l12-month\" aria-label=\"A month of spending against a budget of 300 dollars, with the day of the month across and the money up. A solid line climbs as money is spent: 84.17 dollars early in the month, 273.40 later, 318.92 near the end. A dashed line is Google's forecast for the end of the month, which crosses 300 dollars on day 5, long before the solid line does. Horizontal marks at 150, 270 and 300 dollars are the actual thresholds at 50, 90 and 100 percent. The forecasted threshold fires on day 5; the 90 percent actual threshold on day 26; the 100 percent on day 29.\"><path d=\"M70.0 250.0 L680.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L70.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"259.3\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"469.7\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><text x=\"680.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><text x=\"364.5\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day of the month</text><path d=\"M70.0 158.3 L680.0 158.3\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"64.0\" y=\"158.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><text x=\"684.0\" y=\"158.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70.0 85.0 L680.0 85.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"64.0\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">270</text><text x=\"684.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">90%</text><path d=\"M70.0 66.7 L680.0 66.7\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"64.0\" y=\"66.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300</text><text x=\"684.0\" y=\"66.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><path d=\"M70.0 250.0 L217.2 198.6 L385.5 152.2 L595.9 82.9 L659.0 55.1\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M70.0 250.0 L154.1 213.3 L680.0 42.2\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"6 4\"></path><circle cx=\"154.1\" cy=\"68.7\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"162.1\" y=\"55.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">forecast passes 300 on day 5</text><circle cx=\"595.9\" cy=\"82.9\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"587.9\" y=\"98.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">273.40</text><circle cx=\"659.0\" cy=\"55.1\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"651.0\" y=\"45.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">318.92</text><circle cx=\"217.2\" cy=\"198.6\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"225.2\" y=\"202.6\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">84.17</text><text x=\"448.6\" y=\"213.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">actual spend</text></svg>", "caption": "The forecasted threshold warns weeks before the actual one does."}
```

A budget is also **not instant**. Costs reach the billing data with a delay of hours, sometimes more, so a
burst of spending in the afternoon may cross a threshold that evening. Lesson 13 comes back to why.

## The budget, written down

Make a directory with lesson 2's provider file:

```sh
mkdir -p ~/gcp/budget && cd ~/gcp/budget
cp ~/gcp/hierarchy/provider.tf .
terraform init -input=false
```

Save this as `budget.tf`:

```hcl
resource "google_billing_budget" "planner" {
  billing_account = "012345-6789AB-CDEF01" # made up for this course
  display_name    = "planner monthly"

  budget_filter {
    projects = ["projects/planner-prod", "projects/planner-staging", "projects/planner-dev"]
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "300"
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    pubsub_topic = "projects/planner-dev/topics/budget-alerts"
  }
}
```

```
ana@laptop:~/gcp/budget$ terraform plan -input=false -no-color -out=plan.bin | grep "^Plan:"
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/budget$ terraform show -json plan.bin | jq -c '.resource_changes[0].change.after.threshold_rules[]'
{"spend_basis":"CURRENT_SPEND","threshold_percent":0.5}
{"spend_basis":"CURRENT_SPEND","threshold_percent":0.9}
{"spend_basis":"CURRENT_SPEND","threshold_percent":1}
{"spend_basis":"FORECASTED_SPEND","threshold_percent":1}
```

The second command prints the thresholds as Google would hold them. `spend_basis` came back
`CURRENT_SPEND` on the three thresholds that did not name one: **actual spend is the default**, and only a
threshold that says `FORECASTED_SPEND` looks ahead. `all_updates_rule` is the line that matters for the
next section: it asks Google to publish every update of this budget to a Pub/Sub topic, several times a
day, threshold or not.

The budget is planned, not created: budgets belong to the Cloud Billing Budget API, which no emulator
answers, and creating one needs `roles/billing.costsManager` on the billing account.
