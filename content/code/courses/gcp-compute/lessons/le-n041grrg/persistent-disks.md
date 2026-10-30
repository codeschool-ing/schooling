---
title: Persistent disks, zonal and regional
version: 1
---

The commonest wrong picture of a cloud disk is a drive inside the server. **A persistent disk is
storage on Google's network, attached to the machine over that network, and it outlives the
machine it is attached to.** Delete the machine and the disk can stay; stop it and the disk keeps
everything; attach it to another machine and the data comes along.

## Four types, one question

The type decides how fast the disk is and what each gigabyte costs, and the price sheet from
lesson 1 lists them:

```
ana@laptop:~/gcp$ python3 prices.py disks | head -7
Google Cloud public prices, us-central1, USD, 30 October 2026

Disks and images, per GiB per month
  pd-standard, after the free 30 GiB                    0.04  per GiB-month
  pd-balanced                                            0.1  per GiB-month
  pd-ssd                                                0.17  per GiB-month
  pd-balanced, regional                                  0.2  per GiB-month
```

| type | what it is for |
|---|---|
| `pd-standard` | backed by hard disks: logs, backups, data read in long runs |
| `pd-balanced` | SSD at a moderate price: the default for boot disks and most data |
| `pd-ssd` | SSD with more operations per second per GiB: busy databases |
| `pd-extreme` | SSD whose operations you provision separately: the largest databases |

**The performance of a persistent disk grows with its size.** Each type promises a number of
operations per second and a throughput per GiB, up to a ceiling, so a small `pd-ssd` can be slower
than a large `pd-balanced`. The machine sets ceilings of its own, by series and vCPU count, and the
disk gets the lower of the two. That is why "the database is slow, give it a faster disk" sometimes
fixes nothing: the limit was the machine's.

## A disk of its own

A boot disk comes with the machine. A data disk is a resource of its own, created separately and
attached, which is what lets it outlive the machine. For the shop's `orders` service, in a folder
`disks`:

```hcl
# disks/main.tf
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

resource "google_compute_disk" "orders_data" {
  name = "orders-data"
  type = "pd-balanced"
  zone = "southamerica-east1-a"
  size = 100
}

resource "google_compute_region_disk" "orders_ha" {
  name          = "orders-ha"
  type          = "pd-balanced"
  region        = "southamerica-east1"
  replica_zones = ["southamerica-east1-a", "southamerica-east1-b"]
  size          = 100
}

resource "google_compute_instance" "orders" {
  name         = "orders-1"
  machine_type = "e2-standard-2"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  attached_disk {
    source      = google_compute_disk.orders_data.id
    device_name = "orders-data"
  }

  network_interface {
    network = "default"
  }
}
```

```
ana@laptop:~/gcp/disks$ terraform plan -no-color | grep -E '^  #|^      \+ (type|size) |device_name += "|^Plan'
  # google_compute_disk.orders_data will be created
      + size                           = 100
      + type                           = "pd-balanced"
  # google_compute_instance.orders will be created
          + device_name                = "orders-data"
  # google_compute_region_disk.orders_ha will be created
      + size                           = 100
      + type                           = "pd-balanced"
Plan: 3 to add, 0 to change, 0 to destroy.
```

`device_name` is the name the disk has inside the machine: Debian shows it as
`/dev/disk/by-id/google-orders-data`, which is the path to put in `/etc/fstab`, because `/dev/sdb`
can change between boots and the by-id name cannot. The disk arrives empty and unformatted; making a
file system on it is a step inside the machine, which lesson 7's startup script can do.

## Zonal or regional

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two zones of southamerica-east1 side by side. In zone a, the machine orders-1 writes to the regional disk orders-ha, and every write is copied to its replica in zone b. In zone b a second machine, drawn dashed, can attach the replica and carry on if zone a fails. A zonal disk, orders-data, sits in zone a alone.\"><defs><marker id=\"l3r-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"370\" y=\"20\" width=\"330\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">southamerica-east1-a</text><text x=\"386\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">southamerica-east1-b</text><rect x=\"60\" y=\"66\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-1</text><text x=\"140.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">machine</text><rect x=\"60\" y=\"150\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-ha</text><text x=\"140.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">regional disk</text><rect x=\"410\" y=\"150\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-ha</text><text x=\"490.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">replica</text><rect x=\"410\" y=\"66\" width=\"160\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"490.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">standby</text><text x=\"490.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">if zone a fails</text><rect x=\"60\" y=\"222\" width=\"160\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"140.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders-data</text><text x=\"234\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zonal: zone a only</text><path d=\"M140 110 L140 148\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3r-ah)\"></path><path d=\"M220 175 L408 175\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l3r-ah)\"></path><text x=\"314\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">every write</text><path d=\"M490 148 L490 112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l3r-ah)\"></path></svg>", "caption": "A regional disk writes every block to two zones before it confirms the write. A zonal disk lives in one zone and is unavailable while that zone is."}
```

A zonal disk lives in one zone, and **a zone that fails takes its zonal disks with it** until it
comes back. A **regional disk** writes every block to two zones synchronously, so a machine in the
other zone can attach it and carry on. That is the second resource in the file, and its price is the
price of that guarantee: 0.2 per GiB-month against 0.1, because every byte is stored twice. Writes
also take a little longer, since each one is confirmed in two places.

Use one where the data is the thing that cannot be lost and the service cannot wait for a zone to
recover: the disk under a database that has no replica of its own. Where the application already
keeps copies, a managed database or a group of stateless machines, a regional disk pays twice for
something that is already there.
