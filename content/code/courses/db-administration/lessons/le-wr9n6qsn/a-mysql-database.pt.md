---
title: Um banco MySQL para migrar
version: 1
---

Para migrar alguma coisa é preciso ter o que migrar, e o `shop` do curso já está no PostgreSQL.
Então esta seção monta um segundo servidor ao lado dele: **o MySQL 8.0, instalado dos pacotes do
próprio Ubuntu na mesma máquina virtual**, com um banco pequeno que tem todos os hábitos da seção
anterior. São duas tabelas, escritas do jeito que uma aplicação MySQL antiga as escreve.

```sh
sudo apt install -y mysql-server-8.0
```

O pacote sobe o servidor e o habilita, como o do PostgreSQL fez na lição 3. A conta de
administrador do MySQL no Ubuntu é `root`, e ela se autentica como a regra peer do PostgreSQL: o
usuário `root` do sistema operacional entra como o usuário `root` do banco, sem senha. É por isso que
todo comando `mysql` desta lição começa com `sudo`.

```
ana@db:~$ mysql --version
mysql  Ver 8.0.46-0ubuntu0.24.04.4 for Linux on x86_64 ((Ubuntu))
ana@db:~$ sudo mysql -e "SELECT @@version, @@sql_mode, @@collation_server\G"
*************************** 1. row ***************************
         @@version: 8.0.46-0ubuntu0.24.04.4
        @@sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
@@collation_server: utf8mb4_0900_ai_ci
```

Dois desses valores importam mais adiante. O **`sql_mode` é estrito**: `NO_ZERO_DATE` e
`STRICT_TRANS_TABLES` significam que um MySQL 8 novo se recusa a guardar uma data zerada. E a
**collation é `utf8mb4_0900_ai_ci`**, a que ignora acentos e maiúsculas.

## O banco

Salve isto como `legacy.sql`. É o banco inteiro, e ele cria as mesmas linhas toda vez que roda:

```sql
-- legacy.sql: an old MySQL shop. Run it with: sudo mysql < legacy.sql
-- The application that wrote it ran with a lax sql_mode, which is how the
-- zero dates got in; this session does the same, so they get in here too.
SET NAMES utf8mb4;
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';

CREATE DATABASE legacy CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE legacy;

CREATE TABLE Customers (
  CustomerID INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  Email      VARCHAR(255) NOT NULL,
  FullName   VARCHAR(100) NOT NULL,
  IsActive   TINYINT(1) NOT NULL DEFAULT 1,
  BirthDate  DATE NOT NULL DEFAULT '0000-00-00',
  CreatedAt  DATETIME NOT NULL,
  UNIQUE KEY customers_email (Email)
) ENGINE=InnoDB;

CREATE TABLE Orders (
  OrderID    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  CustomerID INT UNSIGNED NOT NULL,
  Status     ENUM('new', 'paid', 'shipped', 'cancelled') NOT NULL DEFAULT 'new',
  TotalCents INT UNSIGNED NOT NULL,
  ShippedAt  DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
  Note       VARCHAR(200) NOT NULL DEFAULT '',
  KEY orders_customer (CustomerID),
  CONSTRAINT orders_customer_fk FOREIGN KEY (CustomerID) REFERENCES Customers (CustomerID)
) ENGINE=InnoDB;

-- 2,000 customers and 10,000 orders, by arithmetic, so every run makes the
-- same rows. One customer in seven never gave a birth date; an order that has
-- not shipped carries the zero date, as the application wrote it.
SET SESSION cte_max_recursion_depth = 10000;

INSERT INTO Customers (Email, FullName, IsActive, BirthDate, CreatedAt)
WITH RECURSIVE n (i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 2000)
SELECT CONCAT('customer', i, '@example.com'),
       CONCAT(ELT(1 + i % 4, 'João', 'Zoë', 'Ana', 'Mário'), ' Customer ', i),
       IF(i % 10 = 0, 0, 1),
       IF(i % 7 = 0, '0000-00-00', DATE('1960-01-01') + INTERVAL (i * 37) % 15000 DAY),
       TIMESTAMP('2024-01-01 09:00:00') + INTERVAL i * 3 HOUR
FROM n;

INSERT INTO Orders (CustomerID, Status, TotalCents, ShippedAt, Note)
WITH RECURSIVE n (i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 10000)
SELECT 1 + (i * 7919) % 2000,
       ELT(1 + i % 4, 'new', 'paid', 'shipped', 'cancelled'),
       500 + (i * 37) % 50000,
       IF(i % 4 = 2, TIMESTAMP('2025-06-01 12:00:00') + INTERVAL i MINUTE, '0000-00-00 00:00:00'),
       IF(i % 50 = 0, 'leave at the door', '')
FROM n;

-- One row the application's own rules never meant to allow: a flag of 2,
-- and a name with a character outside the first 65,536 (an emoji, U+1F600).
INSERT INTO Customers (Email, FullName, IsActive, BirthDate, CreatedAt)
VALUES ('flag@example.com', CONCAT('Ana ', CONVERT(0xF09F9880 USING utf8mb4)), 2,
        '0000-00-00', '2025-03-01 10:00:00');
```

