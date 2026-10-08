---
title: Scanning the plan, where the values are
version: 2
---

The reviewer of the SSH pull request asked for one change: do not write the range into the file,
make it a variable, so each environment can give its own. It is a reasonable request and it has a
side effect nobody asked for:

```
ana@laptop:~/shop$ git diff
diff --git a/ssh.tf b/ssh.tf
index b975fc3..bfe7bb9 100644
--- a/ssh.tf
+++ b/ssh.tf
@@ -1,8 +1,13 @@
+variable "admin_cidr" {
+  type        = string
+  description = "The range SSH is allowed from."
+}
+
 resource "aws_vpc_security_group_ingress_rule" "ssh" {
   security_group_id = aws_security_group.web.id
   description       = "SSH for maintenance"
   ip_protocol       = "tcp"
   from_port         = 22
   to_port           = 22
-  cidr_ipv4         = "0.0.0.0/0"
+  cidr_ipv4         = var.admin_cidr
 }
```

Ana makes that edit to `ssh.tf`, commits it as *admin_cidr as a variable*, and scans again:

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_24

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform scan results:

Passed checks: 3, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_security_group.web
	File: /main.tf:26-32
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.https
	File: /main.tf:34-41
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:6-13

ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -c AWS-0107
0
```

**Checkov now passes the SSH rule and Trivy finds nothing.** Neither scanner was fooled in a way it
could have avoided. `cidr_ipv4` is now `var.admin_cidr`, the variable has no default, and nothing in
the directory says what it will be. A check that cannot see a value has nothing to fail on, and
both tools report that as a pass. *Passed* in a scan of the configuration means "nothing wrong in
what I could read", which is less than it sounds.

The value arrives when somebody plans, from a file given on the command line, `maintenance.tfvars`:

```hcl
admin_cidr = "0.0.0.0/0"
```

## The plan has the values

A plan is the configuration with every value filled in: variables from files, `-var` and `TF_VAR_`
in the environment, the results of functions, the outputs of modules, and what data sources read
during the plan. Lesson 9 turns a saved plan into JSON with `terraform show -json`, and Checkov
reads that JSON as a framework of its own:

```
ana@laptop:~/shop$ terraform plan -no-color -var-file=maintenance.tfvars -out tfplan | grep -E "^  # |Plan:"
  # aws_vpc_security_group_ingress_rule.ssh will be created
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/shop$ terraform show -json tfplan > tfplan.json
```

```
ana@laptop:~/shop$ checkov -f tfplan.json --skip-download --quiet --check CKV_AWS_24 --repo-root-for-plan-enrichment .
terraform_plan scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: ssh.tf:6-13

		6  | resource "aws_vpc_security_group_ingress_rule" "ssh" {
		7  |   security_group_id = aws_security_group.web.id
		8  |   description       = "SSH for maintenance"
		9  |   ip_protocol       = "tcp"
		10 |   from_port         = 22
		11 |   to_port           = 22
		12 |   cidr_ipv4         = var.admin_cidr
		13 | }
```

**The same rule, on the same code, now fails**, because in the plan `cidr_ipv4` is `0.0.0.0/0`. The
report header says `terraform_plan scan results`. `--repo-root-for-plan-enrichment .` is what maps
the finding back to `ssh.tf:6-13` and prints the source; without it Checkov can only point at
`/tfplan.json`, which tells a reviewer nothing. Notice that the code it prints still says
`var.admin_cidr`. The code is where the finding is fixed. The plan is where the value was found.

Trivy also reads a plan in JSON. On this plan, where the SSH rule is the only change, it did not
report the rule:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q tfplan.json | grep -c AWS-0107
0
```

That is a measurement of one version on one plan, and the lesson draws only one conclusion from it.
**Test what your scanner does with a plan** before you rely on it, with a known-bad value like this
one, the same way `legacy/main.tf` tested tfsec.

## What the plan costs

A configuration scan needs a checkout. A plan scan needs everything a plan needs: initialised
providers, credentials, an API to read the current resources from (moto, in this lab) and the
right variable files. So it runs later in a pipeline and fails for reasons that are not security.
**The JSON also holds every value in clear**, including the ones marked sensitive, which lesson 12
showed reaching the state the same way. Treat `tfplan.json` like the state: do not attach it to a
pull request or keep it as a build artefact longer than the review needs.

When the values are in a file you know about, there is a cheaper middle way. Checkov takes
`--var-file` and fills the variables in before it checks:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --check CKV_AWS_24 --var-file maintenance.tfvars --framework terraform
terraform scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:6-13
```

It works for the values you remember to pass, and only for those. The plan covers the rest,
including a value nobody knew was there.

Ana changes the file to the office range, plans again, and the plan scan agrees:

```
ana@laptop:~/shop$ echo 'admin_cidr = "203.0.113.0/24"' > maintenance.tfvars
ana@laptop:~/shop$ terraform plan -var-file=maintenance.tfvars -out tfplan > /dev/null && terraform show -json tfplan > tfplan.json
ana@laptop:~/shop$ checkov -f tfplan.json --skip-download --compact --check CKV_AWS_24

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform_plan scan results:

Passed checks: 3, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_security_group.web
	File: /tfplan.json:0-0
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.https
	File: /tfplan.json:0-0
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /tfplan.json:0-0
```

The fix landed in `maintenance.tfvars`, the one place a configuration scan could never have seen.
