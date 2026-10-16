---
title: Table mappings, LOBs and validation
version: 1
---

**Table mappings decide what crosses, and task settings decide how.** Both are JSON documents
attached to the task, and both are where a migration is usually gone wrong: a table nobody selected,
a column that should never have left the old database, a large text field cut short without a
warning. The two files in this section are what Quitanda's real task would carry.

## Mappings: select, then transform

**Rules run in two kinds.** `selection` rules say which tables are taken, with `%` as a wildcard and
`include` or `exclude` as the action; `transformation` rules change what is taken, renaming a schema
or a table, dropping or adding a column. Quitanda takes every table of the `public` schema except
its session table, which is worthless outside the shop, and drops the column of customers' tax
numbers, which the lake has no reason to hold. Save this as `mappings-full.json`:

`mappings-full.json`:

```json
{
  "rules": [
    {
      "rule-type": "selection", "rule-id": "1", "rule-name": "all-public",
      "object-locator": {"schema-name": "public", "table-name": "%"},
      "rule-action": "include"
    },
    {
      "rule-type": "selection", "rule-id": "2", "rule-name": "not-sessions",
      "object-locator": {"schema-name": "public", "table-name": "web_sessions"},
      "rule-action": "exclude"
    },
    {
      "rule-type": "transformation", "rule-id": "3", "rule-name": "drop-tax-id",
      "rule-target": "column",
      "object-locator": {"schema-name": "public", "table-name": "customers", "column-name": "tax_id"},
      "rule-action": "remove-column"
    },
    {
      "rule-type": "transformation", "rule-id": "4", "rule-name": "schema-name",
      "rule-target": "schema",
      "object-locator": {"schema-name": "public"},
      "rule-action": "rename", "value": "shop"
    }
  ]
}
```

**The exclusion wins over the wildcard**, so `web_sessions` stays behind while every other table of
`public` crosses. **The column is removed in transit**, which is the cheapest place to remove a piece
of personal data: it never reaches the target, so it never has to be deleted from it, and the
lake's own rules on who may read what, lesson 18's subject, have one column fewer to protect. The
last rule names the schema `shop` on the target, which on S3 becomes the first folder under `cdc/`.

## Settings: LOBs and validation

**A LOB is a large object: a `text`, `bytea` or `jsonb` value with no fixed size**, and it is the one
kind of column DMS cannot treat like the others, because it cannot know how big a buffer to give it
before reading it. It offers three modes. **Full LOB mode** reads every LOB whole, however large,
piece by piece, and is the slowest. **Limited LOB mode** reads each LOB up to `LobMaxSize` kilobytes,
fast, and **truncates anything longer**; on AWS the task log records it with a warning, and nothing
stops the task. **No LOBs** leaves those columns out. Quitanda's orders carry a `notes` column the
delivery drivers write in, never more than a few lines, so limited mode at 64 KB is safe; the
assumption has to be measured on the source first, with `SELECT max(octet_length(notes)) FROM
orders`, because the failure mode is silent.

**Validation compares the target with the source, row by row**, after the full load and then
continuously during CDC, and reports each table as validated, mismatched or not comparable. It costs
the source extra reads, and it is the only thing in DMS that tells you the copy is right rather than
that the copy ran. Save the settings as `task-settings.json`:

`task-settings.json`:

```json
{
  "TargetMetadata": {
    "SupportLobs": true,
    "FullLobMode": false,
    "LimitedSizeLobMode": true,
    "LobMaxSize": 64
  },
  "FullLoadSettings": {"TargetTablePrepMode": "DROP_AND_CREATE"},
  "ValidationSettings": {"EnableValidation": true, "ThreadCount": 5}
}
```

Create the task with both files:

```
ana@laptop:~/aws$ aws dms create-replication-task --replication-task-identifier shop-to-lake --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --migration-type full-load-and-cdc --table-mappings file://mappings-full.json --replication-task-settings file://task-settings.json --query ReplicationTask.ReplicationTaskSettings --output text
{
  "TargetMetadata": {
    "SupportLobs": true,
    "FullLobMode": false,
    "LimitedSizeLobMode": true,
    "LobMaxSize": 64
  },
  "FullLoadSettings": {"TargetTablePrepMode": "DROP_AND_CREATE"},
  "ValidationSettings": {"EnableValidation": true, "ThreadCount": 5}
}

ana@laptop:~/aws$ cat broken.json
{"rules": [
ana@laptop:~/aws$ aws dms create-replication-task --replication-task-identifier broken --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --migration-type cdc --table-mappings file://broken.json --query 'ReplicationTask.[ReplicationTaskIdentifier,Status,TableMappings]'
[
    "broken",
    "creating",
    "{\"rules\": [\n"
]
```

**moto stored both documents as text and judged neither.** The settings came back byte for byte,
which is what moto is good at. The second command is the warning: a mapping file that is not even
valid JSON, one line long, and moto created a task with it. On AWS that call is refused with an
error naming the table mappings, before any task exists. In this lab, check a JSON file yourself
before giving it to DMS:

```
ana@laptop:~/aws$ python3 -m json.tool broken.json
Expecting value: line 2 column 1 (char 12)
ana@laptop:~/aws$ python3 -m json.tool mappings-full.json > /dev/null && echo valid
valid
```

**`python3 -m json.tool` reads a file and prints it, or names the line where it stops making
sense**, which is the check moto does not make. It proves the file is JSON; whether the rules in it
select the tables you meant is a question only a run against the real source answers, and that run
is not possible here.
