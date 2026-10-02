---
title: CloudFormation, where AWS keeps the state
version: 1
---

Terraform runs on your machine, calls the AWS API, and keeps a state file to remember what it made.
**CloudFormation moves both of those jobs into AWS.** It is a service of AWS's own: you send it a
template, it works out the changes, makes the calls, and remembers the result in a **stack**. There
is nothing to install, no state file to protect and no lock to configure. The price is the obvious
one: it describes AWS and nothing else.

## A template

The same network, written for CloudFormation in YAML:

```yaml
AWSTemplateFormatVersion: "2010-09-09"
Description: The shop's network, as a CloudFormation stack.

Parameters:
  VpcCidr:
    Type: String
    Default: 10.20.0.0/16

Resources:
  ShopVpc:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: !Ref VpcCidr
      Tags:
        - Key: Name
          Value: shop

  WebSubnetA:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref ShopVpc
      CidrBlock: 10.20.1.0/24
      AvailabilityZone: sa-east-1a
      Tags:
        - Key: Name
          Value: shop-web-a

  WebSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupName: web
      GroupDescription: web servers
      VpcId: !Ref ShopVpc
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0

Outputs:
  VpcId:
    Value: !Ref ShopVpc
  WebSubnetId:
    Value: !Ref WebSubnetA
```

The pieces line up with what you know. `Parameters` play the part of variables, with a default.
Each entry under `Resources` has a **logical id**, `ShopVpc` or `WebSubnetA`, which is the name the
template uses for it, and a `Type` from AWS's own catalogue. `!Ref ShopVpc` is a reference: it gives
the subnet the VPC's real id and orders the two, as `aws_vpc.shop.id` did in lesson 2. `Outputs` are
outputs. The security group's rule is a property of the group here rather than a resource of its own,
because that is how this resource type is written.

## A change set is the plan

CloudFormation's equivalent of `terraform plan` is a **change set**: the changes it would make,
computed and kept, waiting for somebody to execute them. Ana creates one for a stack that does not
exist yet, so every resource is an addition:

```
ana@laptop:~/shop/cfn$ aws cloudformation create-change-set --stack-name shop-network --change-set-name first --change-set-type CREATE --template-body file://network.yaml --query Id --output text
arn:aws:cloudformation:sa-east-1:123456789012:changeSet/first/643e7985-0e57-4160-8103-2ca815cc3e53
ana@laptop:~/shop/cfn$ aws cloudformation wait change-set-create-complete --stack-name shop-network --change-set-name first
ana@laptop:~/shop/cfn$ aws cloudformation describe-change-set --stack-name shop-network --change-set-name first --query "Changes[].ResourceChange.[Action,LogicalResourceId,ResourceType]" --output text
Add	ShopVpc	AWS::EC2::VPC
Add	WebSubnetA	AWS::EC2::Subnet
Add	WebSecurityGroup	AWS::EC2::SecurityGroup
```

Executing it is the apply. CloudFormation then works through the resources in the order the
references impose, and the stack reports when it is done:

```
ana@laptop:~/shop/cfn$ aws cloudformation execute-change-set --stack-name shop-network --change-set-name first
ana@laptop:~/shop/cfn$ aws cloudformation wait stack-create-complete --stack-name shop-network
ana@laptop:~/shop/cfn$ aws cloudformation describe-stacks --stack-name shop-network --query "Stacks[0].StackStatus" --output text
CREATE_COMPLETE
```

`aws cloudformation deploy` does both steps in one command, which is what most people type; the two
commands make the review step visible.

## The stack is the state

What Terraform keeps in `terraform.tfstate`, the link between a name in the file and an id in the
cloud, CloudFormation keeps in the stack and shows on request:

```
ana@laptop:~/shop/cfn$ aws cloudformation describe-stack-resources --stack-name shop-network --query "StackResources[].[LogicalResourceId,PhysicalResourceId]" --output text
ShopVpc	vpc-a3e28d373ad658e89
WebSubnetA	subnet-010e74ae6d32f65b0
WebSecurityGroup	sg-8d0ba39ee4cdbecdf
```

You cannot lose that file, leave it in a bucket anybody can read, or edit it by hand, because there
is no file. And the stack owns what it created, so deleting the stack deletes the network:

```
ana@laptop:~/shop/cfn$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text | wc -w
1
ana@laptop:~/shop/cfn$ aws cloudformation delete-stack --stack-name shop-network
ana@laptop:~/shop/cfn$ aws cloudformation wait stack-delete-complete --stack-name shop-network
ana@laptop:~/shop/cfn$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].VpcId" --output text | wc -w
0
```

Two habits differ from Terraform's. **When a resource fails while a stack is being created,
CloudFormation rolls back** and removes what it had made, where Terraform keeps the half that
succeeded and finishes it on the next apply (lesson 9). And CloudFormation has **drift detection**
built in: it compares each resource with the template and reports what somebody changed by hand,
the job `terraform plan -refresh-only` did in lesson 7.

## What the lab cannot show

Moto emulates CloudFormation well enough to create and delete a stack, and no further. Asked to
detect drift, it fails with an internal error of its own. Asked for a change set on an **existing**
stack, it lists every resource as `Add`, which a real change set would never do for resources that
already exist. So this section stops at creation and deletion. On a real account, the change set for an update marks each resource `Modify` or `Remove`, and says whether a
modification needs a replacement, the same question `-/+` answers in a Terraform plan.
