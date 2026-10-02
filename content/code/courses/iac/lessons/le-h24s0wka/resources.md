---
title: Resources, and the references between them
version: 1
---

A VPC on its own carries nothing. The shop needs a subnet for its web servers and a security group
that lets HTTPS in, so `main.tf` grows by three blocks:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"

  tags = {
    Name = "shop"
  }
}

resource "aws_subnet" "web_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "shop-web-a"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}
```

The new idea is all in one line, `vpc_id = aws_vpc.shop.id`, and it is two ideas at once.

**An argument is a value you set; an attribute is a value the resource has once it exists.**
`cidr_block` is an argument. `id` is an attribute: nobody writes a VPC's id, AWS invents it when
the VPC is created, and Terraform reads it back. A resource exposes its arguments and many
attributes besides, and the provider's documentation lists both for every type. The VPC alone has
`arn`, `owner_id`, `main_route_table_id` and more than a dozen others, and the plan in the next
section shows most of them as `(known after apply)`.

**A reference, `TYPE.NAME.ATTRIBUTE`, is also a dependency.** The subnet cannot be created before
the VPC, because until then there is no id to give it. Nobody has to tell Terraform that. It reads
the references and builds a graph out of them: the subnet and the security group point at the VPC,
and the ingress rule points at the security group. `terraform graph` prints that graph in DOT, the
language Graphviz draws from:

```
ana@laptop:~/shop$ terraform graph
digraph G {
  rankdir = "RL";
  node [shape = rect, fontname = "sans-serif"];
  "aws_security_group.web" [label="aws_security_group.web"];
  "aws_subnet.web_a" [label="aws_subnet.web_a"];
  "aws_vpc.shop" [label="aws_vpc.shop"];
  "aws_vpc_security_group_ingress_rule.https" [label="aws_vpc_security_group_ingress_rule.https"];
  "aws_security_group.web" -> "aws_vpc.shop";
  "aws_subnet.web_a" -> "aws_vpc.shop";
  "aws_vpc_security_group_ingress_rule.https" -> "aws_security_group.web";
}
```

Read each `->` as "depends on". The line that is missing matters as much as the three that are
there. Nothing joins the subnet and the security group, so neither waits for the other, and the
apply in the next section starts them at the same moment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 250\" role=\"img\" aria-label=\"The dependency graph of the shop's network, read as the order of creation. The VPC aws_vpc.shop comes first, alone. Arrows lead from it to aws_subnet.web_a and to aws_security_group.web, which are created together in the second step. A third arrow leads from the security group to aws_vpc_security_group_ingress_rule.https, created last.\"><defs><marker id=\"gr-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"gr-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"95.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 · first, alone</text><text x=\"330.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2 · together</text><text x=\"615.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3 · once the group exists</text><rect x=\"20\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_vpc.shop</text><rect x=\"230\" y=\"45\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_subnet.web_a</text><rect x=\"230\" y=\"155\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.web</text><rect x=\"490\" y=\"155\" width=\"250\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">aws_vpc_security_group_ingress_rule.https</text><path d=\"M170 118 L228 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-ah-phosphor)\"></path><path d=\"M170 132 L228 174\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-ah-phosphor)\"></path><path d=\"M430 180 L488 180\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#gr-ah-amber)\"></path><text x=\"615.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no arrow between the subnet and the group:</text><text x=\"615.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">neither waits for the other</text><text x=\"380.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">each arrow is a reference: the second needs an id the first only has once it exists</text></svg>", "caption": "The graph `terraform graph` printed, drawn as the order apply follows: anything whose dependencies exist is started, and the rest waits."}
```

The instinct this replaces is ordering the blocks in the file the way they must be created, or
adding an explicit `depends_on` everywhere to be safe. Neither does anything useful. The order in
the file is ignored, and a reference carries its dependency along with its value. `depends_on`
exists for the rare dependency that no attribute expresses, and lesson 6 shows when that happens.

**The rule is a resource of its own.** The security group could carry its rules as `ingress` blocks
inside it, and the AWS provider still accepts that form. Its documentation recommends the separate
`aws_vpc_security_group_ingress_rule` instead, one address range per rule, so that each rule has
its own address and can be added or removed without rewriting the group. Lesson 1's drift was one
extra rule on this group, and with one resource per rule, a rule nobody declared is easy to name.

Before anything is planned, `terraform validate` checks the configuration on its own, without
asking AWS a thing: every reference points at something declared, every argument exists for its
type, and every value has a type that fits.

```
ana@laptop:~/shop$ terraform validate
Success! The configuration is valid.
```

**Valid means coherent, not accepted.** A subnet whose range lies outside its VPC's range passes
`validate` without complaint and fails at apply, because only AWS knows that rule. What `validate`
buys you is speed: it runs in a second, needs no credentials, and catches the typo in an attribute
name before a plan spends time talking to the cloud. Lesson 13 puts it at the bottom of a whole
ladder of checks.
