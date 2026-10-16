#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of aws-compute (EKS), as a script
# that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-6kvdzrz9/captures.sh  # the moto blocks
#   LAB_HOSTS=1 bash lessons/le-6kvdzrz9/captures.sh prices
#
# Every run starts from an EMPTY moto and the terminal lines of lesson 1's
# section `your-lab`.
#
# What is STAGED rather than typed:
#   - moto is started by the lab before the first command, not in a second
#     terminal;
#   - the two trust policies are written by `put`, which prints them, and the
#     lesson quotes the files as printed: the student writes them with an editor;
#   - `prices` reads prices.py out of lesson 1's `the-price-sheet` and needs the
#     internet, reached through the recording machine's proxy (HTTPS_PROXY),
#     which does not change what AWS publishes.
#
# NOT RUN: there is no Kubernetes behind moto's EKS. A cluster is a record with
# an endpoint name nobody answers on, so kubectl has nothing to talk to and is
# not installed. moto 5.2.3 answers add-ons, cluster upgrades and node group
# upgrades with a 404; the lesson shows that refusal once and teaches the rest
# from AWS's documentation, saying so. Kubernetes version numbers in the
# commands (1.35, 1.36) are examples; which versions AWS offers on a given day
# is what `aws eks describe-cluster-versions` answers on AWS.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
LESSON1=$(cd "$HERE/../le-ps61q5st" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

if [ "${1:-}" = prices ]; then
  export HTTPS_PROXY=$LAB_PROXY
  from_example "$LESSON1/the-price-sheet.md" prices.py > prices.py
  block prices
  run 'python3 prices.py containers | grep -A3 "EKS and ECR"'
  exit 0
fi

block cluster-role
put eks-cluster-trust.json <<'EOF'
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
EOF
run 'aws iam create-role --role-name eks-cluster --assume-role-policy-document file://eks-cluster-trust.json --query Role.Arn'

block subnets
run "aws ec2 describe-subnets --query 'Subnets[].[SubnetId,AvailabilityZone,CidrBlock]' --output text"
run "SUBNETS=\$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\\t' ',')"

block create-cluster
run "aws eks create-cluster --name shop --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=\$SUBNETS --query 'cluster.{status: status, version: version, endpoint: endpoint, oidc: identity.oidc.issuer}'"

block kubeconfig
run 'aws eks update-kubeconfig --name shop --kubeconfig ./kubeconfig'
run "sed -n '/^users:/,\$p' kubeconfig"

block token
run "aws eks get-token --cluster-name shop --query status.token --output text | cut -d. -f1"
run "aws eks get-token --cluster-name shop --query status.token --output text | cut -c12- | base64 -d 2>/dev/null | cut -d'&' -f1-2"

block node-role
put eks-node-trust.json <<'EOF'
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
EOF
run 'aws iam create-role --role-name eks-node --assume-role-policy-document file://eks-node-trust.json --query Role.Arn'
run 'aws iam attach-role-policy --role-name eks-node --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy'

block nodegroup
run "aws eks create-nodegroup --cluster-name shop --nodegroup-name general --node-role arn:aws:iam::123456789012:role/eks-node --subnets \${SUBNETS/,/ } --instance-types m7g.large --ami-type AL2023_ARM_64_STANDARD --scaling-config minSize=2,maxSize=6,desiredSize=3 --update-config maxUnavailable=1 --labels role=general"

block no-asg
run "aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].AutoScalingGroupName'"
run "aws ec2 describe-instances --query 'length(Reservations[].Instances[])'"

block scale
run 'aws eks update-nodegroup-config --cluster-name shop --nodegroup-name general --scaling-config minSize=2,maxSize=8,desiredSize=4 --query update.[type,status]'

block bad-scaling
run "aws eks create-nodegroup --cluster-name shop --nodegroup-name wrong --node-role arn:aws:iam::123456789012:role/eks-node --subnets \${SUBNETS/,/ } --scaling-config minSize=5,maxSize=2,desiredSize=9 --query nodegroup.[status,scalingConfig]"
run 'aws eks delete-nodegroup --cluster-name shop --nodegroup-name wrong --query nodegroup.nodegroupName'

block spot
run "aws eks create-nodegroup --cluster-name shop --nodegroup-name spot --node-role arn:aws:iam::123456789012:role/eks-node --subnets \${SUBNETS/,/ } --capacity-type SPOT --instance-types m7g.large c7g.large r7g.large --scaling-config minSize=0,maxSize=10,desiredSize=2 --query nodegroup.[capacityType,instanceTypes]"

block delete-refused
run 'aws eks delete-cluster --name shop'

block max-pods
run "aws ec2 describe-instance-types --instance-types t3.medium m7g.large c7g.xlarge --query 'InstanceTypes[].[InstanceType,NetworkInfo.MaximumNetworkInterfaces,NetworkInfo.Ipv4AddressesPerInterface]' --output text"
run "aws ec2 describe-instance-types --instance-types t3.medium m7g.large c7g.xlarge --query 'InstanceTypes[].[InstanceType,NetworkInfo.MaximumNetworkInterfaces,NetworkInfo.Ipv4AddressesPerInterface]' --output text | awk '{ print \$1, \$2 * (\$3 - 1) + 2 }'"

block addons-404
run 'aws eks list-addons --cluster-name shop'

block upgrade-404
run 'aws eks update-cluster-version --name shop --kubernetes-version 1.36'

block upgrade-policy
run "aws eks create-cluster --name shop-standard --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=\$SUBNETS --upgrade-policy supportType=STANDARD --query 'cluster.[version,upgradePolicy]'"
run "aws eks create-cluster --name shop-old --kubernetes-version 1.10 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=\$SUBNETS --query 'cluster.[version,status]'"
