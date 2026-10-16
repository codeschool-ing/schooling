---
title: A Glue job, and the cluster that is not yours
version: 1
---

**A Glue job is a script and a size, and AWS supplies the Spark to run it.** You write a Python
program against Spark, put it in S3, and tell Glue how many workers of which type to run it on.
At each run Glue starts that many machines, runs the script, and takes them away again. There is no
cluster between runs, so nothing to patch, nothing idle and nothing to forget to switch off, and the
bill is the run: the workers, multiplied by the seconds they were up.

The wrong picture is that "serverless" means no capacity to choose. The capacity is the first thing
a job definition asks for, and it is paid for whether the script keeps it busy or not. Ten workers
running a script that needed two cost ten.

## The words a job definition uses

Glue measures capacity in **DPUs**, data processing units, and AWS defines one as 4 vCPUs and 16 GB
of memory. A worker type is a number of DPUs per worker:

| worker type | DPUs | what it is for |
|---|---:|---|
| `G.1X` | 1 | the ordinary choice for a batch job |
| `G.2X` | 2 | jobs short of memory: wide joins, large shuffles |
| `G.4X`, `G.8X` | 4, 8 | the heaviest batch jobs |
| `G.025X` | 0.25 | streaming jobs, which run all the time on little |

**The DPUs of a run are the workers times the DPUs of each**, the driver included: ten `G.1X` workers
are ten DPUs, and one of them coordinates rather than computes. The script's type is a choice too:
`glueetl` is Spark, `gluestreaming` is Spark reading a stream, and `pythonshell` is plain Python on a
sixteenth of a DPU or a whole one, with no Spark at all. And `--glue-version` picks the Spark the run
gets: Glue 5.0 is Spark 3.5.

**A run of Glue 2.0 or later is billed per second, with one minute as the least a run costs.** The
versions before it billed ten minutes at least, which is worth knowing for the line moto prints below.

## What moto does with a job

The terminal is the one from lesson 1: moto running in its own terminal and the four lines of
lesson 1's "Your lab, in brief" typed in this one. The script of the next section goes to S3, and a
job names it:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-glue-prod
make_bucket: quitanda-glue-prod
ana@laptop:~/aws$ aws s3 cp orders_etl.py s3://quitanda-glue-prod/scripts/orders_etl.py --only-show-errors
ana@laptop:~/aws$ aws glue create-job --name orders-etl --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=glueetl,ScriptLocation=s3://quitanda-glue-prod/scripts/orders_etl.py,PythonVersion=3 --glue-version 5.0 --worker-type G.1X --number-of-workers 10 --timeout 60 --default-arguments '{"--job-bookmark-option": "job-bookmark-enable"}'
{
    "Name": "orders-etl"
}
ana@laptop:~/aws$ aws glue start-job-run --job-name orders-etl
{
    "JobRunId": "jr_abcdd673ba3667e392d422417578d9435f2fe7b6912898e12172173557f5f595"
}
ana@laptop:~/aws$ aws glue get-job-run --job-name orders-etl --run-id jr_abcdd673ba3667e392d422417578d9435f2fe7b6912898e12172173557f5f595 --query 'JobRun.[JobRunState,ExecutionTime,GlueVersion,WorkerType,NumberOfWorkers,DPUSeconds]' --output text
SUCCEEDED	123	0.9	G.1X	10	None
ana@laptop:~/aws$ aws glue get-job --job-name orders-etl --query 'Job.GlueVersion' --output text
5.0
```

**`SUCCEEDED` in `123` seconds, and nothing ran.** The script was never opened: moto has no Spark,
and every run of every job comes back `SUCCEEDED` with the same 123, a constant and not a
measurement. The run also says Glue `0.9` while the job says `5.0`, because moto fills in a default
of its own, and `DPUSeconds`, the field AWS fills in for the bill of some runs, is empty. **Nothing on
that line is evidence about the script**, which is why lesson 1 called a moto success a statement
about the request. The job definition is kept faithfully, and this lesson uses moto for exactly
that: recording what a job is. What it does is run for real two sections on, without Glue.

## The two prices

```
ana@laptop:~/aws$ python3 prices.py glue
AWS public price list, sa-east-1, USD, excluding tax

Glue, USD
  ETL job, per DPU-hour                                 0.69000  DPU-hour
  ETL job, Flex, per DPU-hour                           0.45000  DPU-hour
  crawler, per DPU-hour                                 0.69000  DPU-hour
  Data Catalog, per 100,000 objects beyond free         1.00000  month
  Data Catalog, per million requests beyond free        1.00000  million
```

**0.69 dollars a DPU-hour, or 0.45 on Flex**, the execution class for jobs that can wait. A Flex run
uses capacity AWS has spare, so it may start later and take longer, and it costs about a third less
for the same DPU-hours. The last section of this lesson does the arithmetic for Quitanda's nightly
job both ways.
