---
title: What a machine type's name says
version: 1
---

`e2-standard-2` looks like a code you would have to look up, and it is not one. **A predefined
machine type's name is three words joined by hyphens: the series, the type, and the number of
vCPUs.** Read it left to right and you know what you are paying for before you open a price page.

## Three words

The **series** comes first. Its letter says what the series is for, the number after it is the
generation, and a letter after that, when there is one, names the processor:

| series | the letter | what it is for |
|---|---|---|
| `e2` | E, efficient | the lowest price per vCPU; Google picks the processor |
| `n4`, `n2`, `n2d` | N, general purpose | balanced machines with a fixed processor; `d` is AMD |
| `c4`, `c4a` | C, performance | newer, faster processors; `a` is Arm, Google's own Axion |
| `t2a`, `t2d` | T, Tau | scale-out work at a low price per core |
| `m3`, `x4` | M and X, memory | from about a terabyte of memory upwards |
| `g2`, `a3` | G and A, accelerator | a GPU fixed to the machine; lesson 2 |

The **type** is the ratio of memory to vCPUs, and there are three common ones. `standard` gives
about 4 GiB per vCPU, `highmem` about 8 and `highcpu` 1 or 2, depending on the series. The
**last number** is the vCPU count itself, which makes it easier to read than most clouds' sizes:
`n4-standard-8` has eight vCPUs, full stop.

**A vCPU is not a core.** On Intel and AMD series it is one hardware thread, and two threads share
each physical core. On the Arm series, `c4a` and `t2a`, there are no shared threads and a vCPU
is a whole core. Two machines with the same vCPU count can therefore do noticeably different
amounts of work, which is one reason the series matters as much as the size.

Three more shapes complete the vocabulary. A **custom** type spells out its own vCPUs and its
memory in MiB, as in `n4-custom-4-10240`; section 06 is about when that pays. A **shared-core**
type, `e2-micro`, `e2-small` and `e2-medium`, sells a fraction of a vCPU, also in section 06.
And a few series add a **suffix** for something bundled with the machine: `-lssd` for local SSDs,
which lesson 3 is about, and `-metal` for a whole server with no hypervisor.

## Writing one down

Every machine in this course is written as Terraform, because `terraform plan` is the one place
on your laptop where a Google resource takes its full shape. **Create a folder `vm` in `~/gcp`
and save this as `main.tf` in it:**

```hcl
# vm/main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.9.0"
    }
  }
}

provider "google" {
  project = "planner-dev"
  region  = "southamerica-east1"
}

resource "google_compute_instance" "web" {
  name         = "web-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }
}
```

The first block pins the provider you mirrored in section 02; the second names the project and
region; the third is the machine. Then, in `~/gcp/vm`:

```
ana@laptop:~/gcp/vm$ terraform init
Initializing the backend...

Initializing provider plugins...
- Finding hashicorp/google versions matching "8.9.0"...
- Installing hashicorp/google v8.9.0...
- Installed hashicorp/google v8.9.0 (unauthenticated)

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

╷
│ Warning: Incomplete lock file information for providers
│ 
│ Due to your customized provider installation methods, Terraform was forced
│ to calculate lock file checksums locally for the following providers:
│   - hashicorp/google
│ 
│ The current .terraform.lock.hcl file only includes checksums for
│ linux_amd64, so Terraform running on another platform will fail to install
│ these providers.
│ 
│ To calculate additional checksums for another platform, run:
│   terraform providers lock -platform=linux_amd64
│ (where linux_amd64 is the platform to generate)
╵
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

**`(unauthenticated)` and the warning are about where the provider came from, not about Google.**
It was installed from your own mirror rather than downloaded from HashiCorp's registry, so
Terraform could not compare its signature against the registry's and recorded checksums for your
own platform only. That is right for a lab. In a team, the lock file it mentions goes into git.

Now the plan, filtered to the four lines that matter here. **Terraform colours its output even
into a pipe**, so `-no-color` comes first whenever you `grep` it:

```
ana@laptop:~/gcp/vm$ terraform plan -no-color | grep -E '^  #|^      \+ (machine_type|name|zone) |^Plan'
  # google_compute_instance.web will be created
      + machine_type         = "e2-standard-2"
      + name                 = "web-1"
      + zone                 = "southamerica-east1-a"
Plan: 1 to add, 0 to change, 0 to destroy.
```

The unfiltered plan runs to 85 lines, most of them `(known after apply)`: values only
Compute Engine can decide, such as the instance's id and its internal address. Everything you wrote
is there exactly as you wrote it.

If your plan stops instead with an error about **application default credentials**, the
`GOOGLE_OAUTH_ACCESS_TOKEN` line of section 02 was not typed in this terminal:

```
ana@laptop:~/gcp/vm$ terraform plan

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Attempted to load application default credentials since neither `credentials` nor `access_token` was set in the provider block.  No credentials loaded. To use your gcloud credentials, run 'gcloud auth application-default login'.  Original error: google: could not find default credentials. See https://cloud.google.com/docs/authentication/external/set-up-adc for more information
│ 
│   with provider["registry.terraform.io/hashicorp/google"],
│   on main.tf line 11, in provider "google":
│   11: provider "google" {
│ 
╵
```

**Do not follow the advice inside that message.** `gcloud auth application-default login` would
put a real Google credential on your computer, and every plan in this course would then be one
`terraform apply` away from a real, billed machine. Type the line with `no-account` instead.

## What the plan does not check

Change the type to one that does not exist, then to a custom one, and plan each time:

```
ana@laptop:~/gcp/vm$ sed -i 's/e2-standard-2/e2-standard-3/' main.tf
ana@laptop:~/gcp/vm$ terraform plan -no-color | grep -E 'machine_type|^Plan'
      + machine_type         = "e2-standard-3"
Plan: 1 to add, 0 to change, 0 to destroy.
ana@laptop:~/gcp/vm$ sed -i 's/e2-standard-3/n4-custom-4-10240/' main.tf
ana@laptop:~/gcp/vm$ terraform plan -no-color | grep -E 'machine_type|^Plan'
      + machine_type         = "n4-custom-4-10240"
Plan: 1 to add, 0 to change, 0 to destroy.
```

**There is no `e2-standard-3`**: E2 sizes go 2, 4, 8, 16, 32. Terraform planned it anyway,
because the provider checks the shape of your file and not Google's catalogue. The catalogue lives
in Compute Engine, zone by zone, and the first thing to refuse that name would be the API call
that creates the machine. `gcloud compute machine-types list --zones=southamerica-east1-a` is how
you ask a zone what it offers; in this lab it stops at the missing account, as section 02 showed.

That is the honest limit of this lab, and it is worth stating once: **a clean plan says your file
is coherent, not that Google would accept it.** Names, quotas and whether a series is offered in
a zone are all checked on the other side.
