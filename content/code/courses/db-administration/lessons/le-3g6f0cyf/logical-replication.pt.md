---
title: Replicação lógica, para o upgrade que não pode parar
version: 1
---

O pg_upgrade para o servidor por minutos, e um dump por horas. Quando até minutos são demais, o
terceiro caminho mantém o servidor antigo rodando o tempo todo. **Um servidor novo, da versão nova,
assina o antigo**: copia cada tabela uma vez, depois recebe cada mudança feita dali em diante, linha
por linha, e fica em dia pelo tempo que você quiser. Quando ele alcançou o antigo, a troca são poucos
segundos de escritas paradas enquanto a conexão da aplicação passa para o endereço novo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 248\" role=\"img\" aria-label=\"Uma linha do tempo de um upgrade por replicação lógica. O servidor antigo, 16, atende a aplicação o tempo todo até a troca, depois é guardado por um tempo e removido. O novo, 17, recebe o esquema, faz uma cópia inicial de cada tabela e depois recebe cada mudança, à medida que cada linha alterada é enviada. Na troca, de poucos segundos, as escritas param e a aplicação passa para o 17, que a atende dali em diante.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"20\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">antigo, 16</text><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">novo, 17</text><rect x=\"120\" y=\"45\" width=\"440\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">atende a aplicação, como sempre</text><rect x=\"580\" y=\"45\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--scan)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"640.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">guardado, depois removido</text><rect x=\"120\" y=\"115\" width=\"56\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"148.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">esquema</text><rect x=\"180\" y=\"115\" width=\"146\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"253.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia inicial</text><rect x=\"330\" y=\"115\" width=\"226\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"443.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recebe cada mudança</text><rect x=\"580\" y=\"115\" width=\"120\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">atende</text><line x1=\"360\" y1=\"76\" x2=\"360\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"410\" y1=\"76\" x2=\"410\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"460\" y1=\"76\" x2=\"460\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><line x1=\"510\" y1=\"76\" x2=\"510\" y2=\"113\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><rect x=\"560\" y=\"30\" width=\"20\" height=\"130\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"570\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">a troca</text><text x=\"570\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segundos</text><line x1=\"120\" y1=\"220\" x2=\"700\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"700\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo</text><text x=\"250\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cada linha alterada é enviada</text></svg>", "caption": "A replicação lógica tira o trabalho longo da janela de parada: a cópia e o alcance acontecem enquanto o servidor antigo continua atendendo, e só a troca para as escritas."}
```

**Esta seção mostra o formato e para por aí.** Replicação lógica é um assunto próprio — medir quanto
um assinante está atrasado, o que um slot de replicação custa ao publicador, o que acontece num
conflito — e a lição 14 de db-reliability o ensina. Aqui ela serve a um propósito só, um upgrade
maior, e a sessão abaixo é a menor que mostra o método e a armadilha que há nele.

## Um publicador

O servidor antigo precisa escrever no WAL o suficiente para descrever as mudanças linha por linha, o
que significa **`wal_level = logical`**, e mudar o `wal_level` exige reinício. Num servidor real esse
reinício é planejado com semanas de antecedência, como uma janela de manutenção curta própria. O
`main` não deve ser reiniciado nesta lição, então o publicador aqui é um terceiro cluster 16, criado
já com o parâmetro no lugar e preenchido do mesmo jeito que o ensaio:

```
ana@db:~$ sudo pg_createcluster 16 source -o wal_level=logical --start >/dev/null
ana@db:~$ sudo -u postgres pg_dumpall | sudo -u postgres psql -q -p 5436 >/dev/null
ERROR:  role "postgres" already exists
ana@db:~$ psql -p 5436 shop
shop=# SHOW wal_level;
 wal_level 
-----------
 logical
(1 row)

shop=# CREATE PUBLICATION upgrade FOR ALL TABLES;
CREATE PUBLICATION

shop=# \q
```

Uma **publicação** diz o que é publicado; `FOR ALL TABLES` é o banco inteiro.

## Um assinante

O lado novo precisa que as tabelas existam antes de poder preenchê-las, então começa só pelo
esquema. A cópia restaurada no `17/main` na seção anterior é trocada por um banco vazio, e o
`pg_dump` do 17 traz o esquema. `--no-publications` deixa de fora a própria publicação, que senão
seria copiada junto com as tabelas:

```
ana@db:~$ dropdb -p 5434 shop && createdb -p 5434 shop
ana@db:~$ /usr/lib/postgresql/17/bin/pg_dump -p 5436 --schema-only --no-publications shop | psql -q -p 5434 shop >/dev/null
```

```
ana@db:~$ psql -p 5434 shop
shop=# CREATE SUBSCRIPTION upgrade
shop-#     CONNECTION 'host=/var/run/postgresql port=5436 dbname=shop user=postgres'
shop-#     PUBLICATION upgrade;
NOTICE:  created replication slot "upgrade" on publisher
CREATE SUBSCRIPTION

