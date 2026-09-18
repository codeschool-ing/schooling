---
title: As três instruções que mudam dados
version: 1
---

As aulas 4 a 7 fizeram perguntas. Estas três dizem alguma coisa ao banco, e juntas são tudo o que
existe de mudar dados:

```sql
INSERT INTO customers (name, email, city) VALUES ('Duarte Alves', 'duarte@example.com', 'Sao Paulo');
UPDATE orders SET status = 'shipped' WHERE ordered_on < DATE '2026-03-05';
DELETE FROM order_lines WHERE order_id = 7;
```

**O `WHERE` é o mesmo `WHERE`.** Cada operador, cada padrão, `IN`, `BETWEEN` e o `NULL` que se recusa
a ser igual a si mesmo — a aula 4 ensinou tudo isso e nenhuma regra muda aqui. Uma linha que o
`SELECT` teria devolvido é uma linha que o `UPDATE` altera.

O que muda é quanto custa um engano. É por isso que elas chegam nesta aula e não na 4: a próxima
seção é sobre o engano, e o resto desta é sobre as instruções.

## `INSERT`

```
shop=# INSERT INTO customers (name, email, city) VALUES ('Duarte Alves', 'duarte@example.com', 'Sao Paulo');
INSERT 0 1
```

Uma linha. O zero é um identificador de objeto que o PostgreSQL deixou de usar em 2005 e continua
imprimindo.

**Escreva a lista de colunas.** Ela é opcional, e deixá-la de fora casa os valores com as colunas na
ordem em que a tabela por acaso as declara — a começar pela primeira, que aqui é a chave de
identidade que ninguém quis fornecer:

```
shop=# INSERT INTO customers VALUES ('Xico', 'xico@example.com', 'Porto');
ERROR:  invalid input syntax for type integer: "Xico"
LINE 1: INSERT INTO customers VALUES ('Xico', 'xico@example.com', 'P...
                                      ^
```

Essa é barulhenta porque os tipos discordam. A versão silenciosa é uma tabela de colunas de texto e
uma instrução que está certa há dois anos. O PostgreSQL acrescenta a coluna nova no fim, então o
`INSERT` antigo continua funcionando e para de preenchê-la sem dizer nada. O MySQL consegue
acrescentar **no meio**, onde os valores escorregam e toda linha escrita depois do deploy fica errada
por uma coluna. A lista custa uma linha e elimina a categoria.

Várias linhas vão numa instrução só:

```
shop=# INSERT INTO products (sku, name, price) VALUES ('HD-500', 'Headset', 259.00), ('WC-020', 'Webcam', 179.90);
INSERT 0 2
```

E isso não é só mais curto de ler. Três mil linhas como três mil instruções são três mil idas e
voltas ao servidor, e a aula 11 é em boa parte sobre quanto isso custa.

Os valores podem vir de uma consulta, e aí o `VALUES` dá lugar ao `SELECT` inteiro:

```sql
INSERT INTO cancelled_archive (id, customer_id, ordered_on)
SELECT id, customer_id, ordered_on FROM orders WHERE status = 'cancelled';
```

**O que você deixa de fora é o que a tabela decide.** A aula 3 declarou `ordered_on` como
`DEFAULT current_date` e `status` como `DEFAULT 'placed'`, e esta é a primeira vez que você os vê
disparar:

```
shop=# INSERT INTO orders (customer_id, total) VALUES (3, 39.90) RETURNING id, ordered_on, status;
 id | ordered_on | status 
----+------------+--------
  5 | 2026-09-18 | placed
(1 row)

INSERT 0 1
```

A data é o dia em que a instrução rodou, que é o que `DEFAULT current_date` quer dizer. E o
`RETURNING` devolve a linha como ela ficou — defaults preenchidos e a chave gerada junto, que é como
você descobre o `id` que o banco escolheu sem fazer uma segunda pergunta e torcer para nada ter
acontecido no meio.

## `UPDATE`

```
shop=# UPDATE orders SET status = 'shipped' WHERE ordered_on < DATE '2026-03-05';
UPDATE 3
```

Três linhas. **Esse número é a conferência mais barata desta aula**, e a próxima seção é quase toda
sobre lê-lo.

O lado direito de um `SET` é uma expressão, e ela pode ler a coluna que está escrevendo:

```
shop=# UPDATE products SET price = price * 1.10 WHERE sku = 'KB-101' RETURNING sku, price;
  sku   | price  
--------+--------
 KB-101 | 384.89
(1 row)

UPDATE 1
```

Cada linha é calculada a partir do próprio valor atual, numa passada só, sem laço e sem uma
instrução por linha. Um reajuste no catálogo inteiro é uma linha de SQL.

## `DELETE`

```sql
DELETE FROM order_lines WHERE order_id = 7;
```

Mesma forma e o mesmo `WHERE`. O `RETURNING` funciona aqui também, e é o único jeito de ver o que
você tirou — depois não sobra nada para selecionar:

```
shop=# DELETE FROM order_lines WHERE quantity > 1 RETURNING order_id, product_id, quantity;
 order_id | product_id | quantity 
----------+------------+----------
        2 |          3 |        2
        3 |          4 |        2
(2 rows)

DELETE 2
```

**`DELETE FROM order_lines;` sem `WHERE` esvazia a tabela.** É legal, e de vez em quando é o que
você queria mesmo.

## As restrições da aula 3 são o que faz tudo isto valer

Tudo o que a tabela declara vale para cada uma destas instruções, e a recusa é a qualidade e não o
atrito:

```
shop=# UPDATE orders SET status = 'enviado' WHERE id = 1;
ERROR:  new row for relation "orders" violates check constraint "orders_status_check"
DETAIL:  Failing row contains (1, 1, 2026-03-02, 1499.00, enviado).
```

Ela recusou um status que nenhum outro código do sistema sabe ler. A aula 3 disse que uma restrição
é uma regra que o banco mantém contra quem quer que escreva nele; isto é o manter, e a linha
`DETAIL` nomeia a linha para você não ter que procurar.

As chaves estrangeiras são a mesma regra, e um `DELETE` é onde as duas palavras no fim do esquema da
aula 1 finalmente fazem alguma coisa:

```
shop=# DELETE FROM customers WHERE email = 'ana@example.com';
ERROR:  update or delete on table "customers" violates foreign key constraint "orders_customer_id_fkey" on table "orders"
DETAIL:  Key (id)=(1) is still referenced from table "orders".
```

`ON DELETE RESTRICT`: a Ana tem pedidos, então a Ana fica. Do outro lado do esquema, `order_lines`
diz `ON DELETE CASCADE`, e essa não recusa — ela acompanha:

```
shop=# SELECT count(*) FROM order_lines WHERE order_id = 3;
 count 
-------
     2
(1 row)

shop=# DELETE FROM orders WHERE id = 3;
DELETE 1

shop=# SELECT count(*) FROM order_lines WHERE order_id = 3;
 count 
-------
     0
(1 row)
```

**`DELETE 1`, e duas linhas que ninguém nomeou se foram.** É exatamente o que o esquema pediu, e
vale saber quais das suas chaves estrangeiras dizem `CASCADE` antes de descobrir assim.
