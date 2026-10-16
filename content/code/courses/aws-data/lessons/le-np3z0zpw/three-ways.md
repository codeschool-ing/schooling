---
title: EMR on EC2, on EKS and Serverless
version: 1
---

**"EMR" names three products that share a release label and little else.** Everything so far was
**EMR on EC2**, the original: a cluster of machines you choose, in roles you configure. **EMR on
EKS** runs the same Spark on a Kubernetes cluster you already operate, as pods beside your other
workloads. **EMR Serverless** has no cluster at all: you create an application, submit jobs to it,
and pay for the processors and memory each job used, which makes it the closest of the three to
Glue.

| | you choose | you pay for | idle costs |
|---|---|---|---|
| EMR on EC2 | instance types, counts, roles, Spot | EC2 machines plus the EMR fee, from boot to termination | everything, until terminated |
| EMR on EKS | the Kubernetes cluster and its nodes | the nodes, plus an EMR fee per vCPU and GB used by the job | the nodes you keep, as for any EKS cluster |
| EMR Serverless | a release and, optionally, limits and warm capacity | vCPU-hours and GB-hours each job used | nothing, unless capacity is kept warm |

## Serverless: an application and its job runs

**An EMR Serverless application is a named place to submit jobs**, fixed to one release and one
engine, Spark or Hive. It holds no machines while no job runs. Create one, and read back what it
was given:

```
ana@laptop:~/aws$ aws emr-serverless create-application --name quitanda-spark --type SPARK --release-label emr-7.9.0
{
    "applicationId": "mq3suijxic915tta",
    "name": "quitanda-spark",
    "arn": "arn:aws:emr-serverless:sa-east-1:123456789012:/applications/mq3suijxic915tta"
}
ana@laptop:~/aws$ aws emr-serverless get-application --application-id mq3suijxic915tta --query 'application.{state:state,autoStart:autoStartConfiguration,autoStop:autoStopConfiguration}'
{
    "state": "STARTED",
    "autoStart": {
        "enabled": true
    },
    "autoStop": {
        "enabled": true,
        "idleTimeoutMinutes": 15
    }
}
ana@laptop:~/aws$ aws emr-serverless start-job-run --application-id mq3suijxic915tta --execution-role-arn arn:aws:iam::123456789012:role/quitanda-emr-job --job-driver '{"sparkSubmit": {"entryPoint": "s3://quitanda-raw-prod/jobs/daily_orders.py", "entryPointArguments": ["--dt", "2026-10-15"]}}'
{
    "applicationId": "mq3suijxic915tta",
    "jobRunId": "y2mmgl5jh2ey5c2g",
    "arn": "arn:aws:emr-serverless:sa-east-1:123456789012:/applications/mq3suijxic915tta/jobruns/y2mmgl5jh2ey5c2g"
}
ana@laptop:~/aws$ aws emr-serverless get-job-run --application-id mq3suijxic915tta --job-run-id y2mmgl5jh2ey5c2g --query 'jobRun.{state:state,seconds:totalExecutionDurationSeconds,billed:billedResourceUtilization}'
{
    "state": "SUCCESS",
    "seconds": 0,
    "billed": {
        "vCPUHour": 0.0,
        "memoryGBHour": 0.0,
        "storageGBHour": 0.0
    }
}
```

**`autoStopConfiguration` is the line that sets Serverless apart from a long-running cluster.** The
application starts when a job arrives and stops after 15 minutes with nothing to do, so an
application nobody uses costs nothing. On AWS it can also keep **pre-initialised capacity**, a
number of drivers and workers held warm so that a job does not wait for workers to be provisioned
before it starts, and that capacity is billed while it waits, which turns Serverless back into
something that costs money idle. It is off unless you configure it.

**The job run is `SUCCESS` with zero seconds of execution and zero vCPU-hours billed.** No program
was read and no Spark started; moto marked the run successful on the line that created it. On AWS `billedResourceUtilization` is the field the bill is computed from. For a real job it is the sum,
over every worker, of the vCPUs and gigabytes it held multiplied by the time it held them, which is
why the last section of this lesson can price a Serverless job from two lines of the sheet.

## EMR on EKS: a virtual cluster on somebody's Kubernetes

**On EKS, EMR does not create machines at all.** It registers a **virtual cluster**, which is a
namespace of an existing EKS cluster where EMR may start pods, and a job run becomes a driver pod
and executor pods there, scheduled by Kubernetes beside whatever else the cluster runs.

```
ana@laptop:~/aws$ aws emr-containers create-virtual-cluster --name quitanda-eks --container-provider id=quitanda-eks,type=EKS,info={eksInfo={namespace=spark}}
{
    "id": "8osaqotoiebnflz7te6wsjnvb",
    "name": "quitanda-eks",
    "arn": "arn:aws:emr-containers:sa-east-1:123456789012:/virtualclusters/8osaqotoiebnflz7te6wsjnvb"
}
ana@laptop:~/aws$ aws emr-containers list-virtual-clusters --query 'virtualClusters[].[name,state,containerProvider.id]' --output text
quitanda-eks	RUNNING	quitanda-eks
ana@laptop:~/aws$ aws eks list-clusters
{
    "clusters": []
}
```

**A virtual cluster `RUNNING` on an EKS cluster that does not exist** is moto at its most
accommodating: `aws eks list-clusters` is empty, and the registration succeeded anyway. On AWS it
would be refused until the EKS cluster existed and had been given to EMR. The case for EMR on EKS is
an organisation that already runs Kubernetes and wants Spark to share its machines, its monitoring
and its people. For a team without one, it adds a Kubernetes cluster to operate in order to run
Spark, which is the opposite of the trade this course is looking for.

## How the three divide the work

**EMR on EC2 when the work is big, steady or unusual**: a cluster large enough that Spot and a
machine type of your choosing save real money, a job that needs a library or a configuration on the
machine itself, the Hadoop tools beyond Spark (Hive, HBase, Trino, Flink), or a cluster people work
on all day. **EMR Serverless when the work is Spark or Hive and irregular**, so that paying only for
the job matters more than choosing the machine. **EMR on EKS when Kubernetes is already the
platform** and the team wants one place for everything to run. The next section prices the first
two against Glue for the same night of work, because "irregular" and "steady" are words until a
monthly total is put beside them.
