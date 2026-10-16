---
title: An instance, two endpoints and a task
version: 1
---

**A DMS migration is four objects, and each answers one question.** The replication instance is
where it runs. The source endpoint is how to reach the old database, the target endpoint is how to
reach the new home of the data, and the task says what to copy from one to the other and how. They
are created in that order, because each names the ones before it.

With moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed in
this one, start with the instance:

```
ana@laptop:~/aws$ aws dms create-replication-instance --replication-instance-identifier quitanda-cdc --replication-instance-class dms.c5.large --allocated-storage 50 --query "ReplicationInstance.[ReplicationInstanceArn,ReplicationInstanceStatus]"
[
    "arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc",
    "creating"
]
ana@laptop:~/aws$ aws dms describe-replication-instances --query "ReplicationInstances[].[ReplicationInstanceIdentifier,ReplicationInstanceClass,ReplicationInstanceStatus]" --output text
quitanda-cdc	dms.c5.large	available
```

**`creating` in the answer, `available` on the next line.** On AWS a replication instance takes some
minutes to come up, and the status says `creating` throughout; moto waits for nothing, as lesson 1
warned. `--allocated-storage 50` is the instance's own disk in gigabytes, where it keeps logs and the
changes it is holding back during a full load.

## The source, without a password on the command line

**The old database needs a user and a password, and neither belongs in a command.** A password typed
after `--password` sits in the shell's history and in the process list of the machine it was typed
on. DMS can instead read the credentials from **Secrets Manager**: the secret holds the user, the
password, the host and the port, and the endpoint names the secret and a role DMS may assume to read
it. The secret's password below is made by `openssl rand` inside the command, so it is never typed
and never printed:

```
ana@laptop:~/aws$ aws secretsmanager create-secret --name quitanda/legacy-shop --secret-string "{\"username\": \"dms_reader\", \"password\": \"$(openssl rand -hex 16)\", \"host\": \"198.51.100.20\", \"port\": 5432}" --query Name --output text
quitanda/legacy-shop
ana@laptop:~/aws$ aws dms create-endpoint --endpoint-identifier legacy-shop --endpoint-type source --engine-name postgres --database-name shop --postgre-sql-settings SecretsManagerSecretId=quitanda/legacy-shop,SecretsManagerAccessRoleArn=arn:aws:iam::123456789012:role/quitanda-dms-secrets,SlotName=dms_orders,PluginName=test-decoding --query "Endpoint.[EndpointArn,Status,PostgreSQLSettings]"
[
    "arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G",
    "creating",
    {
        "SlotName": "dms_orders",
        "PluginName": "test-decoding",
        "SecretsManagerAccessRoleArn": "arn:aws:iam::123456789012:role/quitanda-dms-secrets",
        "SecretsManagerSecretId": "quitanda/legacy-shop"
    }
]
```

**`SlotName` and `PluginName` are PostgreSQL's half of CDC**, and the section on PostgreSQL shows
what they are on a running server: the name of the replication slot DMS will read changes from, and
the plugin that turns the write-ahead log into rows. moto stored both, and the secret, exactly as
given. It did not look inside the secret, and it did not try to reach `198.51.100.20`.

## The target, and a test that tests nothing

Quitanda's first target is the lake rather than another database: the orders, and every change to
them, as files under `s3://quitanda-raw-prod/cdc/`, where Glue and Athena from lessons 15 to 17 can
read them. An S3 target endpoint names the bucket, a folder and a role DMS assumes to write there.

```
ana@laptop:~/aws$ aws dms create-endpoint --endpoint-identifier lake-raw --endpoint-type target --engine-name s3 --s3-settings BucketName=quitanda-raw-prod,BucketFolder=cdc,ServiceAccessRoleArn=arn:aws:iam::123456789012:role/quitanda-dms-s3 --query "Endpoint.[EndpointArn,Status]"
[
    "arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13",
    "creating"
]
ana@laptop:~/aws$ aws dms test-connection --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --query Connection.Status
"testing"
```

**`test-connection` is what a careful person runs before a task**, and on AWS it makes the
replication instance actually open a connection to the endpoint, then reports `successful` or a
failure with the reason. In moto it answers `testing` and stops there: there is nothing at
`198.51.100.20` to connect to, and moto never tries.

## The task

**The task joins the three and adds the two decisions that are its own**: the migration type from the
previous section, and the table mappings, a JSON document saying which tables to take. The simplest
mapping selects one table. Save it as `mappings.json`:

`mappings.json`:

```json
{
  "rules": [
    {
      "rule-type": "selection",
      "rule-id": "1",
      "rule-name": "orders",
      "object-locator": {"schema-name": "public", "table-name": "orders"},
      "rule-action": "include"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws dms create-replication-task --replication-task-identifier orders-to-lake --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-instance-arn arn:aws:dms:sa-east-1:123456789012:rep:quitanda-cdc --migration-type full-load-and-cdc --table-mappings file://mappings.json --query 'ReplicationTask.[Status,ReplicationTaskStats]'
[
    "creating",
    {
        "FullLoadProgressPercent": 100,
        "ElapsedTimeMillis": 100,
        "TablesLoaded": 1,
        "TablesLoading": 0,
        "TablesQueued": 0,
        "TablesErrored": 0
    }
]
ana@laptop:~/aws$ aws dms start-replication-task --replication-task-arn arn:aws:dms:sa-east-1:123456789012:task:orders-to-lake --start-replication-task-type start-replication --query ReplicationTask.Status
"running"
ana@laptop:~/aws$ aws dms describe-table-statistics --replication-task-arn arn:aws:dms:sa-east-1:123456789012:task:orders-to-lake

aws: [ERROR]: An error occurred (500) when calling the DescribeTableStatistics operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/cdc/

aws: [ERROR]: An error occurred (NoSuchBucket) when calling the ListObjectsV2 operation: The specified bucket does not exist
ana@laptop:~/aws$ aws dms stop-replication-task --replication-task-arn arn:aws:dms:sa-east-1:123456789012:task:orders-to-lake --query ReplicationTask.Status
"stopped"
```

**Read the statistics before believing them.** At creation, before anything was started, moto
reported `FullLoadProgressPercent` 100 and one table loaded. Nothing was loaded: the source does not
exist, and the target bucket does not either, as the last command shows. Those are numbers moto
writes on every task. The per-table statistics, which on AWS say how many rows each table received
by insert, update and delete, are a `500`. **The lab can create a task, start it and stop it, and
cannot replicate a single row**; what replication itself looks like is the section on PostgreSQL,
which reads real changes from a real log.

## And the serverless form

**DMS Serverless has no instance**: a replication config carries the endpoints, the type, the
mappings and the capacity limits all at once. moto 5.2.3 does not implement it:

```
ana@laptop:~/aws$ aws dms create-replication-config --replication-config-identifier orders-to-lake-serverless --source-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:GE4E4H18LLSZ4S5CLI4PY4BXH3G --target-endpoint-arn arn:aws:dms:sa-east-1:123456789012:endpoint:XKD63514ZWORV4H3HTCYH492I13 --replication-type full-load-and-cdc --table-mappings file://mappings.json --compute-config MinCapacityUnits=2,MaxCapacityUnits=16

aws: [ERROR]: An error occurred (500) when calling the CreateReplicationConfig operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**That `500` is moto, not your command.** On AWS the config would be created, and replication would
start when you start it, with DMS choosing a capacity between the limits; the shape of the call is
AWS's documented one, and it was not run here.
