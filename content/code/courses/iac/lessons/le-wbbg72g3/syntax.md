---
title: Blocks, arguments and labels
version: 1
---

A Terraform file looks like a programming language and is closer to a form. **HCL has two kinds
of thing in it, blocks and arguments**, and an expression on the right of every argument. There
are no statements to run in order, no loops that execute and no functions you define. Ana's
`main.tf`, now with a variable read from a second file, shows nearly all of it:

```hcl
# The shop's network, as Terraform describes it.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

/* One VPC for the whole shop.
   Its subnets are in network.tf. */
resource "aws_vpc" "shop" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true // the machines get DNS names
  tags = {
    Name  = "shop"
    Owner = var.owner
  }
}
```

**A block** is a type, zero or more labels, and a body in braces. `resource "aws_vpc" "shop"` is
a block of type `resource` with two labels: the resource type, `aws_vpc`, and the name Ana gave
it, `shop`. How many labels a block takes is fixed by its type. `provider` takes one, `terraform`
takes none, and a block with the wrong number is an error. Blocks
nest: `required_providers` lives inside `terraform`, and lesson 6's `lifecycle` lives inside a
resource.

**An argument** is a name, an equals sign and an expression: `cidr_block = "10.20.0.0/16"`. The
sign is how you tell the two apart, and it matters in one place that catches everybody. `tags =
{ ... }` is an argument whose value happens to be a map, not a block called `tags`, so it can be
computed, merged or passed around like any other value. A block cannot.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The block resource \"aws_vpc\" \"shop\" with its parts named: the block type resource, the type label aws_vpc, the name label shop, and between the braces the body, holding the argument cidr_block whose expression is the string 10.20.0.0/16. Beside it, three block headers: locals takes no label, variable takes one, resource takes two.\"><text x=\"120.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">resource \"aws_vpc\" \"shop\" {</text><text x=\"120.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">  cidr_block = \"10.20.0.0/16\"</text><text x=\"120.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">}</text><text x=\"148.8\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">block type</text><path d=\"M148.8 43 L148.8 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"217.2\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">type label</text><path d=\"M217.2 68 L217.2 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"278.4\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">name label</text><path d=\"M278.4 43 L278.4 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170.4\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">argument name</text><path d=\"M170.39999999999998 146 L170.39999999999998 207\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"278.4\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">expression</text><path d=\"M278.4 146 L278.4 207\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M105 98 L98 98 L98 172 L105 172\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"88.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">body</text><text x=\"470.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">labels, by block type</text><text x=\"470.0\" y=\"105.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">locals {</text><text x=\"700.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">none</text><text x=\"470.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">variable \"environment\" {</text><text x=\"700.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one</text><text x=\"470.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">resource \"aws_vpc\" \"shop\" {</text><text x=\"700.0\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two</text></svg>", "caption": "A block is a type, as many labels as that type asks for, and a body; inside the body, every argument is a name and an expression."}
```

Names, called identifiers, may hold letters, digits, underscores and hyphens, and may not start
with a digit. Comments come in three spellings, all visible above: `#` and `//` to the end of the
line, `/* */` across lines. `#` is the one HashiCorp's style guide uses, and the other two exist
for people arriving from other languages.

**A configuration is every `.tf` file in one directory, read as one.** The order of the files
does not matter and neither does the order of the blocks inside them: `main.tf` uses
`var.owner`, and the variable is declared in another file. The names
`main.tf`, `variables.tf` and `outputs.tf` are a convention people follow so a colleague knows
where to look, and Terraform attaches no meaning to them. A subdirectory is not read at all;
lesson 10 makes one into a module.

The second file is in JSON. **Every block can be written as `.tf.json`**, with the block type and
its labels becoming nested keys:

```json
{
  "variable": {
    "owner": {
      "type": "string",
      "default": "ana",
      "description": "Who answers for these resources."
    }
  }
}
```

Nobody writes JSON by hand when HCL is available. It exists for the case where a program
generates the configuration, because every language can write JSON and almost none can write
HCL. Terraform mixes the two without complaint:

```
ana@laptop:~/shop$ ls
main.tf
owner.tf.json
ana@laptop:~/shop$ terraform validate
Success! The configuration is valid.
```

`terraform validate` reads the whole directory and checks it against the providers' schemas,
without asking AWS anything. It is the fastest way to find out that a file does not say what you
meant. Here is a subnet whose range Ana forgot to quote:

```hcl
resource "aws_subnet" "a" {
  vpc_id     = aws_vpc.shop.id
  cidr_block = 10.20.1.0/24
}
```

```
ana@laptop:~/shop$ terraform validate
╷
│ Error: Invalid number literal
│ 
│   on subnet.tf line 3, in resource "aws_subnet" "a":
│    3:   cidr_block = 10.20.1.0/24
│ 
│ Failed to recognize the value of this number literal.
╵
```

The parser saw `10.20` and tried to read a number, which is what an unquoted value starting with
a digit is. **The error names the file, the line and the block, and quotes the line.** Every
error in this lesson has that shape, and reading it from the quoted line outwards is the habit
worth having. Lesson 13 runs `validate` as the first step of a test suite.
