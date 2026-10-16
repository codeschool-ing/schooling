---
title: MSK provisioned, Serverless and Connect
version: 1
---

**MSK runs the brokers; you still run Kafka.** That is the sentence to hold on to, because it is
the difference from Kinesis. AWS provisions the machines, the disks and the KRaft controllers,
replaces a broker that fails and upgrades Kafka when asked. Topics, partitions, replication factors,
retention, consumer groups and the arithmetic of how many brokers carry the load stay yours, exactly
as in the last two sections.

## Provisioned

A provisioned cluster is a number of brokers of one instance type, spread over two or three
Availability Zones, with an EBS volume each. **The number of brokers is a multiple of the number of
zones**, because MSK places them evenly: three brokers in three zones, six in three, and so on. The
broker type sets the CPU, memory and network, from the small `kafka.t3.small`, which AWS offers for
development, to the `m7g` family and larger. Storage is per broker, in GB, and can be raised later but
not lowered, and **tiered storage** moves older segments off the brokers' disks into storage AWS
manages, at a lower price per GB, so that a long retention does not need large disks.

In moto, as everywhere in this course, the request is recorded and nothing runs:

```
ana@laptop:~/aws$ aws kafka create-cluster --cluster-name quitanda-events --kafka-version 3.9.x --number-of-broker-nodes 3 --broker-node-group-info "InstanceType=kafka.m7g.large,ClientSubnets=subnet-a,subnet-b,subnet-c,StorageInfo={EbsStorageInfo={VolumeSize=200}}"
{
    "ClusterArn": "arn:aws:kafka:sa-east-1:123456789012:cluster/dd814fa6-0bb8-4ebc-bbf5-e49ecd74ab98",
    "ClusterName": "quitanda-events",
    "State": "CREATING"
}
ana@laptop:~/aws$ aws kafka describe-cluster --cluster-arn arn:aws:kafka:sa-east-1:123456789012:cluster/dd814fa6-0bb8-4ebc-bbf5-e49ecd74ab98 --query 'ClusterInfo.[State,NumberOfBrokerNodes,BrokerNodeGroupInfo.InstanceType,ZookeeperConnectString]'
[
    "CREATING",
    3,
    "kafka.m7g.large",
    "zookeeper.example.com:2181"
]
ana@laptop:~/aws$ aws kafka get-bootstrap-brokers --cluster-arn arn:aws:kafka:sa-east-1:123456789012:cluster/dd814fa6-0bb8-4ebc-bbf5-e49ecd74ab98

aws: [ERROR]: An error occurred (500) when calling the GetBootstrapBrokers operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
ana@laptop:~/aws$ aws kafka create-cluster-v2 --cluster-name quitanda-events-sls --serverless "VpcConfigs=[{SubnetIds=[subnet-a,subnet-b,subnet-c]}]"
{
    "ClusterArn": "arn:aws:kafka:sa-east-1:123456789012:serverless-cluster/39e68554-d99b-4282-bd49-bc5ba257c913",
    "ClusterName": "quitanda-events-sls",
    "State": "CREATING",
    "ClusterType": "SERVERLESS"
}
ana@laptop:~/aws$ aws kafka list-clusters-v2 --query 'ClusterInfoList[].[ClusterName,ClusterType,State]' --output text
quitanda-events	PROVISIONED	CREATING
quitanda-events-sls	SERVERLESS	CREATING
ana@laptop:~/aws$ aws kafkaconnect list-connectors

aws: [ERROR]: An error occurred (500) when calling the ListConnectors operation (reached max retries: 2): <!doctype html>
<html lang=en>
<title>500 Internal Server Error</title>
<h1>Internal Server Error</h1>
<p>The server encountered an internal error and was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>
```

**`CREATING`, and it will stay `CREATING`.** moto made no broker, and the cluster has no address to
connect to: `get-bootstrap-brokers`, the call that returns the brokers' addresses, failed inside moto
with a 500. The `ZookeeperConnectString` it printed, `zookeeper.example.com:2181`, is a placeholder
moto fills in, naming a host that does not exist. On AWS a new cluster takes some minutes to reach
`ACTIVE`, and the subnets have to be real ones, one per zone, which moto did not check: `subnet-a`
is not a subnet id. So the MSK half of this lesson is the API's shape and nothing more, and the Kafka
half, the broker of the earlier section, is where the behaviour was seen.

## Serverless

**MSK Serverless is Kafka with no brokers to choose.** There is no instance type and no disk: AWS
sizes the cluster from the traffic, and bills per cluster-hour, per partition-hour and per GB in and
out. It speaks the Kafka protocol, so clients do not change. And it puts limits where a provisioned cluster puts choices: AWS documents caps on the throughput of each partition and of the cluster, on
the number of partitions, and on how long records are kept, and a workload that outgrows them goes
back to provisioned. It also requires IAM authentication from its clients, which is the identity
model of `aws-foundations` lessons 6 to 9 applied to a Kafka connection.

## Connect

**MSK Connect runs Kafka Connect for you**: the framework of ready-made connectors that move data
between Kafka and other systems without a program of your own. A source connector reads a database's
change log into a topic, which is lesson 26's subject, and a sink connector writes a topic into S3,
which is what Firehose did for Kinesis in lesson 21. You choose a connector, upload its plugin and say how many workers run it, and the workers' capacity is billed by the hour. moto does not imitate it usefully: the last command above, `list-connectors`, failed with the same internal error, so nothing of MSK Connect is shown here.
