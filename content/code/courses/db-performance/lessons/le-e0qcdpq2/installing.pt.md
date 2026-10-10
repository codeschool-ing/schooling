---
title: Instalando o PostgreSQL e o banco do curso
version: 1
---

No prompt da sua máquina Ubuntu, dois comandos instalam o servidor e o cliente `psql`:

```sh
sudo apt update
sudo apt install -y postgresql
```

O `apt` imprime um minuto de progresso e termina criando um **cluster**, a palavra do PostgreSQL
para um servidor rodando e o diretório onde ficam os seus dados. Pergunte o que você ganhou:

```
ana@vm:~$ psql --version
psql (PostgreSQL) 16.15 (Ubuntu 16.15-0ubuntu0.24.04.1)
ana@vm:~$ pg_lsclusters
Ver Cluster Port Status Owner    Data directory              Log file
16  main    5432 online postgres /var/lib/postgresql/16/main /var/log/postgresql/postgresql-16-main.log
```

## Um papel e um banco

O servidor mantém a própria lista de quem pode se conectar, e o único nome nela é `postgres`. Dê
a você mesmo um papel (*role*) com o seu nome e depois um banco para este curso:

```
ana@vm:~$ sudo -u postgres createuser --superuser $USER
ana@vm:~$ createdb market
```

`createuser` e `createdb` não imprimem nada quando funcionam. `--superuser` deixa o seu papel
mudar as configurações do servidor, o que este curso faz em quase toda aula — certo numa máquina
que é só sua, e errado em qualquer servidor de que outras pessoas dependam.

## O banco, inventado a partir de uma semente fixa

Um curso de desempenho precisa de um banco **lento de propósito**. Uma tabela de cem linhas
responde a qualquer consulta numa fração de milissegundo, faça você o que fizer com ela, então não
há nada para medir, nada para consertar e nada para aprender. Este arquivo monta um marketplace
grande o bastante para ter planos que valham a leitura: mil vendedores, duzentos mil clientes,
cinquenta mil produtos, dois milhões de pedidos e cinco milhões de eventos.

Ninguém digita dois milhões de pedidos. O arquivo os inventa com `random()`, a partir de uma
**semente fixa**, então o seu banco e o das transcrições têm as mesmas linhas. Copie-o inteiro
para um arquivo chamado `market.sql`:

