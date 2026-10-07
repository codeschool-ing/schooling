---
title: The AWS CDK, a program that writes the template
version: 2
---

The AWS Cloud Development Kit lets you describe infrastructure in TypeScript, JavaScript, Python,
Java, C# or Go, so it is easy to picture it calling the AWS API the way Terraform does. **It never
does.** A CDK app is a program whose output is a CloudFormation template, and CloudFormation does
the rest. The CDK is a better way of writing the YAML from the last section, with the stack, the
change set and the rollback all unchanged underneath.

## Installing Node.js and the CDK

The CDK is a Node.js program, and the library this section's app is written against needs Node.js
20 or newer, where Ubuntu 24.04's own package is version 18. So Node.js comes from the project's own
build, unpacked into `/usr/local`, and the `cdk` command is installed with Node's package manager,
`npm`:

```sh
curl -fsSL https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.xz | sudo tar -xJ -C /usr/local --strip-components=1
sudo npm install -g aws-cdk@2.1144.0
```

On an ARM computer the file is `node-v22.22.0-linux-arm64.tar.xz`. The library the app imports
belongs to the project rather than to the system, so it is installed in the app's own directory,
where `require` looks for it:

```sh
mkdir -p ~/shop/cdk && cd ~/shop/cdk
npm init -y
npm install aws-cdk-lib@2.272.0 constructs@10
```

`npm init -y` writes a `package.json` with default answers, and `npm install` puts the two packages
in `node_modules`. The versions are the ones the transcripts were recorded with.

## Synthesis

Ana's first app, in JavaScript, asks for a VPC with the shop's range across two availability zones:

```js
const { App, Stack } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
});
```

`ec2.Vpc` is a **construct**, a class that adds resources to a stack when it is created. `cdk synth`
runs the program and writes what it added as a template:

```
ana@laptop:~/shop/cdk$ cdk synth --app "node app.js" > template.yaml
83 feature flags are not configured. Run 'cdk flags --unstable=flags' to learn more.
ana@laptop:~/shop/cdk$ head -n 13 template.yaml
Resources:
  Shop563325D0:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.20.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      InstanceTenancy: default
      Tags:
        - Key: Name
          Value: ShopNetwork/Shop
    Metadata:
      aws:cdk:path: ShopNetwork/Shop/Resource
ana@laptop:~/shop/cdk$ ls cdk.out
ShopNetwork.assets.json
ShopNetwork.metadata.json
ShopNetwork.template.json
cdk.out
manifest.json
tree.json
validation-report.json
```

The line on standard error is a note about feature flags, settings a project created with `cdk init`
records in a `cdk.json`; this app has neither and loses nothing by it. The template is in
`template.yaml` and in `cdk.out`, and its first resource is the VPC, under a logical id the CDK
derived from the construct's path. Nothing in AWS was asked anything: synthesis runs offline.

The surprise is the size. Counted by type:

```
ana@laptop:~/shop/cdk$ jq -r ".Resources[].Type" cdk.out/ShopNetwork.template.json | sort | uniq -c
      1 AWS::CDK::Metadata
      2 AWS::EC2::EIP
      1 AWS::EC2::InternetGateway
      2 AWS::EC2::NatGateway
      4 AWS::EC2::Route
      4 AWS::EC2::RouteTable
      4 AWS::EC2::Subnet
      4 AWS::EC2::SubnetRouteTableAssociation
      1 AWS::EC2::VPC
      1 AWS::EC2::VPCGatewayAttachment
```

**A program of ten lines produced 24 resources**, and among them are two NAT gateways with an
elastic IP each. The `Vpc` construct's defaults are a public and a private subnet in every zone and
a NAT gateway per zone so the private ones can reach the internet. They are reasonable defaults,
and a NAT gateway is also billed for every hour it exists, the kind of cost lesson 16 is about. A
construct's defaults are decisions somebody else made for you, and **the synthesised template is
where you review them.**

Constructs come in levels. The ones named `Cfn…`, such as `ec2.CfnVPC`, map one to one onto a
CloudFormation type and decide nothing. `ec2.Vpc` is the next level up, with defaults. Above it are
patterns that assemble several services at once. Ana states what the shop needs, public subnets of
`/24` and no NAT gateway, and tags everything in the stack:

```js
const { App, Stack, Tags } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
  natGateways: 0,
  subnetConfiguration: [
    { name: "web", subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
  ],
});

Tags.of(stack).add("Project", "shop");
```

```
ana@laptop:~/shop/cdk$ cdk synth --app "node app.js" > template.yaml 2>/dev/null
ana@laptop:~/shop/cdk$ jq -r ".Resources[].Type" cdk.out/ShopNetwork.template.json | sort | uniq -c
      1 AWS::CDK::Metadata
      1 AWS::EC2::InternetGateway
      2 AWS::EC2::Route
      2 AWS::EC2::RouteTable
      2 AWS::EC2::Subnet
      2 AWS::EC2::SubnetRouteTableAssociation
      1 AWS::EC2::VPC
      1 AWS::EC2::VPCGatewayAttachment
```

