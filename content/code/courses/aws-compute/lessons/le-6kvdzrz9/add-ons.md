---
title: Add-ons, the software every node needs
version: 1
---

A control plane and three nodes are not yet a cluster a pod can live in. A pod needs an address,
Services need rules on every node that send traffic to the right pod, and names like
`orders.default.svc` need a DNS server. **None of that is in the control plane.** Three programs
do it, and they run on your nodes, beside your pods:

| add-on | what it does | how it runs |
|---|---|---|
| `vpc-cni` | gives each pod an address from the VPC | one pod on every node, as a DaemonSet called `aws-node` |
| `kube-proxy` | writes the rules that make a Service's address reach its pods | one pod on every node |
| `coredns` | answers DNS for names inside the cluster | a Deployment, two pods by default |

When a cluster is created through the API, EKS installs these three on its own, as plain
Kubernetes objects. AWS's API reference names them as the default networking add-ons and says
`--no-bootstrap-self-managed-addons` leaves them out, for a team that brings its own network
plugin. Two more are common enough to name: `aws-ebs-csi-driver`, which turns a Kubernetes volume
claim into an EBS volume of lesson 3, and `eks-pod-identity-agent`, which lesson 13 uses.

## Managed add-ons, which moto does not have

Installed that way, the three are yours to upgrade with `kubectl`, and the version that suits a
given Kubernetes version is yours to find. **As EKS add-ons**, AWS publishes which versions of each
work with which Kubernetes version, and installs and upgrades them through the EKS API. That API
is the part of EKS moto 5.2.3 does not implement:

```
ana@laptop:~/aws$ aws eks list-addons --cluster-name shop

aws: [ERROR]: An error occurred (404) when calling the ListAddons operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

Every add-on call answers that 404, so what follows is taken from AWS's documentation and **was
not run**. On AWS, these are the three calls:

```sh
aws eks describe-addon-versions --addon-name vpc-cni --kubernetes-version 1.35 \
  --query 'addons[0].addonVersions[0].addonVersion'
aws eks create-addon --cluster-name shop --addon-name vpc-cni --resolve-conflicts OVERWRITE
aws eks update-addon --cluster-name shop --addon-name vpc-cni --addon-version <the version above>
```

The first asks which versions exist for 1.35. The second takes over the copy that is already on
the cluster, and `--resolve-conflicts` says what to do where the running copy was configured
differently from EKS's defaults. `OVERWRITE` replaces those values with EKS's, and `NONE` changes
nothing and lets the call fail when they differ. `PRESERVE` keeps your values, and AWS documents
that it behaves differently on an update. **An EKS add-on still changes only when you ask**: AWS
publishes the versions, and choosing one is the cluster owner's job, which the next section puts
on a calendar.

## What the network plugin decides: how many pods fit on a node

`vpc-cni` gives every pod a real address in the VPC, taken from the network interfaces of its
node. So the number of pods a node can hold is set by the instance type, through two numbers EC2
publishes for each type, and moto carries AWS's catalogue of them:

```
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types t3.medium m7g.large c7g.xlarge --query 'InstanceTypes[].[InstanceType,NetworkInfo.MaximumNetworkInterfaces,NetworkInfo.Ipv4AddressesPerInterface]' --output text
c7g.xlarge	4	15
m7g.large	3	10
t3.medium	3	6
ana@laptop:~/aws$ aws ec2 describe-instance-types --instance-types t3.medium m7g.large c7g.xlarge --query 'InstanceTypes[].[InstanceType,NetworkInfo.MaximumNetworkInterfaces,NetworkInfo.Ipv4AddressesPerInterface]' --output text | awk '{ print $1, $2 * ($3 - 1) + 2 }'
c7g.xlarge 58
m7g.large 29
t3.medium 17
```

The second command applies the formula AWS documents for the default configuration: **interfaces
× (addresses per interface − 1) + 2.** Each interface keeps one address for itself, and the two
added at the end are pods that use the node's own address, such as `kube-proxy` and `aws-node`
themselves. An `m7g.large` holds 29 pods however little each one asks for, and a `t3.medium` 17.
A cluster of small instances full of small pods runs out of addresses long before it runs out of
processor.

Two things move that limit, both described by AWS and neither run here. One is **prefix
delegation**, where `vpc-cni` puts a block of 16 addresses in each slot of an interface where one address used to
go. The other is the subnet itself, whose size caps how many pods the whole cluster can address.

## Add-ons call AWS too

`vpc-cni` creates network interfaces and `aws-ebs-csi-driver` creates volumes, so both need IAM
permissions. Putting them on the node role works and gives every pod on the node the same
permissions as the plugin. The better place is a role for the add-on alone, which EKS attaches to
its service account, and that mechanism is the whole of lesson 13.
