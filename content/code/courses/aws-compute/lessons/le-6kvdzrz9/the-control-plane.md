---
title: The control plane, and what AWS runs for its price
version: 1
---

"Managed Kubernetes" sounds like Kubernetes that somebody else runs, all of it. **EKS manages one
half: the control plane.** The API server, etcd where the cluster's state is kept, the scheduler
and the controllers run in an account AWS owns, spread over three Availability Zones, patched and
kept available by AWS. The machines your pods run on, the software those machines need, and the
decision to move to a new Kubernetes version are yours. This lesson is about the line between the
two halves, and the three sections after this one are the half on your side.

## A cluster is a role and two subnets

EKS acts in your account on the cluster's behalf: it places network interfaces in your subnets and
reads what it needs about them. It does that as an IAM role that trusts the service, the pattern
`aws-foundations` lesson 9 introduced. The trust policy, saved as `eks-cluster-trust.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "eks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-role --role-name eks-cluster --assume-role-policy-document file://eks-cluster-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/eks-cluster"
```

On AWS the role also carries the managed policy `AmazonEKSClusterPolicy`, which is what lets EKS
manage those network interfaces. The cluster needs **at least two subnets, in different zones**,
which AWS's API reference states as a requirement. moto's default VPC has one subnet per zone of
São Paulo, and the second command keeps the first two in a variable:

```
ana@laptop:~/aws$ aws ec2 describe-subnets --query 'Subnets[].[SubnetId,AvailabilityZone,CidrBlock]' --output text
subnet-0d907af99bed87115	sa-east-1a	172.31.0.0/20
subnet-669c66a4048b76897	sa-east-1b	172.31.16.0/20
subnet-8803a7cf9bab445e3	sa-east-1c	172.31.32.0/20
ana@laptop:~/aws$ SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')
```

Then the cluster itself. The `--query` keeps four fields of an answer that is mostly a
certificate:

```
ana@laptop:~/aws$ aws eks create-cluster --name shop --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS --query 'cluster.{status: status, version: version, endpoint: endpoint, oidc: identity.oidc.issuer}'
{
    "status": "ACTIVE",
    "version": "1.35",
    "endpoint": "https://9nTAPRX5t1c0ke4JAps5.Aop.sa-east-1.eks.amazonaws.com/",
    "oidc": "https://oidc.eks.sa-east-1.amazonaws.com/id/Dc9oQpztiq"
}
```

**`ACTIVE` at once is moto's.** On AWS a new cluster is `CREATING` for several minutes while the
control plane is built, and a script that creates one waits with `aws eks wait cluster-active`
before doing anything else. The endpoint is a name moto made up and nothing answers on it. On AWS
it is the address of the API server, reached through a Network Load Balancer, and by default it is
public, so a laptop with credentials can reach it. `--resources-vpc-config endpointPrivateAccess=true`
adds a private path from inside the VPC, and `endpointPublicAccess=false` removes the public one.

