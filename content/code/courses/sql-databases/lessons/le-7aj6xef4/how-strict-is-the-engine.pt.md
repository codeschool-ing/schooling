---
title: O que cada um recusa
version: 1
---

Esta é a maior diferença entre os quatro, e não está perto. A aula 3 disse que o tipo de uma coluna
é uma promessa que o banco cumpre por você. **Com que firmeza ele a cumpre é uma decisão do
motor**, e o mesmo `INSERT` é um erro num motor e uma linha guardada em outro.

Comece pelo que mostra a distância num comando só. `order_lines.quantity` é
`INTEGER NOT NULL CHECK (quantity > 0)` nos três. Aqui está uma quantidade de `'three'`:

```
shop=# INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
ERROR:  invalid input syntax for type integer: "three"
LINE 1: INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
                                              ^
```

```
mysql> INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
ERROR 1366 (HY000) at line 1: Incorrect integer value: 'three' for column 'quantity' at row 1
```

```
sqlite> INSERT INTO order_lines VALUES (5, 2, 'three', 189.00);
sqlite> SELECT order_id, product_id, quantity, typeof(quantity) FROM order_lines WHERE order_id = 5;
order_id  product_id  quantity  typeof(quantity)
--------  ----------  --------  ----------------
5         2           three     text            
5         3           2         integer         
```

O SQLite aceitou. A coluna diz `INTEGER NOT NULL`, a linha guarda a string `three`, e o
`CHECK (quantity > 0)` passou — porque no SQLite um valor de texto compara como maior que qualquer
número, então `'three' > 0` é verdadeiro. Nada foi recusado, nada foi registrado, e o próximo
relatório que somar essa coluna vai estar errado.

## Por que o SQLite faz isso

Não é bug e não é desleixo. O SQLite tem **tipagem dinâmica**: um valor carrega o próprio tipo, e o
tipo declarado de uma coluna é uma *afinidade* — uma preferência aplicada quando um valor pode ser
convertido, e ignorada quando não pode. `INTEGER` quer dizer "guarde isto como inteiro se der
razoavelmente".

Dá para ver a consequência sem inserir nada estranho. Esta é a coluna de preço da loja, que a aula
3 teve o cuidado de declarar `NUMERIC(10,2)` para que dinheiro fosse exato:

```
sqlite> SELECT sku, price, typeof(price) FROM products;
sku     price  typeof(price)
------  -----  -------------
KB-101  349.9  real         
MS-204  189    integer      
MN-330  1499   integer      
CB-012  39.9   real         
```

Quatro linhas de uma coluna, duas guardadas como `real` e duas como `integer`, **decidido por
linha**. `349.90` virou um número de ponto flutuante, e o zero final não está faltando na exibição
— ele nunca foi guardado. Os outros três motores seguram a mesma coluna como decimal exato:

```
shop=# SELECT sku, price, pg_typeof(price) FROM products;
  sku   |  price  | pg_typeof 
--------+---------+-----------
 KB-101 |  349.90 | numeric
 MS-204 |  189.00 | numeric
 MN-330 | 1499.00 | numeric
 CB-012 |   39.90 | numeric
(4 rows)
```

É por isso que o relatório da seção anterior voltou como `2998.00` em três motores e `2998` no
quarto. Não foi diferença de formatação. Foi aritmética de ponto flutuante, e a aula 3 já nomeou a
falha a que ela leva:

```
shop=# SELECT 0.1 + 0.2 = 0.3 AS exact;
 exact 
-------
 t
(1 row)
```

```
mysql> SELECT 0.1 + 0.2 = 0.3 AS exact;
+-------+
| exact |
+-------+
|     1 |
+-------+
```

```
sqlite> SELECT 0.1 + 0.2 = 0.3 AS exact;
exact
-----
0
```

**O SQLite não tem tipo decimal.** Se você guarda dinheiro em SQLite, guarde como número inteiro de
centavos e divida na hora de imprimir — o que é bom conselho em qualquer motor e é a única resposta
correta neste.

## O conserto dentro do SQLite: uma tabela STRICT

Desde a versão 3.37, de 2021, uma tabela pode ser declarada `STRICT`, e então o tipo declarado é
exigido:

```
sqlite> CREATE TABLE order_lines_strict (order_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL CHECK (quantity > 0), unit_price TEXT NOT NULL, PRIMARY KEY (order_id, product_id)) STRICT;
sqlite> INSERT INTO order_lines_strict VALUES (5, 2, 'three', '189.00');
Error: stepping, cannot store TEXT value in INTEGER column order_lines_strict.quantity (19)
```

