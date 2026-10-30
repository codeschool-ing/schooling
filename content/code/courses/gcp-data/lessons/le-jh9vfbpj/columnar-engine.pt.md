---
title: O columnar engine, e a consulta para a qual ele existe
version: 1
---

**O columnar engine é uma segunda cópia de colunas escolhidas, guardada na memória da instância num
formato por coluna, que o planejador usa em consultas que leem muitas linhas e poucas colunas.** As
tabelas na camada de armazenamento continuam exatamente como o PostgreSQL as guarda, linha por linha.
O que o AlloyDB acrescenta é um armazenamento por coluna em memória ao lado delas, preenchido a partir
dessas tabelas e mantido em dia conforme elas mudam, e um scan que o planejador pode escolher em vez
de ler as linhas. É a única coisa que o AlloyDB muda dentro do motor, e não abaixo dele.

**A ideia errada é que ele deixa o banco mais rápido.** Ele deixa mais rápido um formato de consulta: o
relatório que soma uma coluna ao longo de meses de pedidos. O checkout, que lê um pedido pela chave e
grava uma linha, não ganha nada, porque o armazenamento por linha já é o formato certo para ele. Então
o jeito honesto de ver para que o motor serve é medir esse formato num PostgreSQL comum, ver para onde
vai o tempo, e depois ler o que o AlloyDB faz a respeito.

**Tudo o que esta seção roda é PostgreSQL 16 comum, não AlloyDB.** Não há columnar engine neste
laptop. A medida mostra o que um armazenamento por linha lê numa consulta analítica, que é o problema
que o columnar engine existe para eliminar; o que o AlloyDB faz depois é ensinado a partir da
documentação dele, "About the columnar engine" em
cloud.google.com/alloydb/docs/columnar-engine/about, e marcado onde não foi executado.

## Um PostgreSQL só seu

O Ubuntu empacota o PostgreSQL 16, e o AlloyDB oferece o 16 entre as suas versões:

```sh
sudo apt-get install -y postgresql-16
```

**O pacote inicia um servidor próprio** na porta 5432, para uso do sistema, e esta aula o deixa em
paz. Você roda um segundo em `~/gcp`, do jeito que os emuladores rodam: os arquivos num diretório seu,
em primeiro plano num terminal só dele, parado com `Ctrl+C`. Primeiro o diretório, uma vez:

```sh
export PATH="/usr/lib/postgresql/16/bin:$PATH"
initdb -D ~/gcp/pg -U quitanda --auth=trust > /dev/null
```

`-U quitanda` dá nome ao superusuário, e `--auth=trust` deixa qualquer pessoa neste computador se
conectar sem senha, o que só é aceitável porque o servidor não vai escutar em endereço de rede
nenhum. Depois, num terminal só dele:

```sh
cd ~/gcp && export PATH="/usr/lib/postgresql/16/bin:$PATH"
postgres -D ~/gcp/pg -k /tmp -p 5433 -c listen_addresses=''
```

**`listen_addresses=''` é o que torna o `trust` seguro**: o servidor só responde num arquivo de socket
em `/tmp`, que `-k` nomeia, na porta de número 5433, para nunca encontrar o servidor do sistema. No
terminal em que você digita, quatro variáveis dizem ao `psql` onde ele está:

```sh
export PGHOST=/tmp PGPORT=5433 PGUSER=quitanda PGDATABASE=postgres
```

## Dois milhões de pedidos

`orders.sql`:

```sql
SELECT setseed(0.17);
CREATE TABLE orders (
  order_id     bigint PRIMARY KEY,
  customer_id  integer NOT NULL,
  day          date NOT NULL,
  district     text NOT NULL,
  status       text NOT NULL,
  total_cents  integer NOT NULL,
  address      text NOT NULL,
  notes        text NOT NULL
);
INSERT INTO orders
SELECT n,
       1 + floor(random() * 200000)::int,
       date '2026-01-01' + floor(random() * 304)::int,
       (ARRAY['Pinheiros','Mooca','Lapa','Tatuapé','Santana','Butantã'])[1 + floor(random() * 6)::int],
       (ARRAY['delivered','delivered','delivered','cancelled','pending'])[1 + floor(random() * 5)::int],
       500 + floor(random() * 30000)::int,
       'Rua ' || md5(n::text) || ', ' || floor(random() * 2000)::int,
       repeat(md5((n * 7)::text), 3)
FROM generate_series(1, 2000000) AS n;
VACUUM ANALYZE orders;
```

