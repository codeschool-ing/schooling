---
title: Where Terragrunt fits
version: 1
---

**Terragrunt is a wrapper: it writes the repetitive parts of a root configuration for you, then
runs Terraform in it.** It is a separate program, by Gruntwork, with its own file, `terragrunt.hcl`,
and it does not replace Terraform's language; the modules stay exactly as they are. What it takes
over is the directory-per-environment layout from the last section, minus the copies.

Ana adds a `live` tree beside `envs`, using the same two modules. Each leaf directory is a
**unit**: one module, one environment, one state.

```
ana@laptop:~/shop-infra$ tree --noreport live
live
├── dev
│   ├── network
│   │   └── terragrunt.hcl
│   └── web
│       └── terragrunt.hcl
├── prod
│   ├── network
│   │   └── terragrunt.hcl
│   └── web
│       └── terragrunt.hcl
└── root.hcl
```

Everything the units share is written once, in `root.hcl`:

```hcl
terraform_binary = "terraform"

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket       = "shop-tfstate-123456789012"
    key          = "live/${path_relative_to_include()}/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "sa-east-1"
}
EOF
}
```

`remote_state` is the backend block, written once. Terragrunt **generates** a `backend.tf` from it
in every unit, and the key is computed: `path_relative_to_include()` is the unit's path relative to
`root.hcl`, so `dev/network` gets `live/dev/network/terraform.tfstate` and no two units can share a
key by mistake. The `generate "provider"` block writes the provider block the same way.
`terraform_binary` is there because Terragrunt now runs OpenTofu unless told otherwise; its own help
says so:

```
ana@laptop:~/shop-infra/live$ terragrunt run --help | grep -e --tf-path
   --tf-path value                             Path to the OpenTofu/Terraform binary. Default is tofu (on PATH). [$TG_TF_PATH]
```

A unit is short. It includes the root, names its module, and gives the module its inputs:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/network"
}

inputs = {
  environment = "dev"
  cidr        = "10.21.0.0/16"
  azs         = ["sa-east-1a"]
}
```

The `web` unit needs the VPC's id, which is an output of another unit's state. In a single
configuration that would be a reference; across two states it is a **`dependency`** block, which
reads the other unit's outputs and also tells Terragrunt to run that unit first:

```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/web"
}

dependency "network" {
  config_path = "../network"
}

inputs = {
  environment = "dev"
  vpc_id      = dependency.network.outputs.vpc_id
}
```

From those blocks Terragrunt works out the order of the whole tree:

```
ana@laptop:~/shop-infra/live$ terragrunt list --tree --dag
.
├── dev/network
│   ╰── dev/web
╰── prod/network
    ╰── prod/web
```

`run --all` runs one Terraform command in every unit below the current directory, in that order.
Ana asks dev for a plan before anything exists, with Terraform's own lines filtered out of the log:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all plan 2>&1 | grep -v "terraform: "
07:33:38.424 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
07:33:38.428 INFO   [network] Downloading Terraform configurations from ../../modules/network into ./network/.terragrunt-cache/8NfM1BhQNSu3ej20knfGNG3b5dU/vkRyJKeJSFFqzwTOQfTUBt_KXk0
07:33:44.694 ERROR  [web] Error: Unknown variable
07:33:44.694 ERROR  [web]   on /home/ana/shop-infra/live/dev/web/terragrunt.hcl line 15:
07:33:44.695 ERROR  [web]   15:   vpc_id      = dependency.network.outputs.vpc_id
07:33:44.695 ERROR  [web] There is no variable named "dependency".
07:33:44.696 ERROR  Run failed: 2 errors occurred:

* resolving dependency "network" outputs: /home/ana/shop-infra/live/dev/network/terragrunt.hcl is a dependency of /home/ana/shop-infra/live/dev/web/terragrunt.hcl but detected no outputs. Either the target module has not been applied yet, or the module has no outputs.
  
  If this dependency is accessed before the outputs are ready (which can happen during the planning phase of an unapplied stack), consider using mock_outputs:
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Terragrunt's layout for the shop. At the top, root.hcl, included by every unit, holds remote_state and a generate block for the provider. Below it, two rows, dev and prod, each with a network unit and a web unit. An arrow labelled dependency, vpc_id, goes from network to web in each row, and under every unit is the state key it gets: live/dev/network/terraform.tfstate and so on, four keys in all.\"><defs><marker id=\"tu-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"160\" y=\"14\" width=\"400\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"32.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">live/root.hcl</text><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">remote_state { … }   generate \"provider\" { … }</text><text x=\"360.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">included by every unit below</text><text x=\"36.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">dev</text><rect x=\"70\" y=\"100\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dev/network</text><text x=\"185.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/dev/network/terraform.tfstate</text><rect x=\"450\" y=\"100\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">dev/web</text><text x=\"565.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/dev/web/terraform.tfstate</text><path d=\"M300 130 L447 130\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tu-ah-phosphor)\"></path><text x=\"374.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">dependency</text><text x=\"374.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">vpc_id</text><text x=\"36.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">prod</text><rect x=\"70\" y=\"200\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">prod/network</text><text x=\"185.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/prod/network/terraform.tfstate</text><rect x=\"450\" y=\"200\" width=\"230\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">prod/web</text><text x=\"565.0\" y=\"242.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">live/prod/web/terraform.tfstate</text><path d=\"M300 230 L447 230\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tu-ah-phosphor)\"></path><text x=\"374.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">dependency</text><text x=\"374.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">vpc_id</text><text x=\"360.0\" y=\"285.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">run --all: network first, then web, in each environment</text></svg>", "caption": "Terragrunt: every unit includes one root file, gets a state key from its own path, and waits for the units it depends on."}
```

