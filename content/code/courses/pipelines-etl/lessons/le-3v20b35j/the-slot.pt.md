---
title: Um slot, e o que ele entrega
version: 1
---

A decodificação lógica precisa que o WAL traga o suficiente para reconstruir linhas, que é a
configuração `wal_level`. O laboratório a ajustou quando montou o banco; num servidor que não é seu,
é a primeira coisa a perguntar, porque mudá-la exige reiniciar:

```
ana@vm:~/etl$ psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)
```

Um leitor do fluxo é representado no banco por um **slot de replicação**: uma posição com nome no
WAL, mais o plugin que transforma WAL em texto. O slot lembra até onde o seu leitor chegou, e o
PostgreSQL guarda cada byte de WAL que o leitor ainda não consumiu. A Ana cria um com o
`test_decoding`, o plugin que o PostgreSQL traz como demonstração:

```
ana@vm:~/etl$ psql -c "SELECT * FROM pg_create_logical_replication_slot('wh_cdc', 'test_decoding')"
 slot_name |    lsn     
-----------+------------
 wh_cdc    | 0/26E6DF00
(1 row)
```

O número na coluna `lsn` é um **número de sequência do log**: uma posição em bytes no WAL, e na sua
máquina ele vai ser outro. Daqui em diante, cada mudança confirmada na loja fica esperando o leitor
do slot. Toque um dia de vendas e olhe, sem consumir nada, com `peek`:

```
ana@vm:~/etl$ sudo bash ~/lab/lab.sh day 2026-03-01
ana@vm:~/etl$ psql -c "SELECT count(*) FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL)"
 count 
-------
  1088
(1 row)

ana@vm:~/etl$ psql -At -c "SELECT data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) WHERE data LIKE 'table public.customers: UPDATE%' LIMIT 1"
table public.customers: UPDATE: customer_id[integer]:538 name[text]:'Pedro Machado' email[text]:'pedro.machado538@example.net' city[text]:'Campinas' state[text]:'SP' created_at[timestamp with time zone]:'2025-05-10 12:00:00-03' updated_at[timestamp with time zone]:'2026-03-01 08:07:37-03'
ana@vm:~/etl$ psql -c "SELECT lsn, xid, left(data, 60) AS data FROM pg_logical_slot_peek_changes('wh_cdc', NULL, NULL) LIMIT 7"
    lsn     |  xid  |                             data                             
------------+-------+--------------------------------------------------------------
 0/26F63478 | 51696 | BEGIN 51696
 0/26F63478 | 51696 | table public.orders: INSERT: order_id[integer]:117013 shop_i
 0/26F6A170 | 51696 | table public.order_lines: INSERT: order_id[integer]:117013 l
 0/26F6EAF8 | 51696 | table public.payments: INSERT: payment_id[integer]:517013 or
 0/26F70F68 | 51696 | COMMIT 51696
 0/26F70F68 | 51697 | BEGIN 51697
 0/26F70F68 | 51697 | table public.orders: INSERT: order_id[integer]:117014 shop_i
(7 rows)
```

1.088 linhas para um dia: um `BEGIN` e um `COMMIT` em volta de cada uma das 211 transações, e 666
linhas alteradas entre eles. **Cada transação chega inteira, e só depois de confirmada**: uma
transação desfeita nunca aparece, e uma que levou vinte minutos aparece na hora em que foi
confirmada, não no começo. Esse é o problema do caixa lento da lição 4, resolvido — a ordem do fluxo
é a ordem em que as coisas viraram verdade.

A linha de `UPDATE` mostra a linha nova inteira, cada coluna com o seu tipo. O que ela não mostra é a
linha antes da atualização; a seção depois da próxima trata disso.
