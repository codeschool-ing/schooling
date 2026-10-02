---
title: Reading and editing the state with terraform state
version: 1
---

Back in Ana's own directory, with the state that knows the three resources. The JSON can be read
with `jq`, as the first section did, and it should never be edited with a text editor: one stray
comma and Terraform cannot load it, and a field changed by hand is a lie the next plan believes.
**`terraform state` is the set of subcommands for looking at it and changing it safely.**

`list` prints every address the state holds:

```
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.a
aws_vpc.shop
```

`show` prints one of them, every attribute as the state recorded it, in the same syntax a
configuration uses:

```
ana@laptop:~/shop$ terraform state show aws_subnet.a
# aws_subnet.a:
resource "aws_subnet" "a" {
    arn                                            = "arn:aws:ec2:sa-east-1:123456789012:subnet/subnet-1849baa846a6631fa"
    assign_ipv6_address_on_creation                = false
    availability_zone                              = "sa-east-1a"
    availability_zone_id                           = "sae1-az1"
    cidr_block                                     = "10.20.1.0/24"
    customer_owned_ipv4_pool                       = null
    enable_dns64                                   = false
    enable_lni_at_device_index                     = 0
    enable_resource_name_dns_a_record_on_launch    = false
    enable_resource_name_dns_aaaa_record_on_launch = false
    id                                             = "subnet-1849baa846a6631fa"
    ipv6_cidr_block                                = null
    ipv6_cidr_block_association_id                 = null
    ipv6_native                                    = false
    map_customer_owned_ip_on_launch                = false
    map_public_ip_on_launch                        = false
    outpost_arn                                    = null
    owner_id                                       = "123456789012"
    private_dns_hostname_type_on_launch            = "ip-name"
    region                                         = "sa-east-1"
    tags                                           = {
        "Name" = "shop-a"
    }
    tags_all                                       = {
        "Name" = "shop-a"
    }
    vpc_id                                         = "vpc-10f2b2857589fd959"
}
```

Every value there came from AWS during the last apply or refresh. Many of them, `ipv6_native` or
`private_dns_hostname_type_on_launch`, are not in `main.tf` at all: the provider fills in the
defaults and the state keeps them, which is how a later plan notices when one of them changes.

## Renaming: `state mv`

Ana decides that `a` is a poor name for a subnet that will have siblings, and wants
`aws_subnet.public_a`. Renaming it in the file alone would look to Terraform like one resource
deleted and an unrelated one added. `state mv` renames the address in the state, and `-dry-run`
says what it would do without doing it:

```
ana@laptop:~/shop$ terraform state mv -dry-run aws_subnet.a aws_subnet.public_a
Would move "aws_subnet.a" to "aws_subnet.public_a"
ana@laptop:~/shop$ terraform state mv aws_subnet.a aws_subnet.public_a
Move "aws_subnet.a" to "aws_subnet.public_a"
Successfully moved 1 object(s).
```

The state has moved and the file has not, which is the dangerous half-way point. A plan now:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_subnet.a will be created
  # aws_subnet.public_a will be destroyed
  # (because aws_subnet.public_a is not in configuration)
Plan: 1 to add, 0 to change, 1 to destroy.
```

Read that as Terraform does. The state has a `public_a` the file does not mention, so it would be
destroyed; the file has an `a` the state does not know, so it would be created. **One destroy and
one create of the same subnet**, purely because the two halves disagree about a name. Ana makes the
file agree:

```
ana@laptop:~/shop$ sed -i 's/"aws_subnet" "a"/"aws_subnet" "public_a"/' main.tf
ana@laptop:~/shop$ grep aws_subnet main.tf
resource "aws_subnet" "public_a" {
ana@laptop:~/shop$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`, and the subnet kept its id. Lesson 4's `moved` block does this same rename from
inside the configuration, where a reviewer sees it and every copy of the state gets it on its next
plan. `state mv` is the hand tool for when there is no time for that, and it changes one state on
one machine.

## Forgetting: `state rm`

`state rm` removes an address from the state **without touching the real resource**. It is how
Terraform is told to stop managing something:

```
ana@laptop:~/shop$ terraform state rm aws_subnet.public_a
Removed aws_subnet.public_a
Successfully removed 1 resource instance(s).
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # aws_subnet.public_a will be created
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/shop$ aws ec2 describe-subnets --filters Name=tag:Name,Values=shop-a --query "Subnets[].[SubnetId,CidrBlock]" --output text
subnet-1849baa846a6631fa	10.20.1.0/24
```

The subnet is still in AWS; Terraform has forgotten it, and the plan wants to create one. That is
the losing-it accident again, for one resource. Lesson 6's `removed` block is the reviewable way
to stop managing something; `state rm` is the immediate one.

## The backups

For a local state, every `state mv` and `state rm` first writes the state as it was into a backup
file, named with the moment in Unix seconds. There is one from the `mv` and one from the `rm`, and
Ana copies the newest back over the state:

```
ana@laptop:~/shop$ ls terraform.tfstate*
terraform.tfstate
terraform.tfstate.1790913034.backup
terraform.tfstate.1790913055.backup
ana@laptop:~/shop$ cp "$(ls -t terraform.tfstate.*.backup | head -n 1)" terraform.tfstate
ana@laptop:~/shop$ terraform state list
aws_security_group.web
aws_subnet.public_a
aws_vpc.shop
ana@laptop:~/shop$ terraform plan | tail -n 3

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`public_a` is back, and the plan is clean. **This worked because the backup sat in the same
directory**, which is the same reason it would be gone with the laptop. "remote-backend" puts the
state where its history survives, and lesson 8 shows `terraform import`, which brings a real
resource back under management with no backup at all.
