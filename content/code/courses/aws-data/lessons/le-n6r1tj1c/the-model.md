---
title: Administrators, registered locations and grants
version: 1
---

**Lake Formation is a permission system that sits between the engines and the files.** The data
stays in S3 and the tables stay in the Glue Data Catalog of lesson 16. What Lake Formation adds is a
list of grants, in SQL's vocabulary, on the catalogue's databases, tables and columns, and the
power to hand an engine the credentials to read the files only after checking that list. The wrong
picture is a new store, or a copy of the data. Nothing moves, and nothing is copied.

## The table it governs

A grant names a table in the catalogue, so the catalogue needs one. This lesson builds its own,
over the file of the previous section. Save the table's definition, `orders-table.json`:

```json
{
  "Name": "orders",
  "TableType": "EXTERNAL_TABLE",
  "Parameters": {"classification": "csv", "skip.header.line.count": "1"},
  "PartitionKeys": [{"Name": "dt", "Type": "string"}],
  "StorageDescriptor": {
    "Location": "s3://quitanda-curated-prod/curated/orders/",
    "Columns": [
      {"Name": "order_id", "Type": "string"},
      {"Name": "customer_id", "Type": "string"},
      {"Name": "total_cents", "Type": "bigint"},
      {"Name": "phone", "Type": "string"}
    ],
    "InputFormat": "org.apache.hadoop.mapred.TextInputFormat",
    "OutputFormat": "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat",
    "SerdeInfo": {
      "SerializationLibrary": "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe",
      "Parameters": {"field.delim": ","}
    }
  }
}
```

```
ana@laptop:~/aws$ aws glue create-database --database-input Name=curated
ana@laptop:~/aws$ aws glue create-table --database-name curated --table-input file://orders-table.json
ana@laptop:~/aws$ aws glue get-table --database-name curated --name orders --query "Table.StorageDescriptor.Columns[].Name" --output text
order_id	customer_id	total_cents	phone
```

The table has the four columns of the CSV and a partition key, `dt`, which comes from the
`dt=2026-10-01` in the key. Nothing in this lesson reads its rows: moto keeps the definition, and no
engine here would run a query against it.

## The defaults, and the first administrator

```
ana@laptop:~/aws$ aws lakeformation get-data-lake-settings
{
    "DataLakeSettings": {
        "DataLakeAdmins": [],
        "CreateDatabaseDefaultPermissions": [
            {
                "Principal": {
                    "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS"
                },
                "Permissions": [
                    "ALL"
                ]
            }
        ],
        "CreateTableDefaultPermissions": [
            {
                "Principal": {
                    "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS"
                },
                "Permissions": [
                    "ALL"
                ]
            }
        ],
        "TrustedResourceOwners": [],
        "AllowExternalDataFiltering": false,
        "ExternalDataFilteringAllowList": []
    }
}
```

**The defaults hand every new database and table to `IAM_ALLOWED_PRINCIPALS`, with `ALL`.** That
group means "whoever IAM already allows", and the grant means Lake Formation steps aside: until
somebody changes it, permissions on a new table are decided by IAM exactly as before. It is how
Lake Formation can be switched on in an account that already has a lake without breaking a single
query, and it is the subject of the next section.

**The list of administrators is empty.** A data lake administrator is a principal that may grant
and revoke anything in the lake, and the first one has to be named by somebody with the IAM
permission to change these settings:

```
ana@laptop:~/aws$ aws lakeformation put-data-lake-settings --data-lake-settings '{"DataLakeAdmins":[{"DataLakePrincipalIdentifier":"arn:aws:iam::123456789012:user/moto"}]}'
ana@laptop:~/aws$ aws lakeformation get-data-lake-settings
{
    "DataLakeSettings": {
        "DataLakeAdmins": [
            {
                "DataLakePrincipalIdentifier": "arn:aws:iam::123456789012:user/moto"
            }
        ]
    }
}
```

**`put-data-lake-settings` replaced the whole document**, and the two default grants are gone with
everything else that was not in the request. moto behaves the way AWS's API is documented to here:
the call sets the settings, it does not merge into them. Leaving the defaults out is, on AWS, how
an account stops handing new tables to IAM. So the same call that names an administrator can also
change who decides about every table created afterwards, and it deserves to be written in full
each time rather than from memory.

## Registering the location

**A location is registered so that Lake Formation may vend credentials for it.** Registering an S3
path names a role Lake Formation will assume to read it; with `--use-service-linked-role`, that is
a role AWS creates for the purpose:

```
ana@laptop:~/aws$ aws lakeformation register-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/curated --use-service-linked-role
ana@laptop:~/aws$ aws lakeformation list-resources
{
    "ResourceInfoList": [
        {
            "ResourceArn": "arn:aws:s3:::quitanda-curated-prod/curated"
        }
    ]
}
```

From then on, an engine that is allowed to read a table under that path no longer needs its own
permission on the bucket. It asks Lake Formation, and Lake Formation, if the grants allow, hands it
temporary credentials made from that role, good for that path.

