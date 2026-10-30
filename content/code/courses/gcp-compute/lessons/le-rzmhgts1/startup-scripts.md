---
title: Startup scripts, and what runs them
version: 1
---

A machine built from a public image knows nothing about your shop. **What turns it into a web
server is a script you hand Compute Engine as metadata, which the machine fetches and runs as root
every time it boots.** Not once, at creation: every boot. That one difference from what most
people expect decides how the script must be written.

## Where the script lives

A startup script is a value in the instance's metadata under one of a few well-known keys:
`startup-script` for the script itself, `startup-script-url` for a script kept in Cloud Storage,
and `windows-startup-script-ps1` on Windows. Nothing on Google's side runs it. The **guest
environment**, a set of Google programs preinstalled in every public image, reads the key from the
metadata server when the machine boots and runs what it finds. Lesson 2 comes back to this: a
custom image without the guest environment boots and silently ignores its startup script.

The output goes to two places. On a Linux machine, the guest environment writes it to the system
journal under `google_metadata_script_runner`, and copies it to the machine's **serial console**,
which you can read from outside even when SSH is broken. A failing startup script does not stop
the boot and does not mark the machine unhealthy; the instance shows as `RUNNING` with your web
server missing. Lesson 4's health checks are what notice that.

Here is the shop's machine with a script and three metadata values. **Create a folder `meta` in
`~/gcp` and save these two files in it.** The Terraform first:

```hcl
# meta/main.tf
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

resource "google_service_account" "web" {
  account_id   = "shop-web"
  display_name = "The shop's web servers"
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

  metadata = {
    shop-env               = "staging"
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    email  = google_service_account.web.email
    scopes = ["cloud-platform"]
  }
}
```

Then the script, in the same folder:

```sh
#!/bin/bash
# meta/startup.sh: Compute Engine runs this as root on every boot
set -euo pipefail
MD=http://metadata.google.internal/computeMetadata/v1
get() { curl -sSf -H "Metadata-Flavor: Google" "$MD/$1"; }

ENV=$(get instance/attributes/shop-env)
ZONE=$(get instance/zone)

if ! command -v nginx >/dev/null; then
  apt-get update -q
  apt-get install -y -q nginx
fi
echo "shop $ENV, $(hostname), ${ZONE##*/}" > /var/www/html/index.html
```

Read the script once as the machine will. It asks the metadata server for two values, the
`shop-env` attribute you set and the zone Compute Engine chose, installs nginx only if it is not
there already, and writes a page. **The `if` is what makes it safe to run on every boot**: the
second boot finds nginx installed and skips straight to the page. A script that installed
unconditionally would reach for the package archive on every restart, and fail the day the archive
is slow.

## What runs, and what does not

The script is plain bash, so it runs on your laptop too. It stops at its first question:

```
ana@laptop:~/gcp/meta$ bash startup.sh; echo "exit status $?"
curl: (6) Could not resolve host: metadata.google.internal
exit status 6
```

**This is the whole of what is missing here, and nothing else**: there is no metadata server on
a laptop, so the first `curl` cannot resolve `metadata.google.internal`. `-sSf` made it fail
loudly, with a message and status 6, and `set -euo pipefail` made the script stop there rather
than carry on with an empty `ENV`. Without those flags it would have written a page saying
`shop , web-1, ` and exited 0, which is the kind of failure nobody finds until a customer does.

Now the plan, from the `metadata` map down to the end of the script:

```
ana@laptop:~/gcp/meta$ terraform plan -no-color | sed -n '/+ metadata  /,/^ *EOT$/p'
      + metadata                = {
          + "block-project-ssh-keys" = "TRUE"
          + "enable-oslogin"         = "TRUE"
          + "shop-env"               = "staging"
        }
      + metadata_fingerprint    = (known after apply)
      + metadata_startup_script = <<-EOT
            #!/bin/bash
            # meta/startup.sh: Compute Engine runs this as root on every boot
            set -euo pipefail
            MD=http://metadata.google.internal/computeMetadata/v1
            get() { curl -sSf -H "Metadata-Flavor: Google" "$MD/$1"; }
            
            ENV=$(get instance/attributes/shop-env)
            ZONE=$(get instance/zone)
            
            if ! command -v nginx >/dev/null; then
              apt-get update -q
              apt-get install -y -q nginx
            fi
            echo "shop $ENV, $(hostname), ${ZONE##*/}" > /var/www/html/index.html
        EOT
```

The two other keys are not for your script but for the guest environment: `enable-oslogin` makes
SSH access to the machine go through IAM rather than keys pasted into metadata, and
`block-project-ssh-keys` stops keys set for the whole project from reaching this machine.
`gcp-foundations` covers OS Login.

The script is in the plan word for word, which is worth knowing for two reasons. **It is part of
the resource**: anybody who can read the plan or the instance's metadata can read the script, so a
password never goes in it. And it is the provider's attribute `metadata_startup_script`, which
Terraform's documentation for the provider marks as forcing a new instance when it changes. Edit
one line of the script and the next apply destroys `web-1` and creates another. The same text
under the `startup-script` key of `metadata` updates in place instead and runs at the next boot.
Neither behaviour can be shown without an apply, so take it from the provider's documentation;
choose the key on purpose.

## Running it again, and the shutdown script

On a running machine the guest environment can run the script again without a reboot, which is
how you test a change: `sudo google_metadata_script_runner startup` on the instance, from
Google's documentation and not run here. The same program runs `shutdown-script` when the machine
is stopped, deleted or preempted. **A shutdown script is best effort**: it gets a limited time, it
is not run at all if the machine fails abruptly, and lesson 6 shows how short that time is when a
Spot machine is reclaimed. Anything that must survive the machine belongs somewhere else before
the shutdown starts.
