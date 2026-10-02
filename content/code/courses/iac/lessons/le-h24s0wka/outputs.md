---
title: Outputs, and what a configuration hands back
version: 1
---

The ids AWS invented for the shop's network are in the state file and in the scrollback of an
apply, and neither is a good place to fetch them from. **The habit to avoid is reading the state
file directly**, with `jq` or `grep`: its layout is Terraform's own business, and lesson 7 opens it
to show why. Variables are what a configuration takes in; **outputs are what it promises to give
back**, declared in blocks like everything else:

```hcl
output "vpc_id" {
  description = "The id AWS gave the shop's VPC."
  value       = aws_vpc.shop.id
}

output "web_subnet_id" {
  value = aws_subnet.web_a.id
}

output "web_security_group_id" {
  value = aws_security_group.web.id
}
```

Each output has a name and a `value`, which is any expression, here three attribute references.
`description` is optional and works as it does on a variable. Ana applies:

```
ana@laptop:~/shop$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-7327c901412b20229]
aws_security_group.web: Refreshing state... [id=sg-3475d5edf795d5594]
aws_subnet.web_a: Refreshing state... [id=subnet-246685d4ada451bad]
aws_vpc_security_group_ingress_rule.https: Refreshing state... [id=sgr-dcc6bf0490cd0c301]

Changes to Outputs:
  + vpc_id                = "vpc-7327c901412b20229"
  + web_security_group_id = "sg-3475d5edf795d5594"
  + web_subnet_id         = "subnet-246685d4ada451bad"

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

vpc_id = "vpc-7327c901412b20229"
web_security_group_id = "sg-3475d5edf795d5594"
web_subnet_id = "subnet-246685d4ada451bad"
```

**Adding an output changes no resource, and it still needs an apply.** The plan above has no
resource actions at all, only `Changes to Outputs`, and `0 added, 0 changed, 0 destroyed`. Outputs
are computed during an apply and stored in the state, and the apply is what writes them there.

`terraform output` reads them back, in three shapes for three kinds of reader:

```
ana@laptop:~/shop$ terraform output
vpc_id = "vpc-7327c901412b20229"
web_security_group_id = "sg-3475d5edf795d5594"
web_subnet_id = "subnet-246685d4ada451bad"
ana@laptop:~/shop$ terraform output vpc_id
"vpc-7327c901412b20229"
ana@laptop:~/shop$ terraform output -raw vpc_id; echo
vpc-7327c901412b20229
```

With no name it lists everything. With a name it prints that one value in HCL syntax, with the
quotes that say it is a string. **With `-raw` it prints the bare string, without quotes and without
even a newline**, which is why Ana's command adds `; echo`: without it, the next prompt would have
been printed on the same line. A missing newline is exactly what a script wants, because the value
goes straight into another command:

```
ana@laptop:~/shop$ aws ec2 describe-vpcs --vpc-ids "$(terraform output -raw vpc_id)" --query "Vpcs[].Tags" --output text
Name	shop
Environment	dev
```

That command asks AWS about whichever VPC this configuration created, today, without anybody
copying an id. The tags it returns are `Name` and the `Environment` the last section added.

For a program rather than a shell, `-json` gives every output with its type, and with a flag
lesson 12 is about:

```
ana@laptop:~/shop$ terraform output -json
{
  "vpc_id": {
    "sensitive": false,
    "type": "string",
    "value": "vpc-7327c901412b20229"
  },
  "web_security_group_id": {
    "sensitive": false,
    "type": "string",
    "value": "sg-3475d5edf795d5594"
  },
  "web_subnet_id": {
    "sensitive": false,
    "type": "string",
    "value": "subnet-246685d4ada451bad"
  }
}
```

`sensitive` is `false` on all three. An output marked sensitive is hidden in the plan and in the
plain listing, and lesson 12 shows exactly how much that protects, which is less than it sounds.

**Outputs come from the state, not from the files.** Ask for one that has not been applied, and
Terraform says it cannot find it and suggests the apply:

```
ana@laptop:~/shop$ terraform output bucket_name
╷
│ Error: Output "bucket_name" not found
│ 
│ The output variable requested could not be found in the state file. If you
│ recently added this to your configuration, be sure to run `terraform
│ apply`, since the state won't be updated with new output variables until
│ that command is run.
╵
```

Here the name is wrong, since Ana has no `bucket_name` output, but the message is the same
one you get after writing a new output block and forgetting to apply it.

Outputs matter beyond the terminal. They are the one part of a configuration that other
configurations are meant to read: lesson 8 has the shop's application read the network's outputs
from another state, and lesson 10 makes them the interface of a module. **Choosing what to output
is choosing what other people may depend on**, so an output is worth a moment's thought before it
is published, and a description when its meaning is not obvious from the name.