Twelve resources, every one of which she can now account for.

## Deploying, and the diff

A CDK deployment needs a **bootstrap** first, once per account and region: a stack called
`CDKToolkit` holding what the CDK uses to deploy, such as a bucket for files an app uploads. Then
`cdk deploy` synthesises, hands the template to CloudFormation through a change set, and waits:

```
ana@laptop:~/shop/cdk$ cdk bootstrap --app "node app.js" 2>&1 | grep "^CDKToolkit"
CDKToolkit: creating CloudFormation changeset...
CDKToolkit |  0/15 | 8:28:12 AM | CREATE_IN_PROGRESS      | AWS::CloudFormation::Stack | CDKToolkit User Initiated
CDKToolkit |  1/15 | 8:28:12 AM | CREATE_COMPLETE         | AWS::CloudFormation::Stack | CDKToolkit 
ana@laptop:~/shop/cdk$ cdk deploy --app "node app.js" --require-approval never 2>&1 | grep "^ShopNetwork"
ShopNetwork: start: Building ShopNetwork Template
ShopNetwork: success: Built ShopNetwork Template
ShopNetwork: start: Publishing ShopNetwork Template (current_account-current_region-c4015989)
ShopNetwork: success: Published ShopNetwork Template (current_account-current_region-c4015989)
ShopNetwork: creating CloudFormation changeset...
ShopNetwork: deploying... [1/1]
ShopNetwork |  0/13 | 8:28:16 AM | CREATE_IN_PROGRESS      | AWS::CloudFormation::Stack            | ShopNetwork User Initiated
ShopNetwork |  1/13 | 8:28:16 AM | CREATE_COMPLETE         | AWS::CloudFormation::Stack            | ShopNetwork 
ana@laptop:~/shop/cdk$ aws ec2 describe-subnets --filters Name=tag:Project,Values=shop --query "Subnets[].CidrBlock" --output text
10.20.0.0/24	10.20.1.0/24
```

The event lines are moto's, which reports the stack and not each resource inside it; on a real account
there is one line per resource. The two subnets are the `/24`s the app asked for.

Ana adds one line at the end of the app, a second tag, and asks what would change. The whole
`app.js` is now:

```js
const { App, Stack, Tags } = require("aws-cdk-lib");
const ec2 = require("aws-cdk-lib/aws-ec2");

const app = new App();
const stack = new Stack(app, "ShopNetwork");

new ec2.Vpc(stack, "Shop", {
  ipAddresses: ec2.IpAddresses.cidr("10.20.0.0/16"),
  maxAzs: 2,
  natGateways: 0,
  subnetConfiguration: [
    { name: "web", subnetType: ec2.SubnetType.PUBLIC, cidrMask: 24 },
  ],
});

Tags.of(stack).add("Project", "shop");
Tags.of(stack).add("Owner", "ana");
```

`cdk diff` compares the template the app synthesises now with the one the stack was deployed
from:

```
ana@laptop:~/shop/cdk$ cdk diff --app "node app.js" --method=template
Stack ShopNetwork (aws://123456789012/sa-east-1)
Resources
[~] AWS::EC2::VPC Shop Shop563325D0
 └─ [~] Tags
     └─ @@ -4,6 +4,10 @@
        [ ]   "Value": "ShopNetwork/Shop"
        [ ] },
        [ ] {
        [+]   "Key": "Owner",
        [+]   "Value": "ana"
        [+] },
        [+] {
        [ ]   "Key": "Project",
        [ ]   "Value": "shop"
        [ ] }
```

```
ana@laptop:~/shop/cdk$ cdk diff --app "node app.js" --method=template 2>&1 | grep -F "[~] AWS"
[~] AWS::EC2::VPC Shop Shop563325D0
[~] AWS::EC2::Subnet Shop/webSubnet1/Subnet ShopwebSubnet1Subnet697C84D9
[~] AWS::EC2::RouteTable Shop/webSubnet1/RouteTable ShopwebSubnet1RouteTable7465C0F7
[~] AWS::EC2::Subnet Shop/webSubnet2/Subnet ShopwebSubnet2Subnet45249714
[~] AWS::EC2::RouteTable Shop/webSubnet2/RouteTable ShopwebSubnet2RouteTable50B3D37F
[~] AWS::EC2::InternetGateway Shop/IGW ShopIGWE4EB83B3
```

One line in the program reaches six resources, because `Tags.of(stack)` applies to everything in the
stack that can carry a tag. By default `cdk diff` also asks CloudFormation for a change set, to learn
which changes need a replacement; moto cannot create one for an existing stack, so these commands pass
`--method=template` and compare templates only.

The state is the stack, as in the last section. `cdk.out` is build output the next synth rewrites,
and it is left out of version control, as `node_modules` is. What goes in git is the program, which is the point of the
CDK: **loops, functions and classes for the description, with CloudFormation still doing the
deploying.**
