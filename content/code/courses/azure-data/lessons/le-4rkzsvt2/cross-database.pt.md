---
title: Dois bancos, uma consulta
version: 1
---

**Um nome de três partes, `database.schema.table`, é como uma consulta num banco lê uma tabela de
outro**, e é o hábito que o Azure SQL Database quebra e a Managed Instance mantém. As entregas da
Quitanda moram num banco próprio, escrito pelo app dos entregadores, e a tela de atendimento quer um
pedido e a sua entrega numa linha só. Numa instância isso é um `JOIN`.

Suba o SQL Server em `~/azure` e, num terminal novo, defina de novo a função da lição 8:

```sh
docker compose --profile sql up -d
sql() { docker compose exec -T sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Quitanda-Lab-2026 -C -W -s '|' "$@"; }
```

**O contêiner subiu vazio, então monte os pedidos de novo** a partir do `orders.sql` que você salvou na
lição 8, e depois as entregas. Salve isto como `~/azure/delivery.sql`: um segundo banco, preenchido a
partir do primeiro por um nome de três partes, com uma entrega para cada pedido do primeiro dia:

`delivery.sql`:

```sql
CREATE DATABASE delivery;
GO
USE delivery;
CREATE TABLE dbo.deliveries (
  order_id     int PRIMARY KEY,
  courier      varchar(20) NOT NULL,
  delivered_at datetime2(0) NOT NULL
);
INSERT dbo.deliveries
SELECT order_id, CONCAT('courier-', order_id % 40), DATEADD(minute, 50, placed_at)
FROM quitanda.dbo.orders WHERE placed_at < '2026-01-02';
SELECT COUNT(*) AS deliveries FROM dbo.deliveries;
GO
```

```
ana@laptop:~/azure$ sql < orders.sql
Changed database context to 'quitanda'.

(100000 rows affected)
orders
------
100000

(1 rows affected)
ana@laptop:~/azure$ sql < delivery.sql
Changed database context to 'delivery'.

(287 rows affected)
deliveries
----------
287

(1 rows affected)
```

**O `INSERT` já atravessou a fronteira**: ele rodou em `delivery` e leu `quitanda.dbo.orders`. A
consulta da tela de atendimento vai no sentido contrário, a partir de `quitanda`, que o `-d` torna o
banco atual:

```
ana@laptop:~/azure$ sql -d quitanda -Q "SELECT TOP (3) o.order_id, o.total_cents, d.courier, d.delivered_at FROM dbo.orders o JOIN delivery.dbo.deliveries d ON d.order_id = o.order_id ORDER BY o.order_id"
order_id|total_cents|courier|delivered_at
--------|-----------|-------|------------
1|1537|courier-1|2026-01-01 00:55:00
2|1574|courier-2|2026-01-01 01:00:00
3|1611|courier-3|2026-01-01 01:05:00

(3 rows affected)
```

## O que o Azure SQL Database responde em vez disso

**O Azure SQL Database recusa essa consulta**: lá um nome de três partes só pode nomear o banco atual,
e `delivery.dbo.deliveries` nomeia outro. A documentação lista isso entre as diferenças em relação ao
SQL Server, e não foi rodado aqui, porque não há Azure SQL Database neste curso; não há transcrição da
recusa. Os dois bancos podem ficar no mesmo servidor lógico e isso não muda nada, já que o servidor
lógico é um nome e não uma instância, como a lição 8 mostrou.

O que uma empresa faz a respeito, no Azure SQL Database, é uma de três coisas, cada uma um trabalho:

- **juntar os dois num banco só**, como dois esquemas, `orders.orders` e `delivery.deliveries`, que é a
  resposta limpa quando uma equipe é dona dos dois;
- **consultar a partir da aplicação**, lendo cada banco com a sua conexão e juntando no código, o que
  tira o join do motor e em geral o deixa mais lento;
- **uma elastic query**, uma tabela externa num banco que aponta para uma tabela do outro, um recurso
  do Azure SQL Database com limites próprios, a ser lido na documentação antes de qualquer coisa
  depender dele.

**Na Managed Instance nada disso é preciso**, que é o ponto desta lição numa consulta. O `JOIN` acima
roda lá sem mudança, porque os dois bancos estão numa instância, exatamente como estão neste
contêiner.
