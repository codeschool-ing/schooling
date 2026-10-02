---
title: The plan as data, and a guard that reads it
version: 1
---

The text of a plan is written for people: aligned columns, hidden unchanged attributes, a
summary. **A program should never parse that text.** Its layout is not a promise and changes
between versions. The same plan is available as JSON, and that format is versioned on purpose:

```
ana@laptop:~/shop$ terraform show -json tfplan | jq '{format_version, terraform_version, n: (.resource_changes | length)}'
{
  "format_version": "1.2",
  "terraform_version": "1.16.4",
  "n": 12
}
```

Here it is run against the saved plan from the last section, as it stood before it was applied.
The part a check needs is `resource_changes`, one entry per resource, each with a list of actions:

```
ana@laptop:~/shop$ terraform show -json tfplan | jq -c '.resource_changes[] | {address, actions: .change.actions}'
{"address":"data.aws_iam_policy_document.assets_read","actions":["read"]}
{"address":"aws_iam_role.web","actions":["no-op"]}
{"address":"aws_iam_role_policy.web_assets","actions":["create"]}
{"address":"aws_instance.web","actions":["delete","create"]}
{"address":"aws_s3_bucket.assets","actions":["create"]}
{"address":"aws_security_group.web","actions":["no-op"]}
{"address":"aws_subnet.a","actions":["update"]}
{"address":"aws_subnet.b","actions":["delete"]}
{"address":"aws_vpc.shop","actions":["no-op"]}
{"address":"aws_vpc_security_group_ingress_rule.https","actions":["no-op"]}
{"address":"aws_vpc_security_group_ingress_rule.ssh","actions":["no-op"]}
{"address":"random_password.db","actions":["create"]}
```

Twelve entries where the text showed seven, because the JSON also lists every resource the plan
leaves alone, as `no-op`. The rest map onto the symbols: `create` is `+`, `update` is `~`, `delete`
is `-`, `read` is `<=`. **A replacement is a list of two**, `["delete","create"]`, and with
`create_before_destroy` it would be `["create","delete"]`. So "does this plan delete anything?"
has a one-word answer in JSON: does any list contain `delete`?

That question is worth asking by machine because the text plan makes it easy to miss. A
replacement is a destroy, and in a long plan it looks like one more block of `~` lines with a
comment at the top. Ana writes a guard of a few lines that refuses any plan that deletes, for
whatever reason:

```sh
#!/bin/sh
# Refuse a saved plan that deletes anything, replacements included.
set -eu
plan=${1:-tfplan}
deletes=$(terraform show -json "$plan" | jq -r '
  .resource_changes[]
  | select(.change.actions | index("delete"))
  | "\(.change.actions | join(","))  \(.address)"')
if [ -n "$deletes" ]; then
  echo "refused: this plan deletes"
  echo "$deletes"
  exit 1
fi
echo "ok: this plan deletes nothing"
```

`index("delete")` is jq's way of asking whether the list contains that string; `select` keeps
the entries where it does. Run against the same plan, the guard names both deletions, the
replacement first, and fails:

```
ana@laptop:~/shop$ ./check-plan.sh tfplan; echo "exit $?"
refused: this plan deletes
delete,create  aws_instance.web
delete  aws_subnet.b
exit 1
```

Against a plan that only adds things, it passes. This one is the plan from two sections on, which
adds three resources:

```
ana@laptop:~/shop$ ./check-plan.sh tfplan; echo "exit $?"
ok: this plan deletes nothing
exit 0
```

**A guard does not decide; it makes a person decide.** Ana and her reviewer had already agreed to
lose subnet `b` and rebuild `web`, and the plan was applied in the last section. What the guard
changes is that a delete can no longer go through because nobody noticed it. In a pipeline,
lesson 15, a refusal like this one stops the job and asks for an explicit approval; on a laptop,
it is a habit you run before `apply tfplan`.

## A plan's exit code

There is one more machine-readable answer, and it needs no JSON at all. With
`-detailed-exitcode`, `terraform plan` exits with 0 when there is nothing to do, 1 on an error,
and 2 when there are changes. Before the apply:

```
ana@laptop:~/shop$ terraform plan -detailed-exitcode > /dev/null; echo "exit $?"
exit 2
```

And after it, the same command finds nothing left:

```
ana@laptop:~/shop$ terraform plan -detailed-exitcode > /dev/null; echo "exit $?"
exit 0
```

**That makes "is anything pending?" a question a scheduled job can ask every night.** Exit 2 on a
configuration nobody touched means the world moved, and lesson 7 showed what drift looks like
when you find it.
