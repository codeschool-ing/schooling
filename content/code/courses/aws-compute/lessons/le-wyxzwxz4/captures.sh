#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of aws-compute (Lambda inside a
# VPC), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT
# IS NOT COMMITTED.
#
#   bash lessons/le-wyxzwxz4/captures.sh
#
# One run against an empty moto 5.2.3. moto keeps the VPC, the subnets, the
# security groups, the role and the function as records; it creates no network
# interface for a function and runs no code, and the lesson says so where it
# matters.
#
# vpc-access.json is read out of the example in `configuring-it`, bare/app.py
# out of that section's fence, and prices.py out of lesson 1's
# `the-price-sheet`, so none of them is kept twice.
#
# What is STAGED rather than typed:
#   - the student writes vpc-access.json and bare/app.py with an editor; here
#     they are extracted from the lesson without being shown;
#   - the price cache was filled by an earlier run of prices.py, so the sheet
#     prints without the network;
#   - the shell variables VPC, A, B, FN and DB are set by the commands shown,
#     in one shell, as they would be in the student's terminal.
#
# Recorded 2026-10-16 on Ubuntu 24.04, no AWS account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

mkdir -p bare
from_lesson "$HERE/configuring-it.md" bare/app.py > bare/app.py
from_example "$HERE/configuring-it.md" vpc-access.json > vpc-access.json
from_example "$HERE/../le-ps61q5st/the-price-sheet.md" prices.py > prices.py

block network
run 'VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)'
run 'A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)'
run 'B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)'
run 'FN=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-fn --description "the function" --query GroupId --output text)'
run 'DB=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-db --description "the database" --query GroupId --output text)'
run 'echo $VPC $A $B $FN $DB'
run 'aws ec2 authorize-security-group-ingress --group-id $DB --protocol tcp --port 5432 --source-group $FN --query "SecurityGroupRules[].{Port: FromPort, From: ReferencedGroupInfo.GroupId}"'

block role
run "aws iam create-role --role-name orders-vpc-role --query Role.Arn --output text --assume-role-policy-document '{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"lambda.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}'"
run 'aws iam put-role-policy --role-name orders-vpc-role --policy-name vpc-access --policy-document file://vpc-access.json'
run 'aws iam list-role-policies --role-name orders-vpc-role'

block function
run 'zip -j orders.zip bare/app.py'
run 'aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-vpc-role --zip-file fileb://orders.zip --vpc-config SubnetIds=$A,$B,SecurityGroupIds=$FN --query VpcConfig'

block nothing-there
run 'aws lambda create-function --function-name ghost --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-vpc-role --zip-file fileb://orders.zip --vpc-config SubnetIds=subnet-0000000000000000a,SecurityGroupIds=sg-0000000000000000a --query "{Name: FunctionName, State: State}"'

block enis
run 'aws ec2 describe-network-interfaces --query "NetworkInterfaces[].NetworkInterfaceId"'

block leave
run 'aws lambda update-function-configuration --function-name orders --vpc-config SubnetIds=[],SecurityGroupIds=[] --query VpcConfig'

block nat-price
run "python3 prices.py ec2 | grep -A2 '^Network'"

block endpoints
run 'RT=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values=$VPC --query "RouteTables[0].RouteTableId" --output text)'
run 'aws ec2 create-vpc-endpoint --vpc-id $VPC --vpc-endpoint-type Gateway --service-name com.amazonaws.sa-east-1.s3 --route-table-ids $RT --query "VpcEndpoint.{Id: VpcEndpointId, Type: VpcEndpointType, State: State}"'
run 'aws ec2 create-vpc-endpoint --vpc-id $VPC --vpc-endpoint-type Interface --service-name com.amazonaws.sa-east-1.secretsmanager --subnet-ids $A $B --security-group-ids $FN --query "VpcEndpoint.{Id: VpcEndpointId, Type: VpcEndpointType, Interfaces: NetworkInterfaceIds}"'
run 'aws ec2 describe-route-tables --route-table-ids $RT --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationPrefixListId, GatewayId]" --output text'
run 'aws ec2 describe-network-interfaces --query "NetworkInterfaces[].[NetworkInterfaceId, SubnetId]" --output text'
