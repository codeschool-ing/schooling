---
title: Instalando o PostgreSQL, e o banco que você vai perder
version: 1
---

No prompt da sua máquina Ubuntu, dois comandos instalam o servidor, o cliente `psql` e as
ferramentas em volta deles:

```sh
sudo apt update
sudo apt install -y postgresql
```

O `apt` imprime uma tela de progresso, e as últimas linhas falam de criar um **cluster**: a palavra
do Ubuntu, e do PostgreSQL, para um servidor rodando e o diretório onde os dados dele moram. Pergunte
o que você ganhou:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

Versão 16, um cluster chamado `main`, na porta 5432, **`online`**. As duas colunas da direita são as
que este curso mais revisita: o **diretório de dados**, que é o banco como arquivos no disco, e o
**log**, que é o primeiro lugar a olhar quando algo deu errado. Quando a lição 2 acrescentar um
segundo servidor, ele vai ser uma segunda linha nesta tabela.

## Você, do jeito que o banco te conhece

O PostgreSQL mantém sua própria lista de quem pode se conectar, separada dos usuários do computador.
O instalador pôs um nome nela, `postgres`, e esse nome não é você:

```
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "ana" does not exist
```

Um **papel** (role) é um usuário do banco. Crie um com o seu próprio nome, agindo como
`postgres`, que tem permissão para isso:

```
ana@vm:~$ sudo -u postgres createuser --superuser $USER
ana@vm:~$ psql
psql: error: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  database "ana" does not exist
```

O `createuser` não imprimiu nada, que é o jeito dele de dizer que deu certo. `--superuser` deixa o
seu papel fazer qualquer coisa neste servidor, o que é certo numa máquina só sua e errado em
qualquer outro lugar. A segunda recusa é progresso: você entrou, e não havia banco chamado `ana`
para entrar. Este curso usa um chamado `shop`:

```
ana@vm:~$ createdb shop
```

## O shop

Todas as lições trabalham no mesmo banco pequeno: mil clientes e cinquenta mil pedidos. Ele é gerado
em vez de baixado, por um script que produz as mesmas linhas toda vez que roda, e essa propriedade
importa mais do que parece. Quando a lição 6 restaurar o shop para um momento antes de um erro, você
vai conferir o resultado contra números impressos aqui, e eles só significam alguma coisa se a sua
cópia e esta foram montadas do mesmo jeito.

Salve isto como `shop.sql` no seu diretório home. O botão de copiar acima do código pega o script
inteiro, sem as notas.

```schooling-example
{"language": "sql", "file": "shop.sql", "parts": [{"code": "-- shop.sql: the course's database, built the same way every time\nDROP TABLE IF EXISTS orders, customers;\n", "note": "Toda execução começa do zero. Apagar as duas tabelas primeiro quer dizer que o script pode ser rodado de novo, e a lição 2 faz isso."}, {"code": "CREATE TABLE customers (\n  id   bigint PRIMARY KEY,\n  name text NOT NULL,\n  city text NOT NULL\n);\n\nCREATE TABLE orders (\n  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,\n  customer_id bigint NOT NULL REFERENCES customers,\n  total_cents integer NOT NULL CHECK (total_cents > 0),\n  placed_at   timestamptz NOT NULL\n);\n", "note": "Duas tabelas ligadas por uma chave estrangeira, para que uma restauração que traga de volta uma tabela e não a outra falhe de forma barulhenta."}, {"code": "INSERT INTO customers\nSELECT i, 'customer ' || i,\n       (ARRAY['Recife', 'Porto Alegre', 'Belém', 'Curitiba'])[1 + i % 4]\nFROM generate_series(1, 1000) AS i;\n", "note": "`generate_series` produz os números de 1 a 1000, e cada um vira um cliente. A cidade é escolhida pelo resto da divisão, então um quarto deles mora em cada uma."}, {"code": "INSERT INTO orders (customer_id, total_cents, placed_at)\nSELECT 1 + (i * 7919) % 1000,\n       500 + (i::bigint * 104729) % 20000,\n       timestamptz '2026-01-01 09:00-03' + i * interval '7 minutes'\nFROM generate_series(1, 50000) AS i;\n", "note": "Nenhum número aleatório em lugar nenhum. Multiplicar por um primo e tirar o resto espalha os clientes e os totais, e dá a mesma resposta em qualquer máquina. Um pedido a cada sete minutos desde 1º de janeiro cobre oito meses."}, {"code": "CREATE INDEX orders_customer ON orders (customer_id);", "note": "Um índice, porque uma restauração tem que reconstruí-los e isso leva um tempo que vale medir."}]}
```

Rode o script e olhe o que você criou:

```
ana@vm:~$ psql shop -f shop.sql
psql:shop.sql:2: NOTICE:  table "orders" does not exist, skipping
psql:shop.sql:2: NOTICE:  table "customers" does not exist, skipping
DROP TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1000
INSERT 0 50000
CREATE INDEX
```

As duas linhas de `NOTICE` são o `DROP TABLE IF EXISTS` não achando nada para apagar na primeira
vez, o que é inofensivo. Depois:

```
shop=# SELECT count(*) AS customers FROM customers;
 customers 
-----------
      1000
(1 row)

shop=# SELECT count(*) AS orders, min(placed_at), max(placed_at) FROM orders;
 orders |          min           |          max           
--------+------------------------+------------------------
  50000 | 2026-01-01 09:07:00-03 | 2026-09-01 10:20:00-03
(1 row)
```

**Cinquenta mil pedidos, de 1º de janeiro a 1º de setembro de 2026.** Guarde esses dois números; o
resto desta lição é sobre recuperá-los.
