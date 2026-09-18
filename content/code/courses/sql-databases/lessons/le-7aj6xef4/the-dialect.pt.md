---
title: Onde o próprio SQL difere
version: 1
---

As duas seções anteriores foram sobre comportamento que parece idêntico e não é. Esta é a
diferença comum: sintaxe escrita de outro jeito, que você consulta uma vez e depois sabe. É uma
lista mais curta do que as pessoas esperam, e três itens dela são armadilhas em vez de consultas.

## As três que mordem

**`||` não é concatenação no MySQL nem no MariaDB.** É OU lógico, e não falha:

```
shop=# SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;
 half |  sku   
------+--------
    2 | MN-330
(1 row)
```

```
mysql> SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;
+--------+-----+
| half   | sku |
+--------+-----+
| 2.5000 |   1 |
+--------+-----+
```

```
sqlite> SELECT 5 / 2 AS half, 'MN' || '-330' AS sku;
half  sku   
----  ------
2     MN-330
```

`'MN' || '-330'` voltou como `1`. As duas strings foram lidas como números, `'-330'` não é zero,
então o OU é verdadeiro. Sem erro, sem aviso no resultado — uma coluna `sku` cheia de `1`.
`CONCAT('MN','-330')` é a grafia portátil e funciona nos quatro.

**`5 / 2` é divisão inteira no PostgreSQL e no SQLite, e decimal no MySQL e no MariaDB.** Dois
contra dois e meio, da mesma expressão. Onde importa — uma média, uma porcentagem, um preço
unitário — escreva a divisão de modo que a resposta não dependa do motor: multiplique por `1.0`, ou
converta. `5 * 1.0 / 2` é 2.5 em todo lugar.

**Uma chave estrangeira ganha um índice no MySQL e no MariaDB, e não ganha no PostgreSQL.**
`orders` declara `customer_id` como chave estrangeira e nada mais. Aqui está o que cada motor
construiu:

```
mysql> SHOW CREATE TABLE orders\G
*************************** 1. row ***************************
       Table: orders
Create Table: CREATE TABLE `orders` (
  `id` int NOT NULL AUTO_INCREMENT,
  `customer_id` int NOT NULL,
  `ordered_on` date NOT NULL DEFAULT (curdate()),
  `total` decimal(10,2) NOT NULL,
  `status` varchar(10) NOT NULL DEFAULT 'placed',
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`) ON DELETE RESTRICT,
  CONSTRAINT `orders_chk_1` CHECK ((`total` >= 0)),
  CONSTRAINT `orders_chk_2` CHECK ((`status` in (_latin1'placed',_latin1'shipped',_latin1'cancelled')))
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci
```

```
shop=# \d orders
                               Table "public.orders"
   Column    |     Type      | Collation | Nullable |           Default            
-------------+---------------+-----------+----------+------------------------------
 id          | integer       |           | not null | generated always as identity
 customer_id | integer       |           | not null | 
 ordered_on  | date          |           | not null | CURRENT_DATE
 total       | numeric(10,2) |           | not null | 
 status      | text          |           | not null | 'placed'::text
Indexes:
    "orders_pkey" PRIMARY KEY, btree (id)
Check constraints:
    "orders_status_check" CHECK (status = ANY (ARRAY['placed'::text, 'shipped'::text, 'cancelled'::text]))
    "orders_total_check" CHECK (total >= 0::numeric)
Foreign-key constraints:
    "orders_customer_id_fkey" FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT
Referenced by:
    TABLE "order_lines" CONSTRAINT "order_lines_order_id_fkey" FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
