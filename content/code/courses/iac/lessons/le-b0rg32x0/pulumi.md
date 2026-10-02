---
title: Pulumi, a program with an engine of its own
version: 1
---

**Pulumi cannot be installed in this lab**, which has no network to download it from. Everything in
this section is illustrative: the files below were written for it and were not run, and no output is
shown, because none was produced.

Pulumi sits between the last two sections and Terraform. Like the CDK, you write a program in a
general-purpose language: TypeScript, JavaScript, Python, Go, C#, Java, or YAML for small cases.
**Unlike the CDK, nothing turns it into a template for another service.** Pulumi's own engine
compares what the program declares with Pulumi's own state and calls the cloud's API through a
provider, which is Terraform's model with a different language in front of it.

## A program

The shop's VPC and two subnets, one per availability zone, as a Pulumi program in JavaScript. A
project is a directory with a `Pulumi.yaml`:

```yaml
name: shop-network
runtime: nodejs
description: The shop's network
```

and the program itself, `index.js`:

```js
"use strict";
const aws = require("@pulumi/aws");

const vpc = new aws.ec2.Vpc("shop", {
  cidrBlock: "10.20.0.0/16",
  tags: { Name: "shop" },
});

const zones = ["sa-east-1a", "sa-east-1c"];

const subnets = zones.map((zone, i) =>
  new aws.ec2.Subnet(`web-${i + 1}`, {
    vpcId: vpc.id,
    cidrBlock: `10.20.${i + 1}.0/24`,
    availabilityZone: zone,
    tags: { Name: `shop-web-${i + 1}` },
  }));

exports.vpcId = vpc.id;
exports.subnetIds = subnets.map((s) => s.id);
```

The argument names will look familiar, `cidrBlock` where HCL says `cidr_block`. That is not an
accident: `@pulumi/aws` is built from the same Terraform AWS provider, through a bridge Pulumi
maintains, so the resource types and their arguments match lesson 2's almost one for one.

**`new aws.ec2.Vpc(...)` does not create a VPC.** It registers one with the engine, and the program
carries on at once. That is why `vpc.id` is not a string: it is an `Output`, a value that will exist
after the engine has made the VPC, the same thing a Terraform plan shows as `(known after apply)`.
Passing it to the subnet records the dependency, exactly as a reference does in HCL. A program that
tries to print it, or to branch on it with an `if`, finds nothing there yet.

The loop is an ordinary `map`. That is the attraction, and the risk alongside it: the program can do
anything JavaScript can, including read a file, call a web service or pick a random number while it
runs. Each of those makes the next preview different from this one. A Pulumi program stays a
description only as long as you keep it one.

## The commands, and the state

The workflow has the shape you know, under other names. These are the commands; their output is not
shown here:

```sh
pulumi login --local                     # keep the state in files under ~/.pulumi
pulumi stack init dev                    # one stack per environment
pulumi config set aws:region sa-east-1   # stored in Pulumi.dev.yaml
pulumi preview                           # the plan
pulumi up                                # shows the preview again, then asks
pulumi destroy
```

A **stack** in Pulumi is an instance of the project with its own configuration and its own state,
closer to lesson 11's workspaces than to a CloudFormation stack. Where that state lives is a choice
made at `pulumi login`: Pulumi Cloud, the company's hosted service, is the default; a bucket such as
`s3://shop-pulumi-state` or a local directory are the alternatives. Everything lesson 7 said about
protecting a state applies, and a value set with `pulumi config set --secret` is stored encrypted,
both in the stack's configuration file and in the state.
