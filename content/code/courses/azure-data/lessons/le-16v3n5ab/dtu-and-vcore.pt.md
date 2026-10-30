---
title: DTU e vCore, os dois jeitos de comprar um
version: 1
---

**Um banco no Azure SQL Database é comprado pela computação, e há dois jeitos de dizer quanta.** O
modelo DTU vende um pacote: um número de unidades de transação de banco de dados, cada uma uma mistura
fixa de processador, memória e IO, com o armazenamento incluído até um tamanho. O modelo vCore vende as
partes: um número de núcleos virtuais numa geração de hardware com nome, o armazenamento com preço à
parte, e uma escolha de como o banco é construído por baixo. O motor é o mesmo nos dois. O que muda é o
que você pode escolher, e o que a conta conta.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado contra o
Azure.** As declarações do fim são conferidas pelo Terraform, offline, o que é saída real sobre as
regras do provider e nada mais.

## DTU: três níveis, um número

| nível | tamanhos | para que serve |
|---|---|---|
| Basic | 5 DTUs | um banco pequeno, de uso leve e ocasional |
| Standard | o S0 tem 10 DTUs, o S1 20, o S2 50, o S3 100, e assim até o S12 | a maioria das cargas que não precisam de IO rápido |
| Premium | o P1 tem 125 DTUs, e assim até o P15 | trabalho pesado em IO, em armazenamento local de estado sólido |

**Um DTU não pode ser lido numa máquina**: é a medida da Microsoft para um benchmark misto, e o único
jeito de saber de quantos um banco precisa é rodá-lo e olhar a porcentagem que ele usa. Essa é a
força do modelo para uma equipe pequena, já que um número move tudo junto, e a fraqueza para quem sabe
que o banco precisa de memória e não de processador: no modelo DTU os dois não podem ser comprados
separados.

## vCore: três níveis, construídos de jeitos diferentes

| nível | como é construído | o que compra |
|---|---|---|
| General Purpose | computação num nó, os dados em armazenamento premium remoto | o padrão; um failover sobe um nó novo e conecta o armazenamento |
| Business Critical | dados no SSD local do nó, mantidos em sincronia em outras réplicas | latência menor de IO, failover mais rápido e uma réplica de leitura incluída |
| Hyperscale | computação separada de uma camada de page servers que guardam os dados | armazenamento que cresce muito além dos outros, restaurações rápidas, réplicas extras para leitura |

**O modelo vCore é o mais novo dos dois, e duas coisas só existem nele.** A primeira é a computação
serverless da próxima seção. A segunda é o Azure Hybrid Benefit: uma empresa que tem licenças de SQL
Server com Software Assurance paga os vCores sem a parte de licença do preço. Para uma empresa que sai
de um armário cheio de SQL Servers licenciados, essa é a maior linha da decisão, e o modelo DTU não
pode usá-la.

**O armazenamento, no vCore, é cobrado à parte**, por GB do tamanho máximo que você define, e os
backups também, além de uma franquia. Um mês tem 730 horas, como na calculadora da própria Microsoft,
e a computação tem preço por vCore por hora. A ilustrativos 0,25 USD por vCore-hora, os dois vCores de
um `GP_Gen5_2` custam 2 × 0,25 × 730 = 365,00 por mês, sem ninguém conectado.

## Os nomes, como declaração

Os nomes entre os quais você escolhe são strings curtas: `Basic`, `S0` e `P1` para DTU, e para vCore
o nível, o hardware e os núcleos, `GP_Gen5_2`, `BC_Gen5_4`, `HS_Gen5_8`. O banco de pedidos da
Quitanda, o servidor lógico dele e uma cópia de desenvolvimento, declarados para o Terraform. Crie um
diretório para eles:

```sh
mkdir -p ~/azure/tf/sql && cd ~/azure/tf/sql
```

e salve isto nele:

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

variable "sql_admin_password" {
  type      = string
  sensitive = true
}

resource "azurerm_resource_group" "data" {
  name     = "rg-quitanda-data-prd"
  location = "brazilsouth"
}

resource "azurerm_mssql_server" "orders" {
  name                         = "sql-quitanda-orders-prd"
  resource_group_name          = azurerm_resource_group.data.name
  location                     = azurerm_resource_group.data.location
  version                      = "12.0"
  administrator_login          = "quitanda"
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
}

resource "azurerm_mssql_database" "orders" {
  name        = "orders"
  server_id   = azurerm_mssql_server.orders.id
  sku_name    = "GP_Gen5_2"
  max_size_gb = 100

  short_term_retention_policy {
    retention_days = 7
  }
}

resource "azurerm_mssql_database" "orders_dev" {
  name                        = "orders-dev"
  server_id                   = azurerm_mssql_server.orders.id
  sku_name                    = "GP_S_Gen5_2"
  min_capacity                = 0.5
  auto_pause_delay_in_minutes = 60
  max_size_gb                 = 32
}
```

**A senha é uma variável marcada como sensível, e não tem valor no arquivo**, então nunca cai num
repositório; um deploy de verdade a passa a partir de um cofre de segredos. `version = "12.0"` é a
versão da API do servidor lógico, que é `12.0` há anos e não diz nada sobre o motor. `retention_days`
é a janela de restauração a um ponto no tempo da primeira seção.

```
ana@laptop:~/azure/tf/sql$ terraform init -no-color | grep -E 'Installing|Installed|successfully'
- Installing hashicorp/azurerm v5.12.0...
- Installed hashicorp/azurerm v5.12.0 (signed by HashiCorp)
Terraform has been successfully initialized!
ana@laptop:~/azure/tf/sql$ terraform validate -no-color
Success! The configuration is valid.

```

O provider conhece a forma de um nome, ainda que não todo nome que o Azure vende:

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/"GP_Gen5_2"/"GP-Gen5-2"/' main.tf && terraform validate -no-color; mv main.tf.bak main.tf

Error: invalid value for sku_name (This is not a valid sku name. For example, a valid sku name is 'GP_S_Gen5_1','HS_Gen4_1','BC_Gen5_2', 'ElasticPool', 'Basic', 'S0', 'P1'.)

  with azurerm_mssql_database.orders,
  on main.tf line 37, in resource "azurerm_mssql_database" "orders":
  37:   sku_name    = "GP-Gen5-2"

```

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/retention_days = 7/retention_days = 40/' main.tf && terraform validate -no-color 2>&1 | grep Error; mv main.tf.bak main.tf
Error: expected short_term_retention_policy.0.retention_days to be in the range (1 - 35), got 40
```

**As duas recusas são regras do próprio provider, conferidas sem conta nenhuma**: um nome que não tem
a forma de um SKU, e uma retenção fora dos 1 a 35 dias que a documentação dá. O que o `validate` não
tem como saber é se `brazilsouth` vende um dado tamanho hoje, ou se a cota da sua assinatura permite;
isso só o Azure responde, na criação.