The `oidc` issuer is the cluster's own identity provider, one per cluster. Lesson 13 hands it to
IAM so that a pod can take a role without a stored key.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Two boxes. On the left, an account AWS manages, holding the control plane: the API server and etcd in three Availability Zones behind a Network Load Balancer, billed at 0.10 USD an hour. On the right, your VPC: network interfaces EKS places in your subnets, and the node groups, Auto Scaling groups of EC2 instances running your pods and the add-ons, billed at EC2's prices.\"><defs><marker id=\"eks-cp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"12\" y=\"12\" width=\"330\" height=\"306\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">an account AWS manages</text><rect x=\"28\" y=\"50\" width=\"96\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zone a</text><rect x=\"36\" y=\"80\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"36\" y=\"112\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"132\" y=\"50\" width=\"96\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zone b</text><rect x=\"140\" y=\"80\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"140\" y=\"112\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"236\" y=\"50\" width=\"96\" height=\"96\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">zone c</text><rect x=\"244\" y=\"80\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">API server</text><rect x=\"244\" y=\"112\" width=\"80\" height=\"26\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"284\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">etcd</text><rect x=\"28\" y=\"164\" width=\"304\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"180\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Network Load Balancer: the endpoint</text><text x=\"180\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">0.10 USD an hour, whatever it runs</text><rect x=\"372\" y=\"12\" width=\"336\" height=\"306\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"386\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">your account and your VPC</text><rect x=\"388\" y=\"50\" width=\"304\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">network interfaces EKS puts in your subnets</text><rect x=\"388\" y=\"130\" width=\"304\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a node group: an Auto Scaling group</text><rect x=\"404\" y=\"166\" width=\"80\" height=\"64\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"444\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"444\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pods</text><rect x=\"500\" y=\"166\" width=\"80\" height=\"64\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pods</text><rect x=\"596\" y=\"166\" width=\"80\" height=\"64\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"636\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">node</text><text x=\"636\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">pods</text><text x=\"540\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">your pods, and the add-ons</text><text x=\"540\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">EC2's price for every node</text><path d=\"M388 200 L334 186\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#eks-cp-ah)\"></path><text x=\"358\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kubelet registers</text><path d=\"M342 66 L386 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#eks-cp-ah)\"></path><text x=\"360\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">exec, logs</text></svg>", "caption": "The line EKS draws. Everything on the left is AWS's to run, patch and keep available, for one hourly price. Everything on the right is in your account: the nodes, what runs on them, and what they cost."}
```

## How kubectl gets in

`kubectl` reads a kubeconfig file, and the AWS command line writes one. `--kubeconfig` keeps it in
the working directory rather than in `~/.kube/config`:

```
ana@laptop:~/aws$ aws eks update-kubeconfig --name shop --kubeconfig ./kubeconfig
Added new context arn:aws:eks:sa-east-1:123456789012:cluster/shop to /home/ana/aws/kubeconfig
ana@laptop:~/aws$ sed -n '/^users:/,$p' kubeconfig
users:
- name: arn:aws:eks:sa-east-1:123456789012:cluster/shop
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - --region
      - sa-east-1
      - eks
      - get-token
      - --cluster-name
      - shop
      - --output
      - json
      command: aws
```

There is no password in it. **The user is a command**: each time `kubectl` needs to authenticate,
it runs `aws eks get-token`, and the token that command prints is the interesting part:

```
ana@laptop:~/aws$ aws eks get-token --cluster-name shop --query status.token --output text | cut -d. -f1
k8s-aws-v1

ana@laptop:~/aws$ aws eks get-token --cluster-name shop --query status.token --output text | cut -c12- | base64 -d 2>/dev/null | cut -d'&' -f1-2
http://localhost:4567/?Action=GetCallerIdentity&Version=2011-06-15
```

After the `k8s-aws-v1` prefix, the token is a pre-signed request to STS's `GetCallerIdentity`,
encoded in base64. The API server sends that request to STS, and STS answers with the identity
that signed it. **A Kubernetes user on EKS is an IAM principal**, so whoever can sign as the role
can reach the cluster, and nobody else can. Here the request points at `localhost:4567`, because
`AWS_ENDPOINT_URL` sends everything to moto; on AWS it is STS's own address.

What that principal may do inside the cluster is a separate grant. EKS's access entries map an IAM
principal to Kubernetes permissions, and moto does not implement them. **None of the `kubectl`
part was run**, and it could not be: moto keeps a record of the cluster and runs no Kubernetes
behind it, so there is no API server for `kubectl` to talk to.

## What the control plane costs

The price sheet of lesson 1, published on 16 October 2026, has two lines for it:

```
ana@laptop:~/aws$ python3 prices.py containers | grep -A3 "EKS and ECR"
EKS and ECR
  EKS cluster, standard support                      0.1  per hour
  EKS extended support, on top of that               0.5  per hour
  ECR storage                                        0.1  per GB-month
```

**A cluster costs 0.10 USD an hour whatever it runs**, empty or full, which is 73 USD for a month
of 730 hours before a single node exists. That is small against the nodes of a busy cluster and
large against the nodes of an idle one. A team that gives each of its ten developers a cluster of
their own pays 730 USD a month for control planes alone, which is why shared clusters with a
namespace per developer are the usual answer. The second line, extended support, belongs to the
section on upgrades.
