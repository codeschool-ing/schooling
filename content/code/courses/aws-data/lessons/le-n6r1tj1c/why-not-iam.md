---
title: Why IAM and bucket policies stop being enough
version: 1
---

**IAM and a bucket policy decide who may read an object, and a lake's questions are about tables,
columns and rows.** A policy can say "this role may read keys under `curated/orders/`". It cannot
say "this role may read the orders but not the customers' phone numbers", because the phone number
is a column, and a column is inside the object. Whoever may read the file reads every byte of it.
That is the whole reason Lake Formation exists, and it is worth seeing before anything else.

Quitanda's curated orders carry a phone number for the delivery driver. Make one day of them, with
numbers that belong to nobody:

```sh
mkdir -p lake
cat > lake/part-0.csv <<'EOF'
order_id,customer_id,total_cents,phone
01-1,c-17,4590,+55 11 90000-0017
01-2,c-03,12800,+55 11 90000-0003
01-3,c-22,990,+55 11 90000-0022
EOF
```

With moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed
in this one, put it where the curated layer keeps orders, and read it back the way any principal
allowed `s3:GetObject` on that key would:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-curated-prod
make_bucket: quitanda-curated-prod
ana@laptop:~/aws$ aws s3 cp lake/part-0.csv s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv
upload: lake/part-0.csv to s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv
ana@laptop:~/aws$ aws s3 cp s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv -
order_id,customer_id,total_cents,phone
01-1,c-17,4590,+55 11 90000-0017
01-2,c-03,12800,+55 11 90000-0003
01-3,c-22,990,+55 11 90000-0022
```

**Every column came back, the phone numbers with the rest.** There is no request to S3 that returns
three columns of a CSV and leaves out the fourth; the object is the unit S3 knows. An analyst who
needs the totals per customer and has no business with phone numbers still gets them, as long as
the permission is written in IAM.

## What it takes with IAM alone

**Granting a team a table through IAM means granting two things, in two services that know nothing
of each other.** One is the catalogue: `glue:GetTable`, `glue:GetPartitions` and their kin on the
database and the table, so that Athena can find out what the table is. The other is the data:
`s3:GetObject` and `s3:ListBucket` on the table's prefix, so that it can read the files. Miss the first and the
query fails before it starts; miss the second and it fails on the first file. Both are written per
role, per table or per prefix.

**It is the arithmetic that stops scaling.** Quitanda has six teams and forty tables in the curated
layer. Every change of who may read what is an edit to a JSON policy in IAM, sometimes in two. And
"who can read the phone column?" has no answer short of reading every policy and every bucket
policy and working out which prefixes each one covers. Nothing in IAM can hide one column. The
usual workaround is a second copy of the table without the column, under another prefix, and a
second copy is a second thing to keep in step, pay for and protect.

## The levels a lake needs

**A permission for a lake has to be able to stop at a database, a table, a column, a row or a
single cell.** IAM stops at the object and the prefix, which are a level below the table in one
sense and above it in another: a prefix holds a whole table's files, and a file holds every column
of the rows in it.
Lake Formation adds the levels IAM does not have, and it does it by putting itself between the
engine and the files, which is the next section.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two nestings side by side. On the left, S3 and IAM: a bucket, quitanda-curated-prod, holds a prefix, curated/orders/, which holds an object, part-0.csv, with every column and every row in one piece; the object is the smallest thing IAM can name. On the right, the Glue Data Catalog and Lake Formation: the database curated holds the table orders, drawn as a grid of four columns, order_id, customer_id, total_cents and phone, by three rows; Lake Formation reaches down to a column, a row or a cell. The phone column is highlighted.\" data-fig=\"l18-levels\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">S3 and IAM</text><rect x=\"20\" y=\"32\" width=\"300\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">bucket</text><text x=\"310\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">quitanda-curated-prod</text><rect x=\"36\" y=\"60\" width=\"268\" height=\"166\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">prefix</text><text x=\"294\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">curated/orders/</text><rect x=\"52\" y=\"90\" width=\"236\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"62\" y=\"106\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">object</text><text x=\"278\" y=\"106\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">part-0.csv</text><text x=\"170\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every column,</text><text x=\"170\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every row,</text><text x=\"170\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in one piece</text><text x=\"170\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the smallest thing IAM can name</text><text x=\"540\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Glue Data Catalog and Lake Formation</text><rect x=\"380\" y=\"32\" width=\"320\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">database</text><text x=\"690\" y=\"48\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">curated</text><rect x=\"396\" y=\"60\" width=\"288\" height=\"166\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"406\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">table</text><text x=\"674\" y=\"76\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">orders</text><rect x=\"406\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">order_id</text><rect x=\"474\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">customer_id</text><rect x=\"542\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">total_cents</text><rect x=\"610\" y=\"90\" width=\"66\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">phone</text><rect x=\"406\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">01-1</text><rect x=\"474\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">c-17</text><rect x=\"542\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">4590</text><rect x=\"610\" y=\"116\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">...0017</text><rect x=\"406\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">01-2</text><rect x=\"474\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">c-03</text><rect x=\"542\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">12800</text><rect x=\"610\" y=\"142\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">...0003</text><rect x=\"406\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"439.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">01-3</text><rect x=\"474\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"507.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">c-22</text><rect x=\"542\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">990</text><rect x=\"610\" y=\"168\" width=\"66\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"643.0\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">...0022</text><text x=\"540\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a column, a row, a cell</text></svg>", "caption": "The phone number is inside the object, so IAM cannot hide it: whoever reads the file reads the column. The catalogue sees the same file as a table, and that is the level Lake Formation grants at."}
```
