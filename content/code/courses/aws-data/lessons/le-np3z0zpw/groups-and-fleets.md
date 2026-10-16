---
title: Instance groups, instance fleets and Spot for the task nodes
version: 1
---

**A cluster describes its machines in one of two ways, and it cannot mix them.** With **instance
groups**, each role is a group of identical machines: one type, one count, one way of paying. With
**instance fleets**, each role is a target capacity and a list of machine types that may fill it,
and EMR chooses among them at launch. Groups are simpler to read and to resize; fleets are what let a
cluster start when the one type it asked for is not available.

With moto running in its own terminal and the four lines of lesson 1's "Your lab, in brief" typed
in this one, create a cluster with instance groups: one primary node and two core nodes, all
`m7i.xlarge`, which `cloud` lesson 4 priced at 4 vCPU and 16 GiB.

```
ana@laptop:~/aws$ aws emr create-cluster --name quitanda-emr --release-label emr-7.9.0 --applications Name=Spark --instance-groups InstanceGroupType=MASTER,InstanceType=m7i.xlarge,InstanceCount=1 InstanceGroupType=CORE,InstanceType=m7i.xlarge,InstanceCount=2 --service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole --log-uri s3://quitanda-logs-prod/emr/ --no-auto-terminate
{
    "ClusterId": "j-F34XLF93AZT13",
    "ClusterArn": "arn:aws:elasticmapreduce:us-east-1:123456789012:cluster/j-F34XLF93AZT13"
}
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.{State:Status.State,AutoTerminate:AutoTerminate,Zone:Ec2InstanceAttributes.Ec2AvailabilityZone}'
{
    "State": "WAITING",
    "AutoTerminate": false,
    "Zone": "us-east-1a"
}
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.InstanceGroups[].[Id,Name,InstanceGroupType,Market,RequestedInstanceCount,Status.State]' --output table
----------------------------------------------------------------------
|                          describe_cluster                          |
+------------------+---------+---------+------------+----+-----------+
|  i-4F6BZBCG9FX54 |  CORE   |  CORE   |  ON_DEMAND |  2 |  RUNNING  |
|  i-XWWQ4VDMTLWGH |  MASTER |  MASTER |  ON_DEMAND |  1 |  RUNNING  |
+------------------+---------+---------+------------+----+-----------+
```

**EMR answered with a cluster id, `j-` and thirteen characters**, and every later command names it.
Yours is different; use your own. `--no-auto-terminate` makes this a long-running cluster, one that
waits for work when it has none, and `WAITING` is that state. The two roles behind `--service-role`
and `--ec2-attributes InstanceProfile=` are how EMR acts in your account and how the machines read
S3; on a real account `aws emr create-default-roles` makes both, and moto accepts the names without
checking that they exist. `--log-uri` is where EMR copies each step's logs, which the next section
needs.

**Look at the ARN in the first answer and the zone in the second, though.** Both say `us-east-1`,
while the terminal and every other service in this course say `sa-east-1`. moto's EMR places every
cluster in Virginia whatever the region of the request. A real cluster is created in the
region you asked for; this is moto being wrong in a detail, and it is worth having seen once, so that
an ARN is something you read rather than something you trust.

## Spot, for the machines that may disappear

**Spot is EC2's spare capacity, sold below the on-demand price, and taken back with two minutes'
warning when AWS needs it.** The price moves with demand, which is why the price sheet has no line
for it. The previous section ordered the roles by what their loss costs, and that order is the rule
for Spot: the task nodes may be Spot, because losing one costs time. The core nodes should not be,
unless the job can survive failing; the primary node never should be, because losing it ends the
cluster.

Add a group of four task nodes as Spot. `BidPrice=OnDemandPrice` is how a group asks for Spot and
says it will pay up to the on-demand price, which is the setting AWS recommends:

