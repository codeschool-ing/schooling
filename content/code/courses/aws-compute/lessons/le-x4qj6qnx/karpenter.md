---
title: Karpenter, which chooses the machine for the pods
version: 1
---

A node group fixes the machine before anyone knows what will run on it: `m7g.large`, between 2 and 6
of them. When pods arrive that need something else, the group can only add more of the same.
**Karpenter starts from the other end. It looks at the pods that cannot be scheduled, works out
what machine would hold them, and asks EC2 for that machine directly**, with no Auto Scaling group
in between. It is an open-source project that AWS started, and it runs inside the cluster as an
ordinary Deployment.

Nothing in this section was run against a cluster, because moto runs no Kubernetes and Karpenter
has nowhere to run. The two files are shown whole, as Karpenter's documentation describes them, and
the one AWS call Karpenter makes is run against moto further down.

## What it may buy: the NodePool

```schooling-example
{"language": "yaml", "file": "nodepool.yaml", "parts": [{"code": "apiVersion: karpenter.sh/v1\nkind: NodePool\nmetadata:\n  name: general\n", "note": "A NodePool is a Kubernetes object that Karpenter reads, in the API group `karpenter.sh/v1`. A cluster can hold several, one for each kind of node a team wants to keep apart."}, {"code": "spec:\n  template:\n    metadata:\n      labels:\n        role: general\n    spec:\n      nodeClassRef:\n        group: karpenter.k8s.aws\n        kind: EC2NodeClass\n        name: shop\n", "note": "What every node it creates will look like: the label `role: general`, and a reference to the EC2NodeClass below, which holds the AWS half of the description."}, {"code": "      requirements:\n        - key: kubernetes.io/arch\n          operator: In\n          values: [\"arm64\"]\n        - key: karpenter.k8s.aws/instance-category\n          operator: In\n          values: [\"c\", \"m\", \"r\"]\n        - key: karpenter.k8s.aws/instance-generation\n          operator: Gt\n          values: [\"6\"]\n", "note": "**The requirements are a range, not a type.** Any Arm instance of the compute, general or memory families, from the seventh generation on. Karpenter chooses inside that range for each batch of pending pods."}, {"code": "        - key: karpenter.sh/capacity-type\n          operator: In\n          values: [\"spot\", \"on-demand\"]\n", "note": "Spot and on-demand are both allowed. Karpenter tries spot first, and falls back to on-demand when spot cannot supply what the pods need."}, {"code": "      expireAfter: 720h\n", "note": "Every node is replaced after 30 days, so no node lives long enough to drift far from the current image."}, {"code": "  limits:\n    cpu: \"64\"\n", "note": "A ceiling: the pool never holds more than 64 vCPUs in all, whatever is pending. It is the guard against a runaway deployment buying machines all night."}, {"code": "  disruption:\n    consolidationPolicy: WhenEmptyOrUnderutilized\n    consolidateAfter: 1m\n    budgets:\n      - nodes: \"10%\"\n", "note": "**Consolidation** is Karpenter removing or replacing nodes that are empty or underused, a minute after it notices. The budget lets it disrupt at most a tenth of the nodes at once."}]}
```

The difference from lesson 11 is in the third part. A node group names the instance type; a
NodePool names **a set of acceptable types**, and leaves the choice to the moment there are pods to
place. Ten pods asking for 250 millicores each might get one `c7g.xlarge`. One pod asking for 30 GiB
might get an `r7g.xlarge`. Both choices come from the same file.

## How it is built: the EC2NodeClass

```schooling-example
{"language": "yaml", "file": "ec2nodeclass.yaml", "parts": [{"code": "apiVersion: karpenter.k8s.aws/v1\nkind: EC2NodeClass\nmetadata:\n  name: shop\nspec:\n", "note": "The EC2NodeClass is the AWS side: the role, image, subnets and security groups a node gets. It is the part of a launch template Karpenter needs from you."}, {"code": "  role: KarpenterNodeRole-shop\n", "note": "The IAM role its nodes run as, the node role of lesson 11 under another name."}, {"code": "  amiSelectorTerms:\n    - alias: al2023@latest\n", "note": "The image: the latest Amazon Linux 2023 that EKS publishes for the cluster's version. An alias that names one release in place of `latest` is how a team stops new nodes picking up a new image on their own."}, {"code": "  subnetSelectorTerms:\n    - tags:\n        karpenter.sh/discovery: shop\n  securityGroupSelectorTerms:\n    - tags:\n        karpenter.sh/discovery: shop\n", "note": "Subnets and security groups are found by tag rather than listed by id, so adding a subnet means tagging it, and nothing in this file changes."}]}
```

