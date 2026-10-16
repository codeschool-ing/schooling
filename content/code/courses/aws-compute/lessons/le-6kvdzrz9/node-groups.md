---
title: Node groups, and the machines that are yours
version: 1
---

A new EKS cluster has no nodes. People expect it to arrive with some, since a Kubernetes cluster
on a laptop does, and the first pod they create waits in `Pending` with nowhere to run. **The
machines are a separate decision, made in your account and billed at EC2's prices.** There are
four ways to make it: a managed node group, a self-managed group of instances, Fargate, and
Karpenter. This section is the first two, and lesson 12 is the other two.

## The node role

Every node calls AWS: to join the cluster, to pull images from ECR, and to give pods addresses in
the VPC. It does that as a role that EC2 may assume, so the trust policy names
`ec2.amazonaws.com`. The file `eks-node-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name eks-node --assume-role-policy-document file://eks-node-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/eks-node"
ana@laptop:~/aws$ aws iam attach-role-policy --role-name eks-node --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws: [ERROR]: An error occurred (NoSuchEntity) when calling the AttachRolePolicy operation: Policy arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy does not exist or is not attachable.
```

AWS documents three managed policies for that role: `AmazonEKSWorkerNodePolicy` to join the
cluster, `AmazonEC2ContainerRegistryReadOnly` to pull from ECR, which is lesson 10's repository
seen from the other side, and `AmazonEKS_CNI_Policy` for the network plugin of the next section.
**moto does not carry those three policies**, so attaching the first one fails with `NoSuchEntity`
here and succeeds on AWS. Nothing below depends on it, because moto evaluates no policy anyway.

## A managed node group

A managed node group is an Auto Scaling group that EKS creates and looks after. It chooses the
image, launches the instances and joins them to the cluster. When you ask for a new version, it
replaces them one batch at a time.

```
ana@laptop:~/aws$ aws eks create-nodegroup --cluster-name shop --nodegroup-name general --node-role arn:aws:iam::123456789012:role/eks-node --subnets ${SUBNETS/,/ } --instance-types m7g.large --ami-type AL2023_ARM_64_STANDARD --scaling-config minSize=2,maxSize=6,desiredSize=3 --update-config maxUnavailable=1 --labels role=general
{
    "nodegroup": {
        "nodegroupName": "general",
        "nodegroupArn": "arn:aws:eks:sa-east-1:123456789012:nodegroup/shop/general/81031e92-98fd-4871-8837-769815e73c44",
        "clusterName": "shop",
        "version": "1.19",
        "releaseVersion": "1.19.8-20210414",
        "createdAt": "2026-10-16T13:37:35.899000-03:00",
        "modifiedAt": "2026-10-16T13:37:35.899000-03:00",
        "status": "ACTIVE",
        "capacityType": "ON_DEMAND",
        "scalingConfig": {
            "minSize": 2,
            "maxSize": 6,
            "desiredSize": 3
        },
        "instanceTypes": [
            "m7g.large"
        ],
        "subnets": [
            "subnet-0d907af99bed87115",
            "subnet-669c66a4048b76897"
        ],
        "remoteAccess": {
            "ec2SshKey": "eksKeypair"
        },
        "amiType": "AL2023_ARM_64_STANDARD",
        "nodeRole": "arn:aws:iam::123456789012:role/eks-node",
        "labels": {
            "role": "general"
        },
        "taints": [],
        "resources": {
            "autoScalingGroups": [
                {
                    "name": "eks-81031e92-98fd-4871-8837-769815e73c44"
                }
            ],
            "remoteAccessSecurityGroup": "sg-r8ylvhzzz2m3o9ipy"
        },
        "diskSize": 20,
        "health": {
            "issues": []
        },
        "tags": {}
    }
}
```

The request is the part to read. `--scaling-config` is the three numbers of lesson 4's group:
never fewer than 2 nodes, never more than 6, and 3 now. `--update-config maxUnavailable=1` says
that a version update may take one node out of service at a time. `--ami-type
AL2023_ARM_64_STANDARD` is Amazon Linux 2023 for Arm, which is what an `m7g.large` needs, and
`--labels` puts `role=general` on every node, so a pod can ask to be scheduled there.

**The answer is moto's in four places**, and each is worth knowing:

