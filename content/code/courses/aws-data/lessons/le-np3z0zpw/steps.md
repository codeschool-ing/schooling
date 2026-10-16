---
title: Steps, and the cluster that lives for one night
version: 1
---

**A step is one unit of work handed to a cluster**: a Spark program to submit, a Hive script, a
command to run on the primary node. The cluster runs its steps in the order they arrive, one at a
time unless told otherwise, and each carries an instruction for what to do if it fails. A step is
how work reaches a cluster without anybody logging in to it, which is what lets a cluster be
created by a scheduler at three in the morning and gone by four.

The work in this section is Quitanda's nightly job: read one day of orders from the raw bucket,
total them per customer, and write the result as Parquet into the curated bucket. As a PySpark
program it is short. It is shown so that the step below has something to point at, and **it is not
run in this lab**, which has no Spark; on EMR it would be uploaded to
`s3://quitanda-raw-prod/jobs/daily_orders.py`.

```python
import sys
from pyspark.sql import SparkSession, functions as F

dt = sys.argv[sys.argv.index('--dt') + 1]
spark = SparkSession.builder.appName(f'daily-orders-{dt}').getOrCreate()

orders = spark.read.option('header', True).csv(f's3://quitanda-raw-prod/raw/orders/dt={dt}/')
daily = (orders.groupBy('customer_id')
               .agg(F.count('*').alias('orders'),
                    F.sum(F.col('total_cents').cast('long')).alias('total_cents')))
daily.write.mode('overwrite').parquet(f's3://quitanda-curated-prod/daily_orders/dt={dt}/')
```

Give it to the long-running cluster from the previous section as a step:

```
ana@laptop:~/aws$ aws emr add-steps --cluster-id j-F34XLF93AZT13 --steps Type=Spark,Name=daily-orders,ActionOnFailure=CONTINUE,Args=[s3://quitanda-raw-prod/jobs/daily_orders.py,--dt,2026-10-15]
{
    "StepIds": [
        "s-XTL8VVC6SSGYA"
    ]
}
ana@laptop:~/aws$ aws emr list-steps --cluster-id j-F34XLF93AZT13
{
    "Steps": [
        {
            "Id": "s-XTL8VVC6SSGYA",
            "Name": "daily-orders",
            "Config": {
                "Jar": "command-runner.jar",
                "Properties": {},
                "Args": [
                    "spark-submit",
                    "s3://quitanda-raw-prod/jobs/daily_orders.py",
                    "--dt",
                    "2026-10-15"
                ]
            },
            "ActionOnFailure": "CONTINUE",
            "Status": {
                "State": "RUNNING",
                "StateChangeReason": {},
                "Timeline": {
                    "CreationDateTime": "2026-10-16T12:49:37.372000-03:00"
                }
            }
        }
    ]
}
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod/jobs/

aws: [ERROR]: An error occurred (NoSuchBucket) when calling the ListObjectsV2 operation: The specified bucket does not exist
```

**`Type=Spark` became `command-runner.jar` running `spark-submit`** with the program and its two
arguments. That is what a Spark step is on EMR: a command run on the primary node, which submits
the program to YARN. `ActionOnFailure=CONTINUE` says that if it fails the cluster carries on to the
next step; the other two choices are `CANCEL_AND_WAIT`, which cancels the steps queued behind it
and waits, and `TERMINATE_CLUSTER`, which ends the cluster, and the transient cluster below uses
that one.

**The last command is the one to remember.** There is no bucket called `quitanda-raw-prod` in this
moto, so there is no program and no orders, and the step is `RUNNING` anyway. It will stay
`RUNNING`: moto never starts Spark, never reads the program, and never moves a step to `COMPLETED`
or `FAILED`. On AWS this step would fail as soon as `spark-submit` looked for the file,
and the log EMR copies under `--log-uri` would say so; nothing here can show you that log.

## Transient and long-running

**A long-running cluster waits for work; a transient cluster is created for its work and ends with
it.** The difference is one flag. The cluster above was created with `--no-auto-terminate`, so with
its steps done it sits in `WAITING`, billed by the second. A transient cluster is created with its
steps and `--auto-terminate`, and on AWS it terminates itself after the last one:

```
ana@laptop:~/aws$ aws emr create-cluster --name quitanda-nightly-2026-10-15 --release-label emr-7.9.0 --applications Name=Spark --instance-groups InstanceGroupType=MASTER,InstanceType=m7i.xlarge,InstanceCount=1 InstanceGroupType=CORE,InstanceType=m7i.xlarge,InstanceCount=2 --service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole --steps Type=Spark,Name=daily-orders,ActionOnFailure=TERMINATE_CLUSTER,Args=[s3://quitanda-raw-prod/jobs/daily_orders.py,--dt,2026-10-15] --auto-terminate
{
    "ClusterId": "j-0QNKSD17XUPEO",
    "ClusterArn": "arn:aws:elasticmapreduce:us-east-1:123456789012:cluster/j-0QNKSD17XUPEO"
}
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-0QNKSD17XUPEO --query 'Cluster.[Status.State,AutoTerminate]' --output text
WAITING	True
ana@laptop:~/aws$ aws emr list-steps --cluster-id j-0QNKSD17XUPEO --query 'Steps[].[Name,ActionOnFailure,Status.State]' --output text
daily-orders	TERMINATE_CLUSTER	RUNNING
```

**On AWS that cluster would be `TERMINATED` once its one step finished, or as soon as it failed,
because the step says `TERMINATE_CLUSTER`.** In moto it waits forever with its step running, which is
the honest limit of a program that runs nothing: it has no moment at which the step ends, so it has
no moment at which the cluster should. Read the request, not the outcome.

A long-running cluster has one guard against being forgotten, the **auto-termination policy**: an
idle timeout, in seconds, after which EMR ends a cluster that has run nothing. It is set with
`--auto-termination-policy IdleTimeout=3600` at creation, and moto 5.2.3 accepts the flag and answers
`500` when asked to read it back, so it is shown here as a flag and not as a capture.

## Which lifetime, for which work

**Transient is the default answer for scheduled batch work**, and Quitanda's nightly job is the
example. The cluster starts at three, runs one step, and is gone, so the bill is the job's duration
plus the minutes the machines take to boot and install, which on AWS are billed and which moto, ready
on the same line, cannot show. Nothing is left running to forget.

**Long-running earns its place in three cases.** When work arrives all day, the boot minutes are
paid once instead of on every job. When people work against the cluster interactively, a notebook
attached to it or an analyst running queries through Hive or Trino, there is nothing to schedule a
transient cluster around. And when the cluster holds something it would take an hour to rebuild,
such as a large HBase table, stopping it is not an option. Each of those turns a cluster from a
job's container into a service with an owner, and the last section of this lesson prices what that
costs when the owner forgets.

Before going on, end the three clusters this lesson has made. `terminate-clusters` takes a list:

```
ana@laptop:~/aws$ aws emr terminate-clusters --cluster-ids j-F34XLF93AZT13 j-DETAZ49RVUEMK j-0QNKSD17XUPEO
ana@laptop:~/aws$ aws emr list-clusters --query 'Clusters[].[Name,Status.State]' --output text
quitanda-nightly-2026-10-15	TERMINATED
quitanda-fleets	TERMINATED
quitanda-emr	TERMINATED
```
