---
title: Um flexible server, e os três tamanhos de máquina
version: 1
---

**O Azure Database for PostgreSQL e o Azure Database for MySQL são vendidos cada um como um flexible
server**: um servidor de verdade rodando o motor de código aberto, na versão maior que você escolhe,
num tamanho de máquina que você escolhe, com a Microsoft cuidando dos patches, dos backups e do
failover. Ele é mais parecido com um servidor no armário do que o servidor lógico da lição 8. Há um
motor e uma máquina, você escolhe a versão, e os bancos dentro dele são seus para criar. A opção mais
antiga, o Single Server, foi aposentada, então flexible server é o que esta lição quer dizer com
qualquer um dos dois.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado contra o
Azure.** A declaração é conferida pelo Terraform, offline; as duas seções seguintes rodam o próprio
motor.

## Os três níveis de computação

| nível | família de máquina | para que serve |
|---|---|---|
| Burstable | série B, por exemplo `B_Standard_B1ms` | desenvolvimento, testes, um site pequeno: barato, com créditos de processador que gasta em rajadas |
| General Purpose | série D, por exemplo `GP_Standard_D2ds_v5` | a maioria dos bancos de produção: um equilíbrio entre processador e memória |
| Memory Optimized | série E, por exemplo `MO_Standard_E4ds_v5` | conjuntos de trabalho grandes, em que mais memória por vCore mantém os dados quentes em cache |

**Os nomes são o nível e depois o tamanho de máquina que o Azure vende como máquina virtual**, que é a
diferença mais clara em relação ao Azure SQL Database: aqui você compra um servidor do tamanho de uma
VM com um motor de banco em cima, e a conta é as horas da VM mais o armazenamento. O Burstable é o
mais barato e vem com limites que a documentação lista, e esta lição encontra dois deles: sem alta
disponibilidade e sem PgBouncer embutido.

**O armazenamento é provisionado e pode crescer, mas não encolher.** Você escolhe um tamanho, o disco
do servidor tem esse tamanho desde o primeiro dia e é cobrado como tal, e o autogrow pode aumentá-lo
quando os dados se aproximam do limite. Diminuí-lo de novo significa um servidor novo e uma cópia.
Então o tamanho é escolhido para o ano que vem, não para o tamanho do dump.

**Um servidor pode ser parado**, o que para a conta de computação enquanto o armazenamento continua,
por até sete dias; a documentação diz que o Azure o liga de novo depois disso. É para um servidor de
desenvolvimento que ninguém usa no fim de semana, não para um de produção.

## A declaração

Os pedidos da Quitanda poderiam ter morado num PostgreSQL, e a declaração dessa escolha é curta. Num
diretório novo:

```sh
mkdir -p ~/azure/tf/flex && cd ~/azure/tf/flex
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

variable "db_admin_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_postgresql_flexible_server" "orders" {
  name                          = "psql-quitanda-orders-prd"
  resource_group_name           = azurerm_resource_group.data.name
  location                      = azurerm_resource_group.data.location
  version                       = "17"
  sku_name                      = "GP_Standard_D2ds_v5"
  storage_mb                    = 131072
  backup_retention_days         = 7
  geo_redundant_backup_enabled  = false
  zone                          = "1"
  administrator_login           = "quitanda"
  administrator_password        = var.db_admin_password
  public_network_access_enabled = false

  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }
}
```

`version = "17"` é a versão maior, a mesma do contêiner que esta lição roda. `storage_mb` são 128 GB,
escritos em MB porque é a unidade que a API recebe. O bloco `high_availability` é assunto de uma seção
mais adiante nesta lição.

```
ana@laptop:~/azure/tf/flex$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/flex$ terraform validate -no-color
Success! The configuration is valid.

```

```
ana@laptop:~/azure/tf/flex$ sed -i.bak 's/"GP_Standard_D2ds_v5"/"Standard_D2ds_v5"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf

Error: invalid value for sku_name (is not a valid sku name)

  with azurerm_postgresql_flexible_server.orders,
  on main.tf line 29, in resource "azurerm_postgresql_flexible_server" "orders":
  29:   sku_name                      = "Standard_D2ds_v5"

```

**Um tamanho precisa levar o nível na frente**, `GP_` aqui, e o provider recusa o nome da máquina
sozinho. Ele diz menos do que a mensagem da lição 8 dizia: não quais nomes existem, só que este não é
um deles.
