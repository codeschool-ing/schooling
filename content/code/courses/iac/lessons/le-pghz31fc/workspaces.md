---
title: "Workspaces: one directory, a state per name"
version: 1
---

A **workspace** is a named state for one configuration. The directory, the files and the backend
block stay exactly as they are; selecting a workspace changes which state every later command reads
and writes. Every configuration already has one, called `default`, which is where everything in
this course has run so far:

```
ana@laptop:~/shop$ terraform workspace list
* default

ana@laptop:~/shop$ terraform workspace new dev
Created and switched to workspace "dev"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
ana@laptop:~/shop$ terraform workspace new prod
Created and switched to workspace "prod"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
ana@laptop:~/shop$ terraform workspace list
  default
  dev
* prod
```

`new` creates a workspace and selects it, and the message says the important part: a new workspace
starts **empty**. The asterisk in `list` marks the selected one. A plan in `dev` will not see what
`default` or `prod` hold, which is precisely the property the last section was missing.

Inside the configuration, the selected workspace's name is available as `terraform.workspace`.
Ana uses it for the name of everything, so that a resource carries the name of the state that owns
it:

```
ana@laptop:~/shop$ sed -i 's/name = "shop-${var.environment}"/name = "shop-${terraform.workspace}"/' main.tf
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index e140d1e..c309bff 100644
--- a/main.tf
+++ b/main.tf
@@ -12,7 +12,7 @@ provider "aws" {
 }
 
 locals {
-  name = "shop-${var.environment}"
+  name = "shop-${terraform.workspace}"
   tags = { Project = "shop", Environment = var.environment }
 }
```

Then each environment is applied in its own workspace, with its own values:

```
ana@laptop:~/shop$ terraform workspace select dev
Switched to workspace "dev".
ana@laptop:~/shop$ terraform apply -var-file=dev.tfvars -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

```
ana@laptop:~/shop$ terraform workspace select prod
Switched to workspace "prod".
ana@laptop:~/shop$ terraform apply -var-file=prod.tfvars -auto-approve | tail -n 1
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

**Three added for dev, four for prod**, and nothing destroyed: prod's plan started from an empty
state, so the dev network was not in it to be replaced. Both networks exist side by side now, and the
bucket shows where their states went:

```
ana@laptop:~/shop$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 12:13:43       6318 env:/dev/shop/terraform.tfstate
2026-10-02 12:13:53       8445 env:/prod/shop/terraform.tfstate
2026-10-02 12:13:21        181 shop/terraform.tfstate
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Project,Values=shop --query "Vpcs[].[Tags[?Key==\`Name\`]|[0].Value,CidrBlock]" --output text
shop-dev	10.21.0.0/16
shop-prod	10.20.0.0/16
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One directory, ~/shop, with one main.tf, one backend.tf and two tfvars files, and a small file .terraform/environment that says prod. Three arrows leave it for three objects in the state bucket: default goes to shop/terraform.tfstate, dev to env:/dev/shop/terraform.tfstate and prod to env:/prod/shop/terraform.tfstate. Only the prod arrow is solid, because prod is the workspace selected.\"><defs><marker id=\"wk-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"wk-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"130.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">~/shop</text><text x=\"130.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one configuration</text><text x=\"130.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">main.tf  backend.tf</text><text x=\"130.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">dev.tfvars  prod.tfvars</text><rect x=\"36\" y=\"160\" width=\"188\" height=\"46\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"130.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">.terraform/environment</text><text x=\"130.0\" y=\"193.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">prod</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the state bucket</text><text x=\"550.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">shop-tfstate-123456789012</text><rect x=\"414\" y=\"78\" width=\"272\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">shop/terraform.tfstate</text><rect x=\"414\" y=\"133\" width=\"272\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">env:/dev/shop/terraform.tfstate</text><rect x=\"414\" y=\"188\" width=\"272\" height=\"34\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">env:/prod/shop/terraform.tfstate</text><path d=\"M240 110 L300 110 L330 95 L410 95\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#wk-ah-wire)\"></path><path d=\"M240 135 L300 135 L330 150 L410 150\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#wk-ah-wire)\"></path><path d=\"M240 185 L300 185 L330 205 L410 205\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#wk-ah-amber)\"></path><text x=\"368.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">default</text><text x=\"368.0\" y=\"139.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">dev</text><text x=\"368.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">prod</text><text x=\"130.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the selected workspace picks the key</text></svg>", "caption": "Workspaces: one configuration and one backend block, and a state object per workspace. Which one a command touches is decided by a file in `.terraform`."}
```

The S3 backend stores a workspace's state at `env:/<workspace>/` followed by the key from the
backend block; the prefix is the backend's `workspace_key_prefix` setting, and `env:` is its
default. **The `default` workspace keeps the plain key**, which is why `shop/terraform.tfstate` is
still there: it is the state from the last section, emptied by the destroy, 181 bytes of nothing.
Other backends keep workspaces their own way, but every remote backend keeps one state per
workspace, with its own lock.

So where is the selection kept? Not in the bucket and not in the files Ana committed:

```
ana@laptop:~/shop$ terraform workspace show
prod
ana@laptop:~/shop$ cat .terraform/environment; echo
prod
ana@laptop:~/shop$ echo terraform.workspace | terraform console -var-file=prod.tfvars
"prod"
```

**It is one line in `.terraform/environment`**, a file inside the directory `init` creates, which
git ignores and nobody reads. `terraform workspace show` prints it, and so does the console, which is
what the configuration sees. Two consequences follow. The selection belongs to this one checkout on
this one laptop: a colleague's clone, or a CI job, starts in `default` until something selects
otherwise. And nothing else on the screen shows it. That second point is the next section.

Deleting a workspace has a guard worth knowing. Terraform refuses while the workspace's state still
tracks anything, because deleting it would leave those resources running with no record of them:

```
ana@laptop:~/shop$ terraform workspace select default
Switched to workspace "default".
ana@laptop:~/shop$ terraform workspace delete prod
╷
│ Error: Workspace is not empty
│ 
│ Workspace "prod" is currently tracking the following resource instances:
│   - aws_subnet.public["sa-east-1a"]
│   - aws_subnet.public["sa-east-1c"]
│   - aws_vpc.shop
│   - aws_security_group.web
│ 
│ Deleting this workspace would cause Terraform to lose track of any
│ associated remote objects, which would then require you to delete them
│ manually outside of Terraform. You should destroy these objects with
│ Terraform before deleting the workspace.
│ 
│ If you want to delete this workspace anyway, and have Terraform forget
│ about these managed objects, use the -force option to disable this safety
│ check.
╵
```

The way out is a `destroy` inside the workspace first. `-force` deletes it anyway and forgets the
resources, which is the situation lesson 7's "losing-it" showed, reached deliberately.
