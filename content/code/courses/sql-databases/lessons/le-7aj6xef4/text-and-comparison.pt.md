---
title: Caixa, collation, e um UNIQUE que não é o que você pediu
version: 1
---

O `customers.email` da loja é `NOT NULL UNIQUE`. Aqui está a mesma busca em três motores, com o
endereço digitado em maiúsculas:

```
shop=# SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';
 id | email 
----+-------
(0 rows)
```

```
sqlite> SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';
```

```
mysql> SELECT id, email FROM customers WHERE email = 'ANA@EXAMPLE.COM';
+----+-----------------+
| id | email           |
+----+-----------------+
|  1 | ana@example.com |
+----+-----------------+
```

Dois motores não acharam nada; um achou a Ana. Ninguém escreveu um `lower()` em lugar nenhum, e
isto não é uma configuração que alguém ligou — é o padrão.

## Por quê

Toda coluna de texto tem uma **collation**: a regra para comparar e ordenar seus valores. MySQL e
MariaDB escolhem uma que ignora caixa por padrão, e o nome diz isso se você souber onde olhar:

```
mysql> SELECT @@collation_database AS collation_database;
+--------------------+
| collation_database |
+--------------------+
| utf8mb4_0900_ai_ci |
+--------------------+
```

O sufixo é a especificação. `ai` é **accent-insensitive**, ignora acento; `ci` é
**case-insensitive**, ignora caixa. `utf8mb4_0900_ai_ci` portanto diz que `ana`, `ANA` e `Ána` são
uma string só para todo efeito que o motor tem — comparação, `ORDER BY`, `GROUP BY`, `DISTINCT`, e
o índice por trás de uma restrição `UNIQUE`.

A collation padrão do MariaDB difere da do MySQL em nome e geração, mas ignora caixa do mesmo jeito
e pelo mesmo motivo: os dois herdaram a escolha da época em que `VARCHAR` guardava sobretudo nomes
que gente digitava.

PostgreSQL e SQLite comparam texto **byte a byte** a menos que se mande o contrário, e é por isso
que os dois não devolveram nada.

## O que isso significa, e é mais do que "caixa"

Uma collation que ignora caixa alcança mais que o `WHERE`. Ela muda o que o `UNIQUE` promete.

No MySQL e no MariaDB, `email VARCHAR(120) UNIQUE` recusa `ANA@EXAMPLE.COM` quando
`ana@example.com` já existe, porque para o índice são o mesmo valor. No PostgreSQL e no SQLite os
dois são aceitos, e você tem duas contas para uma pessoa.

**Os dois comportamentos são defensáveis e o errado é o que você não esperava.** Um endereço é
insensível a caixa na prática, então o padrão do MySQL por acaso está certo ali. Um hash de senha,
um token em base64, uma chave de API ou um caminho de arquivo não são, e o mesmo padrão
silenciosamente faz de `AbC` e `abc` a mesma chave.

## O que fazer a respeito

**No MySQL ou no MariaDB, declare a collation nas colunas em que a caixa importa.** `VARCHAR(64)
COLLATE utf8mb4_bin` numa coluna de token é uma cláusula e faz a comparação ser byte a byte. Para
forçar uma comparação só em vez da coluna, ponha a cláusula no operando:

```
mysql> SELECT id, email FROM customers WHERE email COLLATE utf8mb4_bin = 'ANA@EXAMPLE.COM';
mysql> SELECT id, email FROM customers WHERE email COLLATE utf8mb4_bin = 'ana@example.com';
+----+-----------------+
| id | email           |
+----+-----------------+
|  1 | ana@example.com |
+----+-----------------+
```

A primeira não acha nada e a segunda acha a Ana, que é o que os outros dois motores fizeram desde
o começo.

**No PostgreSQL, se você quer insensível a caixa, peça.** Ou guarde o endereço em minúsculas na
entrada, ou indexe a expressão — `CREATE UNIQUE INDEX ON customers (lower(email))`, que é o índice
de expressão da aula 9 fazendo exatamente o serviço para o qual foi apresentado. Existem também uma
extensão `citext` e uma collation `nondeterministic` desde o PostgreSQL 12; o índice sobre
`lower()` é o que não precisa instalar nada e cujo comportamento fica visível no esquema.

**No SQLite, `COLLATE NOCASE`** na coluna ou na comparação. Ele dobra apenas ASCII — `Á` e `á`
continuam diferentes — o que é um limite real que vale saber antes de confiar nisso para nomes.

## A regra por baixo de tudo

**Nunca deixe o padrão do motor decidir algo com que a aplicação se importa.** Se duas strings têm
que ser o mesmo valor, diga isso no esquema; se têm que ser diferentes, diga aquilo. O padrão é um
palpite razoável sobre texto em geral, e uma aplicação sempre sabe mais do que isso.

É a mesma forma da seção anterior. O motor tem uma opinião, aplica em silêncio, e a primeira pessoa
a notar costuma ser um usuário com duas contas.
