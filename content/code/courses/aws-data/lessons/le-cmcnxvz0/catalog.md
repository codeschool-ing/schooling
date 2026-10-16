---
title: The catalog, and what a table is made of
version: 1
---

**The Glue Data Catalog is the lake's table of contents, and it holds no data at all.** Lesson 15's
`orders.sql` described a table in a dozen lines; those lines are what the catalog keeps, and
everything that reads the lake by name reads them first. Athena does, Redshift Spectrum does, an EMR
cluster does when it is told to use the catalog as its metastore, a Glue job does, and Lake
Formation, in lesson 18, writes its permissions against the same names. There is one catalog per
account and region, so a table defined once is the same table to all of them.

The wrong picture here is a database engine with a disk of its own. The catalog is closer to a
directory service: databases that group tables, tables that describe where files are and how to
read them, and partitions that say which prefix holds which slice. **Delete every object in S3 and
the catalog is unchanged; delete the catalog and every object is still there**, unreadable by name
until somebody describes it again.

## The parts of a table

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of
lesson 1's "Your lab, in brief" typed in this one. A table lives in a database, so the database comes
first:

```
ana@laptop:~/aws$ aws glue create-database --database-input '{"Name": "quitanda", "Description": "Quitanda lake, curated layer"}'
ana@laptop:~/aws$ aws glue get-databases
{
    "DatabaseList": [
        {
            "Name": "quitanda",
            "Description": "Quitanda lake, curated layer",
            "CreateTime": "2026-10-16T13:22:50.863000-03:00",
            "CatalogId": "123456789012"
        }
    ]
}
```

`CatalogId` is the account, moto's `123456789012`. Then the table, written as the JSON the API
takes, which is the same description `orders.sql` gave Athena with nothing left implicit:

`orders-table.json`:

```json
{
  "Name": "orders",
  "TableType": "EXTERNAL_TABLE",
  "Parameters": {"classification": "parquet"},
  "PartitionKeys": [{"Name": "dt", "Type": "string"}],
  "StorageDescriptor": {
    "Columns": [
      {"Name": "order_id", "Type": "string"},
      {"Name": "customer_id", "Type": "string"},
      {"Name": "hour", "Type": "tinyint"},
      {"Name": "items", "Type": "smallint"},
      {"Name": "total_cents", "Type": "bigint"},
      {"Name": "payment", "Type": "string"},
      {"Name": "neighbourhood", "Type": "string"}
    ],
    "Location": "s3://quitanda-curated-prod/orders/",
    "InputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat",
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
}
```

Four parts, and each one answers a question a reader asks before it reads a byte:

| part | the question it answers |
|---|---|
| `Columns` | what is in each file, in what order, with which type |
| `Location` | which prefix in S3 holds the files |
| `InputFormat`, `OutputFormat`, `SerdeInfo` | how to turn the bytes into rows and back: here, Parquet |
| `PartitionKeys` | which columns come from the key rather than from the file |

**`StorageDescriptor` is the part a reader cannot do without**, and the name is Hive's: the catalog
is compatible with the Hive metastore, which is why Spark and Trino read it with no adapter. The
three class names are how a Hive-compatible engine is told the format. `classification` is Glue's own
label for the same fact, which crawlers write and Glue's console shows.

```
ana@laptop:~/aws$ aws glue create-table --database-name quitanda --table-input file://orders-table.json
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name orders --query 'Table.[Name,TableType,VersionId,StorageDescriptor.Location,length(StorageDescriptor.Columns),PartitionKeys[0].Name]' --output text
orders	EXTERNAL_TABLE	1	s3://quitanda-curated-prod/orders/	7	dt
ana@laptop:~/aws$ aws glue get-table --database-name quitanda --name nope

aws: [ERROR]: An error occurred (EntityNotFoundException) when calling the GetTable operation: Table nope not found.
```

**Version 1, seven columns, one partition key, and a clear refusal for a name that is not there.**
This part of AWS is a data structure, and moto keeps it faithfully: the table above is what Athena
would find if the same JSON were sent to a real account. What moto still does not do is read the
files, so nothing checked that the seven columns are the seven in the Parquet. Neither does the
real catalog: **a table is a claim about the files, and nothing compares the claim with them** until
a query reads both and one of them is wrong.

