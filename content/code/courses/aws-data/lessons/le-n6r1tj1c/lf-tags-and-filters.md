---
title: LF-tags, and filters on rows and cells
version: 1
---

**A grant per table per team is the IAM problem again, one level up.** Forty tables and six teams
is up to 240 grants, each written by hand, and the forty-first table is readable by nobody until
somebody remembers to grant it. LF-tags turn that around: the tables and columns carry labels, a
team is granted a label, and a new table is covered the moment it is labelled.

## Labels on the catalogue

**An LF-tag is a key with a fixed list of values**, defined once by an administrator. Quitanda
needs one, `sensitivity`, with three values. The `orders` table is `internal`, and its `phone`
column overrides that with `pii`:

```
ana@laptop:~/aws$ aws lakeformation create-lf-tag --tag-key sensitivity --tag-values public internal pii
ana@laptop:~/aws$ aws lakeformation add-lf-tags-to-resource --resource '{"Table":{"DatabaseName":"curated","Name":"orders"}}' --lf-tags TagKey=sensitivity,TagValues=internal
{
    "Failures": []
}
ana@laptop:~/aws$ aws lakeformation add-lf-tags-to-resource --resource '{"TableWithColumns":{"DatabaseName":"curated","Name":"orders","ColumnNames":["phone"]}}' --lf-tags TagKey=sensitivity,TagValues=pii
{
    "Failures": []
}
ana@laptop:~/aws$ aws lakeformation get-resource-lf-tags --resource '{"Table":{"DatabaseName":"curated","Name":"orders"}}'
{
    "LFTagsOnTable": [
        {
            "CatalogId": "123456789012",
            "TagKey": "sensitivity",
            "TagValues": [
                "internal"
            ]
        }
    ]
}
```

**A tag flows down**: a table inherits its database's tags and a column its table's, unless it is
given its own value for the same key, as `phone` was. So the table is `internal` except for one
column, without anybody listing the other four.

**moto's answer leaves the column out.** AWS documents `get-resource-lf-tags` on a table as
returning `LFTagsOnColumns` beside `LFTagsOnTable`, and the second call above would appear there as
`phone`, `pii`. moto accepted the tag on the column, reported no failure, and does not return it.
The tag on the column is in the request you would send; whether AWS kept it is not something this
lab can show.

## Granting a tag

**A tag-based grant names an expression instead of a resource**: every table whose tags match it.
The support team handles deliveries and needs the phone numbers, so it is granted `SELECT` on
anything tagged `internal` or `pii`:

```
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/support --permissions SELECT --resource '{"LFTagPolicy":{"ResourceType":"TABLE","Expression":[{"TagKey":"sensitivity","TagValues":["internal","pii"]}]}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,Permissions[0],keys(Resource)[0]]' --output text
arn:aws:iam::123456789012:role/analyst	SELECT	TableWithColumns
arn:aws:iam::123456789012:role/analyst	DESCRIBE	Database
arn:aws:iam::123456789012:role/support	SELECT	LFTagPolicy
```

**Three grants now: the support role's on a tag policy, and the analyst's two on named
resources.** On AWS, the support role can read every column of `orders`, phone included, because
both values are in its expression. An analyst granted `internal` alone would read the table without
`phone`, since that column's tag is `pii`. And a table that the pipeline creates next week, tagged
`internal`, is readable by support on the day it appears, with no new grant written. That is the
point of the tags, and it is also their risk: whoever may tag a table decides who reads it, so the
permission to assign tags is granted as carefully as the data itself.

## Filters on rows and cells

**A data filter narrows a grant to some rows, some columns, or both**, which together are cells.
It is written against one table: a row filter is a SQL condition, and the columns are a list to
include or to exclude. Granting `SELECT` on the filter, instead of on the table, gives the principal
only what the filter lets through. Quitanda's support team in one district should see the orders,
with the phone number, of that district's customers and nobody else's. The filter,
`support-filter.json`:

```json
{
  "TableCatalogId": "123456789012",
  "DatabaseName": "curated",
  "TableName": "orders",
  "Name": "support-own-district",
  "RowFilter": {"FilterExpression": "customer_id IN ('c-03', 'c-17')"},
  "ColumnNames": ["order_id", "customer_id", "phone"]
}
```

```
ana@laptop:~/aws$ aws lakeformation create-data-cells-filter --table-data file://support-filter.json

aws: [ERROR]: An error occurred (404) when calling the CreateDataCellsFilter operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
ana@laptop:~/aws$ aws lakeformation list-data-cells-filter
{
    "DataCellsFilters": []
}
```

**moto does not implement data filters**: creating one answered 404, and the list is empty. On AWS,
this filter would let support read three columns of the rows for `c-03` and `c-17` and nothing
about `c-22`, and Athena would apply it to every query that support runs on `orders`. A real
filter would test a district column rather than list customers by hand; the CSV of this lesson has
no district, and the list keeps the example to the columns it does have. Row and cell filtering
are AWS's documented behaviour and were not run.
