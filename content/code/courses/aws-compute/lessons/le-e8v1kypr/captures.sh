#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of aws-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-e8v1kypr/captures.sh
#
# Every block runs in one fresh lab, in order, against one empty moto, so a
# variable set in one block (ID, DATA, FS, ...) is still set in the next, as it
# is in the student's terminal when the sections are followed in order.
#
# What is STAGED rather than typed: nothing beyond the lab itself. The image
# ami-0b44997419d0b0d38 is the Amazon Linux 2023 image moto ships with (lesson
# 2). moto keeps no blocks and no files: no volume here holds data, no file
# system was mounted, and the lesson says so where it matters.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block types
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3'
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --iops 6000 --throughput 250 --query "[VolumeType,Size,Iops,Throughput]" --output text'
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp2 --query "[VolumeType,Size,Iops]" --output text'
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type io2 --iops 10000 --query "[VolumeType,Size,Iops]" --output text'
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 500 --volume-type st1 --query "[VolumeType,Size,Iops]" --output text'

block instance-limit
run 'aws ec2 describe-instance-types --instance-types m7i.large m7i.2xlarge m7i.8xlarge --query "InstanceTypes[].[InstanceType,EbsInfo.EbsOptimizedInfo.BaselineThroughputInMBps,EbsInfo.EbsOptimizedInfo.BaselineIops,EbsInfo.EbsOptimizedInfo.MaximumThroughputInMBps]" --output table'

block lenient
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --iops 90000 --query "[VolumeType,Size,Iops]" --output text'
run 'aws ec2 create-volume --availability-zone sa-east-1a --size 10 --volume-type st1 --query "[VolumeType,Size]" --output text'

block zone
run 'ID=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.large --placement AvailabilityZone=sa-east-1a --query "Instances[0].InstanceId" --output text)'
run 'DATA=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)'
run 'OTHER=$(aws ec2 create-volume --availability-zone sa-east-1b --size 100 --volume-type gp3 --query VolumeId --output text)'
run 'aws ec2 attach-volume --volume-id "$DATA" --instance-id "$ID" --device /dev/sdf'
run 'aws ec2 attach-volume --volume-id "$OTHER" --instance-id "$ID" --device /dev/sdg --query State --output text'
run 'aws ec2 describe-volumes --volume-ids "$DATA" "$OTHER" --query "Volumes[].[VolumeId,AvailabilityZone,State,Attachments[0].Device]" --output text'

block modify
run 'aws ec2 modify-volume --volume-id "$DATA" --size 200 --iops 6000 --throughput 250'
run 'aws ec2 modify-volume --volume-id "$DATA" --size 50 --query "VolumeModification.[ModificationState,OriginalSize,TargetSize]" --output text'

block termination
run 'aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[].[DeviceName,Ebs.VolumeId,Ebs.DeleteOnTermination]" --output text'
run 'ROOT=$(aws ec2 describe-instances --instance-ids "$ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" --output text)'
run 'aws ec2 terminate-instances --instance-ids "$ID" --query "TerminatingInstances[0].CurrentState.Name" --output text'
run 'aws ec2 describe-volumes --volume-ids "$DATA" --query "Volumes[].[VolumeId,State,Size]" --output text'
run 'aws ec2 describe-volumes --volume-ids "$ROOT"'

block flip
run 'ID2=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.large --placement AvailabilityZone=sa-east-1a --query "Instances[0].InstanceId" --output text)'
run 'aws ec2 attach-volume --volume-id "$DATA" --instance-id "$ID2" --device /dev/sdf --query State --output text'
run 'aws ec2 modify-instance-attribute --instance-id "$ID2" --block-device-mappings "DeviceName=/dev/sdf,Ebs={DeleteOnTermination=true}"'
run 'aws ec2 describe-instances --instance-ids "$ID2" --query "Reservations[0].Instances[0].BlockDeviceMappings[].[DeviceName,Ebs.DeleteOnTermination]" --output text'

block store
run 'aws ec2 describe-instance-types --instance-types i4i.large i4i.xlarge c7gd.xlarge m7gd.large m7i.large --query "InstanceTypes[].[InstanceType,InstanceStorageSupported,InstanceStorageInfo.TotalSizeInGB,InstanceStorageInfo.Disks[0].Type]" --output table'
run 'ID3=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type i4i.large --query "Instances[0].InstanceId" --output text)'
run 'aws ec2 describe-instances --instance-ids "$ID3" --query "Reservations[0].Instances[0].[InstanceType,RootDeviceType,BlockDeviceMappings[].DeviceName]" --output text'

block efs
run 'FS=$(aws efs create-file-system --creation-token uploads-2026 --encrypted --tags Key=Name,Value=uploads --query FileSystemId --output text)'
run 'aws efs describe-file-systems --file-system-id "$FS"'
run 'VPC=$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)'
run 'SG=$(aws ec2 create-security-group --group-name efs-nfs --description "NFS from inside the VPC" --vpc-id "$VPC" --query GroupId --output text)'
run 'aws ec2 authorize-security-group-ingress --group-id "$SG" --protocol tcp --port 2049 --cidr 172.31.0.0/16 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text'
run 'for s in $(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" --query "Subnets[].SubnetId" --output text); do aws efs create-mount-target --file-system-id "$FS" --subnet-id "$s" --security-groups "$SG" --query "[MountTargetId,AvailabilityZoneName,IpAddress]" --output text; done'
run 'A=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC" Name=availability-zone,Values=sa-east-1a --query "Subnets[0].SubnetId" --output text)'
run 'aws efs create-mount-target --file-system-id "$FS" --subnet-id "$A" --security-groups "$SG"'
run 'aws efs describe-file-systems --file-system-id "$FS" --query "FileSystems[0].[NumberOfMountTargets,ThroughputMode,SizeInBytes.Value]" --output text'
