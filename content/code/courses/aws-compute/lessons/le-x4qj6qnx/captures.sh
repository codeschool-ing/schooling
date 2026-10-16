#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of aws-compute (EKS on Fargate and
# Karpenter), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS
# OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                     # once, beside course.json
#   bash lessons/le-x4qj6qnx/captures.sh  # the moto blocks
#   LAB_HOSTS=1 bash lessons/le-x4qj6qnx/captures.sh prices
#
# Every run starts from an EMPTY moto and the terminal lines of lesson 1's
# section `your-lab`.
#
# What is STAGED rather than typed:
#   - moto is started by the lab before the first command, not in a second
#     terminal;
#   - the cluster role and the cluster of lesson 11 are made again, quietly,
#     because every run starts from an empty moto: the lesson says lesson 11
#     built them;
#   - the trust policy of the pod execution role is written by `put`, which
#     prints it, and the lesson quotes the file as printed;
#   - `prices` reads prices.py out of lesson 1's `the-price-sheet` and needs the
#     internet, reached through the recording machine's proxy (HTTPS_PROXY),
#     which does not change what AWS publishes.
#
# NOT RUN: there is no Kubernetes behind moto's EKS, so no pod is scheduled on
# Fargate, and Karpenter, which is a program running inside a cluster, has
# nowhere to run. Its NodePool and EC2NodeClass are shown as files and not
# applied. What IS run is the EC2 call Karpenter makes to launch nodes,
# CreateFleet of type instant, against moto, with the prose saying how moto's
# choice of instances differs from AWS's.
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
  run 'python3 prices.py containers | grep -A5 "^Fargate"'
  run "python3 prices.py ec2 | grep -E 'c7g.large|m7i.2xlarge'"
  exit 0
fi

quiet "aws iam create-role --role-name eks-cluster --assume-role-policy-document '{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"eks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}'"
SUBNETS=$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\t' ',')
quiet "aws eks create-cluster --name shop --kubernetes-version 1.35 --role-arn arn:aws:iam::123456789012:role/eks-cluster --resources-vpc-config subnetIds=$SUBNETS"

block pod-role
put eks-fargate-trust.json <<'EOF'
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
EOF
run 'aws iam create-role --role-name eks-fargate-pods --assume-role-policy-document file://eks-fargate-trust.json --query Role.Arn'

block profile
run "SUBNETS=\$(aws ec2 describe-subnets --query 'Subnets[0:2].SubnetId' --output text | tr '\\t' ' ')"
run "aws eks create-fargate-profile --cluster-name shop --fargate-profile-name batch --pod-execution-role-arn arn:aws:iam::123456789012:role/eks-fargate-pods --subnets \$SUBNETS --selectors 'namespace=reports,labels={compute=fargate}' namespace=jobs"

block six
run "aws eks create-fargate-profile --cluster-name shop --fargate-profile-name many --pod-execution-role-arn arn:aws:iam::123456789012:role/eks-fargate-pods --subnets \$SUBNETS --selectors namespace=a namespace=b namespace=c namespace=d namespace=e namespace=f --query 'length(fargateProfile.selectors)'"
run 'aws eks delete-fargate-profile --cluster-name shop --fargate-profile-name many --query fargateProfile.fargateProfileName'

block immutable
run 'aws eks update-fargate-profile --cluster-name shop --fargate-profile-name batch'
run 'aws eks list-fargate-profiles --cluster-name shop'

block candidates
run "aws ec2 describe-instance-types --filters Name=processor-info.supported-architecture,Values=arm64 Name=instance-type,Values='c7g.*,m7g.*,r7g.*' Name=bare-metal,Values=false --query 'InstanceTypes[?VCpuInfo.DefaultVCpus<=\`4\`].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB]' --output text | sort -k2n -k3n"

block fleet
run "aws ec2 create-launch-template --launch-template-name karpenter-shop --launch-template-data '{\"ImageId\":\"ami-0c55b159cbfafe1f0\"}' --query LaunchTemplate.LaunchTemplateName"
run "SUBNET=\$(aws ec2 describe-subnets --query 'Subnets[0].SubnetId' --output text)"
run "aws ec2 create-fleet --type instant --target-capacity-specification TotalTargetCapacity=3,DefaultTargetCapacityType=spot --spot-options AllocationStrategy=price-capacity-optimized --launch-template-configs '[{\"LaunchTemplateSpecification\":{\"LaunchTemplateName\":\"karpenter-shop\",\"Version\":\"\$Latest\"},\"Overrides\":[{\"InstanceType\":\"c7g.large\",\"SubnetId\":\"'\$SUBNET'\"},{\"InstanceType\":\"m7g.large\",\"SubnetId\":\"'\$SUBNET'\"},{\"InstanceType\":\"c7g.xlarge\",\"SubnetId\":\"'\$SUBNET'\"}]}]' --query 'Instances[].[InstanceType,Lifecycle,InstanceIds[0]]' --output text"
run "aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceType,InstanceLifecycle,Placement.AvailabilityZone]' --output text"