The two files split one description: the NodePool says what the nodes are for and how far Karpenter
may go, and the EC2NodeClass says how to build one on AWS. A cluster can pair several NodePools with
one EC2NodeClass.

## The call it makes

To see what "a set of acceptable types" amounts to, ask EC2's catalogue, which moto carries. This
is the slice of the NodePool's range with up to four vCPUs, the seventh generation only; the range
itself goes further, to bigger sizes and newer generations:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --filters Name=processor-info.supported-architecture,Values=arm64 Name=instance-type,Values='c7g.*,m7g.*,r7g.*' Name=bare-metal,Values=false --query 'InstanceTypes[?VCpuInfo.DefaultVCpus<=`4`].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]' --output text | sort -k2n -k3n
c7g.medium	1	2048
m7g.medium	1	4096
r7g.medium	1	8192
c7g.large	2	4096
m7g.large	2	8192
r7g.large	2	16384
c7g.xlarge	4	8192
m7g.xlarge	4	16384
r7g.xlarge	4	32768
```

Karpenter filters a list like this against the pending pods' requests, keeps the types that would
hold them, and then launches with **one EC2 call, `CreateFleet` of type `instant`**, offering several
of those types at once and letting EC2 pick by price and spare capacity. The same call against moto,
with three types on offer and spot capacity asked for:

```
ana@laptop:~/aws$ aws ec2 create-launch-template --launch-template-name karpenter-shop --launch-template-data '{"ImageId":"ami-0c55b159cbfafe1f0"}' --query LaunchTemplate.LaunchTemplateName
"karpenter-shop"
ana@laptop:~/aws$ SUBNET=$(aws ec2 describe-subnets --query 'Subnets[0].SubnetId' --output text)
ana@laptop:~/aws$ aws ec2 create-fleet --type instant --target-capacity-specification TotalTargetCapacity=3,DefaultTargetCapacityType=spot --spot-options AllocationStrategy=price-capacity-optimized --launch-template-configs '[{"LaunchTemplateSpecification":{"LaunchTemplateName":"karpenter-shop","Version":"$Latest"},"Overrides":[{"InstanceType":"c7g.large","SubnetId":"'$SUBNET'"},{"InstanceType":"m7g.large","SubnetId":"'$SUBNET'"},{"InstanceType":"c7g.xlarge","SubnetId":"'$SUBNET'"}]}]' --query 'Instances[].[InstanceType,Lifecycle,InstanceIds[0]]' --output text
c7g.large	spot	i-cf2c912e0dda2e6ec
c7g.large	spot	i-20478a7be6e9ca369
c7g.large	spot	i-0165628e333d62bf3
ana@laptop:~/aws$ aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceType,InstanceLifecycle,Placement.AvailabilityZone]' --output text
c7g.large	spot	sa-east-1a
c7g.large	spot	sa-east-1a
c7g.large	spot	sa-east-1a
```

**On AWS the strategy `price-capacity-optimized` picks among the three types**, weighing the spot
price of each against how much spare capacity its pool has, which is how lesson 6 said spot
interruptions are best avoided. moto gave all three instances the first type in the list and put
them in one zone. It accepted the request and returned instances; the choice it made is not a
choice AWS would make, and nothing here measures one.

## Consolidation, and spot

A Cluster Autoscaler removes a node only when it is nearly empty. **Karpenter also replaces nodes
that are merely badly packed.** With `consolidationPolicy: WhenEmptyOrUnderutilized` it keeps asking
whether the pods on two half-empty nodes would fit on one, or on a cheaper type, and when they would,
it starts the new node, moves the pods, and terminates the old ones. The `budgets` line limits how
much of the pool is being disrupted at once, and a PodDisruptionBudget, from lesson 11, limits it per
workload. So consolidation saves money by moving pods, and a workload that cannot stand being moved
has to say so.

Spot interruptions are the other source of moving pods. Karpenter can listen on an SQS queue fed by
the EventBridge events of lesson 6, the two-minute warning among them, and drain a node before EC2
takes it back. That queue is set up when Karpenter is installed, beside the IAM role it uses to
call EC2.

## Where it runs, and EKS Auto Mode

Karpenter's own pods need a node, and a node Karpenter manages could be consolidated away from
under them. So it runs on capacity it does not manage: a small managed node group of lesson 11, or a
Fargate profile from the previous section that selects its namespace.

**EKS Auto Mode**, which AWS added in December 2024, is Karpenter run by AWS: the cluster comes with
NodePools already defined, and AWS operates the controller, the node images and the add-ons of
lesson 11 that run on those nodes. It charges a fee per instance on top of EC2's price, which is not
on the course's price sheet. The NodePool above is the same kind of object Auto Mode uses, so what
this section describes is what Auto Mode does on your behalf.