**Os pedidos da Quitanda de janeiro a outubro de 2026, dois milhões deles**, com o que uma tabela de
pedidos carrega: um cliente, um dia, um bairro de São Paulo, um status, um total em centavos inteiros,
e as duas colunas de texto largas que toda tabela real tem, o endereço de entrega e as notas do
entregador. `setseed` faz toda execução gravar as mesmas linhas. `VACUUM ANALYZE` dá ao planejador as
estatísticas, para que os planos abaixo sejam os de uma tabela assentada.

```
ana@laptop:~/gcp$ psql -q -f orders.sql > /dev/null
ana@laptop:~/gcp$ psql -c "SELECT pg_size_pretty(pg_relation_size('orders')) AS size, pg_relation_size('orders') / 8192 AS pages"
  size  | pages 
--------+-------
 404 MB | 51658
(1 row)
```

**404 MB em 51.658 páginas de 8 KiB.** Essa é a tabela como um armazenamento por linha a guarda: cada
página carrega linhas inteiras, todas as colunas de cada uma lado a lado.

## A pergunta que os analistas fazem

**A receita de outubro por bairro** lê três colunas, `day`, `district` e `total_cents`, de toda linha.
O primeiro `SET` mantém a consulta num processo só, para que a contagem de páginas lidas seja um
número e não três:

```
ana@laptop:~/gcp$ psql -c "SELECT district, count(*), sum(total_cents) FROM orders WHERE day >= '2026-10-01' GROUP BY district ORDER BY district"
 district  | count |    sum    
-----------+-------+-----------
 Butantã   | 33883 | 526003202
 Lapa      | 33605 | 525988004
 Mooca     | 33966 | 524401303
 Pinheiros | 34010 | 525723124
 Santana   | 33972 | 528352923
 Tatuapé   | 34031 | 526205856
(6 rows)

ana@laptop:~/gcp$ psql -c 'SET max_parallel_workers_per_gather = 0' -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT district, count(*), sum(total_cents) FROM orders WHERE day >= '2026-10-01' GROUP BY district"
SET
                                QUERY PLAN                                 
---------------------------------------------------------------------------
 HashAggregate (actual time=212.761..212.764 rows=6 loops=1)
   Group Key: district
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=14896 read=36762 written=32
   ->  Seq Scan on orders (actual time=0.013..179.844 rows=203467 loops=1)
         Filter: (day >= '2026-10-01'::date)
         Rows Removed by Filter: 1796533
         Buffers: shared hit=14896 read=36762 written=32
 Planning:
   Buffers: shared hit=94
 Planning Time: 0.404 ms
 Execution Time: 212.841 ms
(12 rows)
```

**`Buffers: shared hit=… read=…` é o número a ler**: as páginas em que o scan tocou, achadas no cache
do PostgreSQL (`hit`) ou buscadas abaixo dele (`read`). As duas somam 51.658, a tabela inteira, para
uma resposta que precisava de três colunas de oito. O filtro em `day` jogou fora quase nove linhas em
dez, `Rows Removed by Filter`, e não poupou uma página sequer, porque as linhas de outubro estão
espalhadas pela tabela inteira e toda página precisa ser aberta para achá-las.

**Quanto dessa leitura foi de colunas que ninguém pediu** dá para medir com uma tabela que só tem as
três. Não é assim que alguém deve guardar pedidos; é uma régua:

```
ana@laptop:~/gcp$ psql -c 'CREATE TABLE orders_cols AS SELECT day, district, total_cents FROM orders' -c 'VACUUM ANALYZE orders_cols'
SELECT 2000000
VACUUM
ana@laptop:~/gcp$ psql -c "SELECT pg_size_pretty(pg_relation_size('orders_cols')) AS size, pg_relation_size('orders_cols') / 8192 AS pages"
 size  | pages 
-------+-------
 93 MB | 11840
(1 row)

ana@laptop:~/gcp$ psql -c 'SET max_parallel_workers_per_gather = 0' -c "EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT district, count(*), sum(total_cents) FROM orders_cols WHERE day >= '2026-10-01' GROUP BY district"
SET
                                  QUERY PLAN                                   
-------------------------------------------------------------------------------
 HashAggregate (actual time=130.354..130.357 rows=6 loops=1)
   Group Key: district
   Batches: 1  Memory Usage: 24kB
   Buffers: shared hit=2080 read=9760
   ->  Seq Scan on orders_cols (actual time=0.030..98.626 rows=203467 loops=1)
         Filter: (day >= '2026-10-01'::date)
         Rows Removed by Filter: 1796533
         Buffers: shared hit=2080 read=9760
 Planning:
   Buffers: shared hit=54
 Planning Time: 0.398 ms
 Execution Time: 130.426 ms
(12 rows)
```

