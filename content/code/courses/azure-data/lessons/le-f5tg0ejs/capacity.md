---
title: Capacity: the one thing you size
version: 1
---

**Everything Fabric does is paid for out of one capacity, measured in capacity units, CUs.** A
Spark notebook, a warehouse query, a pipeline's copy, a report refreshing: each consumes CU-seconds
from the capacity of the workspace it runs in. There is no separate price for Spark and another for
SQL. This section is taught from Microsoft's documentation, apart from the declaration Terraform
checks below, and the throttling it describes was not observed.

## The sizes

**A capacity's size is its SKU, and the number in the name is the number of CUs**: F2 has 2, F64 has
64. Microsoft documents the list, and the Azure provider for Terraform carries the same list, which
makes it checkable on a laptop. Make a directory, `~/azure/tf/fabric`, and save this in it:

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "analytics" {
  name     = "rg-quitanda-analytics-prd"
  location = "brazilsouth"
}

resource "azurerm_fabric_capacity" "analytics" {
  name                   = "fcquitandaprd"
  resource_group_name    = azurerm_resource_group.analytics.name
  location               = azurerm_resource_group.analytics.location
  administration_members = ["dados@quitanda.example"]

  sku {
    name = "F2"
    tier = "Fabric"
  }
}
```

```
ana@laptop:~/azure/tf/fabric$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/fabric$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/fabric$ sed -i 's/"F2"/"F3"/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: expected sku.0.name to be one of ["F2" "F4" "F8" "F16" "F32" "F64" "F128" "F256" "F512" "F1024" "F2048"], got F3
ana@laptop:~/azure/tf/fabric$ sed -i 's/"F3"/"F2"/; s/fcquitandaprd/fc-quitanda-prd/' main.tf && terraform validate -no-color 2>&1 | grep Error
Error: invalid value for name (`name` must be between 3 and 63 characters. It can contain only lowercase letters and numbers. It must start with a lowercase letter.)
```

**Eleven sizes, each double the last.** There is no F3 and no F48, so growing is a step to twice the
size and twice the price. The capacity's name follows the storage account's rules of lesson 1, with
more room: lowercase letters and digits, no hyphens. `administration_members` names who may manage
the capacity inside Fabric, and those people need not have any role on the Azure subscription.
Nothing was created: `validate` read the file and the provider's schema, and asked Azure nothing.

## Paying for it

**A capacity is billed for every hour it exists, busy or idle**, at a price per CU-hour, unless it
is paused. A pay-as-you-go capacity can be paused and resumed from the Azure portal or the API.
While it is paused its compute is not billed and the workspaces on it cannot run anything; the data
in OneLake is still there, and still billed as storage, which is a meter of its own. A reservation
buys a size for a year at a discount, and a reserved capacity is paid for whether it runs or not.

The arithmetic, at **an illustrative 0.20 USD per CU-hour**, which is a number for doing the sum
with and not Azure's price, over a 730-hour month:

| capacity | running all month | running 12 hours a day |
|---|---:|---:|
| F2 | 2 × 0.20 × 730 = 292 USD | 146 USD |
| F8 | 8 × 0.20 × 730 = 1,168 USD | 584 USD |
| F64 | 64 × 0.20 × 730 = 9,344 USD | 4,672 USD |

The price per CU is the same at every size, so **the decision is the size and the hours, never the
rate**. Lesson 1's price sheet reads the real per-CU-hour price once it is given the Fabric
service's name as the Retail Prices API spells it, which this course could not confirm, because the
API was out of its reach. One more step is documented for Power BI: below F64, everybody who opens
a report needs a paid Power BI licence of their own, and from F64 up people with the free licence
can view reports on the capacity. For a company whose reports are read by two hundred people, that
line moves the bill more than the CUs do.

## Smoothing

**A capacity does not refuse work the moment it is busy.** Fabric measures consumption in 30-second
timepoints and spreads each operation's CU-seconds forward in time, which Microsoft calls smoothing:

- **interactive operations**, the ones a person is waiting on, such as the queries a Power BI
  report sends while somebody looks at it, are spread over at least five minutes;
- **background operations**, the ones nobody is watching, such as a notebook, a pipeline or a
  scheduled refresh, are spread over twenty-four hours.

Smoothing is what lets a small capacity run a job far larger than itself. A Spark notebook that
loads Quitanda's night and uses 16 CUs for 15 minutes consumes 16 × 900 = 14,400 CU-seconds. Spread
over the 86,400 seconds of a day, that is 0.17 CU on average, a twelfth of an F2. Which kind each
operation is belongs to Fabric and not to you: Microsoft's documentation keeps a table of them, and
it is worth reading before deciding that a capacity is too small.

## Throttling

**Throttling is measured by how much of the capacity's future has already been spent.** When
smoothed consumption runs above the capacity's size, the excess carries forward and is paid back out
of the idle time that follows. Fabric expresses that debt in minutes of future capacity, and
Microsoft documents four stages:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A horizontal axis of future capacity already consumed, marked at 10 minutes, 60 minutes and 24 hours, divided into four stages. Up to 10 minutes, overage protection: everything runs as asked. From 10 to 60 minutes, interactive delay: a new interactive request waits 20 seconds before it starts. From 60 minutes to 24 hours, interactive rejection: new interactive requests are refused and background work still runs. Beyond 24 hours, background rejection: every new request is refused, background included.\" data-fig=\"l17-throttle\"><defs><marker id=\"l17-ah\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"/></marker></defs><rect x=\"30\" y=\"60\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"112.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">overage protection</text><text x=\"112.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">everything runs</text><text x=\"112.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">as asked</text><rect x=\"200\" y=\"60\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"282.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">interactive delay</text><text x=\"282.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a new interactive</text><text x=\"282.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">request waits 20 s</text><text x=\"282.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">before it starts</text><rect x=\"370\" y=\"60\" width=\"164\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"452.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">interactive rejection</text><text x=\"452.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">new interactive</text><text x=\"452.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requests refused;</text><text x=\"452.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">background still runs</text><rect x=\"540\" y=\"60\" width=\"154\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"/><text x=\"617.0\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">background rejection</text><text x=\"617.0\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">every new request</text><text x=\"617.0\" y=\"123\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">refused, background</text><text x=\"617.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">included</text><line x1=\"30\" y1=\"200\" x2=\"700\" y2=\"200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" marker-end=\"url(#l17-ah)\"/><line x1=\"30\" y1=\"194\" x2=\"30\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"30\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><line x1=\"197\" y1=\"194\" x2=\"197\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"197\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 min</text><line x1=\"367\" y1=\"194\" x2=\"367\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"367\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 min</text><line x1=\"537\" y1=\"194\" x2=\"537\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"/><text x=\"537\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24 h</text><text x=\"365\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">minutes of future capacity already consumed by smoothed work</text><text x=\"365\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">what a new request meets, by how far ahead the capacity has spent</text></svg>", "caption": "Fabric's throttling stages, as Microsoft documents them. The measure is not how busy the capacity is now, but how much of its future has already been spent."}
```

**The first stage is the one designed for**: a burst that is paid back within ten minutes is
invisible. The second is the first one people notice, a report that takes twenty seconds longer to
start. In the third, reports fail while the nightly jobs keep running, and the people who notice are
the analysts at nine in the morning. In the fourth, the nightly jobs fail too. **Pausing a capacity
does not cancel the debt**: Microsoft's documentation says the carried-forward consumption is billed
at the moment of pausing, so a capacity paused to escape throttling pays for what it had already
spent.

What a team can do about throttling is the same as what it does about any shared machine: make the
work smaller, which for a lake is mostly the file layout of lesson 18, give production and
development separate capacities, and size up when the third stage is reached every week. Moving a
job to another hour helps less than it seems, because background work is spread over a whole day
whenever it starts.

The Capacity Metrics app, which Microsoft publishes for Fabric, is where the timepoints and the
stages are seen; it is part of the product and was not seen here.
