---
title: Fargate profiles, one pod to a machine
version: 1
---

The usual guess about EKS on Fargate is a node group of large invisible machines that AWS shares
out among your pods. **Each pod runs alone, on a small virtual machine of its own, sized to that
pod and started for it.** Kubernetes sees it as a node, named after its address, that holds exactly
one pod and disappears with it. There is no node to patch, scale or pay for while it sits empty,
and which pods go there is decided by a **Fargate profile**.

Lesson 9 met Fargate under ECS. The machines are the same; what changes is that Kubernetes asks
for them, one pod at a time.

## The pod execution role

The machine Fargate starts has to pull the pod's image and register itself with the cluster as a
node, and it does both as a role that trusts the Fargate service for EKS. The cluster `shop` and its
role are lesson 11's, made again in this lesson's empty moto. The trust policy, as
`eks-fargate-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks-fargate-pods.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name eks-fargate-pods --assume-role-policy-document file://eks-fargate-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/eks-fargate-pods"
```

On AWS the role carries the managed policy `AmazonEKSFargatePodExecutionRolePolicy`, which allows
the image pull from ECR. **It is the machine's role and not the pod's**: what the program inside
the pod may do in AWS is a role of its own, and lesson 13 gives it one.

## A profile is a set of selectors

```
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ' ')
ana@laptop:~/aws$ aws eks create-fargate-profile --cluster-name shop --fargate-profile-name batch --pod-execution-role-arn arn:aws:iam::123456789012:role/eks-fargate-pods --subnets $SUBNETS --selectors 'namespace=reports,labels={compute=fargate}' namespace=jobs
{
    "fargateProfile": {
        "fargateProfileName": "batch",
        "fargateProfileArn": "arn:aws:eks:sa-east-1:123456789012:fargateprofile/shop/batch/ec9bf9b6-871b-4e81-b159-82e09548f58c",
        "clusterName": "shop",
        "createdAt": "2026-10-16T13:50:27.165000-03:00",
        "podExecutionRoleArn": "arn:aws:iam::123456789012:role/eks-fargate-pods",
        "subnets": [
            "subnet-dca5f8059ad9521e6",
            "subnet-0c3c8eb9dad5738a3"
        ],
        "selectors": [
            {
                "namespace": "reports",
                "labels": {
                    "compute": "fargate"
                }
            },
            {
                "namespace": "jobs"
            }
        ],
        "status": "ACTIVE",
        "tags": {}
    }
}
```

A selector is a namespace, and optionally labels. **A pod is sent to Fargate if it matches any
selector of any profile**, and it matches a selector when it is in that namespace and carries every
label the selector names. So with this profile:

- a pod in `jobs` runs on Fargate, whatever its labels;
- a pod in `reports` runs on Fargate only if it carries `compute: fargate`;
- a pod in any other namespace goes to the nodes of a node group, as in lesson 11.

The decision is made when the pod is created. EKS puts its own scheduler in charge of every pod a
profile matches, and an existing pod does not move when a profile appears.

**moto accepted the default VPC's subnets, and AWS would not.** AWS's API reference says a pod on
Fargate gets no public address, so only private subnets, with no route to an internet gateway, are
accepted for a profile. The default VPC's subnets are public. On AWS these would be the private
subnets of `aws-foundations` lesson 16, and the pods would reach the internet through its NAT
gateway. moto also takes more selectors than AWS allows:

```
ana@laptop:~/aws$ aws eks create-fargate-profile --cluster-name shop --fargate-profile-name many --pod-execution-role-arn arn:aws:iam::123456789012:role/eks-fargate-pods --subnets $SUBNETS --selectors namespace=a namespace=b namespace=c namespace=d namespace=e namespace=f --query 'length(fargateProfile.selectors)'
6
ana@laptop:~/aws$ aws eks delete-fargate-profile --cluster-name shop --fargate-profile-name many --query fargateProfile.fargateProfileName
"many"
```

AWS documents a limit of **five selectors per profile**, and refuses the sixth.

## A profile cannot be edited

A profile has no update operation, and the command line says so before any request leaves the
machine:

```
ana@laptop:~/aws$ aws eks update-fargate-profile --cluster-name shop --fargate-profile-name batch

aws: [ERROR]: An error occurred (ParamValidation): argument operation: Found invalid choice 'update-fargate-profile'

Maybe you meant:

  * delete-fargate-profile
  * create-fargate-profile

usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help
ana@laptop:~/aws$ aws eks list-fargate-profiles --cluster-name shop
{
    "fargateProfileNames": [
        "batch"
    ]
}
```

AWS documents profiles as immutable. To change one you create a new profile with the new
selectors, wait for it to be `ACTIVE`, and delete the old one. Pods already running stay where they
are until they are next created.

## What a pod costs on Fargate

Fargate charges for the vCPU and memory of the machine, and **the machine is sized from the pod's
requests, plus 256 MB** that AWS documents as the memory of the Kubernetes components on it:
kubelet, kube-proxy and containerd. The total is then rounded up to the nearest of Fargate's
combinations, the ones lesson 9 listed:

| vCPU | memory |
|---|---|
| 0.25 | 0.5, 1 or 2 GB |
| 0.5 | 1 to 4 GB, by 1 GB |
| 1 | 2 to 8 GB, by 1 GB |
| 2 | 4 to 16 GB, by 1 GB |
| 4 | 8 to 30 GB, by 1 GB |

The prices on the sheet of lesson 1, published on 16 October 2026:

```
ana@laptop:~/aws$ python3 prices.py containers | grep -A5 "^Fargate"
Fargate
  vCPU, x86                                       0.0696  per hour
  memory, x86                                     0.0076  per GB-hour
  vCPU, Arm                                       0.0557  per hour
  memory, Arm                                    0.00612  per GB-hour
  ephemeral storage above 20 GB                 0.000211  per GB-hour
ana@laptop:~/aws$ python3 prices.py ec2 | grep -E 'c7g.large|m7i.2xlarge'
  c7g.large    2 vCPU   4 GiB  EBS only           0.1111  per hour
  m7i.2xlarge  8 vCPU  32 GiB  EBS only           0.6426  per hour
```

A pod that requests 0.5 vCPU and 1 GiB is sized at 1 GiB plus 256 MB, about 1.25 GB, which rounds
up to **0.5 vCPU and 2 GB**. At the x86 prices that is 0.5 × 0.0696 + 2 × 0.0076 = 0.05 USD an hour,
36.50 USD for a month of 730 hours, for a pod whose requests alone would have fitted in the
0.5 vCPU and 1 GB machine. **Requests are what you pay for on Fargate**, so a pod that asks for far
more than it uses wastes money in a way it does not on a node it shares.

## What does not run there

A Fargate pod is alone on its machine and has no access to the machine's host, and AWS documents
what follows from that:

- **DaemonSets** do not run: there is no node of yours to put one on. A log or monitoring agent
  becomes a sidecar container in the pod instead.
- **Privileged containers, `hostNetwork` and `hostPort`** are refused.
- **No EBS volumes and no GPUs.** EFS, lesson 3's shared file system, can be mounted.
- A load balancer reaches the pod by its IP address, so its target type is `ip`.

One more is easy to miss. CoreDNS is created with an annotation that keeps it on EC2 nodes, so a
cluster with **no** node group has nowhere to run its DNS until a profile selects `kube-system` and
that annotation is removed. AWS's guide to a Fargate-only cluster gives the patch. None of this was
run here: moto stores the profile and schedules no pod at all.