```sql
-- market.sql: the database of db-performance, made up from a fixed seed.
-- A marketplace: sellers list products, customers place orders, and the
-- site logs what everybody clicks. Two runs make the same rows.
-- Load it into an empty database:  psql market -f market.sql
SELECT setseed(0.17);

CREATE TABLE sellers (
    id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name  text NOT NULL
);

CREATE TABLE customers (
    id         integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email      text NOT NULL UNIQUE,
    name       text NOT NULL,
    city       text NOT NULL,
    state      text NOT NULL,
    created_at timestamptz NOT NULL
);

CREATE TABLE products (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    seller_id   integer NOT NULL REFERENCES sellers (id),
    title       text    NOT NULL,
    tags        text[]  NOT NULL,
    price_cents integer NOT NULL CHECK (price_cents > 0)
);

CREATE TABLE orders (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id integer     NOT NULL REFERENCES customers (id),
    seller_id   integer     NOT NULL REFERENCES sellers (id),
    placed_at   timestamptz NOT NULL,
    status      text        NOT NULL,
    total_cents integer     NOT NULL
);

CREATE TABLE order_lines (
    order_id    bigint   NOT NULL REFERENCES orders (id),
    line        smallint NOT NULL,
    product_id  integer  NOT NULL REFERENCES products (id),
    quantity    integer  NOT NULL,
    price_cents integer  NOT NULL,
    PRIMARY KEY (order_id, line)
);

CREATE TABLE events (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    at          timestamptz NOT NULL,
    customer_id integer,
    kind        text  NOT NULL,
    payload     jsonb NOT NULL
);

-- 1,000 sellers. Seller 1 is the marketplace's own store, and it is big.
INSERT INTO sellers (name)
SELECT CASE WHEN n = 1 THEN 'Market Own Store' ELSE 'Seller ' || n END
FROM generate_series(1, 1000) AS n;

-- 200,000 customers in twelve cities. A city always has the same state, and
-- more people live in some cities than in others.
INSERT INTO customers (email, name, city, state, created_at)
SELECT 'user' || n || '@example.com',
       (ARRAY['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fabio',
              'Helena', 'Igor', 'Julia', 'Marcos'])[1 + floor(random() * 10)]
       || ' ' ||
       (ARRAY['Alves', 'Costa', 'Lima', 'Mendes', 'Oliveira',
              'Ribeiro', 'Rocha', 'Santos', 'Souza', 'Teixeira'])[1 + floor(random() * 10)],
       (ARRAY['Sao Paulo', 'Rio de Janeiro', 'Belo Horizonte', 'Campinas',
              'Curitiba', 'Porto Alegre', 'Salvador', 'Recife',
              'Niteroi', 'Santos', 'Fortaleza', 'Manaus'])[c],
       (ARRAY['SP', 'RJ', 'MG', 'SP', 'PR', 'RS', 'BA', 'PE',
              'RJ', 'SP', 'CE', 'AM'])[c],
       timestamptz '2022-01-01 00:00-03' + random() * interval '1460 days'
FROM (SELECT n, 1 + floor(12 * power(random(), 2))::int AS c
      FROM generate_series(1, 200000) AS n) AS pick;

-- 50,000 products: a title of three words, and two or three tags.
INSERT INTO products (seller_id, title, tags, price_cents)
SELECT CASE WHEN random() < 0.2 THEN 1 ELSE 2 + floor(random() * 999)::int END,
       (ARRAY['Blue', 'Compact', 'Classic', 'Wooden', 'Steel', 'Portable',
              'Organic', 'Smart', 'Vintage', 'Wireless'])[1 + floor(random() * 10)]
       || ' ' ||
       (ARRAY['lamp', 'chair', 'kettle', 'backpack', 'speaker', 'notebook',
              'blender', 'jacket', 'drill', 'mug'])[1 + floor(random() * 10)]
       || ' ' || n,
       ARRAY[(ARRAY['home', 'kitchen', 'office', 'outdoor', 'kids'])[1 + floor(random() * 5)],
             (ARRAY['gift', 'sale', 'new', 'eco', 'premium'])[1 + floor(random() * 5)]]
       || CASE WHEN random() < 0.1 THEN ARRAY['clearance'] ELSE '{}' END,
       100 * (5 + floor(random() * 500)::int) + 90
FROM generate_series(1, 50000) AS n;

-- 2,000,000 orders over the three years 2023 to 2025, more each year, written
-- in the order they were placed. A quarter of them are seller 1's. Most were
-- delivered long ago; the last two weeks are still on their way.
INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents)
SELECT customer_id, seller_id, placed_at,
       CASE WHEN placed_at >= '2025-12-29' THEN 'pending'
            WHEN placed_at >= '2025-12-17' THEN 'shipped'
            WHEN s < 0.03 THEN 'cancelled'
            ELSE 'delivered' END,
       total_cents
FROM (SELECT 1 + floor(random() * 200000)::int AS customer_id,
             CASE WHEN random() < 0.25 THEN 1 ELSE 2 + floor(random() * 999)::int END AS seller_id,
             timestamptz '2023-01-01 00:00-03' + sqrt(random()) * interval '1095 days' AS placed_at,
             random() AS s,
             500 + floor(random() * 50000)::int AS total_cents
      FROM generate_series(1, 2000000)) AS draw
ORDER BY placed_at;

-- One to four lines an order, two and a half on average.
INSERT INTO order_lines (order_id, line, product_id, quantity, price_cents)
SELECT o.id, k, 1 + (o.id * 7919 + k * 104729) % 50000, 1 + (o.id + k) % 3,
       100 * (5 + (o.id * k) % 500) + 90
FROM orders AS o
CROSS JOIN generate_series(1, 1 + (o.id % 4)::int) AS k;

-- 5,000,000 events over the last ninety days of 2025, in the order they
-- happened. Three in ten are visitors with no account.
INSERT INTO events (at, customer_id, kind, payload)
SELECT at,
       CASE WHEN random() < 0.3 THEN NULL ELSE 1 + floor(random() * 200000)::int END,
       kind,
       jsonb_build_object('product', 1 + floor(random() * 50000)::int,
                          'ms', 20 + floor(random() * 400)::int)
FROM (SELECT timestamptz '2025-10-03 00:00-03' + random() * interval '90 days' AS at,
             (ARRAY['view', 'view', 'view', 'view', 'view', 'view',
                    'search', 'search', 'cart', 'checkout'])[1 + floor(random() * 10)] AS kind
      FROM generate_series(1, 5000000)) AS draw
ORDER BY at;

-- The indexes the application was born with: one for each foreign key that
-- a screen reads by, and the time an order was placed.
CREATE INDEX orders_customer_id_idx ON orders (customer_id);
CREATE INDEX orders_placed_at_idx ON orders (placed_at);
CREATE INDEX order_lines_product_id_idx ON order_lines (product_id);

VACUUM ANALYZE;
```

Algumas escolhas dele são erros que um banco real também teria, feitos aqui de propósito, porque
as aulas seguintes precisam deles:

- **O vendedor 1 é enorme.** Um quarto de todos os pedidos é da loja própria do marketplace, e os
  outros 999 dividem o resto. A aula 7 trata do que isso faz com uma estimativa.
