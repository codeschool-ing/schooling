---
title: Saving a plan, and applying exactly that plan
version: 1
---

Every plan in this course that was not saved has ended with the same note, and it is worth taking
literally: without `-out`, Terraform "can't guarantee to take exactly these actions" if you run
`apply` now. **The plan you read and the plan `apply` carries out are two different computations.** `terraform
apply` with no argument plans again from scratch, and anything that changed in between, a
colleague's apply, a manual edit in the console, another branch's change, changes what it does.
The question it asks shows you the new plan, but it is the old one you reviewed.

`-out` writes the plan to a file instead:

```
ana@laptop:~/shop$ terraform plan -out=tfplan | tail -n 6
─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

`terraform show` prints a saved plan again, in the same form as `terraform plan`, which is how a
reviewer reads it without running a plan of their own:

```
ana@laptop:~/shop$ terraform show tfplan | tail -n 3
    }

Plan: 4 to add, 1 to change, 2 to destroy.
```

The file is a zip archive, and its contents say what it is for:

```
ana@laptop:~/shop$ unzip -l tfplan
Archive:  tfplan
  Length      Date    Time    Name
---------  ---------- -----   ----
    13818  2026-10-02 07:26   tfplan
    16522  2026-10-02 07:26   tfstate
    15677  2026-10-02 07:26   tfstate-prev
     1846  2026-10-02 07:26   tfconfig/m-/main.tf
      199  2026-10-02 07:26   tfconfig/m-/versions.tf
       41  2026-10-02 07:26   tfconfig/modules.json
      459  2026-10-02 07:26   .terraform.lock.hcl
---------                     -------
    48562                     7 files
```

Besides the plan itself, there is the state it was computed against, the state as it was before
the refresh, a copy of the configuration and the lock file. **A saved plan is a snapshot of
everything that decided it**, which is why it can be applied later on another machine, and why
it should be handled like the state: anything secret in the state is in here too. Ana's
`.gitignore` keeps `tfplan*` out of git for that reason.

## A plan that went stale

Ana saves the plan on her branch, `change`, for a colleague to review. While it waits, something
urgent comes up: the VPC needs an `Owner` tag today. She makes that change on a branch of its own,
`hotfix`, and applies it straight away:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index 5c3e89a..22dfa0d 100644
--- a/main.tf
+++ b/main.tf
@@ -4,7 +4,7 @@ provider "aws" {
 
 resource "aws_vpc" "shop" {
   cidr_block = "10.20.0.0/16"
-  tags       = { Name = "shop" }
+  tags       = { Name = "shop", Owner = "ana" }
 }
 
 resource "aws_subnet" "a" {
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 3
aws_vpc.shop: Modifications complete after 0s [id=vpc-bf1e4c53969619f51]

Apply complete! Resources: 0 added, 1 changed, 0 destroyed.
```

The next morning the review is done, and she goes back to `change` to apply the plan that was
approved:

```
ana@laptop:~/shop$ git log --format=%s -1
shop: public subnet, new image, assets bucket
ana@laptop:~/shop$ terraform apply tfplan
╷
│ Error: Saved plan is stale
│ 
│ The given plan file can no longer be applied because the state was changed
│ by another operation after the plan was created.
╵
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two branches and one state file. On the branch change, Ana saves a plan, which records the state it was computed against, and the plan goes to review. Meanwhile a hotfix on another branch is applied and writes the state file. When Ana applies the saved plan, its copy of the state and the file no longer match, and Terraform refuses it as stale.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"st-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">terraform plan -out=tfplan</text><text x=\"120.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">keeps a copy of the state</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">under review</text><rect x=\"500\" y=\"30\" width=\"200\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">terraform apply tfplan</text><text x=\"600.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused: the plan is stale</text><path d=\"M222 60 L266 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-wire)\"></path><path d=\"M452 60 L496 60\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-wire)\"></path><text x=\"20.0\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">terraform.tfstate</text><path d=\"M140 135 L700 135\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120 92 L120 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-phosphor)\"></path><text x=\"130.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">read</text><path d=\"M360 186 L360 142\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"370.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">written</text><path d=\"M600 128 L600 94\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"610.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">compared</text><rect x=\"260\" y=\"188\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">a hotfix, on another branch</text><text x=\"360.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">terraform apply</text><text x=\"600.0\" y=\"213.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the two no longer match</text></svg>", "caption": "A saved plan carries the state it was computed against. Any apply in between makes it stale, and Terraform refuses it rather than guess."}
```

The refusal comes from the state the plan carries. Terraform increases a state file's `serial`
every time it writes a change to it, and the copy inside `tfplan` is older than the file on disk:

```
ana@laptop:~/shop$ unzip -p tfplan tfstate | jq .serial
9
ana@laptop:~/shop$ jq .serial terraform.tfstate
11
```

**Terraform will not apply a plan computed against a state that no longer exists**, because it
cannot know whether the plan still means what the reviewer read. Here the old plan predates the
`Owner` tag; applied anyway, it would have been a review of one change and an apply of another.
The fix is the honest one: bring the branch up to date, plan again, and have the new plan
reviewed again.

```
ana@laptop:~/shop$ git log --format=%s -2
shop: public subnet, new image, assets bucket
tag the VPC with its owner
ana@laptop:~/shop$ terraform plan -out=tfplan | tail -n 6
─────────────────────────────────────────────────────────────────────────────

Saved the plan to: tfplan

To perform exactly these actions, run the following command to apply:
    terraform apply "tfplan"
```

## Applying it

A saved plan is applied by naming it, and **`apply` does not ask the question**. The review was
the question, so it goes straight to work:

```
ana@laptop:~/shop$ terraform apply tfplan
random_password.db: Creating...
random_password.db: Creation complete after 0s [id=none]
aws_subnet.b: Destroying... [id=subnet-47480a1b8bee893f8]
aws_instance.web: Destroying... [id=i-43f242be6e5a6202f]
aws_s3_bucket.assets: Creating...
aws_subnet.b: Destruction complete after 0s
aws_s3_bucket.assets: Creation complete after 0s [id=shop-assets-f49cbf8abcb1f97a65245f1ee3]
data.aws_iam_policy_document.assets_read: Reading...
data.aws_iam_policy_document.assets_read: Read complete after 0s [id=2811800691]
aws_iam_role_policy.web_assets: Creating...
aws_iam_role_policy.web_assets: Creation complete after 0s [id=web:assets-read]
aws_instance.web: Still destroying... [id=i-43f242be6e5a6202f, 00m10s elapsed]
aws_instance.web: Destruction complete after 10s
aws_subnet.a: Modifying... [id=subnet-d072b899e3e7150dc]
aws_subnet.a: Modifications complete after 0s [id=subnet-d072b899e3e7150dc]
aws_instance.web: Creating...
aws_instance.web: Still creating... [00m10s elapsed]
aws_instance.web: Creation complete after 10s [id=i-b00516cf21bf483a2]

Apply complete! Resources: 4 added, 1 changed, 2 destroyed.
```

The counts on the last line are the counts the reviewer saw, and lesson 15 builds a pipeline
around exactly that: plan once, review that file, apply that file.
