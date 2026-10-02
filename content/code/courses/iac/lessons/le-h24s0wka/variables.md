---
title: Variables, for the values that change
version: 1
---

Everything in `main.tf` so far is a literal. That is fine for one network and wrong the day the
shop needs a second, for production. **The tempting move is to copy the directory and edit the
numbers, and it gives you two configurations that drift apart one forgotten edit at a time.** The
alternative is to name the values that differ and leave them open. Those names are **input
variables**, and they are declared in blocks of their own:

```hcl
variable "environment" {
  description = "Which copy of the shop this is: dev or prod."
  type        = string
}

variable "vpc_cidr" {
  description = "The address range of the shop's VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "https_port" {
  description = "The port the web servers answer on."
  type        = number
  default     = 443
}
```

Each block declares one input. `description` is shown to whoever is asked for the value, and to
whoever reads the file. `type` says what kind of value is acceptable: `string` and `number` here,
and `bool`, lists, maps and objects in lesson 3. **A `default` makes a variable optional; without
one it is required**, so `environment` must be given every time and the other two need not be.

`main.tf` uses them as `var.NAME`, and since the last version is committed, `git diff` shows
exactly where:

```
ana@laptop:~/shop$ git diff main.tf
diff --git a/main.tf b/main.tf
index e565f3e..a597fc0 100644
--- a/main.tf
+++ b/main.tf
@@ -3,10 +3,11 @@ provider "aws" {
 }
 
 resource "aws_vpc" "shop" {
-  cidr_block = "10.20.0.0/16"
+  cidr_block = var.vpc_cidr
 
   tags = {
-    Name = "shop"
+    Name        = "shop"
+    Environment = var.environment
   }
 }
 
@@ -16,7 +17,8 @@ resource "aws_subnet" "web_a" {
   availability_zone = "sa-east-1a"
 
   tags = {
-    Name = "shop-web-a"
+    Name        = "shop-web-a"
+    Environment = var.environment
   }
 }
 
@@ -29,7 +31,7 @@ resource "aws_security_group" "web" {
 resource "aws_vpc_security_group_ingress_rule" "https" {
   security_group_id = aws_security_group.web.id
   ip_protocol       = "tcp"
-  from_port         = 443
-  to_port           = 443
+  from_port         = var.https_port
+  to_port           = var.https_port
   cidr_ipv4         = "0.0.0.0/0"
 }
```

The range now comes from `var.vpc_cidr`, both resources carry an `Environment` tag, and the rule's
port is `var.https_port`. A default equal to the old literal means the network itself does not
change; only the new tag is new.

**A required variable with no value is a question, or an error.** In a terminal, Terraform asks,
using the description:

```
ana@laptop:~/shop$ terraform plan
var.environment
  Which copy of the shop this is: dev or prod.

  Enter a value: dev
```

Where nobody can answer, as in a pipeline, `-input=false` turns the question into an error that
names the variable and the line that declared it. Failing at once is what you want there:

```
ana@laptop:~/shop$ terraform plan -input=false
╷
│ Error: No value for required variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│ 
│ The root module input variable "environment" is not set, and has no default
│ value. Use a -var or -var-file command line argument to provide a value for
│ this variable.
╵
```

There are three usual ways to supply a value without being asked. **On the command line**,
`-var environment=dev`, or `-var-file=prod.tfvars` for a file of them. **In the environment**, as
`TF_VAR_` followed by the variable's name; `terraform console` evaluates an expression against
the configuration, and lesson 3 uses it properly:

```
ana@laptop:~/shop$ echo var.environment | TF_VAR_environment=dev terraform console
"dev"
```

**In a file Terraform loads by itself**: `terraform.tfvars`, or any name ending in
`.auto.tfvars`, in the configuration's directory. Ana writes one line:

```hcl
environment = "dev"
```

And the plan has its answer. Here is its half about the VPC:

```
  # aws_vpc.shop will be updated in-place
  ~ resource "aws_vpc" "shop" {
        id                                   = "vpc-7327c901412b20229"
      ~ tags                                 = {
          + "Environment" = "dev"
            "Name"        = "shop"
        }
      ~ tags_all                             = {
          + "Environment" = "dev"
            # (1 unchanged element hidden)
        }
        # (19 unchanged attributes hidden)
    }

Plan: 0 to add, 2 to change, 0 to destroy.
```

`~` is **update in place**: the VPC keeps its id and only its tags change, which the AWS API can do
to a running VPC. Not every argument can be changed that way, and lesson 6 is about the ones that
force a replacement.

**When the same variable is set in several places, the later source in Terraform's order wins,
and the environment comes first.** That surprises anyone used to tools where an environment
variable overrides a file. The order, from weakest to strongest: `TF_VAR_` variables, then
`terraform.tfvars`, then `terraform.tfvars.json`, then `*.auto.tfvars` files in alphabetical order,
then `-var` and `-var-file` in the order they appear on the command line. Ana tries it:

```
ana@laptop:~/shop$ echo var.environment | terraform console
"dev"
ana@laptop:~/shop$ echo var.environment | TF_VAR_environment=prod terraform console
"dev"
ana@laptop:~/shop$ echo var.environment | terraform console -var environment=prod
"prod"
```

`TF_VAR_environment=prod` lost to the one line in `terraform.tfvars`, without a warning, and only
`-var` beat the file. That is how somebody exports `prod` in their shell, reads a plan that says
`dev`, and does not notice. **The value a plan used is in the plan**, so read it there rather than
assuming which source won.

The type is checked before the value is used. A port that is not a number is refused, and the
message names the variable and the source of the bad value:

```
ana@laptop:~/shop$ echo var.https_port | terraform console -var https_port=https
╷
│ Error: Invalid value for input variable
│ 
│   on variables.tf line 12:
│   12: variable "https_port" {
│ 
│ Unsuitable value for var.https_port set using -var="https_port=...": a
│ number is required.
╵
```

With `terraform.tfvars` in place, `apply` puts the new tag on both resources:

```
Plan: 0 to add, 2 to change, 0 to destroy.
aws_vpc.shop: Modifying... [id=vpc-7327c901412b20229]
aws_vpc.shop: Modifications complete after 0s [id=vpc-7327c901412b20229]
aws_subnet.web_a: Modifying... [id=subnet-246685d4ada451bad]
aws_subnet.web_a: Modifications complete after 0s [id=subnet-246685d4ada451bad]

Apply complete! Resources: 0 added, 2 changed, 0 destroyed.
```

Lesson 12 comes back to `terraform.tfvars` for a reason this lesson can only name: a value that is
a password is safe in neither a committed file nor a shell history.
