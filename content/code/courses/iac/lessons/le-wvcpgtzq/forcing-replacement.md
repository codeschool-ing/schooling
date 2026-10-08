---
title: Asking for a replacement
version: 2
---

The last two sections were about stopping Terraform from doing something. This one is the
reverse: **a replacement Terraform would never choose on its own**, because nothing in the
resource's arguments changed. The instance is misbehaving and a fresh one would fix it; the boot
script changed and only a new machine runs it. Terraform compares the file with what exists, and
when the two agree it has no reason to touch anything. You have to tell it.

## Once: `-replace`

`-replace` takes a resource address and adds a replacement of it to the plan. It works on `plan`
and `apply` alike, and here it goes through `plan` first, so Ana can see what she is about to ask
for:

```
ana@laptop:~/shop/app$ terraform plan -replace=aws_instance.web | grep -E "replace|Plan:"
+/- create replacement and then destroy
  # aws_instance.web will be replaced, as requested
Plan: 1 to add, 0 to change, 1 to destroy.
```

`will be replaced, as requested` is Terraform saying that the reason is you, not the file. The
symbol is `+/-` because `web` has carried `create_before_destroy` since Ana added it, three sections back, and the
summary counts the one replacement. Nothing about the request is saved anywhere: the next plan,
without the flag, is back to no changes.

**The older way was `terraform taint`**, which you will still find in runbooks and old answers.
It marks the resource in the state, and every plan after that replaces it until somebody applies
or runs `untaint`:

```
ana@laptop:~/shop/app$ terraform taint aws_instance.web
Resource instance aws_instance.web has been marked as tainted.
ana@laptop:~/shop/app$ terraform plan | grep -E "replace|taint|Plan:"
+/- create replacement and then destroy
  # aws_instance.web is tainted, so must be replaced
Plan: 1 to add, 0 to change, 1 to destroy.
ana@laptop:~/shop/app$ terraform untaint aws_instance.web
Resource instance aws_instance.web has been successfully untainted.
```

The plan says `is tainted, so must be replaced` instead of `as requested`, and the difference is
where the instruction lives. `taint` writes to the state, which is shared, so a colleague who plans
an unrelated change an hour later finds a replacement in it they did not ask for. `-replace` lives
in one command line and dies with it, and it shows up in the plan that is reviewed. HashiCorp's
documentation recommends `-replace` and calls `taint` deprecated.

## Every time something else changes: `replace_triggered_by`

Ana's instance runs an installer at first boot, for a release given in a variable. She adds the
user data and the variable, applies, and commits:

```
ana@laptop:~/shop/app$ git show --format= -U0
diff --git a/main.tf b/main.tf
index 104bfa6..f9a3266 100644
--- a/main.tf
+++ b/main.tf
@@ -29,0 +30 @@ resource "aws_instance" "web" {
+  user_data     = "#!/bin/sh\n/opt/shop/install ${var.release}\n"
@@ -46,0 +48,5 @@ resource "aws_security_group" "web" {
+
+variable "release" {
+  type    = string
+  default = "2026.10.1"
+}
```

Then she plans the next release:

```
ana@laptop:~/shop/app$ terraform plan -var release=2026.10.2
aws_vpc.shop: Refreshing state... [id=vpc-620a9a42c64d1b9c4]
aws_subnet.a: Refreshing state... [id=subnet-47e7ab7e19d97ade4]
aws_security_group.web: Refreshing state... [id=sg-7bd9ca389f1f7168d]
aws_instance.web: Refreshing state... [id=i-6deb06a6fc79f194d]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform will perform the following actions:

  # aws_instance.web will be updated in-place
  ~ resource "aws_instance" "web" {
        id                                   = "i-6deb06a6fc79f194d"
        tags                                 = {
            "CostCenter" = "cc-4410"
            "Name"       = "web"
        }
      ~ user_data                            = <<-EOT
            #!/bin/sh
          - /opt/shop/install 2026.10.1
          + /opt/shop/install 2026.10.2
        EOT
        # (40 unchanged attributes hidden)

        # (4 unchanged blocks hidden)
    }

Plan: 0 to add, 1 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
```

**An update in place, and that is the trap.** The provider can change an instance's user data in
place, but a machine reads its user data when it first boots, so the running `web` would carry the
new text and keep the old release. The plan is correct about the API and wrong about what Ana
wants: a new release should be a new machine.

`replace_triggered_by` says that. It is a list of resources, or attributes of them, and when any of
them is updated or replaced, this resource is replaced too. The release is not a resource, so Ana
wraps it in `terraform_data`, a resource built into Terraform that stores a value and does nothing
else, so that the value has something that can change. She applies that and commits it:

```
ana@laptop:~/shop/app$ git show --format= -U0
diff --git a/main.tf b/main.tf
index f9a3266..7260031 100644
--- a/main.tf
+++ b/main.tf
@@ -35,0 +36 @@ resource "aws_instance" "web" {
+    replace_triggered_by  = [terraform_data.release]
@@ -52,0 +54,4 @@ variable "release" {
+
+resource "terraform_data" "release" {
+  input = var.release
+}
```

```
ana@laptop:~/shop/app$ terraform plan -var release=2026.10.2 | grep -E "replace|update|Plan:"
  ~ update in-place
+/- create replacement and then destroy
  # aws_instance.web will be replaced due to changes in replace_triggered_by
  # terraform_data.release will be updated in-place
Plan: 1 to add, 1 to change, 1 to destroy.
```

`terraform_data.release` is updated in place, and that update is what replaces `web`: `will be
replaced due to changes in replace_triggered_by`. The plan now says what Ana means, and so will
every future release, without anybody remembering a flag.

Use it for a link the configuration cannot express any other way. When an argument of the
resource already forces a replacement, as `ami` does, the trigger adds nothing; and a trigger
pointed at something that changes often replaces machines often, so point it at the one value
that should.
