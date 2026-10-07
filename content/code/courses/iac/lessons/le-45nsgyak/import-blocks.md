---
title: Import blocks, and letting Terraform write the first draft
version: 2
---

Bruno's bucket had two arguments worth writing, and Ana could guess both. A security group made
by hand is a different matter. Somebody created one for the monitoring agent, in the shop's VPC,
with a rule nobody wrote down. To make it in your moto, run what they ran; `VPC` holds the shop's
VPC id and `MSG` the new group's:

```sh
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query 'Vpcs[0].VpcId' --output text)
MSG=$(aws ec2 create-security-group --vpc-id "$VPC" --group-name monitoring --description "node exporter" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $MSG --protocol tcp --port 9100 --cidr 10.20.0.0/16
aws ec2 create-tags --resources $MSG --tags Key=Name,Value=monitoring
```

The group, as the CLI finds it:

```
ana@laptop:~/shop/app$ aws ec2 describe-security-groups --filters Name=group-name,Values=monitoring --query "SecurityGroups[].[GroupId,GroupName]" --output text
sg-9dc3670bcfa1b0d03	monitoring
```

To write its block by hand, Ana would have to read every attribute AWS holds for it, decide which
ones the block must state, and plan until it stopped complaining. **Terraform can write that first
draft itself.** She declares the import in `imports.tf`, with the id the CLI just printed (yours
is the one your CLI printed), and writes no resource block at all:

```hcl
import {
  to = aws_security_group.monitoring
  id = "sg-9dc3670bcfa1b0d03"
}
```

Then a plan with one extra flag, `-generate-config-out`, which names the file to write:

```
ana@laptop:~/shop/app$ terraform plan -generate-config-out=generated.tf
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_security_group.monitoring: Preparing import... [id=sg-9dc3670bcfa1b0d03]
aws_security_group.monitoring: Refreshing state... [id=sg-9dc3670bcfa1b0d03]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_s3_bucket.backups: Refreshing state... [id=shop-backups-dev]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

Terraform will perform the following actions:

  # aws_security_group.monitoring will be imported
  # (config will be generated)
```

```
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

`(config will be generated)` is the new line. For every `import` block whose address has no
resource block, Terraform reads the object and writes a block for it into the file:

```
ana@laptop:~/shop/app$ cat generated.tf
# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "sg-9dc3670bcfa1b0d03"
resource "aws_security_group" "monitoring" {
  description = "node exporter"
  egress = [{
    cidr_blocks      = ["0.0.0.0/0"]
    description      = ""
    from_port        = 0
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "-1"
    security_groups  = []
    self             = false
    to_port          = 0
  }]
  ingress = [{
    cidr_blocks      = ["10.20.0.0/16"]
    description      = ""
    from_port        = 9100
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 9100
  }]
  name                   = "monitoring"
  region                 = "sa-east-1"
  revoke_rules_on_delete = null
  tags = {
    Name = "monitoring"
  }
  tags_all = {
    Name = "monitoring"
  }
  vpc_id = "vpc-644904a24046c8bab"
}
```

**This is a first draft, and the comment at its top says so.** It is a faithful dump of what the
provider read, and that is its problem. Read it as a reviewer would:

- Literal ids. `vpc_id` is the VPC's id as a string. In this configuration the VPC belongs to
  the network's state, and the reference to use is its output.
- Values that are defaults. Empty lists, `description = ""`, `self = false`,
  `revoke_rules_on_delete = null`: each says nothing a reader needs, and a block made of them is
  hard to review.
- Computed attributes. `tags_all` is what the provider works out from `tags` plus any
  provider-wide default tags; writing it down states the same thing twice.
- The less common syntax. The rules come out as `ingress = [{ … }]`, a list of objects, where
  the rest of this configuration writes `ingress { … }` blocks.

What it does get right is everything that matters: the name, the description, the port, the
range, the tag, and the egress rule that AWS adds to every new group, which moto, standing in for
AWS here, added too. Ana keeps those, in the house style, with the two values that belong to the network read from its
outputs, in `monitoring.tf`, and deletes the draft:

```hcl
resource "aws_security_group" "monitoring" {
  name        = "monitoring"
  description = "node exporter"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  tags        = { Name = "monitoring" }

  ingress {
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

```
ana@laptop:~/shop/app$ rm generated.tf
```

## The proof

Rewriting a generated block by hand is exactly where a value gets lost. **The plan is the check**,
and it says only one thing when the block is right:

```
ana@laptop:~/shop/app$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_security_group.monitoring will be imported
Plan: 1 to import, 0 to add, 0 to change, 0 to destroy.
```

One import and nothing else: no attribute the cleaned block states differs from the group as it
exists, so the import changes the state and leaves AWS alone. Had she dropped the egress rule or
mistyped the port, this plan would have shown an update beside the import, and she would edit the
block again until it did not. Then the apply, and the plan that closes it:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 1 imported, 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/app$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
ana@laptop:~/shop/app$ terraform state list
data.terraform_remote_state.network
aws_s3_bucket.assets
aws_s3_bucket.backups
aws_security_group.monitoring
aws_security_group.web
```

`1 imported`, then `No changes`, and the app's state holds four resources besides the data
source: the security group and the bucket it kept from the split, Bruno's bucket and the
monitoring group.

## Imports at scale

The same block works for fifty resources: fifty `import` blocks in one file, one plan, one
generated draft to clean. An `import` block also takes `for_each`, like a resource, for a set of
objects that follow one pattern, and its `id` may be an expression as long as it is known at plan
time. None of that changes the routine this section followed: **declare the import, let a plan
show it, make the block describe what exists, and accept nothing but an import and no changes.**
