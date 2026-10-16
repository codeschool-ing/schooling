---
title: The Cost and Usage Report, delivered as files
version: 1
---

**The Cost and Usage Report is the bill as a table: one row per line of the bill, hundreds of
columns, written as files into an S3 bucket you own.** Cost Explorer (lesson 13) answers the
questions its screens were built for. The report answers any question, because it is the data those
screens are drawn from. It is the only place where every line of lesson 14 sits beside the account
that used it, the resource that caused it and the tags it carried. Nothing reads it for you. You
query it, which is why this lesson ends with a query rather than a chart.

## CUR 2.0, made through Data Exports

The current version is **CUR 2.0**, and you create it as a **data export** in Billing and Cost
Management. An export is three decisions written down. The first is which columns, from which table,
at what granularity. The second is where the files go, and the third is how they are refreshed.
Written as the file the AWS command line takes:

```sh
cat > export.json <<'EOF'
{
  "Name": "shop-cur2",
  "DataQuery": {
    "QueryStatement": "SELECT bill_payer_account_id, line_item_usage_account_id, line_item_line_item_type, line_item_product_code, line_item_usage_type, line_item_resource_id, line_item_usage_amount, line_item_unblended_cost, pricing_term, savings_plan_savings_plan_effective_cost, reservation_effective_cost, resource_tags FROM COST_AND_USAGE_REPORT",
    "TableConfigurations": {
      "COST_AND_USAGE_REPORT": {
        "TIME_GRANULARITY": "DAILY",
        "INCLUDE_RESOURCES": "TRUE",
        "INCLUDE_SPLIT_COST_ALLOCATION_DATA": "FALSE",
        "INCLUDE_MANUAL_DISCOUNT_COMPATIBILITY": "FALSE"
      }
    }
  },
  "DestinationConfigurations": {
    "S3Destination": {
      "S3Bucket": "shop-logs",
      "S3Prefix": "billing",
      "S3Region": "sa-east-1",
      "S3OutputConfigurations": {
        "OutputType": "CUSTOM",
        "Format": "PARQUET",
        "Compression": "PARQUET",
        "Overwrite": "OVERWRITE_REPORT"
      }
    }
  },
  "RefreshCadence": {"Frequency": "SYNCHRONOUS"}
}
EOF
```

The **query** is SQL over one table, `COST_AND_USAGE_REPORT`, and choosing columns is the point. A
full report carries hundreds, most of them empty for most lines. `INCLUDE_RESOURCES` adds
`line_item_resource_id`, without which no line names the instance or the bucket that caused it. The
**destination** is a bucket, here the shop's `shop-logs` under the prefix `billing`. The files are
in **Parquet**, a columnar format that query engines read a column at a time, or in compressed CSV.
`OVERWRITE_REPORT` replaces the month's files at each refresh instead of keeping every version. An
export belongs to the **management account** when it should cover the organisation, for the same
reason the cost allocation tags of lesson 13 do. Restart moto in the first terminal (Ctrl+C, then
`moto_server -p 4567`) so this lesson starts from an empty AWS, and send it:

```
ana@laptop:~/aws$ aws bcm-data-exports create-export --export file://export.json 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the CreateExport operation (reached max retries: 2): <!doctype html>
ana@laptop:~/aws$ aws cur describe-report-definitions 2>&1 | grep ERROR
aws: [ERROR]: An error occurred (500) when calling the DescribeReportDefinitions operation (reached max retries: 2): <!doctype html>
```

**moto has neither Data Exports nor the older CUR API**; both answer with a server error. What the
lab does show is narrower and still useful. The command line checks the field names of `export.json`
against AWS's API before it sends anything, and refuses a misspelt one with `Unknown parameter`. So
the shape above got as far as moto. The values, such as `PARQUET` and `OVERWRITE_REPORT`, are from
AWS's documentation, and nothing in the lab judged them. Against AWS, the bucket also needs a policy
that lets the billing service write to it. AWS's documentation says AWS refreshes the files at least
once a day and rewrites them until the month's bill is final.

## The columns that answer "who spent what"