**A mesma pergunta, uma fração das páginas.** As três colunas são 93 MB dos 404, e o scan que só tinha
elas leu 11.840 páginas em vez de 51.658, em 130 milissegundos em vez de 212. Todo o resto que o
primeiro scan leu eram endereços e notas, carregados pela consulta porque um armazenamento por linha
não consegue ler parte de uma linha. E mesmo os 93 MB são 93 MB de armazenamento por linha: cada uma
dessas linhas ainda carrega um cabeçalho próprio, e `district` escreve `Pinheiros` por extenso dois
milhões de vezes.

**O checkout é a pergunta oposta**, e a resposta do armazenamento por linha para ela é difícil de
bater:

```
ana@laptop:~/gcp$ psql -c 'EXPLAIN (ANALYZE, BUFFERS, COSTS OFF) SELECT * FROM orders WHERE order_id = 1234567'
                                    QUERY PLAN                                    
----------------------------------------------------------------------------------
 Index Scan using orders_pkey on orders (actual time=0.052..0.052 rows=1 loops=1)
   Index Cond: (order_id = 1234567)
   Buffers: shared hit=4 read=3
 Planning:
   Buffers: shared hit=114 read=1
 Planning Time: 0.580 ms
 Execution Time: 0.103 ms
(7 rows)
```

**Um punhado de buffers para um pedido inteiro**, todas as colunas, pelo índice da chave primária. Esse
é o trabalho que um banco transacional faz o dia todo, e o columnar engine não mexe nele.

## O que o AlloyDB faz a respeito, não executado

**O columnar engine guarda colunas escolhidas em memória, uma coluna de cada vez, comprimidas.** Uma
coluna de datas é uma sequência de datas, uma coluna com seis nomes de bairro diferentes pode ser
guardada como seis nomes e um código curto por linha, e um scan lê só as colunas que a consulta nomeia.
Isso elimina os dois custos que a régua acima mediu: as colunas que ninguém pediu e a repetição dentro
das que pediram. O scan então processa os valores em lotes, e não linha por linha. A documentação do
Google diz que o planejador o escolhe por custo, como qualquer outro plano, e que o `EXPLAIN` então
mostra um scan colunar onde estava o scan sequencial. **Nada disso foi executado aqui, e nenhum plano
do AlloyDB aparece.**

**Ele é ligado com uma flag do banco e preenchido de um de dois jeitos.** A flag é
`google_columnar_engine.enabled`, definida na instância, e a memória que ele pode usar é uma segunda
flag. O AlloyDB pode escolher as colunas sozinho, a partir das consultas que vê, o que a documentação
chama de auto-columnarization; ou uma tabela é acrescentada à mão:

```sql
SELECT google_columnar_engine_add('orders');
```

**Só no AlloyDB.** O PostgreSQL acima nunca ouviu falar da função:

```
ana@laptop:~/gcp$ psql -c "SELECT google_columnar_engine_add('orders')"
ERROR:  function google_columnar_engine_add(unknown) does not exist
LINE 1: SELECT google_columnar_engine_add('orders')
               ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
```

Duas consequências do projeto valem ser lembradas antes de escolhê-lo. O armazenamento por coluna é
memória, então disputa com o cache do próprio PostgreSQL os gigabytes da instância, e um grande pode
significar uma máquina maior e mais cara. E ele é uma cópia: as escritas na tabela precisam chegar a
ele também, o que o AlloyDB faz por você, a um custo com que a velocidade dos analistas é paga.

**Onde ele fica importa tanto quanto estar ligado.** A flag é por instância, então o read pool dos
analistas da seção anterior pode carregar um armazenamento por coluna grande enquanto a primária não
carrega nenhum, e o checkout nunca divide a memória com um relatório. Esse é o formato que a Quitanda
montaria.
