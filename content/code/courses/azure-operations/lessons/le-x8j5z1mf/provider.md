---
title: The provider, fetched and checked
version: 1
---

`iac` taught Terraform's model from its first lesson: providers, the plan, state and a remote backend.
This lesson is about the part that only appears against Azure. Terraform goes into `~/.local/bin`, at
the version `iac` uses; Ubuntu adds that directory to the path at your next login, and the last line adds
it now:

```sh
mkdir -p ~/.local/bin && cd ~/azure
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -o -q terraform.zip terraform -d ~/.local/bin && rm terraform.zip
export PATH="$HOME/.local/bin:$PATH"
```

On an Arm computer the file is `terraform_1.16.4_linux_arm64.zip`.

```
ana@laptop:~/azure/tf/shop$ terraform version
Terraform v1.16.4
on linux_amd64
```

The shop's first configuration declares the provider, pinned to an exact version, and one resource
group, `rg-shop`, in São Paulo:

```hcl
# main.tf
resource "terraform_data" "release" {
  input = "v42"
}
```

`features {}` is required by the `azurerm` provider even when empty; it is where provider-wide
behaviour is tuned, such as whether deleting a resource group that still contains resources is refused.
`subscription_id` is required as well since the provider's version 4: Terraform will not guess which of
your subscriptions to change, and that is a refusal worth having. It comes from a variable, so the same
files serve every environment.

```
ana@laptop:~/azure/tf/shop$ terraform init -input=false -no-color
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/azurerm versions matching "5.12.0"...
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
ana@laptop:~/azure/tf/shop$ du -sh .terraform
254M	.terraform
ana@laptop:~/azure/tf/shop$ cat .terraform.lock.hcl | head -5
# This file is maintained automatically by "terraform init".
# Manual edits may be lost in future updates.

provider "registry.terraform.io/hashicorp/azurerm" {
  version     = "5.12.0"
```

`init` fetched the provider from the Terraform Registry, checked HashiCorp's signature, and wrote
`.terraform.lock.hcl`, which records the exact version and the checksums of what was installed. **Commit
the lock file**, as its own comment says, so that a colleague and the pipeline install the same bytes.
The provider is a quarter of a gigabyte per working directory, which is a reason to keep `.terraform/` out
of the repository and a reason the pipeline caches it.

```
ana@laptop:~/azure/tf/shop$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/shop$ terraform fmt -check; echo "exit status $?"
exit status 0
```

**`validate` and `fmt` need no credentials and no subscription**, which is why they belong in the first
stage of a pipeline and in this lab. `validate` checks the configuration against the provider's schema:
types, required arguments, references that resolve. `fmt -check` exits non-zero when a file is not in
canonical layout, which saves every review an argument about spaces.
