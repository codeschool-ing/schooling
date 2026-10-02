---
title: The wrong workspace
version: 1
---

Workspaces put the choice of environment in a hidden file, and that is the whole risk. **Nothing
in the command, the directory or the prompt says which environment a command is about to touch.**
The prompt below reads `ana@laptop:~/shop$` in dev and in prod alike, and the command is the same
command.

Here is the accident, recorded exactly as it happens. The last thing Ana did was the prod apply,
so `prod` is still selected. The next morning she wants to try something in dev, and starts with a
plan using dev's values:

```
ana@laptop:~/shop$ terraform plan -var-file=dev.tfvars -no-color | grep -E "^  #|# forces|^Plan:"
  # aws_security_group.web must be replaced
      ~ vpc_id                 = "vpc-05c746657d7e3f10b" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1a"] must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.21.1.0/24" # forces replacement
      ~ vpc_id                                         = "vpc-05c746657d7e3f10b" -> (known after apply) # forces replacement
  # aws_subnet.public["sa-east-1c"] will be destroyed
  # (because key ["sa-east-1c"] is not in for_each map)
  # aws_vpc.shop must be replaced
      ~ cidr_block                           = "10.20.0.0/16" -> "10.21.0.0/16" # forces replacement
Plan: 3 to add, 0 to change, 4 to destroy.
```

**Read as a plan for dev, this looks like nonsense; it is a plan for prod.** Dev's values, applied
to prod's state: the production VPC replaced by one with dev's range, the second subnet destroyed,
the security group recreated. Four resources destroyed, in production, from a command that was
meant for the environment where mistakes are cheap. With `-auto-approve`, or a quick `yes`, that is an outage.

The selection that caused it is the one-word file from the last section:

```
ana@laptop:~/shop$ cat .terraform/environment; echo
prod
```

Every defence against this is a way of putting the environment back somewhere a person or a
machine checks it. The cheapest is in the configuration itself. The values file already says which
environment it was written for, so Ana makes the variable refuse to be used anywhere else, with a
`validation` block of the kind lesson 3 introduced, and makes the same mistake again:

```
ana@laptop:~/shop$ git diff
diff --git a/variables.tf b/variables.tf
index 313010f..2966bc7 100644
--- a/variables.tf
+++ b/variables.tf
@@ -1,6 +1,11 @@
 variable "environment" {
   description = "Which environment these values are for: dev or prod."
   type        = string
+
+  validation {
+    condition     = var.environment == terraform.workspace
+    error_message = "These values are for ${var.environment}, and the selected workspace is ${terraform.workspace}."
+  }
 }
 
 variable "cidr" {
ana@laptop:~/shop$ terraform plan -var-file=dev.tfvars

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on dev.tfvars line 1:
│    1: environment = "dev"
│     ├────────────────
│     │ terraform.workspace is "prod"
│     │ var.environment is "dev"
│ 
│ These values are for dev, and the selected workspace is prod.
│ 
│ This was checked by the validation rule at variables.tf:5,3-13.
╵
```

**The plan is refused before anything is read from AWS, and the error names both sides**: the
environment the values were written for and the workspace they were given to. That is exactly the
sentence that was missing from the screen the first time. The right pairing still plans cleanly:

```
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars -no-color | grep -E "^(No changes|Plan:)"
No changes. Your infrastructure matches the configuration.
```

The check is only as good as the values file, and it catches only this one mistake: a change to
`main.tf` itself, tried in the wrong workspace, carries no `environment` to compare. Three more
habits close the rest of the gap.

**Name the workspace on every command that matters.** `TF_WORKSPACE` selects a workspace for one
command without touching the file, so a script or a pipeline never depends on what somebody left
selected:

```
ana@laptop:~/shop$ TF_WORKSPACE=dev terraform plan -var-file=dev.tfvars -no-color | grep -E "^(No changes|Plan:)"
No changes. Your infrastructure matches the configuration.
ana@laptop:~/shop$ terraform workspace show
prod
```

The plan ran in dev, or the validation would have refused it, and the stored selection is still
prod: the variable won for that one command
and changed nothing else. Pipelines should always pass it, or run `terraform workspace select`
as their first step.

**Put it in the prompt.** A shell prompt that reads `.terraform/environment` when it exists puts
the environment on every line, which is the defence aimed at the actual failure, a person not
noticing. It is a few lines of shell configuration and has nothing to do with Terraform.

**Give prod credentials dev does not have.** A plan that cannot authenticate to prod's account
cannot replace prod's VPC, whatever workspace is selected. That is the isolation layer from the
first section, and it is the one workspaces are weakest at: one directory and one backend block mean
one set of credentials reading every environment's state, in one bucket. Terraform's own
documentation says as much, that CLI workspaces are not a fit for environments that need separate
credentials and access controls. The next section's layout is the usual answer.
