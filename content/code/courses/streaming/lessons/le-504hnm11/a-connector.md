---
title: A connector, from table to topic
version: 1
---

**A Debezium connector is configuration, not code.** You write two property files — one for Kafka
Connect, one for the connector — and Connect does the rest: it connects to PostgreSQL, copies what
the tables hold now, and then follows the log. Before that, the database needs something to
capture.

## Two roles and a database

Two database users, with different rights. `ubuntu`, your own login, owns the tables; `cdc` is the
one Debezium connects as, and it may log in, replicate and read, and nothing else. The password is
in a file in this lab, which is acceptable for a lab and not for anything else:

```
ubuntu@stream:~/work$ sudo -u postgres createuser --createdb ubuntu
```

Because the operating-system user and the database role share a name, `createdb` and `psql` now
work without naming a user or typing a password; PostgreSQL's default **peer** authentication
trusts the login. `cdc` connects over TCP, with its password, as Debezium will.

The data is Ponto Final's catalogue and how many copies of each book every shop holds: eight books,
five shops, three copies of everything. Save this as `~/work/stock.sql`:

```sql
-- stock.sql: Ponto Final's books, and how many of each every shop holds.
CREATE TABLE books (
  book  text PRIMARY KEY,
  title text NOT NULL,
  cents integer NOT NULL
);
CREATE TABLE stock (
  shop text NOT NULL,
  book text NOT NULL REFERENCES books,
  qty  integer NOT NULL CHECK (qty >= 0),
  PRIMARY KEY (shop, book)
);
INSERT INTO books VALUES
  ('bk-01', 'Vidas Secas', 3990),
  ('bk-02', 'Grande Sertão: Veredas', 5490),
  ('bk-03', 'O Quinze', 2990),
  ('bk-04', 'Dom Casmurro', 7900),
  ('bk-05', 'Capitães da Areia', 4490),
  ('bk-06', 'A Hora da Estrela', 6200),
  ('bk-07', 'Morte e Vida Severina', 3500),
  ('bk-08', 'Memórias Póstumas de Brás Cubas', 8990);
INSERT INTO stock
  SELECT shop, book, 3
  FROM unnest(ARRAY['recife', 'olinda', 'caruaru', 'natal', 'joao-pessoa']) AS shop,
       books;
-- Debezium reads these two tables, and only these two.
CREATE PUBLICATION ponto_final FOR TABLE books, stock;
GRANT SELECT ON books, stock TO cdc;
```

```
ubuntu@stream:~/work$ createdb pontofinal
```

Forty rows of stock and eight books. **Every table Debezium captures needs a primary key**: it
becomes the key of each Kafka message, so all the changes to one row land in one partition, in
order — the rule from lesson 3, applied to rows.

## The worker and the connector

Kafka Connect runs in one of two modes. **Distributed** mode is a cluster of workers that share
connectors and keep their configuration and positions in Kafka topics; it is how Connect runs in
production. **Standalone** mode is one process that reads its configuration from files and keeps
its position in a local file, which is all a lab needs. Save the worker's configuration as
`~/work/connect.properties`:

```properties
bootstrap.servers=localhost:9092
plugin.path=/home/ubuntu/connect-plugins
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=false
offset.storage.file.filename=/home/ubuntu/work/connect.offsets
offset.flush.interval.ms=1000
```

The **converters** decide how a change becomes bytes. JSON with `schemas.enable=false` writes plain
JSON objects, which `jq` can read in the next section; with `true`, each message also carries a
description of its own fields, several times larger than the data. Lesson 6's Avro and a schema
registry are the production answer to the same problem. `offset.storage.file.filename` is where
standalone Connect writes how far the connector has got; the slot in PostgreSQL keeps the same
position on the database's side.

And the connector, as `~/work/stock-connector.properties`:

```properties
name=stock
connector.class=io.debezium.connector.postgresql.PostgresConnector
database.hostname=localhost
database.port=5432
database.user=cdc
database.password=lab-only-password
database.dbname=pontofinal
topic.prefix=pf
plugin.name=pgoutput
publication.name=ponto_final
publication.autocreate.mode=disabled
slot.name=debezium_stock
table.include.list=public.books,public.stock
```

`topic.prefix` names the topics: one per table, called `pf.public.books` and `pf.public.stock`,
prefix then schema then table. `publication.autocreate.mode=disabled` makes the connector use the
publication you made instead of creating one for every table, and `slot.name` is the slot it will
create on its first start.

## Starting it

In your **second shell**, from `~/work`, start Connect with both files. It writes its log to the
terminal, a few hundred lines of it in the first seconds, and keeps running:

```
ubuntu@stream:~/work$ connect-standalone.sh connect.properties stock-connector.properties
```

In the first shell, ask Connect itself. Every worker has a REST interface on port 8083, and it is
how you find out whether a connector is running without reading the log:

```
ubuntu@stream:~/work$ curl -s localhost:8083/connectors/stock/status | jq .
```

`RUNNING` for the connector and for its one task. A connector that cannot reach the database, or is
refused by it, shows `FAILED` here, with the Java exception in a `trace` field; that field is the
first thing to read when something is wrong. Then look at what exists now, on both sides:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --list
```

```
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, plugin, active FROM pg_replication_slots"
```

Two topics that nobody created by hand, one per table: the broker made them the moment the
connector first wrote to them, because automatic topic creation is on by default. They have one
partition each, this lab's default; a production setup creates them first, or lets Connect create
them with the partitions it is told. And in PostgreSQL there is a slot, `active`, which means
somebody is reading it right now. **From this moment, every change to `books` and `stock` is on its
way to Kafka**, and the next section reads one.
