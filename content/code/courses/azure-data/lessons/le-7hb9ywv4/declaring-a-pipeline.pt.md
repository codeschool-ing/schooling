---
title: Uma factory, declarada e conferida num laptop
version: 1
---

**O Data Factory não tem emulador, e nada nesta seção roda um pipeline.** O que dá para fazer sem
conta é o que a lição 1 fez com uma conta de armazenamento: escrever a declaração e fazer o Terraform
conferi-la contra o schema do provider do Azure, offline. Isso confere mais do que parece, porque uma
factory é quase toda declaração: o linked service, os datasets, o pipeline e o gatilho são documentos
JSON que o Azure guarda, e o Terraform é um dos jeitos de escrevê-los.

O pipeline abaixo é a carga noturna da Quitanda na cadeia da seção anterior: o export do dia no
contêiner `raw`, em CSV, copiado para `curated` como Parquet em `orders/dt=<dia>/`. Crie um diretório
e salve o arquivo nele:

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

Cinco recursos depois da conta de armazenamento, um para cada parte da seção anterior, e cada um cita
o anterior:

- **`azurerm_data_factory`** é a factory, com uma **identidade gerenciada atribuída pelo sistema**: o
  tipo de identidade da lição 8 de `azure-foundations`, que o Azure cria com a factory e apaga com
  ela, e que não precisa de segredo nenhum;
- **o linked service** aponta para o endpoint de blob da conta e entra como essa identidade,
  `use_managed_identity = true`, então nenhuma chave ou connection string fica escrita em lugar
  nenhum. A identidade ainda precisa de um papel na conta, como Storage Blob Data Contributor, que é
  uma atribuição de papel e não faz parte deste arquivo;
- **os dois datasets** recebem um parâmetro, `day`, e montam a pasta a partir dele com uma expressão,
  `@concat('orders/dt=', dataset().day)`. O `@` marca um texto que o Data Factory avalia na hora da
  execução;
- **o pipeline** tem uma atividade, um `Copy`, cuja entrada e saída são os dois datasets com o `day` do
  próprio pipeline repassado a eles, e uma política: duas novas tentativas, com cinco minutos entre
  elas, e uma hora até a atividade ser declarada falha.

`activities_json` é a única parte escrita como JSON e não como HCL, porque é assim que o Azure guarda
um pipeline: o `jsonencode` transforma a lista em HCL no documento que a API do Data Factory espera.

## O que o validate confere, e o que não consegue

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

**O nome da factory foi conferido; o tipo da atividade, não.** O provider conhece as regras de nome
de uma factory, letras, dígitos e hífens, então os sublinhados foram recusados antes de qualquer
envio. Ele não sabe o que um pipeline pode conter: `activities_json` é um texto para ele, e uma
atividade do tipo `Cpy` é tão válida quanto uma do tipo `Copy`. O Azure a recusaria na implantação,
que é o momento a que este curso não chega.

**Essa lacuna é onde moram os erros de uma factory.** O schema de uma atividade, os nomes dos
datasets que ela cita, se `@pipeline().parameters.day` está bem escrito, se a identidade pode ler o
contêiner: nada disso é conferido pelo `validate`, e tudo isso é conferido pelo Azure, na implantação
ou na primeira execução. Times que mantêm factories no Terraform costumam também exportar o JSON da
factory de uma factory de desenvolvimento, onde o editor do portal confere cada atividade enquanto ela
é escrita, que é a conferência que este curso não tem como rodar.