**A plan across states that depend on each other cannot be complete before the first apply.** The
network unit planned. The web unit could not, because its input is an output of a state that does not
exist yet. The error offers `mock_outputs`, placeholder values a plan may use until the real ones
exist; the other way through is to apply in order. Terragrunt asks first, once, for the whole queue:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all apply 2>&1 | grep -v "terraform: "
07:33:44.981 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
Are you sure you want to run 'terragrunt apply' in each unit of the run queue displayed above? (y/n) 07:33:45.029 INFO   TIP (debugging-docs): For help troubleshooting errors, visit https://docs.terragrunt.com/troubleshooting/debugging
07:33:45.029 ERROR  EOF
```

The question got no answer, because this terminal's input is empty, and Terragrunt stopped with
`EOF` before running anything. Answered `y`, or skipped with `--non-interactive`, it applies every
unit in turn:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all --non-interactive apply 2>&1 | grep -v "terraform: "
07:33:45.233 INFO   The following units will be run, starting with dependencies and then their dependents:
.
╰── network
    ╰── web
07:33:51.833 INFO   [web] Downloading Terraform configurations from ../../modules/web into ./web/.terragrunt-cache/IeaLxhtezokSWz7KRPOsZscXNMQ/oggAgWRx6GeDvWQfFfCMEvrgY4Y

❯❯ Run Summary  2 units  14s
   ────────────────────────────
   Succeeded    2
```

**That one question is the only confirmation a whole environment gets.** Under `run --all`,
Terragrunt adds `-auto-approve` to every Terraform command it runs, unless told not to:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --help | grep -e --no-auto-approve
   --no-auto-approve                           Don't automatically append '-auto-approve' to the underlying OpenTofu/Terraform commands run with 'run --all'. [$TG_NO_AUTO_APPROVE]
```

After the apply, a plan across the units finds nothing to do, and each unit has its own key:

```
ana@laptop:~/shop-infra/live/dev$ terragrunt run --all plan 2>&1 | grep -E "No changes|Plan:|Run Summary|Succeeded|Failed"
07:34:05.899 STDOUT [network] terraform: No changes. Your infrastructure matches the configuration.
07:34:12.631 STDOUT [web] terraform: No changes. Your infrastructure matches the configuration.
❯❯ Run Summary  2 units  12s
   Succeeded    2
```

```
ana@laptop:~/shop-infra/live/dev$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:33:32        181 envs/dev/terraform.tfstate
2026-10-02 07:33:37        181 envs/prod/terraform.tfstate
2026-10-02 07:33:50       4480 live/dev/network/terraform.tfstate
2026-10-02 07:33:59       2041 live/dev/web/terraform.tfstate
2026-10-02 07:32:15        181 shop/terraform.tfstate
ana@laptop:~/shop-infra/live/dev$ find network/.terragrunt-cache -name backend.tf -exec cat {} \;
# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    encrypt      = true
    key          = "live/dev/network/terraform.tfstate"
    region       = "sa-east-1"
    use_lockfile = true
  }
}
```

The `envs/` states are empty: Ana destroyed those two environments before building the same thing
with Terragrunt. The last command shows the file Terragrunt generated for the network unit, inside
`.terragrunt-cache`, where it copies the module and runs Terraform. That copy is what Terraform
actually sees, and it is why `.terragrunt-cache/` goes into `.gitignore`.

**What it costs is a second tool.** Everybody who runs the infrastructure, and every pipeline,
needs Terragrunt at a known version as well as Terraform; errors arrive through two layers of log;
and a reviewer has a second set of blocks to learn, written in HCL but meaning nothing to Terraform.
For two environments with one state each, the copies from the last section are cheaper. Terragrunt starts paying
when there are many units, which is when forty-five backend blocks stop being a figure of speech.
