---
title: Splitting traffic between revisions
version: 1
---

A service's address does not point at a revision. **It points at a traffic split: a list of
revisions with a percentage each, adding up to one hundred.** By default the list has one entry,
`LATEST`, at 100%, which is why a plain deployment sends everybody to the new code at once. Change
the list and the same address serves two revisions at the ratio you chose.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Requests to the service address reach a traffic split, which sends 90 per cent to revision orders-v1 and 10 per cent to revision orders-v2. A second address, the canary tag, reaches orders-v2 directly, whatever the split says. Both revisions are immutable snapshots of an image and its settings.\"><defs><marker id=\"l9-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"190\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the service address</text><text x=\"115.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">orders-….run.app</text><rect x=\"20\" y=\"190\" width=\"190\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"115.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the canary tag</text><text x=\"115.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">canary---orders-…</text><rect x=\"270\" y=\"40\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"345.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">traffic split</text><path d=\"M210 64 L270 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ah)\"></path><rect x=\"500\" y=\"30\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">orders-v1</text><text x=\"600.0\" y=\"69.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">image and settings, frozen</text><rect x=\"500\" y=\"150\" width=\"200\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"600.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">orders-v2</text><text x=\"600.0\" y=\"189.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">image and settings, frozen</text><path d=\"M420 56 L500 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ah)\"></path><text x=\"460\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">90%</text><path d=\"M420 76 L500 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l9-ah)\"></path><text x=\"452\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">10%</text><path d=\"M210 214 L500 194\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l9-ah)\"></path><text x=\"355\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">always this revision</text><text x=\"600\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing is ever edited</text></svg>", "caption": "The address points at the split, and the split points at revisions. A tag is a second address that skips the split."}
```

## The split, written down

Save this as `traffic/main.tf` in `~/gcp`. It describes the service after `orders-v2` was
deployed, with nine requests in ten still going to `orders-v1`:

```hcl
# traffic/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_cloud_run_v2_service" "orders" {
  name     = "orders"
  location = "southamerica-east1"

  template {
    revision = "orders-v2"

    containers {
      image = "southamerica-east1-docker.pkg.dev/planner-dev/shop/orders:2"
    }
  }

  traffic {
    type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
    revision = "orders-v1"
    percent  = 90
  }

  traffic {
    type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
    revision = "orders-v2"
    percent  = 10
    tag      = "canary"
  }
}
```

`template.revision` is the name of the revision this `template` creates; the two `traffic` blocks
are the split. Then, in `~/gcp/traffic`, `terraform init` as in lesson 1, and the plan's traffic
blocks:

```
ana@laptop:~/gcp/traffic$ terraform plan -no-color | sed -n '/+ traffic {/,/^        }/p'
      + traffic {
          + percent  = 90
          + revision = "orders-v1"
          + type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
        }
      + traffic {
          + percent  = 10
          + revision = "orders-v2"
          + tag      = "canary"
          + type     = "TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"
        }
```

**Each request is assigned independently, at random, in the proportion written.** Cloud Run
does not route a user to one revision and keep them there: a person who loads three pages may see
both versions. A change that must be consistent for one user across requests, a new checkout flow
for instance, needs more than a percentage, usually a flag in the application that decides per
user.

## What the plan does not catch

Raise the canary to 20% and leave the other at 90%:

```
ana@laptop:~/gcp/traffic$ sed -i 's/percent  = 10/percent  = 20/' main.tf
ana@laptop:~/gcp/traffic$ terraform plan -no-color | grep -E 'percent|^Plan'
          + percent  = 90
          + percent  = 20
Plan: 1 to add, 0 to change, 0 to destroy.
```

**110 per cent planned without a word.** The rule that the percentages add up to one hundred is
enforced by Cloud Run's API when the change is applied, not by the provider when it is planned,
so this file would fail at `terraform apply` with an error from Google. It is lesson 1's warning in
another form: a clean plan says the file is coherent, and nothing more.

## Other ways to name a target

One other kind of entry is worth knowing, from the provider's and Google's documentation.
`TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST` sends its share to whatever revision is newest, so the
next deployment moves that share automatically; it is the default, and it is what makes a plain
deployment go to 100% at once. A revision named explicitly stays where it is until somebody moves
it. **For a rollout you control, name revisions; for a service where every deployment should go
live at once, use `LATEST`.** Mixing the two is legal and confusing: `LATEST` at 10% beside a named
revision means the next deployment takes that 10% without anybody deciding it.
