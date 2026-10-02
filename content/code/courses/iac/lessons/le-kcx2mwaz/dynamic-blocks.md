---
title: dynamic blocks, for what repeats inside a resource
version: 1
---

`count` and `for_each` repeat whole resources. Some repetition happens one level down, inside a
single resource: a security group has one `ingress` block per rule, written as nested blocks
rather than as arguments. **A nested block cannot take `count` or `for_each` itself**, and writing
out one per port is the copy-and-edit problem again. A `dynamic` block generates them.

Ana's web servers need ports 80 and 443 open, and she expects the list to grow:

```hcl
variable "web_ports" {
  type    = list(number)
  default = [80, 443]
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.shop.id

  dynamic "ingress" {
    for_each = var.web_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

Read it from the outside in. `dynamic "ingress"` names the block it generates. `for_each` is the
collection to walk, and unlike the resource-level argument it accepts a list. `content` is the
body of each generated block. Inside it, the current element is reached through a variable named
after the block, `ingress.value`; `ingress.key` would be its index in the list. If that name
collides with something, an `iterator` argument gives it another.

The plan shows what the `dynamic` block turned into, two ordinary `ingress` blocks:

```
  # aws_security_group.web will be created
  + resource "aws_security_group" "web" {
      + arn                    = (known after apply)
      + description            = "Managed by Terraform"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + from_port        = 443
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 443
                # (1 unchanged attribute hidden)
            },
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + from_port        = 80
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 80
                # (1 unchanged attribute hidden)
            },
```

AWS agrees, which you can check without Terraform:

```
ana@laptop:~/shop/network$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	80	0.0.0.0/0
```

## Reading the plan when the list grows

The trouble starts with the next change. Add 8443 to the list and look at what the plan says
about the rules, cut down to the ports:

```
ana@laptop:~/shop/network$ terraform plan -no-color -var "web_ports=[80, 443, 8443]" | grep -E "^  # |from_port|^Plan"
  # aws_security_group.web will be updated in-place
              - from_port        = 443
              - from_port        = 80
              + from_port        = 8443
              + from_port        = 443
              + from_port        = 80
Plan: 0 to add, 1 to change, 0 to destroy.
```

The rules live inside one resource, as a set, and the plan compares the set as a whole: it lists
the two rules that were there going out and three coming in. **Only one rule is new**, and the
reviewer has to work that out by comparing ports by eye. With two rules it is easy. With fifteen,
it is where a mistake goes past unnoticed.

## When a separate resource is better

The AWS provider has a resource per rule, `aws_vpc_security_group_ingress_rule`, and its
documentation recommends it over inline `ingress` blocks. Each rule then becomes a resource with
its own address, and the repetition goes back to `for_each`. Ana tries it in a directory of its
own, `~/shop/rules`, with the ports as a set of strings so they can be keys:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variable "web_ports" {
  type    = set(string)
  default = ["80", "443"]
}

resource "aws_vpc" "rules" {
  cidr_block = "10.50.0.0/16"
}

resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.rules.id
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = var.web_ports

  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = each.value
  to_port           = each.value
  cidr_ipv4         = "0.0.0.0/0"
}
```

After one apply, the same change is now one line of plan:

```
ana@laptop:~/shop/rules$ terraform state list
aws_security_group.web
aws_vpc.rules
aws_vpc_security_group_ingress_rule.web["443"]
aws_vpc_security_group_ingress_rule.web["80"]
ana@laptop:~/shop/rules$ terraform plan -no-color -var 'web_ports=["80", "443", "8443"]' | grep -E "^  # |^Plan"
  # aws_vpc_security_group_ingress_rule.web["8443"] will be created
Plan: 1 to add, 0 to change, 0 to destroy.
```

`aws_vpc_security_group_ingress_rule.web["8443"] will be created`, and nothing else is mentioned.
The rule for 443 has an address of its own that a removal, a review or an import can point at.
Do not mix the two styles on one security group: the inline blocks and the separate rules would
each try to own the full set of rules and undo each other on every apply.

So `dynamic` is for nested blocks that have no resource of their own, and there are many: the
`setting` blocks of an Elastic Beanstalk environment, the `rule` blocks of an S3 bucket's
lifecycle configuration. HashiCorp's own documentation warns that overusing `dynamic` makes a configuration
hard to read. A block that generates two fixed entries is usually clearer written out twice.
