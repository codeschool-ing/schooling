#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of aws-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-ps61q5st/captures.sh
#
# The environment the transcripts run in is the one the section `your-lab`
# builds: lab.sh runs that section's own fences, and every run starts with the
# lines of its fourth fence, the ones a student types in every new terminal.
#
# What is STAGED rather than typed:
#   - moto is started by the lab before the first command, as the fifth fence
#     of `your-lab` starts it, rather than in a second terminal;
#   - `moto-down` stops it first, which is the state the failure shows;
#   - `real-aws` unsets AWS_ENDPOINT_URL, as a new terminal would, and needs
#     the internet: the machine this was recorded on reaches it through a proxy
#     that re-signs TLS, so that one command is given HTTPS_PROXY and the
#     proxy's certificate bundle as AWS_CA_BUNDLE. Neither changes what AWS
#     answers;
#   - `prices` reads prices.py out of the example in `the-price-sheet` and
#     empties ~/.cache/aws-prices first. It needs the internet, through the
#     same proxy as `real-aws`.
#
# The blocks from `name-letters` to `burstable` belong to the sections
# `the-name`, `families` and `sizes-and-burstable`, and run against the same
# empty moto as `check`. The image id ami-0b44997419d0b0d38 is the Amazon Linux
# 2023 image moto ships with; lesson 2 shows where such an id comes from.
#
# One failure in `the-price-sheet` is quoted and not produced here, because it
# cannot be produced on purpose: the cut download (ContentTooShortError). It
# happened on 2026-10-16 while the EC2 file was first downloaded for this
# course.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

if [ "${1:-}" = real-aws ]; then
  # LAB_HOSTS=1 bash lessons/le-ps61q5st/captures.sh real-aws
  block real-aws
  quiet 'kill "$LAB_MOTO_PID"'
  unset AWS_ENDPOINT_URL
  export HTTPS_PROXY=$LAB_PROXY AWS_CA_BUNDLE=/root/.ccr/ca-bundle.crt
  run 'aws sts get-caller-identity'
  exit 0
fi

if [ "${1:-}" = prices ]; then
  # LAB_HOSTS=1 bash lessons/le-ps61q5st/captures.sh prices
  # The price list is on the internet, reached through the recording machine's
  # proxy (HTTPS_PROXY, as above). The cache starts empty.
  export HTTPS_PROXY=$LAB_PROXY
  quiet 'rm -rf ~/.cache/aws-prices'
  from_example "$HERE/the-price-sheet.md" prices.py > prices.py
  block price-first
  run 'python3 prices.py lambda'
  run 'ls ~/.cache/aws-prices'
  block price-all
  run 'time python3 prices.py'
  block price-after
  run 'du -sh ~/.cache/aws-prices'
  run 'time python3 prices.py ec2 > /dev/null'
  exit 0
fi

block check
run 'aws --version'
run 'aws sts get-caller-identity'

block port-taken
run '~/aws/venv/bin/moto_server -p 4567'

block name-letters
run 'aws ec2 describe-instance-types --instance-types c7g.xlarge c7gd.xlarge c7gn.xlarge --query "InstanceTypes[].[InstanceType,ProcessorInfo.SupportedArchitectures[0],InstanceStorageInfo.TotalSizeInGB,NetworkInfo.NetworkPerformance]" --output table'

block processors
run 'aws ec2 describe-instance-types --instance-types m7i.large m7a.large m7g.large --query "InstanceTypes[].[InstanceType,ProcessorInfo.Manufacturer,ProcessorInfo.SupportedArchitectures[0],VCpuInfo.DefaultCores,VCpuInfo.DefaultThreadsPerCore]" --output table'

block lenient
run 'aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7g.large --query "Instances[0].[InstanceType,Architecture]" --output text'
run 'aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type m7i.huge --query "Instances[0].[InstanceType,State.Name]" --output text'

block catalogue
run 'aws ec2 describe-instance-types --query "length(InstanceTypes)"'
run 'aws ec2 describe-instance-type-offerings --query "length(InstanceTypeOfferings)"'
run 'aws ec2 describe-instance-type-offerings --location-type availability-zone --filters Name=instance-type,Values=i4i.large --query "InstanceTypeOfferings[].Location" --output text'

block families
run 'aws ec2 describe-instance-types --instance-types m7i.large c7i.large r7i.large i4i.large g4dn.xlarge --query "InstanceTypes[].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB,InstanceStorageInfo.TotalSizeInGB,GpuInfo.Gpus[0].Name]" --output table'

block sizes
run 'aws ec2 describe-instance-types --filters "Name=instance-type,Values=m7i.*" --query "sort_by(InstanceTypes,&VCpuInfo.DefaultVCpus)[].[InstanceType,VCpuInfo.DefaultVCpus,MemoryInfo.SizeInMiB,NetworkInfo.NetworkPerformance]" --output table'
run 'aws ec2 describe-instance-types --instance-types m7i.large m7i.xlarge m7i.4xlarge m7i.8xlarge --query "InstanceTypes[].[InstanceType,NetworkInfo.NetworkCards[0].BaselineBandwidthInGbps,NetworkInfo.NetworkCards[0].PeakBandwidthInGbps]" --output table'

block burstable
run 'aws ec2 describe-instance-types --instance-types t3.micro t3.medium t4g.medium m7i.large --query "InstanceTypes[].[InstanceType,BurstablePerformanceSupported]" --output text'
run 'ID=$(aws ec2 run-instances --image-id ami-0b44997419d0b0d38 --instance-type t3.medium --credit-specification CpuCredits=unlimited --query "Instances[0].InstanceId" --output text)'
run 'aws ec2 describe-instance-credit-specifications --instance-ids "$ID"'
run 'aws ec2 modify-instance-credit-specification --instance-credit-specifications "InstanceId=$ID,CpuCredits=unlimited"'

block moto-down
quiet 'kill "$LAB_MOTO_PID"; sleep 1'
run 'aws sts get-caller-identity'

