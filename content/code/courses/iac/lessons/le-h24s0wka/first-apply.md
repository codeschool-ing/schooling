---
title: Reading the plan, and saying yes
version: 1
---

**A plan is Terraform's proposal: what the configuration asks for, what already exists, and the
difference between them written as actions.** Nothing changes while you read it. `terraform plan`
prints the proposal and stops; `terraform apply` prints the same proposal and then asks. Here is
the start of the shop's first one:

```
ana@laptop:~/shop$ terraform plan

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_security_group.web will be created
  + resource "aws_security_group" "web" {
      + arn                    = (known after apply)
      + description            = "web servers"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = (known after apply)
      + name                   = "web"
      + name_prefix            = (known after apply)
      + owner_id               = (known after apply)
      + region                 = "sa-east-1"
      + revoke_rules_on_delete = false
      + tags_all               = (known after apply)
      + vpc_id                 = (known after apply)
    }

```

Read the header first. Every action has a symbol, and the header lists the ones this plan uses:
here only `+`, create. This lesson meets two more, `~` and `-`, and lesson 9 goes through all of
them and what to look for in each.

Then each resource, by address, with every attribute it will have. Values from the file appear as
they were written: `"web"`, `"web servers"`. Some come from the provider's defaults, like
`revoke_rules_on_delete = false`, which nobody typed. And `region` is there although no resource
mentions it, because the provider block set it for all of them. **`(known after apply)` marks
whatever nobody can know until AWS answers**: the id, the ARN, and `vpc_id`, because that is the
VPC's id and the VPC does not exist yet. A plan is computed before anything happens, so a value
the cloud invents is a blank in it.

The same block follows for the subnet, the VPC and the rule, in alphabetical order of address, not
in the order they will be created. The plan ends on the line worth reading first:

```
Plan: 4 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

Four to add, nothing to change or destroy: exactly the four blocks in `main.tf`, which is the
check to make every time. A plan that says `1 to destroy` where you expected none is the moment to
stop. The note underneath is about saving a plan with `-out`, which lesson 9 covers; here the plan
is simply thrown away.

`terraform apply` computes the same plan again, prints it, and stops at a question. **Anything
other than the exact word `yes` cancels**, which is what happened when Ana answered `no`:

```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: no
Apply cancelled.
```

And with `yes`:

```
Plan: 4 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 2s [id=vpc-7327c901412b20229]
aws_subnet.web_a: Creating...
aws_security_group.web: Creating...
aws_subnet.web_a: Creation complete after 1s [id=subnet-246685d4ada451bad]
aws_security_group.web: Creation complete after 1s [id=sg-3475d5edf795d5594]
aws_vpc_security_group_ingress_rule.https: Creating...
aws_vpc_security_group_ingress_rule.https: Creation complete after 0s [id=sgr-dcc6bf0490cd0c301]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**The order in the log is the graph from the last section.** The VPC alone first. Then the subnet
and the security group, both started before either finished. Then the rule, which had to wait for
the group's id. Terraform walks the graph and starts whatever has nothing left to wait for, up to
ten operations at once unless `-parallelism` says otherwise.

The ids at the end of each line are the ones AWS invented, moto here, and they change on every run
of the lab. Terraform wrote each one into a new file, `terraform.tfstate`, the moment it received
it. That file is how it knows which real VPC is `aws_vpc.shop`, and `terraform state list` shows
the four addresses it now tracks. AWS agrees about the subnet:

```
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.web_a
aws_vpc.shop
aws_vpc_security_group_ingress_rule.https
ana@laptop:~/shop$ aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-web-a --query "Subnets[].[SubnetId,VpcId,CidrBlock]" --output text
subnet-246685d4ada451bad	vpc-7327c901412b20229	10.20.1.0/24
```

Then the test lesson 1 ended on: apply again, changing nothing.

```
ana@laptop:~/shop$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-7327c901412b20229]
aws_security_group.web: Refreshing state... [id=sg-3475d5edf795d5594]
aws_subnet.web_a: Refreshing state... [id=subnet-246685d4ada451bad]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-dcc6bf0490cd0c301]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
```

The `Refreshing state` lines are Terraform reading each resource back from AWS by the id it
stored. **`No changes` means the configuration and the world agree**, so there is nothing to ask
about, and nothing was done.

`-auto-approve` answered the question for this run, and it is how Terraform runs where nobody can
type. Used by hand, it skips the one moment you read the plan before it happens. Lesson 15 shows
the safe version: a pipeline that applies a plan somebody already reviewed, rather than a fresh
one nobody read.
