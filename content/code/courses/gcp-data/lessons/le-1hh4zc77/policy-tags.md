---
title: Policy tags: a permission on one column of BigQuery
version: 1
---

**Quitanda's curated orders carry the customer's phone number, for the delivery driver, and the
analysts who need the orders have no business with the phones.** IAM on the table cannot say that:
a role on a BigQuery table grants every column of it or none. Copying the table without the column
works and leaves two tables to keep in step. **A policy tag is a permission attached to a column**,
and BigQuery checks it on every query, whatever table or view the column is reached through.

## Taxonomies, tags and the reader role

**A taxonomy is a tree of policy tags, and each tag is a label for a kind of data.** Quitanda would
have one taxonomy, `personal-data`, with tags such as `phone`, `email` and `tax-id`, nested if it
helps: a parent `contact` over `phone` and `email` lets one grant cover both. The taxonomy lives in a
region, and it governs columns of tables in the same region. Policy tags began in Data Catalog, and the
taxonomies are still managed through its API and `gcloud data-catalog taxonomies`; as far as this
lesson knows, the retirement of Data Catalog left policy tags where they were.

**Three steps make the column private**, all taught here from the documentation and none run:

1. **Create the taxonomy and its tags**, and switch on access control for the taxonomy. Until access
   control is on, a tag is a label and enforces nothing.
2. **Attach the tag to the column** in the table's schema. The schema field gains a `policyTags`
   entry naming the tag, as `bq show --schema` would print it:

```json
{
  "name": "phone",
  "type": "STRING",
  "policyTags": {
    "names": ["projects/planner-dev/locations/southamerica-east1/taxonomies/TAXONOMY_ID/policyTags/PHONE_TAG_ID"]
  }
}
```

3. **Grant the role Fine-Grained Reader**, `roles/datacatalog.categoryFineGrainedReader`, on the tag,
   to the people who may read the column: the delivery team, not the analysts.

**The column then answers differently depending on who asks.** An analyst who selects `phone` is
refused with an access error, and the query fails rather than returning a blank column; a query that
names the other columns runs as before, and so does `SELECT * EXCEPT (phone)`. A member of the
delivery team reads the numbers. The permission follows the column into every view built over it,
because BigQuery checks the tag on the underlying column, not on the view.

## Masking, when the column must still be usable

**Refusal is sometimes too strong.** An analyst counting orders per customer by phone needs the
values to group by, not to read. **Dynamic data masking** attaches a **data policy** to the same policy tag.
Those granted the Masked Reader role on it then see a transformed value instead of
an error: a SHA-256 hash of the value, which still groups and joins; a null; the last four
characters; or a default value of the column's type. Fine-Grained Readers still see the real number,
and everybody else is refused as before. A hash is deterministic, which is what makes it useful for
joining, and it is also why a hash of a phone number is not anonymous: anybody can hash every phone
number in São Paulo and look the result up.

## Where this sits among the rest

**Policy tags are BigQuery's**, enforced by BigQuery's engine on BigQuery's tables. A Parquet file in
a bucket under a BigLake table can be governed the same way when it is read through BigQuery, which
is one of the reasons lesson 17 gave for BigLake; read directly with `gcloud storage cat`, the file
answers to IAM on the bucket and nothing else. **And the catalog of the earlier section can carry
the same knowledge as metadata**, an aspect saying `contains_personal_data`, which tells people. A
policy tag tells the engine. Quitanda needs both: the aspect so that somebody searching knows the
phones are there, and the tag so that knowing does not let them read them.

**Applying policy tags costs nothing on the Dataplex page**, which lists security policy application
and propagation among its free features. What a refused query costs is the analyst's afternoon, so
the work is in the grants, not in the bill.
