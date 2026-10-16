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
@@CAP:network@@
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
@@CAP:role@@
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
@@CAP:function@@
```

The subnets and the security group came back as given. **The `VpcId` did not**: moto answers
`vpc-123abc`, a fixed placeholder, instead of the `$VPC` the subnets belong to. AWS works the VPC
out from the subnets and returns it. That is the first sign of how little moto checks here, and
the next one is plainer. A subnet and a security group that do not exist:

```
@@CAP:nothing-there@@
```

moto created the function. AWS refuses it, because it looks the subnets and the group up before
it does anything else. **A VPC configuration that works against moto has proved its syntax and
nothing about the network**, which is the same lesson as lesson 16's reservation of 2000.

## Taking it out again

A function leaves its VPC by being given two empty lists, and on AWS it then goes back to
reaching the internet the way any function outside a VPC does:

```
@@CAP:leave@@
```

What AWS does with the network interfaces when a function joins or leaves, and why that once cost
seconds on every cold start, is the next section.
