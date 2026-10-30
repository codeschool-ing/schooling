---
title: O próprio PostgreSQL, no contêiner
version: 1
---

**Um flexible server roda o PostgreSQL da comunidade**, o mesmo motor que qualquer um pode baixar,
então o contêiner que a lição 1 preparou roda a parte desta lição que é do motor. A versão 17.6, a
imagem que o `compose.yaml` nomeia, é uma versão menor da versão maior que a seção anterior declarou.

Suba-o em `~/azure` e dê ao cliente um nome curto, como a lição 8 fez para o SQL Server. O `psql` é o
cliente de linha de comando do próprio PostgreSQL e vem dentro do contêiner:

```sh
docker compose --profile postgres up -d
pg() { docker compose exec -T postgres psql -U postgres -X "$@"; }
```

`-U postgres` conecta como o superusuário que a imagem cria, e `-X` ignora qualquer arquivo pessoal
de configurações, para que o que você vê seja o que o motor responde. Depois, a descrição do motor
sobre si mesmo:

```
ana@laptop:~/azure$ pg -c "SELECT version()"
                                                      version                                                       
--------------------------------------------------------------------------------------------------------------------
 PostgreSQL 17.6 (Debian 17.6-2.pgdg13+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 14.2.0-19) 14.2.0, 64-bit
(1 row)

```

## Os pedidos, de novo

Os mesmos cem mil pedidos que a lição 8 pôs no SQL Server, escritos do jeito que o PostgreSQL fala.
Salve isto como `~/azure/orders-pg.sql`:

`orders-pg.sql`:

```sql
CREATE TABLE orders (
  order_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  customer_id int NOT NULL,
  placed_at   timestamptz NOT NULL,
  total_cents int NOT NULL
);
INSERT INTO orders (customer_id, placed_at, total_cents)
SELECT i % 7000, timestamptz '2026-01-01 00:00-03' + i * interval '5 minutes', 1500 + (i * 37) % 30000
FROM generate_series(1, 100000) AS i;
CREATE INDEX orders_customer ON orders (customer_id) INCLUDE (total_cents);
SELECT count(*) AS orders, pg_size_pretty(pg_total_relation_size('orders')) AS size FROM orders;
```

```
ana@laptop:~/azure$ pg < orders-pg.sql
CREATE TABLE
INSERT 0 100000
CREATE INDEX
 orders | size  
--------+-------
 100000 | 10 MB
(1 row)

```

**`generate_series` é a tabela de números do PostgreSQL**, e faz o que o cross join de
`sys.all_objects` da lição 8 fez com menos cerimônia. O índice é o que a lição 8 precisou criar; aqui
ele faz parte da tabela desde o começo. E a pergunta da tela de atendimento tem a mesma resposta que
no SQL Server:

```
ana@laptop:~/azure$ pg -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF, TIMING OFF, SUMMARY OFF) SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17"
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 Aggregate (actual rows=1 loops=1)
   Buffers: shared hit=15 read=3
   ->  Bitmap Heap Scan on orders (actual rows=15 loops=1)
         Recheck Cond: (customer_id = 17)
         Heap Blocks: exact=15
         Buffers: shared hit=15 read=3
         ->  Bitmap Index Scan on orders_customer (actual rows=15 loops=1)
               Index Cond: (customer_id = 17)
               Buffers: shared read=3
 Planning:
   Buffers: shared hit=77 read=7
(11 rows)

ana@laptop:~/azure$ pg -c "SELECT count(*), sum(total_cents) FROM orders WHERE customer_id = 17"
 count |  sum   
-------+--------
    15 | 256935
(1 row)

```

**Quinze pedidos, 256.935 centavos, e dois tipos de página tocada**: `shared hit` conta páginas
achadas no cache do próprio PostgreSQL e `read` conta páginas que ele precisou buscar. Esse cache é o
`shared_buffers`, e o tamanho dele é um parâmetro do servidor, que é onde a próxima seção começa.

## O que o Azure muda no motor, e o que não muda

**O motor, o SQL e os planos são os mesmos num flexible server**, e é isso que faz do contêiner um lugar
justo para praticar. Três coisas mudam, e cada uma é uma propriedade documentada do serviço, não algo
rodado aqui:

- **você não é o superusuário.** O login de administrador que o Azure cria é membro de um papel
  chamado `azure_pg_admin`, que pode criar bancos, papéis e as extensões permitidas, e não pode fazer
  o que só um superusuário faz, como ler os arquivos do servidor ou mudar a configuração por SQL;
- **as versões menores são aplicadas pelo Azure**, numa janela de manutenção que você pode escolher, e
  uma atualização maior, de 17 para 18, é algo que você inicia depois de testar;
- **o arquivo de configuração não é seu.** As configurações moram como parâmetros do servidor, lidos e
  escritos pelo Azure, que é a próxima seção.
