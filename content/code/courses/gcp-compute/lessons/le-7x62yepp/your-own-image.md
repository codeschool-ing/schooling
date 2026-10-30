---
title: Building an image of your own
version: 1
---

A public image is a clean operating system, and the shop needs more than that: a runtime, its own
code, a configured web server. **Installing all of it at boot, on every machine, is slow and fails in
new ways each time; baking it into an image once makes every boot the same.** Lesson 7 is about the
first approach, the startup script. This section is about the second.

## Three sources for an image

Compute Engine makes an image from something that already exists:

- **a disk**, usually the boot disk of a machine you set up by hand or by script and then stopped;
- **a snapshot** of such a disk, which lesson 3 is about;
- **an imported file**, a virtual disk built somewhere else and uploaded to Cloud Storage.

The first is the one a small team starts with. Set up a builder machine, stop it so its disk is
quiet, make an image of the disk, delete the builder. Written as Terraform, in a folder
`image-build`, it looks like this:

```hcl
# image-build/main.tf
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

resource "google_compute_instance" "builder" {
  name         = "shop-web-builder"
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

resource "google_compute_image" "shop_web" {
  name              = "shop-web-v3"
  family            = "shop-web"
  source_disk       = google_compute_instance.builder.boot_disk[0].source
  storage_locations = ["southamerica-east1"]
}
```

```
ana@laptop:~/gcp/image-build$ terraform plan -no-color | grep -E '^  #|^      \+ (name|family|source_disk) |^Plan'
  # google_compute_image.shop_web will be created
      + family             = "shop-web"
      + name               = "shop-web-v3"
      + source_disk        = (known after apply)
  # google_compute_instance.builder will be created
      + name                 = "shop-web-builder"
Plan: 2 to add, 0 to change, 0 to destroy.
```

**`(known after apply)` is the honest answer for the disk**: it does not exist until the builder
does, so neither Terraform nor anybody else can name it yet. The family, the name and the place the
image is stored are all yours, and `storage_locations` is the one worth deciding on purpose. Left
out, Google stores the image in a multi-region near the source; set, it stays in São Paulo, which is
where the machines that boot from it will be.

One step is missing from that file and cannot be written in it: **the builder must be stopped
before the image is taken**, or the image captures a disk in the middle of being written. Terraform
has no "stop, then copy" step. The usual answer is to make the image with `gcloud compute images
create shop-web-v3 --source-disk=shop-web-builder --family=shop-web` after stopping the machine, or
to let a tool built for this do the whole sequence.

## Packer, the tool built for it

HashiCorp's Packer does exactly that sequence: it starts a temporary machine from a source image,
runs your provisioning steps on it, stops it, makes the image, and deletes everything it created.
The template for the shop's web image, written from Packer's documentation for its
`googlecompute` builder, **is shown here and not run**, because every step of it calls Google:

```hcl
# shop-web.pkr.hcl
source "googlecompute" "shop_web" {
  project_id          = "planner-dev"
  zone                = "southamerica-east1-a"
  source_image_family = "debian-12"
  image_name          = "shop-web-{{timestamp}}"
  image_family        = "shop-web"
  ssh_username        = "packer"
}

build {
  sources = ["source.googlecompute.shop_web"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx python3-venv",
    ]
  }
}
```

`{{timestamp}}` gives every build a unique name and `image_family` puts it in the family, so each
`packer build` publishes a new newest image and moves the pointer of section 03. That is the whole
release process for a machine image: build, test a machine made from it, and deprecate it if the test
fails.

## What an image costs to keep

An image is stored, and storage is billed for as long as it exists:

```
ana@laptop:~/gcp$ python3 prices.py disks | grep -E "image|snapshot"
Disks and images, per GiB per month
  standard snapshot                                     0.05  per GiB-month
  archive snapshot                                     0.019  per GiB-month
  custom image                                          0.05  per GiB-month
```

Five cents per GiB per month is small for one image. It stops being small for a nightly build that
nobody deletes: a 10 GiB image built every night for a year is 365 images and about 180 dollars a
month by the end of it. **Deprecating an image does not delete it**, as section 03 quoted, so a build
pipeline needs a step that deletes the old ones, and lesson 21 meets the same problem with container
images.

A **machine image** is a different object with a confusingly close name. It captures a whole machine:
its configuration, its metadata and every disk attached to it, which makes it a backup of one
machine rather than a template for many. Use an image to make new machines alike; use a machine
image to put one machine back the way it was.
