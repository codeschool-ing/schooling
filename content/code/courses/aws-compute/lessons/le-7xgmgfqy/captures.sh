#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of aws-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-7xgmgfqy/captures.sh
#
# Every block runs in one fresh lab, in order, against one empty moto, so a
# variable set in one block (VOL, SNAP, IMG) is still set in the next, as it
# is in the student's terminal when the sections are followed in order.
#
# What is STAGED rather than typed: nothing beyond the lab itself. The image
# ids, snapshot ids and dates are whatever moto produced on the run; the
# public images moto ships with are dated the moment moto started, which the
# lesson says.
#
# Nothing in an image was installed: moto runs no instance, so "nginx on
# Amazon Linux 2023" is the description the image was given, and the lesson
# says so where it matters.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block latest
run 'aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text'
run 'aws ec2 describe-images --image-ids ami-0b44997419d0b0d38'

block catalogue
run 'aws ec2 describe-images --query "length(Images)"'
run 'aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/*" --query "sort_by(Images,&CreationDate)[].[ImageId,CreationDate,Name]" --output text'
run 'aws ssm get-parameter --name /aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id'

block snapshots
run 'VOL=$(aws ec2 create-volume --availability-zone sa-east-1a --size 100 --volume-type gp3 --query VolumeId --output text)'
run 'SNAP=$(aws ec2 create-snapshot --volume-id "$VOL" --description "orders, Monday" --query SnapshotId --output text)'
run 'aws ec2 create-snapshot --volume-id "$VOL" --description "orders, Tuesday"'
run 'aws ec2 describe-snapshots --filters Name=volume-id,Values="$VOL" --query "Snapshots[].[SnapshotId,VolumeSize,State,Description]" --output table'

block restore
run 'aws ec2 create-volume --availability-zone sa-east-1c --snapshot-id "$SNAP" --volume-type gp3 --query "[VolumeId,AvailabilityZone,Size,SnapshotId]" --output text'
run 'aws ec2 create-volume --availability-zone sa-east-1a --snapshot-id "$SNAP" --size 50 --volume-type gp3 --query "[VolumeId,Size]" --output text'

block build
run 'BASE=$(aws ssm get-parameter --name /aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64 --query Parameter.Value --output text)'
run 'ID=$(aws ec2 run-instances --image-id "$BASE" --instance-type t3.micro --query "Instances[0].InstanceId" --output text)'
run 'IMG=$(aws ec2 create-image --instance-id "$ID" --name web-2026-10-16 --description "nginx on Amazon Linux 2023" --tag-specifications "ResourceType=image,Tags=[{Key=app,Value=web}]" --query ImageId --output text)'
run 'aws ec2 describe-images --owners self'

block its-snapshot
run 'SNAP=$(aws ec2 describe-images --image-ids "$IMG" --query "Images[0].BlockDeviceMappings[0].Ebs.SnapshotId" --output text)'
run 'aws ec2 describe-snapshots --snapshot-ids "$SNAP" --query "Snapshots[].[SnapshotId,VolumeSize,Description]" --output text'

block launch-own
run 'aws ec2 run-instances --image-id "$IMG" --instance-type t3.micro --count 2 --query "Instances[].[InstanceId,ImageId]" --output text'

block copy
run 'aws ec2 copy-image --source-region sa-east-1 --source-image-id "$IMG" --region us-east-1 --name web-2026-10-16'
run 'aws ec2 describe-images --owners self --region us-east-1 --query "Images[].[ImageId,Name,State]" --output text'

block share
run 'aws ec2 modify-image-attribute --image-id "$IMG" --launch-permission "Add=[{UserId=111122223333}]"'
run 'aws ec2 describe-image-attribute --image-id "$IMG" --attribute launchPermission'

block deprecate
run 'aws ec2 enable-image-deprecation --image-id "$IMG" --deprecate-at 2027-04-16T00:00:00Z'

block retire
run 'aws ec2 delete-snapshot --snapshot-id "$SNAP"'
run 'aws ec2 deregister-image --image-id "$IMG"'
run 'aws ec2 describe-images --image-ids "$IMG"'
run 'aws ec2 describe-snapshots --snapshot-ids "$SNAP" --query "Snapshots[].[SnapshotId,VolumeSize,Description]" --output text'
run 'aws ec2 run-instances --image-id "$IMG" --instance-type t3.micro --query "Instances[0].[InstanceId,ImageId]" --output text'
run 'aws ec2 delete-snapshot --snapshot-id "$SNAP"'
run 'aws ec2 describe-snapshots --snapshot-ids "$SNAP"'
