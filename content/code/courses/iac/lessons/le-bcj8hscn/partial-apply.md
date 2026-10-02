---
title: An apply that fails halfway
version: 1
---

It is natural to think of an apply as a database transaction: either every change in the plan
happens or none does. **It is not one, and it cannot be.** Each resource is a separate call to
the cloud's API, and there is no API call that undoes the three before it. When one call fails,
Terraform stops starting new work, keeps what already succeeded, and tells you what failed.

Ana adds batch workers to the shop: a security group, a subnet `c` and an instance in it. She
types the subnet's range from memory and gets one digit wrong, `10.30` where the VPC is `10.20`:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index cc59f60..20936a5 100644
--- a/main.tf
+++ b/main.tf
@@ -76,3 +76,24 @@ resource "aws_iam_role_policy" "web_assets" {
 resource "random_password" "db" {
   length = 24
 }
+
+resource "aws_security_group" "batch" {
+  name        = "batch"
+  description = "batch workers"
+  vpc_id      = aws_vpc.shop.id
+}
+
+resource "aws_subnet" "c" {
+  vpc_id            = aws_vpc.shop.id
+  cidr_block        = "10.30.3.0/24"
+  availability_zone = "sa-east-1a"
+  tags              = { Name = "shop-c" }
+}
+
+resource "aws_instance" "batch" {
+  ami                    = "ami-785db401"
+  instance_type          = "t3.micro"
+  subnet_id              = aws_subnet.c.id
+  vpc_security_group_ids = [aws_security_group.batch.id]
+  tags                   = { Name = "batch" }
+}
```

The plan is clean. **Terraform checks that `10.30.3.0/24` is a valid CIDR, and it is**; whether it
fits inside the VPC is something only the API knows. The guard from two sections back passes too,
because nothing is deleted. Then the apply:

```
ana@laptop:~/shop$ terraform apply tfplan; echo "exit $?"
aws_subnet.c: Creating...
aws_security_group.batch: Creating...
aws_security_group.batch: Creation complete after 1s [id=sg-0f05ca3472b6dbbca]
╷
│ Error: creating EC2 Subnet: operation error EC2: CreateSubnet, https response error StatusCode: 400, RequestID: c90SD4mAktjhE1nWlSkLjgYWfZYKv4KibyRoPxnPSPW8I43QpAJO, api error InvalidSubnet.Range: The CIDR '10.30.3.0/24' is invalid.
│ 
│   with aws_subnet.c,
│   on main.tf line 86, in resource "aws_subnet" "c":
│   86: resource "aws_subnet" "c" {
│ 
╵
exit 1
```

The security group and the subnet were started together, since neither needs the other. The group
was created. The subnet was refused by the API, here moto answering as EC2 does, with
`InvalidSubnet.Range`. And the instance does not appear in the log at all: it needs the subnet's
id, there is none, so it was never started.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One apply, three new resources. The security group batch was created and is now in the state. The subnet c was refused by the API because its range is outside the VPC. The instance batch needs both, so it was never started. Nothing that was created is rolled back.\"><defs><marker id=\"pa-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"pa-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.batch</text><text x=\"155.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">created: now in the state</text><rect x=\"30\" y=\"160\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"155.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_subnet.c</text><text x=\"155.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">refused by the API</text><rect x=\"440\" y=\"95\" width=\"250\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"565.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_instance.batch</text><text x=\"565.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">never started</text><path d=\"M282 65 L436 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pa-ah-phosphor)\"></path><path d=\"M282 195 L436 145\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#pa-ah-amber)\"></path><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the next plan proposes only what is missing</text></svg>", "caption": "An apply is not a transaction. What succeeded stays, what failed is reported, and whatever depended on the failure never ran."}
```

**What succeeded is in the state**, written the moment the API answered:

```
ana@laptop:~/shop$ terraform state list
data.aws_iam_policy_document.assets_read
aws_iam_role.web
aws_iam_role_policy.web_assets
aws_instance.web
aws_s3_bucket.assets
aws_security_group.batch
aws_security_group.web
aws_subnet.a
aws_vpc.shop
aws_vpc_security_group_ingress_rule.https
aws_vpc_security_group_ingress_rule.ssh
random_password.db
```

`aws_security_group.batch` is there, and nothing was rolled back. The next plan proposes only what
is missing:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|Plan:"
  # aws_instance.batch will be created
  # aws_subnet.c will be created
Plan: 2 to add, 0 to change, 0 to destroy.
```

This is the property that makes a failed apply recoverable rather than a mess. Terraform does not
need to remember that an apply failed; the state already records what exists, so planning again
compares the configuration with that and finds the difference, like any other plan. Ana corrects
the range to `10.20.3.0/24` and applies again:

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 6
aws_subnet.c: Creation complete after 0s [id=subnet-ec52a070d4b58b596]
aws_instance.batch: Creating...
aws_instance.batch: Still creating... [00m10s elapsed]
aws_instance.batch: Creation complete after 10s [id=i-0f4b71b89e1e778e8]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

Two added, the subnet and the instance. The security group from the failed run is not created a
second time, because the state says it exists.

## Where it hurts

Three cases turn a partial apply from an inconvenience into an incident.

**A replacement that fails halfway.** With the default order, `-/+`, the old object is destroyed
before the new one is created. If the create is the call that fails, the old one is already gone
and nothing has taken its place. Lesson 6 showed `create_before_destroy` for exactly this.

**Work outside Terraform that assumed success.** A script that runs after `apply` and configures
the new instance has nothing to configure. Check the exit code: `terraform apply` exited with 1
above, and nothing after it should run.

**A saved plan is spent.** The failed apply wrote the state, so `tfplan` is now stale like any
other plan computed before a write:

```
ana@laptop:~/shop$ terraform apply tfplan; echo "exit $?"
╷
│ Error: Saved plan is stale
│ 
│ The given plan file can no longer be applied because the state was changed
│ by another operation after the plan was created.
╵
exit 1
```

The way forward is always a new plan, because only a new plan describes the world as it is after
the failure.
