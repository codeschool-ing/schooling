#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of aws-data (EMR), as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS LESSON 1'S, and this script starts where a student is after "Every
# time you open a terminal", with moto empty. Nothing here runs Spark: moto 5.2.3
# records clusters, steps and job runs and executes none of them, and the lesson
# says so beside every transcript.
#
# The ids moto hands out (j-..., s-..., ig-..., application and job-run ids) are
# read back with --query between commands, outside `run`, and spliced into the
# next command, the way a student copies them off the screen.
#
# emr_vs_glue.py is read out of the example in emr-or-glue.md, so the program
# shown and the program run are the same file.
#
# STAGED: the price cache is full when this starts, because lab.sh tools ran the
# whole sheet once, which is the first step lesson 1's price sheet asks for.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1

ROLES='--service-role EMR_DefaultRole --ec2-attributes InstanceProfile=EMR_EC2_DefaultRole'
TABLE="--query 'Cluster.InstanceGroups[].[Id,Name,InstanceGroupType,Market,RequestedInstanceCount,Status.State]' --output table"

block emr-create
run "aws emr create-cluster --name quitanda-emr --release-label emr-7.9.0 --applications Name=Spark --instance-groups InstanceGroupType=MASTER,InstanceType=m7i.xlarge,InstanceCount=1 InstanceGroupType=CORE,InstanceType=m7i.xlarge,InstanceCount=2 $ROLES --log-uri s3://quitanda-logs-prod/emr/ --no-auto-terminate"
CID=$(aws emr list-clusters --query 'Clusters[?Name==`quitanda-emr`].Id' --output text)
run "aws emr describe-cluster --cluster-id $CID --query 'Cluster.{State:Status.State,AutoTerminate:AutoTerminate,Zone:Ec2InstanceAttributes.Ec2AvailabilityZone}'"
run "aws emr describe-cluster --cluster-id $CID $TABLE"

block emr-task-spot
run "aws emr add-instance-groups --cluster-id $CID --instance-groups InstanceGroupType=TASK,Name=task-spot,InstanceType=m7i.xlarge,InstanceCount=4,BidPrice=OnDemandPrice"
run "aws emr describe-cluster --cluster-id $CID $TABLE"

block emr-fleets
run "aws emr create-cluster --name quitanda-fleets --release-label emr-7.9.0 --applications Name=Spark --instance-fleets InstanceFleetType=MASTER,TargetOnDemandCapacity=1,InstanceTypeConfigs=[{InstanceType=m7i.xlarge}] InstanceFleetType=CORE,TargetOnDemandCapacity=2,InstanceTypeConfigs=[{InstanceType=m7i.xlarge}] InstanceFleetType=TASK,TargetSpotCapacity=4,InstanceTypeConfigs=[{InstanceType=m7i.xlarge},{InstanceType=m6i.xlarge},{InstanceType=m5.xlarge}] $ROLES --no-auto-terminate"
FID=$(aws emr list-clusters --query 'Clusters[?Name==`quitanda-fleets`].Id' --output text)
run "aws emr list-instance-fleets --cluster-id $FID"
run "aws emr describe-cluster --cluster-id $FID --query 'Cluster.InstanceCollectionType'"

block emr-resize
CORE=$(aws emr describe-cluster --cluster-id "$CID" --query 'Cluster.InstanceGroups[?InstanceGroupType==`CORE`].Id' --output text)
run "aws emr modify-instance-groups --cluster-id $CID --instance-groups InstanceGroupId=$CORE,InstanceCount=4"
run "aws emr describe-cluster --cluster-id $CID --query 'Cluster.InstanceGroups[].[InstanceGroupType,RequestedInstanceCount,RunningInstanceCount]' --output text"

block emr-steps
run "aws emr add-steps --cluster-id $CID --steps Type=Spark,Name=daily-orders,ActionOnFailure=CONTINUE,Args=[s3://quitanda-raw-prod/jobs/daily_orders.py,--dt,2026-10-15]"
run "aws emr list-steps --cluster-id $CID"
run 'aws s3 ls s3://quitanda-raw-prod/jobs/'

block emr-transient
run "aws emr create-cluster --name quitanda-nightly-2026-10-15 --release-label emr-7.9.0 --applications Name=Spark --instance-groups InstanceGroupType=MASTER,InstanceType=m7i.xlarge,InstanceCount=1 InstanceGroupType=CORE,InstanceType=m7i.xlarge,InstanceCount=2 $ROLES --steps Type=Spark,Name=daily-orders,ActionOnFailure=TERMINATE_CLUSTER,Args=[s3://quitanda-raw-prod/jobs/daily_orders.py,--dt,2026-10-15] --auto-terminate"
TID=$(aws emr list-clusters --query 'Clusters[?Name==`quitanda-nightly-2026-10-15`].Id' --output text)
run "aws emr describe-cluster --cluster-id $TID --query 'Cluster.[Status.State,AutoTerminate]' --output text"
run "aws emr list-steps --cluster-id $TID --query 'Steps[].[Name,ActionOnFailure,Status.State]' --output text"

block emr-terminate
run "aws emr terminate-clusters --cluster-ids $CID $FID $TID"
run "aws emr list-clusters --query 'Clusters[].[Name,Status.State]' --output text"

block emr-serverless
run 'aws emr-serverless create-application --name quitanda-spark --type SPARK --release-label emr-7.9.0'
AID=$(aws emr-serverless list-applications --query 'applications[0].id' --output text)
run "aws emr-serverless get-application --application-id $AID --query 'application.{state:state,autoStart:autoStartConfiguration,autoStop:autoStopConfiguration}'"
run "aws emr-serverless start-job-run --application-id $AID --execution-role-arn arn:aws:iam::123456789012:role/quitanda-emr-job --job-driver '{\"sparkSubmit\": {\"entryPoint\": \"s3://quitanda-raw-prod/jobs/daily_orders.py\", \"entryPointArguments\": [\"--dt\", \"2026-10-15\"]}}'"
JID=$(aws emr-serverless list-job-runs --application-id "$AID" --query 'jobRuns[0].id' --output text)
run "aws emr-serverless get-job-run --application-id $AID --job-run-id $JID --query 'jobRun.{state:state,seconds:totalExecutionDurationSeconds,billed:billedResourceUtilization}'"

block emr-eks
run 'aws emr-containers create-virtual-cluster --name quitanda-eks --container-provider id=quitanda-eks,type=EKS,info={eksInfo={namespace=spark}}'
run "aws emr-containers list-virtual-clusters --query 'virtualClusters[].[name,state,containerProvider.id]' --output text"
run 'aws eks list-clusters'

block price-emr
run 'python3 prices.py emr glue'

# ---- emr-or-glue: the program, read out of the lesson -------------------------
example "$LESSONS/le-np3z0zpw/emr-or-glue.md" emr_vs_glue.py emr_vs_glue.py || exit 1
block emr-vs-glue
run 'python3 emr_vs_glue.py'