**A linha `SET SESSION sql_mode` é o caminho por onde os dados antigos entraram.** O servidor recusa
datas zeradas por padrão, então uma aplicação que as gravava rodava com um modo frouxo próprio; o
arquivo faz o mesmo, só na própria sessão. Bancos como este são comuns justamente porque o MySQL
usou o modo frouxo como padrão até a versão 5.7.

`SET NAMES utf8mb4` diz qual conjunto de caracteres o cliente está mandando. Sem ele, num terminal
cujo locale não é UTF-8, o cliente anuncia `latin1`, o servidor guarda cada `ã` como dois caracteres
errados, e a migração depois copia o estrago com toda a fidelidade.

```
ana@db:~$ sudo mysql < legacy.sql
ana@db:~$ sudo mysql legacy
mysql> SHOW TABLES;
+------------------+
| Tables_in_legacy |
+------------------+
| Customers        |
| Orders           |
+------------------+
2 rows in set (0.00 sec)

mysql> SELECT COUNT(*) FROM Customers;
+----------+
| COUNT(*) |
+----------+
|     2001 |
+----------+
1 row in set (0.00 sec)

mysql> SELECT COUNT(*) FROM Orders;
+----------+
| COUNT(*) |
+----------+
|    10000 |
+----------+
1 row in set (0.00 sec)

mysql> SELECT * FROM Customers LIMIT 3;
+------------+-----------------------+-------------------+----------+------------+---------------------+
| CustomerID | Email                 | FullName          | IsActive | BirthDate  | CreatedAt           |
+------------+-----------------------+-------------------+----------+------------+---------------------+
|          1 | customer1@example.com | Zoë Customer 1    |        1 | 1960-02-07 | 2024-01-01 12:00:00 |
|          2 | customer2@example.com | Ana Customer 2    |        1 | 1960-03-15 | 2024-01-01 15:00:00 |
|          3 | customer3@example.com | Mário Customer 3  |        1 | 1960-04-21 | 2024-01-01 18:00:00 |
+------------+-----------------------+-------------------+----------+------------+---------------------+
3 rows in set (0.00 sec)
```

**2.001 clientes, e não 2.000**: os gerados e a linha estranha no fim do arquivo. Os ids também não
vão de 1 a 2001: o MySQL entrega valores de `AUTO_INCREMENT` a um insert de muitas linhas em lotes,
deixa os não usados como um buraco, e a última linha ficou com 2048. A última seção desta lição
mostra por que isso importa.

## Valores que o servidor não deixa escrever

As datas zeradas estão lá, e o próprio modo estrito do MySQL não deixa você escrever uma delas para
procurá-las:

```
ana@db:~$ sudo mysql legacy
mysql> SELECT COUNT(*) FROM Customers WHERE BirthDate = '0000-00-00';
ERROR 1525 (HY000): Incorrect DATE value: '0000-00-00'

mysql> SELECT COUNT(*) FROM Customers WHERE BirthDate = 0;
+----------+
| COUNT(*) |
+----------+
|      286 |
+----------+
1 row in set (0.00 sec)

mysql> SELECT COUNT(*) FROM Orders WHERE ShippedAt = 0;
+----------+
| COUNT(*) |
+----------+
|     7500 |
+----------+
1 row in set (0.01 sec)

mysql> INSERT INTO Customers (Email, FullName, BirthDate, CreatedAt) VALUES ('CUSTOMER1@example.com', 'Ana Again', '1990-05-04', NOW());
ERROR 1062 (23000): Duplicate entry 'CUSTOMER1@example.com' for key 'Customers.customers_email'
```

**A tabela guarda valores que as regras atuais do servidor recusam.** Comparar com o número `0` os
encontra onde a data literal falha, e as contagens são as que os comentários do `legacy.sql`
prometiam: um cliente em cada sete sem data de nascimento, e todo pedido que ainda não foi enviado.

A última linha é a collation trabalhando. `CUSTOMER1@example.com` só difere do
`customer1@example.com` que já existe nas maiúsculas, e a chave `UNIQUE` em `Email` o recusou,
porque em `utf8mb4_0900_ai_ci` essas duas strings são iguais. Guarde essa recusa; a última seção
desta lição tenta o mesmo insert no PostgreSQL.
