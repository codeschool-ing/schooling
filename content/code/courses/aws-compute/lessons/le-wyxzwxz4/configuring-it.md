---
title: Putting a function in a VPC, against moto
version: 1
---

Attaching a function to a VPC is one option on `create-function`, and it names two things: **the
subnets the function's network interfaces go in, and the security groups they carry.** Everything
else follows from those two lists, and most of what goes wrong goes wrong in one of them. This
section builds the smallest network that shows the pattern, a function that will talk to a
PostgreSQL database in private subnets, and then reads what moto made of it.

## The network

The VPC, two private subnets in two zones, and two security groups: one for the function and one
for the database. `aws-foundations` lessons 16 and 18 explain each of these; here they are only
the ground the function stands on. The shell variables keep the ids moto invents, so the later
commands can use them:

```
ana@laptop:~/aws$ VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ A=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ B=$(aws ec2 create-subnet --vpc-id $VPC --cidr-block 10.0.2.0/24 --availability-zone sa-east-1b --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ FN=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-fn --description "the function" --query GroupId --output text)
ana@laptop:~/aws$ DB=$(aws ec2 create-security-group --vpc-id $VPC --group-name orders-db --description "the database" --query GroupId --output text)
ana@laptop:~/aws$ echo $VPC $A $B $FN $DB
vpc-8c3e928502e59b35a subnet-dfadb89736d4aa1a9 subnet-2703629957a6494c1 sg-3e0f3ea4cf6cf0f8a sg-f697fa39575f20885
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id $DB --protocol tcp --port 5432 --source-group $FN --query "SecurityGroupRules[].{Port: FromPort, From: ReferencedGroupInfo.GroupId}"
[
    {
        "Port": 5432,
        "From": "sg-3e0f3ea4cf6cf0f8a"
    }
]
```

The last command is the rule that matters. **The database's security group admits port 5432 from
the function's security group, by its id, and from nothing else.** No address range is named, so
the rule stays true however many network interfaces the function ends up with, and whatever
addresses they get. The function's own group needs no inbound rule at all, because nothing
connects to a Lambda function over the network: requests reach it through Lambda's own service.

Two subnets in two zones is not decoration. Lambda places environments in whichever of the listed
subnets it chooses, and a function listed in one subnet stops when that zone does. AWS recommends
at least two zones for any function in a VPC.

## The role needs EC2 permissions

A function in a VPC needs an execution role that may manage network interfaces, because Lambda
creates and deletes them in your account with that role's authority. AWS provides a managed
policy for this, `AWSLambdaVPCAccessExecutionRole`, but moto 5.2.3 does not carry it, so the
policy is written out here. Save it as `~/aws/vpc-access.json`:

```schooling-example
{"language": "json", "file": "vpc-access.json", "parts": [{"code": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n", "note": "An identity policy, attached to the role. It names no principal: the role it is attached to is the principal."}, {"code": "    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"ec2:CreateNetworkInterface\",\n        \"ec2:DescribeNetworkInterfaces\",\n        \"ec2:DescribeSubnets\",\n        \"ec2:DeleteNetworkInterface\",\n        \"ec2:AssignPrivateIpAddresses\",\n        \"ec2:UnassignPrivateIpAddresses\"\n      ],\n      \"Resource\": \"*\"\n    },\n", "note": "What Lambda does in your VPC on the function's behalf: create the network interfaces, find them and the subnets again, give them addresses and delete them when they are no longer needed. `Resource` is `*` because the interfaces do not exist yet when the policy is written."}, {"code": "    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"logs:CreateLogGroup\",\n        \"logs:CreateLogStream\",\n        \"logs:PutLogEvents\"\n      ],\n      \"Resource\": \"*\"\n    }\n", "note": "The function's own logs, which every Lambda role needs whether or not it is in a VPC."}, {"code": "  ]\n}\n"}]}
```

The trust policy is the same as in lesson 16's role, and the permissions go on as an inline
policy:

```
ana@laptop:~/aws$ aws iam create-role --role-name orders-vpc-role --query Role.Arn --output text --assume-role-policy-document '{"Version": "2012-10-17", "Statement": [{"Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
arn:aws:iam::123456789012:role/orders-vpc-role
ana@laptop:~/aws$ aws iam put-role-policy --role-name orders-vpc-role --policy-name vpc-access --policy-document file://vpc-access.json
ana@laptop:~/aws$ aws iam list-role-policies --role-name orders-vpc-role
{
    "PolicyNames": [
        "vpc-access"
    ]
}
```

On AWS, leaving these permissions out is refused at once: `create-function` fails with an
`InvalidParameterValueException` saying that the execution role does not have permission to call
`CreateNetworkInterface` on EC2. moto does not evaluate the role, so it would accept the function
either way; the permissions are here because AWS checks them, not because moto does.

## The function

Any handler will do, because nothing in this lesson invokes it. This is lesson 17's bare handler,
in `~/aws/bare/app.py`:

```python
# bare/app.py
def handler(event, context):
    return {"ok": True}
```

```
ana@laptop:~/aws$ zip -j orders.zip bare/app.py
  adding: app.py (stored 0%)
ana@laptop:~/aws$ aws lambda create-function --function-name orders --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-vpc-role --zip-file fileb://orders.zip --vpc-config SubnetIds=$A,$B,SecurityGroupIds=$FN --query VpcConfig
{
    "SubnetIds": [
        "subnet-dfadb89736d4aa1a9",
        "subnet-2703629957a6494c1"
    ],
    "SecurityGroupIds": [
        "sg-3e0f3ea4cf6cf0f8a"
    ],
    "VpcId": "vpc-123abc"
}
```

The subnets and the security group came back as given. **The `VpcId` did not**: moto answers
`vpc-123abc`, a fixed placeholder, instead of the `$VPC` the subnets belong to. AWS works the VPC
out from the subnets and returns it. That is the first sign of how little moto checks here, and
the next one is plainer. A subnet and a security group that do not exist:

```
ana@laptop:~/aws$ aws lambda create-function --function-name ghost --runtime python3.12 --handler app.handler --role arn:aws:iam::123456789012:role/orders-vpc-role --zip-file fileb://orders.zip --vpc-config SubnetIds=subnet-0000000000000000a,SecurityGroupIds=sg-0000000000000000a --query "{Name: FunctionName, State: State}"
{
    "Name": "ghost",
    "State": "Active"
}
```

moto created the function. AWS refuses it, because it looks the subnets and the group up before
it does anything else. **A VPC configuration that works against moto has proved its syntax and
nothing about the network**, which is the same lesson as lesson 16's reservation of 2000.

## Taking it out again

A function leaves its VPC by being given two empty lists, and on AWS it then goes back to
reaching the internet the way any function outside a VPC does:

```
ana@laptop:~/aws$ aws lambda update-function-configuration --function-name orders --vpc-config SubnetIds=[],SecurityGroupIds=[] --query VpcConfig
{
    "SubnetIds": [],
    "SecurityGroupIds": []
}
```

What AWS does with the network interfaces when a function joins or leaves, and why that once cost
seconds on every cold start, is the next section.