## Granting on columns

**A grant is a principal, a permission and a resource**, and the resource can be a database, a
table, or a table with a list of columns. The analysts need to find the database and to read the
orders without the phone number:

```
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions DESCRIBE --resource '{"Database":{"Name":"curated"}}'
ana@laptop:~/aws$ aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=arn:aws:iam::123456789012:role/analyst --permissions SELECT --resource '{"TableWithColumns":{"DatabaseName":"curated","Name":"orders","ColumnNames":["order_id","customer_id","total_cents","dt"]}}'
ana@laptop:~/aws$ aws lakeformation list-permissions --query "PrincipalResourcePermissions[?Resource.TableWithColumns]"
[
    {
        "Principal": {
            "DataLakePrincipalIdentifier": "arn:aws:iam::123456789012:role/analyst"
        },
        "Resource": {
            "TableWithColumns": {
                "DatabaseName": "curated",
                "Name": "orders",
                "ColumnNames": [
                    "order_id",
                    "customer_id",
                    "total_cents",
                    "dt"
                ]
            }
        },
        "Permissions": [
            "SELECT"
        ],
        "PermissionsWithGrantOption": []
    }
]
```

**`DESCRIBE` on the database lets the analyst see it in the catalogue, and `SELECT` on four columns
lets them query those four.** The column list is the half IAM could not say: `phone` is not in it,
so a query that asks for `phone` is refused, and `SELECT *` returns the other columns. The other
permissions follow SQL: `INSERT`, `DELETE`, `ALTER` and `DROP` on a table, `CREATE_TABLE` on a
database, and a grant option that lets the receiver grant the same permission on.

## How an engine asks

**The check happens when an engine reads, and it is the engine that asks.** When the analyst runs a
query in Athena, Athena reads the table's definition from the catalogue and asks Lake Formation for
access to it as that analyst. Lake Formation checks the grants and, if they allow the query, returns
temporary credentials good for that table's location. Athena reads the files with them and removes
the columns and rows the grant does not cover before anything reaches the analyst. The analyst's own
IAM policy needs Athena's permissions, read access to the catalogue and
`lakeformation:GetDataAccess`, and nothing on the bucket at all.

The engines that ask are **Athena, Redshift Spectrum, EMR and Glue's ETL jobs**, and services that
query through them, such as QuickSight through Athena. moto has no part of the asking:

```
ana@laptop:~/aws$ aws lakeformation get-temporary-glue-table-credentials --table-arn arn:aws:glue:sa-east-1:123456789012:table/curated/orders --permissions SELECT

aws: [ERROR]: An error occurred (404) when calling the GetTemporaryGlueTableCredentials operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

**The call a third-party engine makes to be handed credentials answers 404 in moto**, because it is
not implemented. That is the honest limit of this lesson. moto stores every grant this section made,
and nothing here ever asks for one, so nothing here is ever refused. The flow above is AWS's
documented behaviour and was not run.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Credential vending in six messages between the analyst, Athena, Lake Formation and S3. The analyst sends SELECT from curated.orders to Athena. Athena asks Lake Formation for access as the analyst, and Lake Formation checks the grants and returns temporary credentials. Athena calls GetObject on S3 with them and receives every column, and returns only the granted columns to the analyst. The analyst&#x27;s policy has no s3:GetObject.\" data-fig=\"l18-vending\"><defs><marker id=\"l18-vending-ah-0\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l18-vending-ah-1\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">analyst</text><polyline points=\"90,44 90,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"210\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Athena</text><polyline points=\"280,44 280,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"400\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"470\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Lake Formation</text><polyline points=\"470,44 470,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><rect x=\"570\" y=\"12\" width=\"140\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"640\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3</text><polyline points=\"640,44 640,300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"90,76 278,76\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l18-vending-ah-0)\"></polyline><text x=\"185.0\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">SELECT ... FROM curated.orders</text><polyline points=\"280,112 468,112\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l18-vending-ah-0)\"></polyline><text x=\"375.0\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">access, as the analyst</text><text x=\"478\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">checks the grants</text><polyline points=\"470,166 282,166\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-vending-ah-1)\"></polyline><text x=\"375.0\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">temporary credentials</text><polyline points=\"280,202 638,202\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l18-vending-ah-0)\"></polyline><text x=\"460.0\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">GetObject</text><polyline points=\"640,238 282,238\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-vending-ah-1)\"></polyline><text x=\"460.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every column</text><polyline points=\"280,274 92,274\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\" marker-end=\"url(#l18-vending-ah-1)\"></polyline><text x=\"185.0\" y=\"264\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">only the granted columns</text><text x=\"90\" y=\"316\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no s3:GetObject in its policy</text></svg>", "caption": "Athena reads the files, with credentials Lake Formation handed it after checking the grants. This is AWS's documented behaviour; none of it ran in moto."}
```
