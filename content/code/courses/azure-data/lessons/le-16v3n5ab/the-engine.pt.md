---
title: O motor por baixo, no seu laptop
version: 1
---

**O Azure SQL Database é o motor do SQL Server**, a mesma base de código que a Microsoft vende como
produto, rodada pela Microsoft como serviço. Então a parte dele que é sua, o esquema, as consultas e
os índices, pode ser praticada no próprio SQL Server, no contêiner que a lição 1 preparou. A parte que
é da Microsoft, o modelo de compra e tudo em volta do motor, não pode, e esta seção traça a linha entre
as duas com as respostas do próprio motor.

Suba o SQL Server em `~/azure`. Ele leva alguns segundos até aceitar uma conexão:

```sh
docker compose --profile sql up -d
```

Todo comando abaixo fala com ele pelo `sqlcmd`, o cliente de linha de comando que vem dentro do
contêiner, então nada precisa ser instalado no seu computador. Uma função curta do shell poupa a
digitação, e a consulta que esta seção faz duas vezes vai numa variável:

```sh
sql() { docker compose exec -T sql /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Quitanda-Lab-2026 -C -W -s '|' "$@"; }
Q="SELECT COUNT(*) AS orders, SUM(total_cents) AS cents FROM dbo.orders WHERE customer_id = 17"
```

`-C` confia no certificado do próprio contêiner, `-W` tira os espaços com que o SQL Server preenche
cada coluna, e `-s '|'` põe uma barra entre as colunas. Depois, os pedidos. Salve isto como
`~/azure/orders.sql`: uma tabela e cem mil pedidos de sete mil clientes, gerados pelo próprio motor
para que nada precise ser baixado:

`orders.sql`:

```sql
CREATE DATABASE quitanda;
GO
USE quitanda;
CREATE TABLE dbo.orders (
  order_id    int IDENTITY PRIMARY KEY,
  customer_id int NOT NULL,
  placed_at   datetime2(0) NOT NULL,
  total_cents int NOT NULL
);
WITH n AS (SELECT TOP (100000) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS i
           FROM sys.all_objects a CROSS JOIN sys.all_objects b)
INSERT dbo.orders (customer_id, placed_at, total_cents)
SELECT i % 7000, DATEADD(minute, i * 5, '2026-01-01'), 1500 + (i * 37) % 30000 FROM n;
SELECT COUNT(*) AS orders FROM dbo.orders;
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
```

## O que o motor diz que é

**`SERVERPROPERTY('EngineEdition')` é a resposta do próprio motor sobre como está rodando**, e é a
linha entre este laboratório e o serviço:

```
ana@laptop:~/azure$ sql -Q "SELECT CAST(SERVERPROPERTY('EngineEdition') AS int) AS engine_edition, CAST(SERVERPROPERTY('Edition') AS varchar(40)) AS edition, CAST(DATABASEPROPERTYEX('quitanda', 'ServiceObjective') AS varchar(20)) AS service_objective"
engine_edition|edition|service_objective
--------------|-------|-----------------
3|Enterprise Developer Edition (64-bit)|NULL

(1 rows affected)
```

**3 é o motor completo, aqui na edição Developer que o SQL Server oferece de graça para
desenvolvimento e testes.** A documentação da Microsoft lista as outras respostas, e duas delas são
esta lição e a próxima: **5 é o Azure SQL Database, e 8 é a Azure SQL Managed Instance**. Isso não foi
rodado aqui, e não há transcrição; é a verificação de uma linha que diz a um programa, ou a você, a
qual dos três ele foi conectado. `ServiceObjective` é o mesmo tipo de linha vista do outro lado. No
Azure ela nomeia como o banco foi comprado, `S0` ou `GP_Gen5_2` ou um dos nomes da próxima seção.
Aqui é `NULL`, porque nada foi comprado: o modelo de compra é o plano de controle, e nenhum emulador
responde a ele.

## A parte que é sua

A tela de atendimento da Quitanda pede os pedidos de um cliente toda vez que um cliente liga:

```
ana@laptop:~/azure$ sql -d quitanda -Q "SET STATISTICS IO ON; $Q" | cut -d, -f1-2
orders|cents
------|-----
15|256935

(1 rows affected)
Table 'orders'. Scan count 1, logical reads 337
ana@laptop:~/azure$ printf 'SET SHOWPLAN_TEXT ON\nGO\n%s\nGO\n' "$Q" | sql -d quitanda | grep -oE '(Clustered )?Index (Scan|Seek)'
Clustered Index Scan
```

**Quinze pedidos, e 337 páginas lidas para achá-los.** O `STATISTICS IO` conta as páginas de 8 KB que
o motor tocou, e o `SHOWPLAN_TEXT`, filtrado aqui para o único operador que importa, diz por quê: um
`Clustered Index Scan` lê a tabela inteira, porque nada diz ao motor onde estão as linhas do cliente
17. O índice que diz:

```
ana@laptop:~/azure$ sql -d quitanda -Q "CREATE INDEX ix_orders_customer ON dbo.orders (customer_id) INCLUDE (total_cents)"
ana@laptop:~/azure$ sql -d quitanda -Q "SET STATISTICS IO ON; $Q" | cut -d, -f1-2
orders|cents
------|-----
15|256935

(1 rows affected)
Table 'orders'. Scan count 1, logical reads 2
ana@laptop:~/azure$ printf 'SET SHOWPLAN_TEXT ON\nGO\n%s\nGO\n' "$Q" | sql -d quitanda | grep -oE '(Clustered )?Index (Scan|Seek)'
Index Seek
```

**De 337 páginas para 2, com um comando que não custa nada rodar de novo no Azure.** Esse é o trabalho
que a seção anterior deixou do seu lado, e é de onde vem a conta da próxima seção. No Azure SQL
Database o banco é comprado como uma quantidade fixa de computação e IO, e uma consulta que lê 337
páginas onde precisava de 2 gasta essa quantidade mais de cento e sessenta vezes mais rápido. Comprar
um nível maior deixa o scan mais rápido. Não o torna necessário, e é cobrado toda hora, com o índice
faltando ou não.

O SQL Server segura uns 2 GB de memória enquanto roda, então pare-o com o
`docker compose --profile '*' down` da lição 1 quando terminar; a próxima lição monta os bancos dela
de novo.
