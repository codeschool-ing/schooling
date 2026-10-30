---
title: Capture, the stream copied into storage
version: 1
---

**This section is taught from Microsoft's documentation and was not run.** The Event Hubs emulator
has no Capture, as lesson 1 listed, and the one thing here that ran is Terraform checking a
declaration of it offline.

**Capture is a feature of the event hub that writes everything sent to it into Blob Storage or Data
Lake Storage, with no program of yours involved.** It is the answer to the analysts' half of
Quitanda's problem: every click in the lake by morning, kept for years, while the hub forgets them
after a day. Without it somebody writes a reader like `checkpointed.py` whose only job is to append
events to files, runs it, watches it and pays for it; with it, that reader is a setting.

## What it writes

**Capture writes Avro files, one stream of files per partition.** Avro is a binary format that
carries its schema at the top of each file, and every record in a Capture file holds one event: its
body as bytes, untouched, beside its sequence number, its offset, its enqueued time and the
properties the service and the producer attached to it. Event Hubs still never looks inside the body, so the click's JSON is in
there as JSON, wrapped in Avro.

**A file is closed by time or by size, whichever comes first.** The time window runs from 1 to 15
minutes and the size window from 10 MB to 500 MB, according to the documentation; with a five-minute
window and Quitanda's traffic, each partition produces a file every five minutes. The files are named
by a pattern built from the namespace, the hub, the partition and the time:

```
{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}
```

Those are the default parts, all of which must appear, and they can be arranged in another order.
The date parts are what the lake lessons of this course need: a query about one day reads one day's
directories, which lesson 18 calls partition pruning. A window with no events writes an empty file
unless the hub is told to skip empty archives, and an analyst counting files learns to tell the two
apart.

**Avro is a good format to write and a poor one to query.** It is written row by row, which is why
Capture can produce it as events arrive, and a query engine reading it has to read every byte of
every row, the opposite of the Parquet and Delta files of lessons 16 to 18. The usual pipeline lands
Capture's Avro as the raw layer and converts it on a schedule, which is a Data Factory job of lesson
19 or a notebook of lesson 20.

## Declaring it, and what `validate` cannot see

The declaration of the namespace, the hub with Capture, and the `fraud` group, in Terraform. Lesson
1 showed the pattern: a directory per topic, the file below in it, and `init` once.

```sh
mkdir -p ~/azure/tf/stream && cd ~/azure/tf/stream
```

`main.tf`:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.12.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "stream" {
  name     = "rg-quitanda-stream-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "lake" {
  name                     = "stquitandalakeprd"
  resource_group_name      = azurerm_resource_group.stream.name
  location                 = azurerm_resource_group.stream.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_container" "capture" {
  name               = "clicks-capture"
  storage_account_id = azurerm_storage_account.lake.id
}

resource "azurerm_eventhub_namespace" "app" {
  name                     = "evhns-quitanda-app-prd"
  resource_group_name      = azurerm_resource_group.stream.name
  location                 = azurerm_resource_group.stream.location
  sku                      = "Standard"
  capacity                 = 2
  auto_inflate_enabled     = true
  maximum_throughput_units = 6
}

resource "azurerm_eventhub" "clicks" {
  name              = "clicks"
  namespace_id      = azurerm_eventhub_namespace.app.id
  partition_count   = 4
  message_retention = 1

  capture_description {
    enabled             = true
    encoding            = "Avro"
    interval_in_seconds = 300
    size_limit_in_bytes = 314572800
    skip_empty_archives = true

    destination {
      name                = "EventHubArchive.AzureBlockBlob"
      archive_name_format = "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
      blob_container_name = azurerm_storage_container.capture.name
      storage_account_id  = azurerm_storage_account.lake.id
    }
  }
}

resource "azurerm_eventhub_consumer_group" "fraud" {
  name                = "fraud"
  namespace_name      = azurerm_eventhub_namespace.app.name
  eventhub_name       = azurerm_eventhub.clicks.name
  resource_group_name = azurerm_resource_group.stream.name
}
```

```
ana@laptop:~/azure/tf/stream$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/stream$ terraform validate -no-color
Success! The configuration is valid.
```

**The capacity is on the namespace, the partitions and Capture are on the hub.** `capacity = 2` is two
throughput units shared by every hub in the namespace, and `auto_inflate_enabled` lets Azure raise it
to six on a busy evening; the last section of this lesson is about both. `is_hns_enabled` makes the
destination a Data Lake Storage account, lesson 3's hierarchical namespace, which Capture writes to
like any other. `message_retention = 1` is one day, because the copy that lasts is the one Capture
writes. The window is 300 seconds and 314,572,800 bytes, which is 300 MB.

Then two changes, each of which Azure would refuse:

```
ana@laptop:~/azure/tf/stream$ sed -i 's/interval_in_seconds = 300/interval_in_seconds = 30/' main.tf && terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/stream$ sed -i 's/= 30$/= 300/; /sku /s/"Standard"/"Dedicated"/' main.tf && terraform validate -no-color

Error: expected sku to be one of ["Basic" "Premium" "Standard"], got Dedicated

  with azurerm_eventhub_namespace.app,
  on main.tf line 37, in resource "azurerm_eventhub_namespace" "app":
  37:   sku                      = "Dedicated"
```

**The first change passed and the second did not, and both are wrong.** A window of 30 seconds is
below the documented minimum of one minute; the provider's schema does not encode that rule, so
`validate` accepts it and the error would come from Azure, during `apply`. `Dedicated` is not a tier
a namespace is created in: a Dedicated cluster is a resource of its own, `azurerm_eventhub_cluster`,
that namespaces are then placed on, and the provider knows the namespace's list of `sku` values. What
lesson 1 showed holds here too: `validate` catches what the schema knows, and only an `apply`
against a real subscription would catch the rest.
