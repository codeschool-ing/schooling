---
title: O PgBouncer embutido, e o MySQL ao lado
version: 1
---

**O PostgreSQL dá a cada conexão um processo próprio**, e isso custa caro em memória e no tempo de
abrir uma. Uma aplicação que abre uma conexão por requisição, ou uma frota de funções pequenas que
abrem cada uma a sua, chega ao `max_connections` muito antes de chegar ao limite do processador. A
correção é um pooler de conexões entre a aplicação e o motor, e o mais usado para o PostgreSQL é o
PgBouncer.

**Esta seção é ensinada a partir da documentação da Microsoft, e nada nela foi rodado contra o
Azure.** O laboratório não tem PgBouncer, e o curso não instala um.

## PgBouncer, embutido

**Um flexible server pode rodar o PgBouncer na mesma máquina do motor**, ligado por um parâmetro do
servidor, `pgbouncer.enabled`, e acessado na porta 6432 em vez da 5432. A aplicação não muda nada além
da porta. Muitas conexões de cliente dividem poucas conexões de servidor, então mil clientes de vida
curta podem ser atendidos pelas cem conexões que o contêiner listou como `max_connections`. Ele não é oferecido no Burstable, o segundo limite do Burstable desta lição.
Ele agrupa em modo de transação por padrão, o que quer dizer que um cliente que depende de uma configuração de sessão, de uma tabela
temporária ou de um prepared statement entre transações precisa ser conferido antes.

## MySQL, a mesma forma

**O Azure Database for MySQL flexible server é o mesmo serviço para o outro motor**: uma versão que
você escolhe, níveis de computação do burstable ao grande, armazenamento provisionado que cresce e não
encolhe, alta disponibilidade com redundância de zona ou na mesma zona, réplicas de leitura,
restauração a um ponto no tempo, parar e ligar. O que muda é o motor e o ecossistema dele, e os nomes
que o Azure dá a alguns níveis. Não há pooler embutido para o MySQL, cujas conexões são threads e não
processos, e por isso custam menos.

A Quitanda guarda o catálogo de produtos, escrito pela aplicação de um fornecedor que só fala MySQL,
num pequeno. Salve isto ao lado do `main.tf` em `~/azure/tf/flex`:

`mysql.tf`:

```hcl
resource "azurerm_mysql_flexible_server" "catalogue" {
  name                   = "mysql-quitanda-catalogue-prd"
  resource_group_name    = azurerm_resource_group.data.name
  location               = azurerm_resource_group.data.location
  version                = "8.0.21"
  sku_name               = "B_Standard_B1ms"
  backup_retention_days  = 7
  administrator_login    = "quitanda"
  administrator_password = var.db_admin_password
}
```

```
ana@laptop:~/azure/tf/flex$ terraform validate -no-color
Success! The configuration is valid.

```

`B_Standard_B1ms` é o mesmo tamanho Burstable que o servidor PostgreSQL poderia ter usado, e `8.0.21`
é como a API escreve a linha 8.0 do MySQL. Um catálogo lido pela loja o dia todo e escrito por um job
do fornecedor à noite é a carga para a qual o Burstable existe: quase sempre ocioso, às vezes ocupado,
e bem sem alta disponibilidade nem pooler.

## Escolhendo entre os quatro

| | Azure SQL Database | SQL Managed Instance | PostgreSQL flexible | MySQL flexible |
|---|---|---|---|---|
| motor | SQL Server, sempre atual | SQL Server, sempre atual | PostgreSQL, na versão que você escolhe | MySQL, na versão que você escolhe |
| o que você aluga | um banco | uma instância | um servidor | um servidor |
| licença | no preço, ou o Hybrid Benefit | no preço, ou o Hybrid Benefit | nenhuma | nenhuma |
| o piso | uns poucos DTUs | vários vCores | uma máquina Burstable | uma máquina Burstable |

**O motor decide primeiro, e o preço vem depois.** Uma aplicação escrita para o PostgreSQL vai para o
PostgreSQL flexible server custe o que custarem os outros; uma aplicação nova, ainda sem motor, é onde
a escolha é livre, e onde a ausência de licença no preço é o argumento mais forte dos motores de código
aberto. A lição 26 volta à escolha com todos os armazenamentos do curso na mesa.
