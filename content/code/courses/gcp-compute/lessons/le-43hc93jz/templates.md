---
title: Instance templates, written once and never edited
version: 1
---

Three machines that are meant to be the same drift apart the moment somebody changes one by hand.
**An instance template is the description of a machine kept apart from any machine: the type, the
image, the disks, the network and the metadata, written once, from which a group makes as many
copies as it is asked for.** It is the first half of everything this lesson builds.

## What a template holds, and the one thing it cannot do

A template holds what you would pass to `gcloud compute instances create`, minus the name and the
zone, which the group decides. And **a template cannot be changed**. There is no edit: a new
description is a new template, with a new name, and the group is told to use it. That sounds like a
nuisance and is the opposite. A template that could change would mean two machines made from "the
same" template on two different days could differ, which is the drift templates exist to end.

Terraform has to work around that rule, and the way it does is worth reading closely. For the shop's
`web` machines, in a folder `group`, start the file with the template:

```hcl
# group/main.tf
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

resource "google_compute_instance_template" "web" {
  name_prefix  = "web-"
  machine_type = "e2-standard-2"

  disk {
    source_image = "projects/planner-dev/global/images/family/shop-web"
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    network = "default"
  }

  labels = {
    service = "web"
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

Two lines carry the workaround. **`name_prefix`** lets Terraform invent a new name for every new
version of the template, `web-` followed by a timestamp and a counter, because a new template needs a
name nothing else has. **`create_before_destroy`** makes Terraform create the new template before
deleting the old one, because the group is still using the old one and Compute Engine refuses to
delete a template in use. Together they turn "edit the template" into "make a new one, point the
group at it, then remove the old one", which is the only order that works.

```
ana@laptop:~/gcp/group$ terraform plan -no-color | grep -E '^  #|name_prefix|^      \+ name |machine_type|^Plan'
  # google_compute_instance_template.web will be created
      + machine_type         = "e2-standard-2"
      + name                 = (known after apply)
      + name_prefix          = "web-"
Plan: 1 to add, 0 to change, 0 to destroy.
```

The name is `(known after apply)` because it does not exist until Terraform invents it, and
`name_prefix` is what you wrote. Section 05 shows what happens when a line of the template changes.

The image is the family `shop-web` from lesson 2. That choice has a consequence lesson 2 warned
about: the template names the family, so each machine the group creates resolves the family at that
moment. Two machines created a week apart can boot different builds from one template. Where that is
not acceptable, the template names a dated image instead, and a new build means a new template.
