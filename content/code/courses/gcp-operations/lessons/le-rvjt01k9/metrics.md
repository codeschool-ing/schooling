---
title: Counters and distributions, declared
version: 1
---

**A counter says how many lines matched; a distribution says how a number inside them was spread.** The
second kind reads a value out of each matching entry, `total_cents` here, and keeps a histogram of the values
per minute, so that percentiles can be read from it the way lesson 8 read latency. It is how "what is the
typical order worth, and is it changing" becomes a chart without a line of new code.

Before declaring the buckets of the histogram, look at the values the log holds:

```
ana@laptop:~/gcp$ jq -r 'select(.message == "order placed") | .total_cents' checkout.log | sort -n | uniq -c
    272 1890
    296 2490
    271 4380
    255 6870
```

Four prices, in roughly equal numbers. Buckets with bounds at 1000, 2000, 3000, 5000 and 10000 cents put
each price in a bucket of its own (1890 in the second, 2490 in the third, 4380 in the fourth, 6870 in the
fifth), so the histogram keeps the shape of the data. **Buckets are fixed when the metric is created and
cannot be changed later without a new metric**, so choose them from the data, not from a guess.

Both metrics, in `~/gcp/tf/logmetrics/main.tf`:

```hcl
# tf/logmetrics/main.tf
terraform {
  required_providers {
    google = { source = "hashicorp/google", version = "8.9.0" }
  }
}

provider "google" {
  project = "planner-dev"
}

resource "google_logging_metric" "payment_retries" {
  name   = "shop/payment_retries"
  filter = "resource.labels.service_name=\"shop-api\" AND jsonPayload.message=\"payment retried\""
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    labels {
      key        = "provider"
      value_type = "STRING"
    }
  }
  label_extractors = {
    provider = "EXTRACT(jsonPayload.provider)"
  }
}

resource "google_logging_metric" "order_value" {
  name            = "shop/order_value_cents"
  filter          = "resource.labels.service_name=\"shop-api\" AND jsonPayload.message=\"order placed\""
  value_extractor = "EXTRACT(jsonPayload.total_cents)"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "1"
  }
  bucket_options {
    explicit_buckets {
      bounds = [1000, 2000, 3000, 5000, 10000]
    }
  }
}
```

Three things to read in it:

- **`label_extractors`** takes `provider` out of each entry's payload, which is the split the last section
  made with `jq`. The label is declared in the descriptor too; a label extracted and not declared is an error
  at creation.
- **`value_extractor`** is what makes `order_value` a distribution: the number it extracts is the value
  recorded, and `bucket_options` says how to histogram it.
- **`metric_kind = "DELTA"`**: a log-based metric counts what matched in each interval. It is never
  cumulative, because nothing keeps a running total.

The plan for this file, together with the next section's alert, is at the end of that section.

## What they cost

A log-based metric is charged like any metric a program writes, by the volume of points it produces, at the
price lesson 8 quoted. A counter with one label of two values is two series and costs very little; the same
counter with an order id as a label is one series per order. **The entries it counts must also be kept**: a
metric counts entries as they are written to a bucket, and an entry excluded by lesson 9's exclusion is
never counted. Excluding the health checks and counting them in the same project is a contradiction the plan
does not catch.