```

`KEY customer_id (customer_id)` num; sob `Indexes:` no outro, só a chave primária. MySQL e MariaDB
criam esse índice porque o InnoDB precisa dele para checar a restrição; o PostgreSQL não precisa, e
deixa para você. Este é o índice faltante mais comum num esquema PostgreSQL escrito por quem
aprendeu no MySQL — a regra da aula 9 se aplica e nada é acrescentado por você, então o
`CREATE INDEX ON orders (customer_id)` é seu para escrever.

## As consultas

| | PostgreSQL | MySQL / MariaDB | SQLite |
|---|---|---|---|
| chave autonumerada | `GENERATED ALWAYS AS IDENTITY` | `AUTO_INCREMENT` | `INTEGER PRIMARY KEY` |
| concatenar | `\|\|` ou `concat()` | só `concat()` | `\|\|` ou `concat()` |
| citar um identificador | `"orders"` | `` `orders` `` | qualquer um dos dois |
| data de hoje | `current_date` | `curdate()`, `current_date` | `date('now')` |
| limitar linhas | `LIMIT n OFFSET m` | `LIMIT m, n` ou `LIMIT n OFFSET m` | `LIMIT n OFFSET m` |
| inserir ou atualizar | `ON CONFLICT … DO UPDATE` | `ON DUPLICATE KEY UPDATE` | `ON CONFLICT … DO UPDATE` |
| mudar a caixa | `lower()`, `upper()` | igual | igual |
| descrever uma tabela | `\d orders` | `DESCRIBE orders` | `.schema orders` |
| um booleano | `boolean`, `true`/`false` | `TINYINT(1)`, `1`/`0` | inteiro `1`/`0` |

A linha do booleano merece uma frase. MySQL e MariaDB aceitam as palavras `TRUE` e `FALSE` e as
guardam como `1` e `0` num inteiro de um byte; um driver devolve um número, e código que testa
`=== true` numa linguagem com igualdade estrita vai estar errado. O SQLite é igual, sem nem o
apelido no tipo da coluna. O PostgreSQL tem um `boolean` de verdade e um `NULL` de três valores de
verdade.

## `RETURNING`, que três dos quatro têm

A aula 11 usou `RETURNING` para receber de volta uma chave gerada na mesma ida e volta do insert:

```
shop=# INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
 id 
----
  6
(1 row)

INSERT 0 1
```

```
sqlite> INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
id
--
6
```

```
MariaDB [shop]> INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
+----+
| id |
+----+
|  6 |
+----+
```

```
mysql> INSERT INTO customers (name, email, city) VALUES ('Felipe Nunes', 'felipe@example.com', 'Recife') RETURNING id;
ERROR 1064 (42000) at line 1: You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'RETURNING id' at line 1
```

O PostgreSQL tem desde a 8.2, o SQLite desde a 3.35 e o MariaDB desde a 10.5. O MySQL não tem, e o
substituto é `LAST_INSERT_ID()` na mesma conexão — que serve para uma linha e não tem nada a
oferecer para um insert de várias. Esta é uma diferença real entre MariaDB e MySQL e a próxima
seção é sobre quantas delas existem.

## DDL transacional, que dois dos quatro têm

A aula 8 disse que uma transação é tudo ou nada. Se isso cobre o `ALTER TABLE` é decisão do motor.
Os dois abaixo rodaram `BEGIN`, acrescentaram uma coluna `phone` e então `ROLLBACK`:

```
shop=# SELECT column_name FROM information_schema.columns WHERE table_name = 'customers';
 column_name 
-------------
 id
 name
 email
 city
(4 rows)
```

```
mysql> DESCRIBE customers;
+-------+--------------+------+-----+---------+----------------+
| Field | Type         | Null | Key | Default | Extra          |
+-------+--------------+------+-----+---------+----------------+
| id    | int          | NO   | PRI | NULL    | auto_increment |
| name  | varchar(120) | NO   |     | NULL    |                |
| email | varchar(120) | NO   | UNI | NULL    |                |
| city  | varchar(120) | YES  |     | NULL    |                |
| phone | varchar(30)  | YES  |     | NULL    |                |
+-------+--------------+------+-----+---------+----------------+
```

`phone` sumiu no PostgreSQL e está lá no MySQL. MySQL e MariaDB **confirmam implicitamente** antes
e depois de toda instrução de DDL, então o `ROLLBACK` não tinha mais o que desfazer. PostgreSQL e
SQLite põem DDL dentro da transação como qualquer outra coisa.

Isso importa para as migrações da aula 11, e é o motivo de o conselho lá variar por motor. Uma
migração PostgreSQL de seis `ALTER TABLE` acontece ou não acontece. A mesma migração no MySQL pode
parar depois do terceiro, deixando um esquema que não é nenhuma das duas versões — então uma
migração para MySQL é escrita um passo reversível por vez, e a ferramenta precisa saber retomar.

## Como segurar tudo isso

Não decorando. Dois hábitos cobrem a seção inteira:

**Escreva a grafia portátil quando ela não custa nada.** `concat()` em vez de `||`,
`LIMIT n OFFSET m` em vez de `LIMIT m, n`, um `1.0` explícito numa divisão. Você não perde nada e o
código deixa de se importar.

**Quando custa algo, escreva a do motor e diga qual é.** `ON CONFLICT … DO UPDATE` é mais claro que
qualquer coisa portátil, e um comentário nomeando o motor é mais barato que uma abstração que
esconde em qual deles você está. Os query builders da aula 11 são onde isso mora numa aplicação.
