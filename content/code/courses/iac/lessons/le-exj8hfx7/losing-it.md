---
title: Losing the state, and the second network
version: 1
---

The common belief is that the state is a cache: something Terraform keeps to go faster, and could
rebuild by looking around if it had to. **It cannot rebuild it.** Without the state, Terraform has
no idea that anything exists, and it does what any declarative tool does with a description and an
empty world: it creates the description.

Ana keeps the configuration in git, and she does what most guides say and leaves the state out:

```
.terraform/
*.tfstate
*.tfstate.*
```

```
ana@laptop:~/shop$ git ls-files
.gitignore
.terraform.lock.hcl
main.tf
```

There are good reasons for that line, and the next sections give them. It has one consequence that
is easy to miss: **a checkout of this repository has no state.** Deleting `terraform.tfstate` by
accident gives exactly the same situation, and so does a colleague's laptop, a new machine, or a CI
job. Ana clones her own repository into a second directory, as any of those would:

```
ana@laptop:~$ git clone -q shop shop-2
ana@laptop:~/shop-2$ ls -a
.
..
.git
.gitignore
.terraform.lock.hcl
main.tf
```

Same `main.tf`, same lock file, no `terraform.tfstate`. After `terraform init`, the plan:

```
ana@laptop:~/shop-2$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_security_group.web will be created
  # aws_subnet.a will be created
  # aws_vpc.shop will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

**Three to add.** The VPC, the subnet and the security group are all sitting in the account, and
the plan wants to create all three. Nothing in it is wrong from where Terraform stands: it was given
a description, it has no record of anything, so everything in the description is missing. And it
does not stop at a plan:

```
ana@laptop:~/shop-2$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
ana@laptop:~/shop-2$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-10f2b2857589fd959	10.20.0.0/16
vpc-fffe0fd578d4a6fe0	10.20.0.0/16
ana@laptop:~/shop-2$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[].[GroupId,VpcId]" --output text
sg-3bb7d165786e44657	vpc-10f2b2857589fd959
sg-867bd8138208c328c	vpc-fffe0fd578d4a6fe0
```

**Two VPCs called `shop`, both `10.20.0.0/16`, and two security groups called `web`, one in each.**
It is the same accident `network.sh` had in lesson 1, made by the tool that was supposed to prevent
it. Nothing failed along the way. A security group's name has to be unique only inside its VPC,
and the new group was created in the new VPC, so AWS had no reason to refuse.

In a real account the cost is not only the bill. The second network has the same range as the
first, which matters the day somebody tries to connect the two; whatever is added next lands in one
of them, and whoever opens the console has to work out which. And the original three are now
managed from nowhere: the state that knew them is in the other directory.

Here the copy is easy to remove, because the directory that created it has a state that knows
exactly those three:

```
ana@laptop:~/shop-2$ terraform destroy -auto-approve | tail -n 1
Destroy complete! Resources: 3 destroyed.
ana@laptop:~/shop-2$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-10f2b2857589fd959	10.20.0.0/16
ana@laptop:~$ rm -rf shop-2
```

One VPC is left, the original one, which Ana's first directory still manages. **That `destroy`
worked because the duplicate had a state.** Had she lost the original state instead, nothing would
know which of the identical VPCs was which, and sorting them out would mean reading ids by hand and
bringing them back under management with `terraform import`, which lesson 8 shows.

So keeping the state out of git does not solve the problem; it only stops git from being the
place the state lives. **Every person and every machine that runs Terraform on this network has to
read the same state**, the one copy, the latest serial. A file on one laptop cannot be that, and
"remote-backend" moves it somewhere that can. Before that, two more things the local file is
useful for: reading it and editing it with Terraform's own commands, and finding a change somebody
made behind its back.
