---
title: Drift, found by a plan
version: 1
---

Lesson 1 left a colleague's rule on the `web` security group, port 22 open to the world, typed by
hand from another machine, and promised that Terraform would find it. Here it is again, added the
same way to the group Terraform now manages:

```
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	22	0.0.0.0/0
```

Ana has not touched `main.tf`. She runs a plan, the ordinary one:

```
ana@laptop:~/shop$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_security_group.web will be updated in-place
  ~ resource "aws_security_group" "web" {
        id                     = "sg-3bb7d165786e44657"
      ~ ingress                = [
          - {
              - cidr_blocks      = [
                  - "0.0.0.0/0",
                ]
              - from_port        = 22
              - ipv6_cidr_blocks = []
              - prefix_list_ids  = []
              - protocol         = "tcp"
              - security_groups  = []
              - self             = false
              - to_port          = 22
                # (1 unchanged attribute hidden)
            },
            # (1 unchanged element hidden)
        ]
        name                   = "web"
        tags                   = {
            "Name" = "web"
        }
        # (9 unchanged attributes hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

**Every plan starts by reading the real resources back.** The three `Refreshing state...` lines are
that read, one call to AWS per id the state holds. Terraform then has three versions of the
security group in hand: the file, which has one rule; the state, which recorded one rule at the last
apply; and AWS, which now answers with two. The plan is the difference between the file and AWS,
and it proposes to make AWS match the file: the `-` lines remove the port 22 rule, `0 to add, 1 to
change, 0 to destroy`.

That is the right answer only if the file is right, and a plan cannot know that. Somebody opened the
port for a reason. Before anything is undone, it helps to see the drift on its own, without a
proposal mixed in:

```
ana@laptop:~/shop$ terraform plan -refresh-only
aws_vpc.shop: Refreshing state... [id=vpc-10f2b2857589fd959]
aws_subnet.public_a: Refreshing state... [id=subnet-1849baa846a6631fa]
aws_security_group.web: Refreshing state... [id=sg-3bb7d165786e44657]

Note: Objects have changed outside of Terraform

Terraform detected the following changes made outside of Terraform since the
last "terraform apply" which may have affected this plan:

  # aws_security_group.web has changed
  ~ resource "aws_security_group" "web" {
        id                     = "sg-3bb7d165786e44657"
      ~ ingress                = [
          + {
              + cidr_blocks      = [
                  + "0.0.0.0/0",
                ]
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
                # (1 unchanged attribute hidden)
            },
            # (1 unchanged element hidden)
        ]
        name                   = "web"
        tags                   = {
            "Name" = "web"
        }
        # (9 unchanged attributes hidden)
    }


This is a refresh-only plan, so Terraform will not take any actions to undo
these. If you were expecting these changes then you can apply this plan to
record the updated values in the Terraform state without changing any remote
objects.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

`-refresh-only` asks a narrower question: *what changed out there since the state was written?* The
answer is the same rule, now with `+` signs, because from the state's point of view the rule was
added. Applying a refresh-only plan (`terraform apply -refresh-only`) writes those values into the
state and changes nothing in AWS. It is how you accept that the world moved, before deciding what
to do about it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three boxes: the configuration, the state and the real account. A refresh reads the account into the state. A plan compares the configuration with what the refresh found. terraform apply changes the account to match the configuration; terraform apply -refresh-only changes only the state to match the account.\"><defs><marker id=\"th-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"th-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"th-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">configuration</text><text x=\"105.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one rule: 443</text><rect x=\"275\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state</text><text x=\"360.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what was last seen</text><rect x=\"530\" y=\"80\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AWS</text><text x=\"615.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two rules: 443, 22</text><path d=\"M528 100 L447 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#th-ah-wire)\"></path><text x=\"487.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">refresh</text><path d=\"M105 152 L105 200 L615 200 L615 152\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#th-ah-phosphor)\"></path><text x=\"360.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">terraform apply</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the file wins</text><path d=\"M615 78 L615 40 L360 40 L360 78\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#th-ah-amber)\"></path><text x=\"487.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">terraform apply -refresh-only</text><text x=\"487.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the world wins, in the state</text></svg>", "caption": "Drift is a three-way comparison, and each kind of apply decides a different winner."}
```

**There are two ways out, and each makes one side win.**

- The file wins. The rule was a mistake, or a one-off that should not have outlived the
  afternoon. `terraform apply` removes it, as the plan said.
- The world wins. The rule is needed. Then it belongs in `main.tf`, as a second `ingress`
  block, reviewed like any other change, and after that a plan has nothing to do.

What is never an answer is leaving it: the next person to run `apply` for an unrelated reason will
remove the rule without having read why it was there. Ana asks, learns that the SSH access was for
one evening's debugging, and lets the file win:

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
```

**Terraform found this rule because of how the group was written.** With `ingress` blocks inside
`aws_security_group`, the resource owns the whole list of rules, so an extra one is a difference.
The AWS provider also offers one resource per rule, `aws_vpc_security_group_ingress_rule`, and its
documentation recommends that style; with it, Terraform compares only the rules it created, and a
rule nobody declared is invisible to every plan. Neither is wrong, but you should know which kind of
drift your configuration can see. And a plan sees drift only when somebody runs one: a scheduled
`terraform plan -detailed-exitcode`, which exits with 2 when there are changes, is how teams find
out on a Tuesday instead of during an incident. Lesson 15 puts plans into a pipeline.
