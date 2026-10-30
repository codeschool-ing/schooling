---
title: Public images, and where an image name points
version: 1
---

A machine boots from a disk, and the disk is made from an **image**: a snapshot of an operating
system, frozen at one moment, that Compute Engine copies into every new boot disk. **You never
upload Debian or Ubuntu yourself. Google and the distributions publish their images in public
projects, and you point at them by name.**

## Images live in projects

An image belongs to a project, like everything else in Google Cloud. The public ones live in
projects that exist only to hold them, and the project's name is half of every image reference
you will write:

| project | what it holds |
|---|---|
| `debian-cloud` | Debian, which this course uses |
| `ubuntu-os-cloud` | Ubuntu, including the LTS releases |
| `rocky-linux-cloud` | Rocky Linux, a rebuild of Red Hat Enterprise Linux |
| `cos-cloud` | Container-Optimized OS, the small system GKE's nodes run |
| `rhel-cloud`, `suse-cloud`, `windows-cloud` | systems with a licence, charged per hour on top of the machine |

**The last row is the one that surprises a bill.** A free distribution costs nothing beyond the
machine and its disk. Red Hat, SUSE and Windows carry a licence fee that Google adds per hour while
the machine runs, so the same `e2-standard-2` costs more with Windows on it than with Debian. The
fee is on the operating system's price page, not the machine's.

## Two ways to name one

Inside a project, every image has a dated name, and most also belong to a **family**. The family is
a pointer to the newest image in it that has not been retired, which is what lets you say "the
current Debian 12" instead of a particular build. Section 03 of this lesson is about families; here
it is enough that `debian-cloud/debian-12` means "the newest image in the family `debian-12` of the
project `debian-cloud`".

In Terraform there are two ways to put that on a boot disk, and they behave differently on your
laptop. The first asks Google which image the family points to, with a **data source**. Make a
folder `images` in `~/gcp` and save this as `main.tf` in it:

```hcl
# images/main.tf
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

data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "web" {
  name         = "web-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    network = "default"
  }
}
```

Run `terraform init` there, as in lesson 1, and then the plan. It does not fail at once:

```
ana@laptop:~/gcp/images$ terraform plan
data.google_compute_image.debian: Reading...
data.google_compute_image.debian: Still reading... [00m10s elapsed]
data.google_compute_image.debian: Still reading... [00m20s elapsed]
data.google_compute_image.debian: Still reading... [00m30s elapsed]
```

It goes on like that, a line every ten seconds, for five and a half minutes, because the provider
tries Google's address again and again before giving up. Then:

```
Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: error retrieving image information: Get "https://compute.googleapis.com/compute/v1/projects/debian-cloud/global/images/family/debian-12?alt=json": dial tcp: lookup compute.googleapis.com on 8.8.4.4:53: dial udp 8.8.4.4:53: connect: network is unreachable (Client.Timeout exceeded while awaiting headers)
│ 
│   with data.google_compute_image.debian,
│   on main.tf line 16, in data "google_compute_image" "debian":
│   16: data "google_compute_image" "debian" {
│ 
╵
```

**A data source is read while planning, so it needs the API.** The plan could not resolve
`compute.googleapis.com` at all, because this lab has no network; on a laptop with the internet,
the same request would reach Google and be refused for the token `no-account`. Either way the
lesson is the same: a data source is a question to Google, asked before anything is created.

The second way hands Compute Engine the family as a string and lets it resolve the name when it
creates the disk. Delete the data block and put the string in its place; `sed` does both:

```
ana@laptop:~/gcp/images$ sed -i '/^data/,/^}/d; s|data.google_compute_image.debian.self_link|"debian-cloud/debian-12"|' main.tf
ana@laptop:~/gcp/images$ grep -n image main.tf
1:# images/main.tf
24:      image = "debian-cloud/debian-12"
ana@laptop:~/gcp/images$ terraform plan -no-color | grep -E '^  #|image|^Plan'
  # google_compute_instance.web will be created
              + image                  = "debian-cloud/debian-12"
Plan: 1 to add, 0 to change, 0 to destroy.
```

That plan needed nothing from Google, and that is the trade. **The data source tells you which
image you are getting before you get it; the string finds out at creation.** For a team that
reviews plans, the first is the better habit once there is an account, because the image appears
in the plan as a dated name somebody can read. In this lab it can only be the second.

## What is behind the name

`gcloud compute images list` is the command that shows every public image with its project and
family. Here it stops at the missing account, like every remote command in this course, so the
command is shown and not its output. With an account, `--filter="family~debian"` narrows it to
the Debian families, and `--show-deprecated` adds the images a family no longer points to.
