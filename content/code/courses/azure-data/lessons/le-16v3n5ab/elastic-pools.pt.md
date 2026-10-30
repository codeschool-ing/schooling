---
title: Elastic pools, e muitos bancos numa conta só
version: 1
---

**Um elastic pool é uma quantidade de computação comprada uma vez e dividida por muitos bancos.** Cada
banco nele continua sendo um banco próprio, com os seus dados e as suas conexões, mas nenhum é
dimensionado sozinho: o pool tem um número de eDTUs, ou de vCores, e cada banco pega o que precisa
dele naquele momento, entre um mínimo e um máximo que você define para todos. O pool é cobrado por
hora pelo seu tamanho, seja o que for que os bancos dentro dele façam.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado contra o
Azure.** O pool do fim é uma declaração conferida pelo Terraform, offline, com o que essa conferência
não consegue ver mostrado também.

## Quando dividir ganha

**Um pool ganha quando muitos bancos ficam ociosos a maior parte do tempo e ocupados em horas
diferentes.** Cada um dos doze desenvolvedores da Quitanda tem uma cópia do banco de pedidos para a
suíte de testes. Cada cópia fica ociosa quase o dia todo e roda a toda velocidade por alguns minutos
sempre que o dono roda os testes, e os doze raramente fazem isso no mesmo minuto. Dimensionada sozinha,
cada uma precisa de um S1, 20 DTUs, por esses poucos minutos. A ilustrativos 30,00 USD por mês por S1,
doze custam 360,00.

Um pool Standard de 100 eDTUs, com máximo por banco de 50, guarda os doze: qualquer um deles pode rodar
os testes a mais que o dobro da velocidade de um S1, e dois podem fazer isso ao mesmo tempo a toda
velocidade. A ilustrativos 150,00 por mês por esse pool, os doze custam 150,00 juntos.

**Um pool perde quando os picos chegam juntos.** Se as doze suítes de teste rodam de um pipeline às
nove de toda manhã, doze bancos querem 50 eDTUs cada de um pool de 100, e cada um roda a um sexto da
velocidade. A aritmética do pool é sobre a sobreposição dos picos, não sobre o tamanho da média, e ela
é medida olhando os bancos, não adivinhada.

O serverless, da seção anterior, responde à mesma ociosidade pelo outro lado: encolhe a conta de cada
banco em vez de dividir uma. Um pool serve para muitos bancos ocupados em momentos imprevisíveis que
precisam responder na hora; o serverless serve para poucos bancos ociosos por horas que podem esperar
um pouco pela primeira conexão.

## O pool, como declaração

No mesmo diretório do `main.tf` da seção anterior, `~/azure/tf/sql`, salve isto ao lado dele. O
Terraform lê todos os arquivos `.tf` de um diretório como uma configuração só:

`pool.tf`:

```hcl
resource "azurerm_mssql_elasticpool" "dev" {
  name                = "pool-quitanda-dev"
  resource_group_name = azurerm_resource_group.data.name
  location            = azurerm_resource_group.data.location
  server_name         = azurerm_mssql_server.orders.name
  max_size_gb         = 100

  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 100
  }

  per_database_settings {
    min_capacity = 0
    max_capacity = 50
  }
}

resource "azurerm_mssql_database" "dev" {
  for_each        = toset(["ana", "bruno", "carla"])
  name            = "orders-dev-${each.key}"
  server_id       = azurerm_mssql_server.orders.id
  elastic_pool_id = azurerm_mssql_elasticpool.dev.id
}
```

`capacity` são os 100 eDTUs do pool, e `per_database_settings` é a faixa em que todo banco dentro dele
se move. Um banco entra num pool nomeando-o, e aí não tem tamanho próprio.

```
ana@laptop:~/azure/tf/sql$ terraform validate -no-color
Success! The configuration is valid.

```

**Válido, e uma coisa que o Azure recusaria também é.** Um banco não pode pegar de um pool mais do que
o pool tem, e a documentação diz que um máximo por banco não pode passar do tamanho do pool. O provider
não confere isso:

```
ana@laptop:~/azure/tf/sql$ sed -i.bak 's/max_capacity = 50/max_capacity = 500/' pool.tf && terraform validate -no-color; mv pool.tf.bak pool.tf
Success! The configuration is valid.

```

Então um pool com 100 eDTUs e um máximo por banco de 500 passa no `validate` e falharia quando se
pedisse ao Azure para criá-lo. Essa é a forma geral do que uma conferência offline pode dar: ela pega o
que está errado num valor sozinho, e nada que só está errado ao lado de outro valor cujas regras o
Azure conhece.
