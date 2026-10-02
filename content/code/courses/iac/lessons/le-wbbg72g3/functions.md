---
title: Built-in functions, and cidrsubnet above all
version: 1
---

HCL has more than a hundred functions and **you cannot write one of your own**. That surprises
people arriving from a programming language, and it is deliberate: a configuration is meant to be
read by somebody reviewing a change, and every function in it is one they can look up. What you
can do is combine the ones that exist, and the console is the place to learn them, one call at a
time.

## Cutting a network into subnets

The function this course leans on most is `cidrsubnet`. Ana's VPC is `10.20.0.0/16`, and she
wants `/24` subnets inside it without working out the arithmetic by hand:

```
ana@laptop:~/shop$ echo 'cidrsubnet("10.20.0.0/16", 8, 1)' | terraform console
"10.20.1.0/24"
ana@laptop:~/shop$ echo 'cidrsubnet("10.20.0.0/16", 8, 2)' | terraform console
"10.20.2.0/24"
ana@laptop:~/shop$ echo 'cidrhost("10.20.1.0/24", 10)' | terraform console
"10.20.1.10"
```

`cidrsubnet(prefix, newbits, netnum)` lengthens the prefix by `newbits` and returns subnet number
`netnum` of the ones that makes. Eight new bits turn a `/16` into `/24`s, of which there are 256,
and asking for number 1 gives `10.20.1.0/24`. `cidrhost` goes one level down and returns one
address inside a range: host 10 of the first subnet is `10.20.1.10`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"The 32 bits of 10.20.0.0/16 drawn as three fields. The first 16 bits, 10.20, are fixed by the /16. cidrsubnet with 8 new bits claims the next 8 bits as a network number. The last 8 bits are left for hosts. Network number 1 gives 10.20.1.0/24, 2 gives 10.20.2.0/24, and 255 gives 10.20.255.0/24: 256 subnets of 256 addresses each.\"><defs><marker id=\"ci-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">cidrsubnet(\"10.20.0.0/16\", 8, 1)</text><rect x=\"60\" y=\"60\" width=\"300\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">10.20</text><text x=\"210.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16 bits fixed by the /16</text><rect x=\"370\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">network number</text><text x=\"445.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 new bits</text><rect x=\"530\" y=\"60\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"605.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">host</text><text x=\"605.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 bits left</text><text x=\"445.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">1</text><text x=\"300.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.1.0/24</text><path d=\"M425 160 L370 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ci-ah-phosphor)\"></path><text x=\"445.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">2</text><text x=\"300.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.2.0/24</text><path d=\"M425 190 L370 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ci-ah-phosphor)\"></path><text x=\"445.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">255</text><text x=\"300.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">10.20.255.0/24</text><path d=\"M425 220 L370 220\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ci-ah-phosphor)\"></path><text x=\"445.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">netnum</text><text x=\"300.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">result</text><text x=\"605.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">256 subnets,</text><text x=\"605.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each a /24</text></svg>", "caption": "cidrsubnet adds bits to the prefix and numbers the subnets they make; the third argument picks one of them."}
```

**The point is not saving arithmetic, it is having one source.** Written as literals, a subnet
range repeats a fact the VPC already states, and the two can disagree after an edit. Written as
`cidrsubnet(var.network.cidr, 8, 1)`, the subnet follows the VPC wherever it moves. Further on in this lesson a
`for` expression computes the `netnum` from a position, and lesson 4 creates one subnet per value.

## Strings, lists and maps

```
ana@laptop:~/shop$ echo 'format("%s-%s", "shop", var.environment)' | terraform console
"shop-dev"
ana@laptop:~/shop$ echo 'join(", ", var.network.azs)' | terraform console
"sa-east-1a, sa-east-1c"
ana@laptop:~/shop$ echo 'merge({ Project = "shop", Owner = "ana" }, { Owner = "bruno" })' | terraform console
{
  "Owner" = "bruno"
  "Project" = "shop"
}
```

`format` is `printf`. `join` glues a list into one string. `merge` combines maps and **the later
map wins** where two share a key, which is exactly what default tags and an override need: the
second map changed `Owner` and kept `Project`. There are dozens more in the same families, from
`upper` and `replace` to `concat`, `distinct` and `keys`, and the encoders `jsonencode` and
`yamlencode` that turn a value into text another program reads.

## When a value may not be there

`lookup` reads a key from a map, and a missing key is an error unless you give it a default:

```
ana@laptop:~/shop$ echo 'lookup({ dev = "t3.micro", prod = "t3.large" }, var.environment)' | terraform console
"t3.micro"
ana@laptop:~/shop$ echo 'lookup({ dev = "t3.micro", prod = "t3.large" }, "staging")' | terraform console
╷
│ Error: Invalid function argument
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ Invalid value for "inputMap" parameter: the given object has no attribute
│ "staging".
╵

ana@laptop:~/shop$ echo 'lookup({ dev = "t3.micro", prod = "t3.large" }, "staging", "t3.small")' | terraform console
"t3.small"
```

`try` and `can` are the general versions. `try` evaluates its arguments in turn and returns the
first that does not fail; `can` returns whether an expression would fail, as `true` or `false`:

```
ana@laptop:~/shop$ echo 'var.network.nat' | terraform console
╷
│ Error: Unsupported attribute
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ This object does not have an attribute named "nat".
╵

ana@laptop:~/shop$ echo 'try(var.network.nat, false)' | terraform console
false
ana@laptop:~/shop$ echo 'can(cidrnetmask("10.20.0.0/33"))' | terraform console
false
```

`var.network` has no attribute `nat`, so reading it is an error and `try` falls back to `false`.
**`can` exists mostly for validation rules**, where "would this fail?" is the question being
asked: `cidrnetmask` refuses a `/33`, so `can` answers `false`, and the last section of this
lesson uses exactly that shape. Use `try` sparingly elsewhere. A fallback that hides a typo in an
attribute name hides it for good.

## Functions from a provider

Since Terraform 1.8 a provider can ship functions of its own, called with the provider's name in
front. The AWS provider has a few, such as one that takes an ARN apart:

```
ana@laptop:~/shop$ echo 'provider::aws::arn_parse("arn:aws:s3:::shop-assets")' | terraform console
{
  "account_id" = ""
  "partition" = "aws"
  "region" = ""
  "resource" = "shop-assets"
  "service" = "s3"
}
```

Almost every function, built in or not, is **pure**: the same arguments give the same result, and
nothing is read from the network. A handful, such as `timestamp()`, are the exception, and their
value changes on every plan, which is why they do not belong in an argument that would then
change on every run.