shop=# \q
```

A string de conexão diz `user=postgres` porque o processo que conecta é um worker em segundo plano
do `17/main`, rodando como o usuário `postgres` do sistema operacional, e a autenticação peer deixa
esse usuário entrar como o papel de mesmo nome. O **slot de replicação** criado no publicador é como
o servidor antigo lembra quais mudanças o assinante ainda precisa. A lição 7 citou o perigo: um slot
que ninguém lê guarda WAL para sempre.

## Em dia

Cada tabela passa por uma cópia inicial e depois chega ao estado `r`, pronta, e a partir daí está
recebendo as mudanças:

```
ana@db:~$ psql -p 5434 shop
shop=# SELECT srrelid::regclass, srsubstate FROM pg_subscription_rel;
  srrelid  | srsubstate 
-----------+------------
 customers | r
 orders    | r
(2 rows)

shop=# SELECT count(*) FROM orders;
  count  
---------
 1000000
(1 row)

shop=# \q
```

Um pedido novo no servidor antigo:

```
ana@db:~$ psql -p 5436 shop
shop=# INSERT INTO orders (customer_id, status, total_cents, created_at)
shop-# VALUES (42, 'paid', 1999, '2026-10-01 10:00-03') RETURNING id;
   id    
---------
 1000001
(1 row)

INSERT 0 1

shop=# \q
```

chega ao novo num instante, e a armadilha também:

```
ana@db:~$ psql -p 5434 shop
shop=# SELECT id, customer_id, total_cents FROM orders WHERE id > 999999;
   id    | customer_id | total_cents 
---------+-------------+-------------
 1000000 |           1 |         500
 1000001 |          42 |        1999
(2 rows)

shop=# SELECT last_value, is_called FROM orders_id_seq;
 last_value | is_called 
------------+-----------
          1 | f
(1 row)

shop=# \q
```

**A linha chegou e a sequência não.** A replicação lógica leva linhas, e a posição de uma sequência
não é linha de tabela nenhuma: a `orders_id_seq` no assinante continua em 1, nunca usada, enquanto o
publicador já entregou 1.000.001 números.

## A troca

Numa troca real, as escritas param no servidor antigo, confere-se que o assinante tem todas as
linhas, e a aplicação é apontada para o novo. Aqui a troca é remover a assinatura, o que também
remove o slot no publicador, e então fazer o que a aplicação faria primeiro: inserir uma linha.

```
ana@db:~$ psql -p 5434 shop
shop=# DROP SUBSCRIPTION upgrade;
NOTICE:  dropped replication slot "upgrade" on publisher
DROP SUBSCRIPTION

shop=# INSERT INTO orders (customer_id, status, total_cents, created_at)
shop-# VALUES (7, 'paid', 500, '2026-10-02 09:00-03') RETURNING id;
ERROR:  duplicate key value violates unique constraint "orders_pkey"
DETAIL:  Key (id)=(1) already exists.
```

O primeiro pedido do servidor novo tentou ser o pedido número 1. **Toda sequência precisa ser
movida para além do maior valor em uso antes de a aplicação escrever**, e é este o passo que as
pessoas esquecem, porque nada reclama até o primeiro insert:

```
shop=# SELECT setval('orders_id_seq', (SELECT max(id) FROM orders));
 setval  
---------
 1000001
(1 row)

shop=# SELECT setval('customers_id_seq', (SELECT max(id) FROM customers));
 setval 
--------
  50000
(1 row)

shop=# INSERT INTO orders (customer_id, status, total_cents, created_at)
shop-# VALUES (7, 'paid', 500, '2026-10-02 09:00-03') RETURNING id;
   id    
---------
 1000002
(1 row)

INSERT 0 1

shop=# \q
```

O próximo pedido é o 1.000.002, depois do que veio pela assinatura. Uma troca real roda o `setval`
para cada sequência do banco a partir de uma consulta em `pg_sequences`, em vez de uma por uma, de
memória.

## O que mais a replicação lógica não leva

- Mudanças de esquema. Um `CREATE TABLE` ou `ALTER TABLE` no publicador não é enviado. Do momento
  em que o esquema é copiado até a troca, ninguém mexe nele.
- Tabelas sem chave primária, para `UPDATE` e `DELETE`: o assinante precisa de um jeito de achar a
  linha, e um publicador recusa esses comandos numa tabela assim até que ela tenha uma ou até que se
  defina uma `REPLICA IDENTITY`.
- Large objects, os do tipo `lo_`, que não são linhas de uma tabela comum.

Esse é o preço da parada quase nula: o maior número de peças móveis dos três métodos, e uma lista de
exceções para conferir em cada banco que você publica.