- **`version` is `1.19` and `releaseVersion` is from 2021**, on a cluster of version 1.35. Those
  are moto's fixed values. AWS's API reference says a node group can only be created at the
  cluster's own Kubernetes version, with the latest image released for it.
- **`remoteAccess` names a key pair, `eksKeypair`, that the request never mentioned.** moto adds
  it; on AWS a node group has SSH access only if you ask for it.
- **There is no `updateConfig`** in the answer, although the request carried one.
- **`resources.autoScalingGroups` names a group that does not exist.** On AWS that is the real
  Auto Scaling group, with three instances in it. In moto nothing was launched:

```
ana@laptop:~/aws$ aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName'
[]
ana@laptop:~/aws$ aws ec2 describe-instances --query 'length(Reservations[].Instances[])'
0
```

Changing the size is a call to EKS rather than to the Auto Scaling group, because the group is
EKS's to manage:

```
ana@laptop:~/aws$ aws eks update-nodegroup-config --cluster-name shop --nodegroup-name general --scaling-config minSize=2,maxSize=8,desiredSize=4 --query update.[type,status]
[
    "ConfigUpdate",
    "Successful"
]
```

On AWS the update is `InProgress` for a while before it is `Successful`, and the instances arrive
as lesson 4 described. Lesson 12 is about what changes `desiredSize` on its own when pods are
waiting for room.

moto also accepts a group that AWS would refuse, with a minimum above its maximum:

```
ana@laptop:~/aws$ aws eks create-nodegroup --cluster-name shop --nodegroup-name wrong --node-role arn:aws:iam::123456789012:role/eks-node --subnets ${SUBNETS/,/ } --scaling-config minSize=5,maxSize=2,desiredSize=9 --query nodegroup.[status,scalingConfig]
[
    "ACTIVE",
    {
        "minSize": 5,
        "maxSize": 2,
        "desiredSize": 9
    }
]
ana@laptop:~/aws$ aws eks delete-nodegroup --cluster-name shop --nodegroup-name wrong --query nodegroup.nodegroupName
"wrong"
```

That is a reminder of the lab's limit rather than a feature: **moto checks much less than AWS**,
so a configuration that moto accepts has not been validated by anybody.

## Spot, and several instance types

A node group can run on spot capacity, the discount of lesson 6, and spread itself over several
instance types of the same size, so that one type running short does not stop the group growing:

```
ana@laptop:~/aws$ aws eks create-nodegroup --cluster-name shop --nodegroup-name spot --node-role arn:aws:iam::123456789012:role/eks-node --subnets ${SUBNETS/,/ } --capacity-type SPOT --instance-types m7g.large c7g.large r7g.large --scaling-config minSize=0,maxSize=10,desiredSize=2 --query nodegroup.[capacityType,instanceTypes]
[
    "SPOT",
    [
        "m7g.large",
        "c7g.large",
        "r7g.large"
    ]
]
```

Kubernetes reschedules the pods of a node that spot takes back, which makes stateless workloads a
good fit, and a team commonly keeps one on-demand group for what must not move and one spot group
for everything else. The two groups are why the cluster now refuses to be deleted:

```
ana@laptop:~/aws$ aws eks delete-cluster --name shop

aws: [ERROR]: An error occurred (ResourceInUseException) when calling the DeleteCluster operation: Cluster has nodegroups attached

Additional error details:
clusterName: shop
nodegroupName: general,spot
```

AWS answers the same way: node groups are deleted first, and the cluster after them.

## Managed or self-managed

A self-managed group is lesson 4 applied to Kubernetes: your own launch template, your own Auto
Scaling group, and a bootstrap script in the user data that joins each instance to the cluster.
Nothing in it is hidden, and nothing in it is done for you.

| | managed node group | self-managed group |
|---|---|---|
| who creates the Auto Scaling group | EKS | you |
| the image | EKS's latest for the version, or your own through a launch template | yours to choose and to patch |
| a version update | one call; EKS drains and replaces the nodes in batches | your instance refresh, and your draining |
| what it costs | the EC2 instances, nothing on top | the EC2 instances |

**Managed node groups cost nothing beyond the instances**, so the reason to manage your own is a
need the managed kind cannot meet, such as an operating system EKS does not offer, rather than
money.