- **Uma cidade tem sempre o mesmo estado**, então as duas colunas dizem a mesma coisa duas vezes.
  O planejador supõe que são independentes, e a aula 7 mostra o preço.
- **Pedidos e eventos são gravados em ordem de tempo**, do jeito que uma aplicação real os grava.
  O índice BRIN da aula 8 depende disso.
- **Não há índice em `orders.seller_id`**, embora a tela de um vendedor leia por ele o dia
  inteiro. A aula 2 encontra isso de fora, do jeito que você encontraria no trabalho.

## Carregando

```sh
psql market -v ON_ERROR_STOP=1 -f market.sql
```

O `ON_ERROR_STOP` faz o `psql` parar no primeiro comando que falhar, em vez de relatar o erro e
seguir para o próximo — o que, para um arquivo que cria tabelas e depois as preenche, é a
diferença entre uma falha clara e um banco montado pela metade. Leva alguns minutos. Cada comando
informa o que fez ao terminar, e o último `INSERT` grava cinco milhões de linhas. Esta é a carga
inteira, cronometrada com o `time` do shell:

```
ana@vm:~$ time psql market -v ON_ERROR_STOP=1 -f market.sql
 setseed 
---------
 
(1 row)

CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
CREATE TABLE
INSERT 0 1000
INSERT 0 200000
INSERT 0 50000
INSERT 0 2000000
INSERT 0 5000000
INSERT 0 5000000
CREATE INDEX
CREATE INDEX
CREATE INDEX
VACUUM

real	2m18.547s
user	0m0.032s
sys	0m0.004s
```

**Dois minutos e 19 segundos no computador em que este curso foi gravado**, que tem quatro
processadores e memória de sobra. Uma máquina virtual com dois processadores demora mais, e é a
hora certa de ir passar um café. `real` é o tempo no relógio; `user` e `sys` são o que o próprio
`psql` gastou, quase nada, porque o trabalho acontece no servidor.

## Uma linha de configuração

Toda aula cronometra consultas, então diga ao `psql` para fazer isso sempre que abrir. Isto
escreve um arquivo que o `psql` lê ao iniciar:

```sh
cat > ~/.psqlrc <<'RC'
\set QUIET on
\timing on
\unset QUIET
RC
```

A linha do meio é a configuração. As duas em volta impedem o `psql` de anunciá-la toda vez.

Daqui em diante, cada comando vem seguido de uma linha dizendo quanto tempo levou, medido pelo
`psql` do momento em que enviou a consulta ao momento em que a resposta chegou.

Agora abra o banco e veja o que você tem:

```
ana@vm:~$ psql market
market=# SELECT relname AS table, reltuples::bigint AS rows, pg_size_pretty(pg_total_relation_size(oid)) AS size FROM pg_class WHERE relnamespace = 'public'::regnamespace AND relkind = 'r' ORDER BY pg_total_relation_size(oid) DESC;
    table    |  rows   |  size   
-------------+---------+---------
 events      | 4999827 | 618 MB
 order_lines | 4999992 | 432 MB
 orders      | 2000000 | 234 MB
 customers   |  200000 | 36 MB
 products    |   50000 | 6344 kB
 sellers     |    1000 | 128 kB
(6 rows)

Time: 4.020 ms

market=# SELECT pg_size_pretty(pg_database_size('market')) AS database;
 database 
----------
 1334 MB
(1 row)

Time: 1.903 ms
```

**1334 MB** em disco, a maior parte em eventos e linhas de pedido. São umas dez vezes os 128 MB
que o PostgreSQL reserva para si de fábrica, e a ideia é essa: parte do que você pedir vai ter de
vir do disco, e a diferença é uma das coisas que este curso mede.

Duas das contagens de linhas estão um pouco erradas — `4999908` eventos onde o arquivo gravou
cinco milhões — e isso não é defeito da carga. A coluna vem de `reltuples`, que é a **estimativa**
do próprio servidor de quantas linhas uma tabela tem, mantida em dia por `VACUUM` e `ANALYZE` a
partir de uma amostra. É o número com que o planejador trabalha, e a aula 6 trata do que acontece
quando ele erra muito, e não pouco.

O `Time:` embaixo de cada resposta é a configuração de agora há pouco funcionando.

## Uma cópia para onde voltar

Várias aulas mudam o banco: acrescentam linhas, apagam índices, reconstroem tabelas. Faça agora
uma cópia dele, enquanto tem exatamente o que o `market.sql` fez, para poder sempre voltar:

```
ana@vm:~$ createdb -T market market_base
```

`-T` nomeia um **modelo** (*template*): o banco novo começa como uma cópia, arquivo por arquivo,
do `market`, o que leva segundos em vez dos minutos de carregá-lo de novo, e dobra o espaço que o
curso ocupa no disco. A aula 2 transforma o caminho de volta num script de três linhas, e daí em
diante uma aula que muda as linhas avisa e diz quando rodá-lo.