```
ana@laptop:~/aws$ aws emr add-instance-groups --cluster-id j-F34XLF93AZT13 --instance-groups InstanceGroupType=TASK,Name=task-spot,InstanceType=m7i.xlarge,InstanceCount=4,BidPrice=OnDemandPrice
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.InstanceGroups[].[Id,Name,InstanceGroupType,Market,RequestedInstanceCount,Status.State]' --output table
-------------------------------------------------------------------------
|                           describe_cluster                            |
+------------------+------------+---------+------------+----+-----------+
|  i-4F6BZBCG9FX54 |  CORE      |  CORE   |  ON_DEMAND |  2 |  RUNNING  |
|  i-PB5EHG715IN9W |  task-spot |  TASK   |  SPOT      |  4 |  RUNNING  |
|  i-XWWQ4VDMTLWGH |  MASTER    |  MASTER |  ON_DEMAND |  1 |  RUNNING  |
+------------------+------------+---------+------------+----+-----------+
```

**moto printed nothing, where AWS answers with the new group's id, and the table has three groups.**
The market column is the point of them: the machines that hold the cluster together are `ON_DEMAND`, the ones that only add speed are `SPOT`. On AWS a reclaimed task node is
replaced when capacity returns, and the tasks it was running are run again elsewhere. moto reclaims
nothing; the four Spot nodes are `RUNNING` forever.

## Fleets: a target and a list of types

**A fleet asks for capacity rather than for machines.** The task fleet below wants four units of
Spot capacity and offers three machine types that could provide them, so that a shortage of
`m7i.xlarge` in one zone does not stop the cluster starting. On AWS each type can carry a weight,
the units it counts for, and an allocation strategy decides which of the offered types to take from
the pools Spot has the most of.

```
ana@laptop:~/aws$ aws emr create-cluster --name quitanda-fleets --release-label emr-7.9.0 --applications Name=Spark --instance-fleets InstanceFleetType=MASTER,TargetOnDemandCapacity=1,InstanceTypeConfigs=[{InstanceType=m7i.xlarge}] InstanceFleetType=CORE,TargetOnDemandCapacity=2,InstanceTypeConfigs=[{InstanceType=m7i.xlarge}] InstanceFleetType=TASK,TargetSpotCapacity=4,InstanceTypeConfigs=[{InstanceType=m7i.xlarge},{InstanceType=m6i.xlarge},{InstanceType=m5.xlarge}] --service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole --no-auto-terminate
{
    "ClusterId": "j-DETAZ49RVUEMK",
    "ClusterArn": "arn:aws:elasticmapreduce:us-east-1:123456789012:cluster/j-DETAZ49RVUEMK"
}
ana@laptop:~/aws$ aws emr list-instance-fleets --cluster-id j-DETAZ49RVUEMK

aws: [ERROR]: An error occurred (500) when calling the ListInstanceFleets operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-DETAZ49RVUEMK --query 'Cluster.InstanceCollectionType'
null
```

**moto accepted the fleets and kept none of them.** The cluster was created, listing its fleets is a
`500` from inside moto, and `InstanceCollectionType`, which on AWS says `INSTANCE_FLEET` for exactly
this cluster, is `null`. That is the edge of the imitation, and the right reading of it is the one
lesson 1 gave: the request was well formed. How EMR fills a fleet, and what it does when none of the
types is available, is AWS's documented behaviour and was not run here.

## Which one to use

**Use instance groups while one instance type is easy to get**, which in practice means on-demand
core nodes and a small cluster. Use fleets when the cluster leans on Spot, because Spot is a set of
pools, one per type and zone, and a cluster that can take any of three types is one that rarely
waits. Either way the decision is made at creation: a cluster built with groups stays with groups.

Both kinds can change size while they run, and the call for groups is the one most clusters use:

```
ana@laptop:~/aws$ aws emr modify-instance-groups --cluster-id j-F34XLF93AZT13 --instance-groups InstanceGroupId=i-4F6BZBCG9FX54,InstanceCount=4
ana@laptop:~/aws$ aws emr describe-cluster --cluster-id j-F34XLF93AZT13 --query 'Cluster.InstanceGroups[].[InstanceGroupType,RequestedInstanceCount,RunningInstanceCount]' --output text
CORE	4	4
TASK	4	4
MASTER	1	1
```

The core group went from two nodes to four in one call. On AWS that takes the minutes two more machines
take to boot and join, and shrinking it again takes longer, because HDFS moves the departing nodes'
blocks first. EMR's **managed scaling** does both on its own, between limits you set, from what YARN
reports it needs. moto changed the number on the line.
