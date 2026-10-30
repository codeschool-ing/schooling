---
title: A factory, declared and checked on a laptop
version: 1
---

**Data Factory has no emulator, and nothing in this section runs a pipeline.** What can be done
without an account is what lesson 1 did for a storage account: write the declaration and have
Terraform check it against the Azure provider's schema, offline. That checks more than it sounds,
because a factory is almost entirely declaration: the linked service, the datasets, the pipeline and
the trigger are all JSON documents that Azure stores, and Terraform is one of the ways to write them.

The pipeline below is Quitanda's nightly load from the previous section's chain: the day's export in
the `raw` container, as CSV, copied into `curated` as Parquet under `orders/dt=<day>/`. Make a
directory and save the file in it:

```sh
mkdir -p ~/azure/tf/factory && cd ~/azure/tf/factory
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

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_storage_account" "lake" {
  name                     = "stquitandalakeprd"
  resource_group_name      = azurerm_resource_group.data.name
  location                 = azurerm_resource_group.data.location
  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"
  is_hns_enabled           = true
}

resource "azurerm_data_factory" "etl" {
  name                = "adf-quitanda-etl-prd"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "lake" {
  name                 = "ls_lake"
  data_factory_id      = azurerm_data_factory.etl.id
  service_endpoint     = azurerm_storage_account.lake.primary_blob_endpoint
  use_managed_identity = true
}

resource "azurerm_data_factory_dataset_delimited_text" "raw_orders" {
  name                = "ds_raw_orders"
  data_factory_id     = azurerm_data_factory.etl.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.lake.name
  parameters          = { day = "" }
  column_delimiter    = ","
  first_row_as_header = true

  azure_blob_storage_location {
    container            = "raw"
    path                 = "@concat('orders/', dataset().day)"
    dynamic_path_enabled = true
    filename             = "orders.csv"
  }
}

resource "azurerm_data_factory_dataset_parquet" "curated_orders" {
  name                = "ds_curated_orders"
  data_factory_id     = azurerm_data_factory.etl.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.lake.name
  parameters          = { day = "" }
  compression_codec   = "snappy"

  azure_blob_storage_location {
    container            = "curated"
    path                 = "@concat('orders/dt=', dataset().day)"
    dynamic_path_enabled = true
  }
}

resource "azurerm_data_factory_pipeline" "nightly" {
  name            = "pl_orders_nightly"
  data_factory_id = azurerm_data_factory.etl.id
  parameters      = { day = "" }
  activities_json = jsonencode([
    {
      name = "CopyOrders"
      type = "Copy"
      inputs = [{
        referenceName = azurerm_data_factory_dataset_delimited_text.raw_orders.name
        type          = "DatasetReference"
        parameters    = { day = "@pipeline().parameters.day" }
      }]
      outputs = [{
        referenceName = azurerm_data_factory_dataset_parquet.curated_orders.name
        type          = "DatasetReference"
        parameters    = { day = "@pipeline().parameters.day" }
      }]
      policy = { retry = 2, retryIntervalInSeconds = 300, timeout = "0.01:00:00" }
      typeProperties = {
        source = { type = "DelimitedTextSource" }
        sink   = { type = "ParquetSink" }
      }
    }
  ])
}
```

Five resources after the storage account, one for each part of the previous section, and each names
the one before it:

- **`azurerm_data_factory`** is the factory, with a **system-assigned managed identity**:
  `azure-foundations` lesson 8's kind of identity, which Azure creates with the factory and deletes
  with it, and which needs no secret;
- **the linked service** points at the account's blob endpoint and signs in as that identity,
  `use_managed_identity = true`, so no key or connection string is written anywhere. The identity
  still needs a role on the account, such as Storage Blob Data Contributor, which is a role
  assignment and not part of this file;
- **the two datasets** take a parameter, `day`, and build their folder from it with an expression,
  `@concat('orders/dt=', dataset().day)`. The `@` marks a string Data Factory evaluates at run time;
- **the pipeline** has one activity, a `Copy`, whose input and output are the two datasets with the
  pipeline's own `day` passed down to them, and a policy: two retries, five minutes apart, and an
  hour before the activity is declared failed.

`activities_json` is the one part written as JSON rather than as HCL, because that is how Azure
stores a pipeline: `jsonencode` turns the HCL list into the document the Data Factory API expects.

## What validate checks, and what it cannot

```
ana@laptop:~/azure/tf/factory$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/factory$ terraform validate -no-color
Success! The configuration is valid.

ana@laptop:~/azure/tf/factory$ sed -i 's/adf-quitanda-etl-prd/adf_quitanda_etl_prd/' main.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/adf_quitanda_etl_prd/adf-quitanda-etl-prd/' main.tf
Error: invalid value for name (invalid data_factory_name, see https://docs.microsoft.com/azure/data-factory/naming-rules)
ana@laptop:~/azure/tf/factory$ sed -i 's/type = "Copy"/type = "Cpy"/' main.tf && terraform validate -no-color; sed -i 's/type = "Cpy"/type = "Copy"/' main.tf
Success! The configuration is valid.

```

**The factory's name was checked; the activity's type was not.** The provider knows the naming rules
of a factory, letters, digits and hyphens, so the underscores were refused before anything was sent.
It does not know what a pipeline may contain: `activities_json` is a string to it, and an activity of
type `Cpy` is as valid as one of type `Copy`. Azure would refuse it at deployment, which is the moment
this course cannot reach.

**That gap is where a factory's errors live.** The schema of an activity, the names of the datasets it
references, whether `@pipeline().parameters.day` is spelt right, whether the identity may read the
container: none of it is checked by `validate`, and all of it is checked by Azure, at deployment or at
the first run. Teams that keep factories in Terraform usually also export the factory's JSON from a
development factory, where the portal's editor checks each activity as it is written, which is the
check this course has no way to run.