O mesmo insert agora é recusado, com a coluna nomeada. Uma tabela `STRICT` aceita apenas `INT`,
`INTEGER`, `REAL`, `TEXT`, `BLOB` e `ANY` como tipos declarados — e é por isso que `unit_price`
acima é `TEXT` em vez de `NUMERIC(10,2)`: não há decimal a declarar, e as opções honestas são texto
ou centavos num inteiro.

**Escreva `STRICT` em toda tabela SQLite nova.** Custa uma palavra, não é o padrão apenas porque
trinta anos de bancos existentes dependem do comportamento antigo, e a falha que evita é silenciosa.

## MySQL, MariaDB, e o modo que já esteve desligado

O MySQL recusou a string acima, e nem sempre recusou. Até o MySQL 5.7, o padrão permitia que um
valor que não cabia fosse **coagido e guardado com um aviso** — `'three'` virava `0`, uma string
longa demais era truncada, uma data inválida virava `0000-00-00`. Esse comportamento é a origem da
maior parte da reputação do MySQL nesse assunto, e é controlado por uma variável em vez de ser fixo
no motor:

```
mysql> SELECT @@sql_mode\G
*************************** 1. row ***************************
@@sql_mode: ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
```

```
MariaDB [shop]> SELECT @@sql_mode\G
*************************** 1. row ***************************
@@sql_mode: STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION
```

Os dois vêm com `STRICT_TRANS_TABLES`, então uma instalação nova de qualquer um recusa a string
acima — e os dois podem ser desligados de novo, por sessão, por conexão ou num arquivo de
configuração. Num sistema que você não montou, essa variável merece ser lida em vez de suposta.

Ponha as duas listas lado a lado e uma palavra está na do MySQL e não na do MariaDB:
`ONLY_FULL_GROUP_BY`. A aula 6 disse que toda coluna da lista do `SELECT` tem que estar agrupada ou
agregada. Essa regra é do motor fazer valer, e aqui os dois discordam.

Esta consulta quebra a regra, e Recife tem dois clientes:

```
shop=# SELECT city, name, count(*) FROM customers GROUP BY city;
ERROR:  column "customers.name" must appear in the GROUP BY clause or be used in an aggregate function
LINE 1: SELECT city, name, count(*) FROM customers GROUP BY city;
                     ^
```

```
mysql> SELECT city, name, count(*) FROM customers GROUP BY city;
ERROR 1055 (42000) at line 1: Expression #2 of SELECT list is not in GROUP BY clause and contains nonaggregated column 'shop.customers.name' which is not functionally dependent on columns in GROUP BY clause; this is incompatible with sql_mode=only_full_group_by
```

```
MariaDB [shop]> SELECT city, name, count(*) FROM customers GROUP BY city;
+-----------+--------------+----------+
| city      | name         | count(*) |
+-----------+--------------+----------+
| NULL      | Elisa Fontes |        1 |
| Curitiba  | Diego Alves  |        1 |
| Recife    | Ana Ribeiro  |        2 |
| Sao Paulo | Bruno Costa  |        1 |
+-----------+--------------+----------+
```

```
sqlite> SELECT city, name, count(*) FROM customers GROUP BY city;
city       name          count(*)
---------  ------------  --------
           Elisa Fontes  1       
Curitiba   Diego Alves   1       
Recife     Ana Ribeiro   2       
Sao Paulo  Bruno Costa   1       
```

A linha de Recife diz `Ana Ribeiro` e `2`. Há dois clientes em Recife e o motor escolheu um deles —
não o primeiro, não o maior, não documentado; a linha que a varredura por acaso tinha em mãos.
Carla Meneses sumiu de um relatório que parece completo.

Essa é a forma da seção inteira. **O motor rigoroso dá uma mensagem de erro; o permissivo dá um
número plausível.** Qual dos dois você prefere depurar às quatro da tarde é o argumento inteiro.

## Os quatro, em ordem

| | recusa um valor ruim | recusa coluna solta no `GROUP BY` | decimais exatos |
|---|---|---|---|
| PostgreSQL | sempre | sempre | sim |
| MySQL 8 | por padrão, `sql_mode` desliga | por padrão, `sql_mode` desliga | sim |
| MariaDB 10.11 | por padrão, `sql_mode` desliga | **não** | sim |
| SQLite | só numa tabela `STRICT` | não | **não** |

Saem daí dois hábitos, e vale carregá-los seja qual for o motor em que você acabar. No MySQL ou no
MariaDB, **leia `@@sql_mode` num sistema que você não montou** — é uma consulta e ela diz em qual
dessas duas colunas você está vivendo. No SQLite, **escreva `STRICT`, e guarde dinheiro em
centavos.**