The column names are long because each one says which group of the report it belongs to. These
are the ones the next two sections use, and the ones nearly every question needs:

| column | what it holds |
|---|---|
| `bill_payer_account_id` | the account that pays: the management account, on a consolidated bill (lesson 3) |
| `line_item_usage_account_id` | the account that used it, which is the one a team owns |
| `line_item_line_item_type` | `Usage`, `SavingsPlanCoveredUsage`, `Tax` and the rest of lesson 14's types |
| `line_item_product_code` | the service, such as `AmazonEC2` or `AmazonVPC` |
| `line_item_usage_type` | the exact thing, such as `SAE1-NatGateway-Hours` |
| `line_item_resource_id` | the instance, bucket or gateway, when resources are included |
| `line_item_unblended_cost` | the cost as charged, lesson 13's unblended |
| `pricing_term` | `OnDemand` or `Reserved` for usage lines |
| `savings_plan_savings_plan_effective_cost`, `reservation_effective_cost` | what a covered line cost at the commitment's rate, its amortised cost |
| `resource_tags` | the activated cost allocation tags, as a map: `user_team`, `user_env` |

**`resource_tags` is one column in CUR 2.0, a map from key to value.** The older report gave every
activated tag a column of its own, such as `resource_tags_user_team`, so adding a tag changed the
table's shape. A map does not. The prefix `user_` marks a tag somebody wrote, as against one AWS
generated. Only tags activated in Billing appear in it at all, which is lesson 13's second gate.

**Split cost allocation data** is the one table option this export leaves off. When containers on
ECS or EKS share an EC2 instance, the instance is one line and its cost belongs to several teams.
Turned on, it adds `split_line_item_*` columns that divide each shared instance's cost among the
containers on it, by the processor and memory they reserved or used. A team running containers can
then be charged its share of a machine it never owned outright.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-pipeline\" aria-label=\"Two paths to the same question. Above, the AWS way, not run in this course: usage in every account becomes the bill; a data export in the management account writes CUR 2.0 files, in Parquet, to the bucket shop-logs under billing; Amazon Athena runs SQL over those files; Amazon QuickSight draws dashboards from the answers. Below, this lab: make_cur.py writes cur.csv, made-up lines in the same columns; ask.py loads it into sqlite3 and runs the same SQL; the answer is a table in the terminal.\"><defs><marker id=\"l15-pipeline-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l15-pipeline-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">the AWS way: not run in this course</text><rect x=\"20.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"80.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">usage in every</text><text x=\"80.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">account</text><rect x=\"162.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"222.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a data export</text><text x=\"222.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">CUR 2.0</text><path d=\"M142.0 72.0 L159.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><rect x=\"304.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"364.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-logs/billing</text><text x=\"364.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Parquet</text><path d=\"M284.0 72.0 L301.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><rect x=\"446.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"506.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Amazon Athena</text><text x=\"506.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQL over S3</text><path d=\"M426.0 72.0 L443.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><rect x=\"588.0\" y=\"42.0\" width=\"120.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"648.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Amazon QuickSight</text><text x=\"648.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">dashboards</text><path d=\"M568.0 72.0 L585.0 72.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-paper-dim)\"></path><text x=\"20.0\" y=\"166.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">this lab: on your own machine</text><rect x=\"20.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">make_cur.py</text><text x=\"95.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">made-up lines</text><rect x=\"197.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"272.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cur.csv</text><text x=\"272.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same columns</text><path d=\"M172.0 212.0 L194.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-phosphor)\"></path><rect x=\"374.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"449.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ask.py</text><text x=\"449.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">sqlite3</text><path d=\"M349.0 212.0 L371.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-phosphor)\"></path><rect x=\"551.0\" y=\"182.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"626.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a table</text><text x=\"626.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the terminal</text><path d=\"M526.0 212.0 L548.0 212.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l15-pipeline-af-ah-phosphor)\"></path><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">the same SQL asks both</text><path d=\"M506.0 104.0 L449.0 180.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"360.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the lab replaces the data, not the method</text></svg>", "caption": "Above, what a real organisation runs. Below, the same questions against a file you made."}
```
