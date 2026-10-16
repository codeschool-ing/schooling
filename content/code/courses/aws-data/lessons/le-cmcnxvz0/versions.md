---
title: Changing a table, and the versions it leaves
version: 1
---

**A table changes by being replaced whole, and the catalog keeps the one it replaced.**
`update-table` takes a complete table description, the same JSON `create-table` took, and the
previous description becomes a numbered version. Nothing is edited in place, the same rule lesson 1
found for an object in S3, and for the same reason: a reader halfway through a query should keep
the description it started with.

In November Quitanda's shop starts taking coupons, and the export gains a column. The table has to
say so. Then, in the same week, somebody decides totals should be in reais rather than cents, and
changes the type. Both are one `jq` and one `update-table`:

```
ana@laptop:~/aws$ jq '.StorageDescriptor.Columns += [{"Name": "coupon", "Type": "string"}]' orders-table.json > orders-table-2.json
ana@laptop:~/aws$ aws glue update-table --database-name quitanda --table-input file://orders-table-2.json
ana@laptop:~/aws$ jq '(.StorageDescriptor.Columns[] | select(.Name == "total_cents") | .Type) = "double"' orders-table-2.json > orders-table-3.json
ana@laptop:~/aws$ aws glue update-table --database-name quitanda --table-input file://orders-table-3.json
ana@laptop:~/aws$ aws glue get-table-versions --database-name quitanda --table-name orders --query 'TableVersions[].[VersionId,length(Table.StorageDescriptor.Columns),Table.StorageDescriptor.Columns[4].Type]' --output text
1	7	bigint
2	8	bigint
3	8	double
```

**Three versions: seven columns, then eight, then eight with `total_cents` as `double`.** moto
keeps them faithfully, and so does the catalog on AWS. A version is a whole table description, so
going back is `update-table` with an old one, which is the closest thing to an undo the catalog has.
It is also an object, counted against the free million like a partition, and **a crawler left on
`UPDATE_IN_DATABASE` adds one every time a file disagrees with the table**. Nobody runs out of a
million versions by hand; a crawler pointed at a noisy prefix every hour can make a table's history
the largest thing in the catalog.

## The partitions kept the old columns

```
ana@laptop:~/aws$ aws glue get-partition --database-name quitanda --table-name orders --partition-values 2026-10-15 --query 'Partition.StorageDescriptor.Columns[-1].Name' --output text
neighbourhood
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name orders --query 'Table.StorageDescriptor.Columns[-1].Name' --output text
coupon
```

**The table ends in `coupon` and the partition for 15 October ends in `neighbourhood`.** Each
partition took a copy of the storage descriptor when `partitions.py` made it, columns included, and
an `update-table` changes the table and none of its 31 partitions. That is deliberate, since an old day's files really do have seven columns. It is also where queries break: an engine that compares a partition's columns with the table's can refuse the partition, and Athena's error for a
column whose type differs between the two is `HIVE_PARTITION_SCHEMA_MISMATCH`. The type change in
version 3 is exactly that case, a table that says `double` over 31 partitions that say `bigint`.

Two ways to keep them in step: `batch-update-partition` from the program that changed the table, or
a crawler with the setting that makes partitions inherit the table's schema. Neither was needed for
the added column, which a partition without it can simply not have; the type change is the one that
needs a decision.

## Where moto and AWS differ

```
ana@laptop:~/aws$ aws glue update-table --database-name quitanda --table-input file://orders-table-2.json --skip-archive
ana@laptop:~/aws$ aws glue get-table-versions --database-name quitanda --table-name orders --query 'TableVersions[].VersionId' --output text
1	2	3	4
```

**`--skip-archive` made a fourth version anyway.** On AWS the flag means exactly the opposite:
update the table and do not archive the previous description, which is how a job that rewrites a
table every night avoids leaving a version each time. moto ignores it. A test that counts versions
against moto would pass here and count differently on a real account, which is the kind of
difference lesson 1 asked you to expect.
