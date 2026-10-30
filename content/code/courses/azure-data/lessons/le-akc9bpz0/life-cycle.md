---
title: Life-cycle rules, which move and delete by age
version: 1
---

**A life-cycle management policy is a set of rules the storage account runs on its own, once a day.**
They move blobs to cooler tiers and delete them by age. It is lesson 4's tier changes and lesson 4's
arithmetic handed to the account, so that nobody has to remember to archive last year's exports. A rule
names which blobs it applies to and what happens to them after how many days, and it works on the
current blob, on its previous versions and on its snapshots separately.

Life-cycle policies belong to the account, and only the control plane sets them; Azurite has no
policy at all. This section is taught from Microsoft's documentation and checked with Terraform.

## Quitanda's rule for the exports

The exports are read for about a month, rarely for a year, and must exist for seven years. The
exports account is ZRS, which lesson 4 found has no archive tier, so the coldest step here is cold.
Save this beside `account.tf`:

`lifecycle.tf`:

```hcl
resource "azurerm_storage_management_policy" "data" {
  storage_account_id = azurerm_storage_account.data.id

  rule {
    name    = "exports-age-out"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["orders-raw/exports/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        tier_to_cold_after_days_since_modification_greater_than = 365
        delete_after_days_since_modification_greater_than       = 2555
      }
      version {
        delete_after_days_since_creation = 90
      }
    }
  }
}
```

```
ana@laptop:~/azure/tf/protect$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/protect$ sed -i 's/"blockBlob"/"BlockBlob"/' lifecycle.tf && terraform validate -no-color

Error: expected rule.0.filters.0.blob_types.0 to be one of ["blockBlob" "appendBlob"], got BlockBlob

  with azurerm_storage_management_policy.data,
  on lifecycle.tf line 9, in resource "azurerm_storage_management_policy" "data":
   9:       blob_types   = ["BlockBlob"]
```

Read the rule from the filter down. **`prefix_match` starts with the container's name**,
`orders-raw/`, and then the start of the blob names, so this rule touches the exports and nothing else
in the account. `blob_types` limits it to block blobs, and the refusal shows the provider holding the
exact spelling, `blockBlob`: the same word with a capital letter is not a type. Then three ages for
the current blob, counted from its last modification: cool after 30 days, cold after a year, deleted
after 2,555 days, seven years of 365 days. And the `version` block deletes previous versions 90 days
after they were made, the line that keeps versioning from growing for ever.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The exports-age-out rule on a timeline of days on a square-root scale. The current blob is hot for its first 30 days, cool from day 30 to day 365, cold from day 365 to day 2,555, and deleted on day 2,555. Previous versions are kept 90 days from their creation and then deleted.\" data-fig=\"l05-lifeline\"><defs><marker id=\"l05-lifeline-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,4 L0,8 z\" fill=\"var(--wire)\"/></marker></defs><text x=\"30\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">the current blob, by days since it was last modified</text><rect x=\"31.0\" y=\"40\" width=\"69.51697073924622\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"65.75848536962312\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Hot</text><rect x=\"102.51697073924622\" y=\"40\" width=\"175.9395814468437\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"190.48676146266808\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Cool</text><rect x=\"280.45655218608994\" y=\"40\" width=\"408.54344781391006\" height=\"34\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"/><text x=\"484.728276093045\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Cold</text><line x1=\"690.0\" y1=\"36\" x2=\"690.0\" y2=\"82\" stroke=\"var(--amber)\" stroke-width=\"2\"/><text x=\"686.0\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">deleted</text><path d=\"M30 110 L690 110\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><path d=\"M30.0 110 L30.0 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"30.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M101.5 110 L101.5 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"101.51697073924622\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><path d=\"M153.9 110 L153.9 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"153.8710269237912\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">90</text><path d=\"M279.5 110 L279.5 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"279.45655218608994\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">365</text><path d=\"M442.9 110 L442.9 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"442.9034230793039\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1,000</text><path d=\"M690.0 110 L690.0 116\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"/><text x=\"690.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2,555</text><text x=\"690\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">days, on a square-root scale</text><text x=\"30\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\" font-weight=\"600\">previous versions</text><rect x=\"31.0\" y=\"188\" width=\"121.87102692379119\" height=\"26\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"/><text x=\"91.9355134618956\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">kept 90 days</text><line x1=\"153.8710269237912\" y1=\"184\" x2=\"153.8710269237912\" y2=\"218\" stroke=\"var(--amber)\" stroke-width=\"2\"/><text x=\"161.8710269237912\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\" font-weight=\"600\">deleted</text></svg>", "caption": "What lifecycle.tf declares. Every move respects the tier's minimum days: 335 in cool, about six years in cold."}
```

## What a rule does not know

**A rule is not instant.** Microsoft's documentation says the policy runs once a day, and that a new
or changed policy can take up to 24 hours to go into effect, and longer for its actions to finish on
a large account. A rule written today archives nothing tonight.

**A rule knows nothing about minimum days.** Lesson 4's early deletion charge applies to whatever a
rule moves or deletes, exactly as if a person had done it. A rule that moved blobs to cold at 30 days
and deleted them at 60 would pay cold's 90 for every one. The rule above respects each minimum: cool
for 335 days, cold for six years.

**Counting from the last modification is the safe clock for files written once.** The other clocks
the provider listed, creation and last access, have their uses: last access moves a blob down only if
nobody reads it, but it needs access tracking switched on for the account, and it is billed. For the
exports, written once and never modified, all three clocks would agree, and the simplest is the one
that cannot surprise anybody.
